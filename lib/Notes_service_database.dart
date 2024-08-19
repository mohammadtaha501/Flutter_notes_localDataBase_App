import 'dart:async';
import 'dart:core';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

//dont forget to add await on function which have Future in their return type

const dbName="notes.db";

int notesId=0;

class DatabaseAlreadyOpenException implements Exception{}
class DatabaseNotOpenException implements Exception{}
class UnableToGetDocumentsDirectory implements Exception{}
class CouldNotDeleteUser implements Exception{}
class UserAlreadyExist implements Exception{}
class CouldNotFindUser implements Exception{}
class noRowUpdated implements Exception{}
class NotesNotCreated implements Exception{}
class NoNotesFound implements Exception{}

/*if the exception is thrown you can use try and catch statement in the place where function is being called
and use the exception in the on statement for example see line 48 and getNotes function throws CouldNotFindUser
exception and also see getNotes function to understand it better*/

class NotesService{

  late Database _db;
  List<Map<String,Object?>> _notes=[];/*to insert the data in the stream controller */
  late final StreamController<List<Map<String,Object?>>> noteStreamCController;//declaration of the stream controller

  static final NotesService _shared=NotesService._sharedInstance();
  NotesService._sharedInstance() {
    noteStreamCController = StreamController<List<Map<String,Object?>>>.broadcast(
      onListen: () {
        noteStreamCController.sink.add(_notes);
      },
    );
  }
  factory NotesService()=> _shared;//making sure that only one instance of this class is created by the previous lines


/*stream controller automatically creates a stream and it used to show the data with continues updates
everytime .add function called on stream controller it will remove the previous data
and will add the new data in the stream */

  Future<void> cacheNotes()async{
    final allNotes=await getAllNotes();
    if(allNotes!=null){
      _notes=allNotes;
      print("catching the notes");
      /*to insert the data in the stream controller */
      noteStreamCController.sink.add(_notes);
    }
  }

  Future<Map<String,Object?>?> getOrCreateUser (String email)async{
    if(_db.isOpen) {
      print('in getOrCreateUser');
      try {
        final result = await getUser(email);
        return result;
      } on CouldNotFindUser {
        final recordAdded = await _db.insert('user', {
          'email': email,
        }
        );
        Map<String, Object?> returnAddedRecord = {
          'user_id': recordAdded,
          'email': email,
        };
        print("user created");
        return returnAddedRecord;
      }
    }else{
      print("in get or create user exception");
      throw DatabaseNotOpenException();
    }
  }

  Future<void> updateNotes(int id,String text)async {
    final noOfRowUpdated = await _db.update(
      'notes',
      {'text': text },
      where: 'id=?',
      whereArgs: [id],
    );
    //updating the stream controller
    if (noOfRowUpdated == 0) {
      throw noRowUpdated();
    }
    else {
      // for(int i=0;i<_notes.length;i++) {
      //  final temp = _notes[i];
      //  if (temp['id'] == id) {
      //   Map<String, Object?> changeInNotes = {
      //    'id': temp['id'],
      //    'text': text,
      //    'user_id': temp['user_id']
      //   };
      //   _notes[i] = changeInNotes;
      //   break;
      //  }
      // }
      //for less time complexity use the code below
      _notes.removeWhere((map) =>map['id'] == id);           //deleting the old record from the _notes
      final note = await getNotes(id); //as the record is already updated so this will
      // return the updated record and old record is already deleted
      _notes.add(note[0]);
      // the getNotes(id) returned the type Map<String,Object> without ?
      //and _notes type is Map<String,Object?> so type casting it so tha tit can be stored in notes
      noteStreamCController.add(_notes); //adding to stream controller
      //or else another method tp update stream controller
/*   _notes = [];
     final featchNotes = await getAllNotes(); //dont forget to add await on function which have Future in their return type
     if (featchNotes != null){
     _notes = featchNotes;
     _noteStreamCController.add(_notes);
   }           */
    }
  }

  Future<List<Map<String,Object?>>?> getAllNotes()async{
    if(_db.isOpen){
      final results=await _db.query(
        'notes',
      );
      if(results.isNotEmpty){
        return results;
      }
      else{return null;}
    }
    else{throw DatabaseNotOpenException();}
  }

  Stream<List<Map<String,Object?>>> get streamGetAllNotes{
    //this is a getter function so it has the keyword get and if it don't need
    //parameter then don't need to add () parameter bracket
    if(_db.isOpen){
      print('in streamGetAllNotes');
      return noteStreamCController.stream;
    }
    else{print("in streamGetAllNotes exception");
    throw DatabaseNotOpenException();}
  }

  Future<Map<String,Object?>> getUser(String email)async{
    if(_db.isOpen){
      final results=await _db.query(
        'user',
        where: 'email=?',
        whereArgs: [email.toLowerCase()],
        limit: 1,
      );
      if(results.isEmpty){
        throw CouldNotFindUser();
      }
      else{
        return results.first;
      }
    }
    else{
      throw DatabaseNotOpenException();
    }
  }

  Future<List<Map<String,Object?>>> getNotes(int id)async{
    if(_db.isOpen){
      final result=await _db.query(
        'notes',
        limit: 1,
        where: 'id=?',
        whereArgs: [id],
      );
      if(result.isNotEmpty){
        return result;
      }else{
        throw NoNotesFound();
      }
    }
    else{
      throw DatabaseNotOpenException();
    }
  }

  Future<void> deleteNotes(int id)async{

    await _db.delete(
        'notes',
        where:'id=?',
        whereArgs: [id]);
    // _notes.removeWhere((map)=> map['id'] == id);
    // _noteStreamCController.add(_notes);
    cacheNotes();
  }

  Future<void> deleteAllNotes()async{
    if(_db.isOpen){
      await _db.delete('notes');//this is going to delete the all rows int the table 'notes'
      _notes=[];
      noteStreamCController.add(_notes);}
  }

  Future<Map<String,Object?>> createNote(String email,String text)async{
    if(_db.isOpen){
      try{
        final user=await getUser(email);
        final id=await _db.insert(
            'notes', {
          'user_id': user['user_id'],
          'text': text,
        }
        );
        Map<String, Object?> addedRecord = {
          'id': id, 'text': text, 'user_id': user['user_id']
        };
        _notes.add(addedRecord);
        noteStreamCController.add(_notes);
        //cacheNotes();
        return addedRecord;
      }on CouldNotFindUser{
        throw CouldNotFindUser();
      }
    }
    else{
      throw DatabaseNotOpenException();
    }
  }

  Future<void> close() async{
    if(_db.isOpen){
      await _db.close();
    }else{
      throw DatabaseNotOpenException();
    }
  }

  Database getDatabaseOrThrowError(){
    if(_db.isOpen){
      return _db;
    }
    else{
      throw DatabaseNotOpenException();
    }
  }

  Future<void> open()async{
    try{
      print("in open");
      final docsPath=await getApplicationDocumentsDirectory();
      final dbPath=join(docsPath.path,dbName);
      _db=await openDatabase(dbPath);
      String createTable='''CREATE TABLE IF NOT EXISTS "user" (
	"user_id"	INTEGER NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("user_id" AUTOINCREMENT)
);''';
      await _db.execute(createTable);
      createTable='''CREATE TABLE IF NOT EXISTS"notes" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"text"	TEXT,
	FOREIGN KEY("user_id") REFERENCES "user"("user_id"),
	PRIMARY KEY("id")
  );''';
      await _db.execute(createTable);
      await cacheNotes();
    }on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }

  Future<void> deleteUser(String email) async{
    final deleteCount=await _db.delete(
      "user",//name of the table to delete from
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if(deleteCount==0){
      throw CouldNotDeleteUser();
    }
  }

  Future<Map<String,Object?>> createUser(String email)async{
    if(_db.isOpen){
      final results= await _db.query(//.query is to fetch a record
          "user",
          limit: 1,
          where: 'email=?',
          whereArgs: [email.toLowerCase()]
      );
      if(results.isNotEmpty){
        throw UserAlreadyExist();
      }
      else{
        final userId=await _db.insert('user', {
          "email":email.toLowerCase(),
        }
        );
        Map<String,Object?> createdUser={
          'user_id': userId,'email':email
        };
        return createdUser;
      }
    }else{
      throw DatabaseNotOpenException();}
  }
}
NotesService noteService=NotesService();