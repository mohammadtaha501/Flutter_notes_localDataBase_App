import 'package:flutter/material.dart';
import 'package:expandable_text/expandable_text.dart' show ExpandableText;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'generic_message.dart';
import 'Notes_service_database.dart';
import 'newNoteAddingAndEditing_view.dart';
//always run "flutter pub get"command in flutter terminal after adding a dependency
//see line 137 important wighit their
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp( MaterialApp(
    title: 'Flutter Demo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const MainUI(),
  )
  );
}

class MainUI extends StatefulWidget {
  const MainUI({super.key});
//when a new screen is pushed it will have a back arrow in the app bar
//so this screen will have a app bar  but i have removed it using
  // automaticallyImplyLeading: false, in app bar
  //setting  automaticallyImplyLeading: to false will remove the app bar

  @override
  State<MainUI> createState() => _MainUIState();
}

class _MainUIState extends State<MainUI> {
  @override
  void initState() {
    _initializeDatabase();
    super.initState();
  }
  Future<void> _initializeDatabase() async {
    try {
      await noteService.open(); // Assuming _db.open() is an async method
      print('Database is open.');
      setState(() {
        // Update your UI or perform actions with the opened database
      });
    } catch (e) {
      print('Error opening database: $e');
    }
  }
  //int counter = 0;


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("Your Notes"),
        automaticallyImplyLeading: false, // Add this line to hide the back arrow
        actions: [
          IconButton(
              onPressed:() {
                int id=0;
                String text=' ';
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewNotesView(id:id ,newTextToAdd: text)),
                );
                setState(() {

                });
              },
              icon: const Icon(Icons.add)
          ),
/*enum is created to handele the values to be returned from the PopItem in the app aap bar you will see the the dots in menu button those dots are shown
using PopupMenuButton and the options shown in it are the PopupMenuItem and
PopupMenuItem is returned in the itemBuilder: (context) and you can return
multiple  PopupMenuItem as it returns the list of PopupMenuItem and when an
PopupMenuItem is pressed its return a value to onSelected and the value will be
PopupMenuItem<PopupAction>(value: this value written after this see below for
example   */
          PopupMenuButton(
            color: Colors.white,
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value:"logout",/*this value can be of any
                  datatype eg int weighit*/
                  child:Text("logout"),
                ),
                const PopupMenuItem(
                  value:"test" ,
                  child:Text("test"),
                )
              ];
            },
            onSelected:(value) async{
              switch (value){
                case "logout":
                  final Dialogresult=await showGenericDialog(context: context
                      ,message: "are you sure you want to logout",tittle: "logout",
                    optionBuilder: () => {
                    'yes':true,
                    'NO':false,
                    },);/* context
                predefined but not reachable in the function and this function is
                created in DialogMessage dart file*/
                  if(Dialogresult==true){
                    await FirebaseAuth.instance.signOut();
                    // Navigator.push(context,
                    //   MaterialPageRoute(builder: (context) => const LoginView()),
                    // );
                    Navigator.of(context).pushNamed('/login/');
                  }
                  else if(Dialogresult==false){
                    print("false is returned");
                  }
                  else if(Dialogresult==null){
                    print("null is returned");
                  }
                  else{}
                  print("logout pressed");
                case "test":
                  print("test pressed");
              }
            },
          )
        ],

      ),
      body:StreamBuilder(
        stream:noteService.noteStreamCController.stream,//if the stream is null connection state will be .waiting
        //and getter function dont require any paranthese brackets()
        builder:(context, snapshot) {
          switch (snapshot.connectionState){
            case ConnectionState.active:
              if (!snapshot.hasData || snapshot.data==null) {
                return const Text("No data found");
              }
              if(snapshot.hasData){
                final allNOtes=snapshot.data as List<Map<String, Object?>>;
                return ListView.builder(
                  itemCount: allNOtes.length,
                  itemBuilder: (context, index) {
                    final note=allNOtes[index];
                    return ListTile(
                      onTap: () {
                        String text=note['text'] as String;
                        print(text);
                        int id=note['id'] as int;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NewNotesView(id:id ,newTextToAdd: text)),
                        );
                        //  Navigator.of(context).pushNamed('/addOrEditNotes/',arguments: { 'id':id, 'newTextToAdd':text });
                        //in arguments we are sending the map
                        //so 'id','newTextToAdd' are the keys
                      },
                      title:ExpandableText(      //for ExpandableText add the dependency expandable_text
                        note['text'] as String,  //using flutter pub add expandable_text
                        expandText: 'click to see the text',//and then use it after adding library for it
                        collapseText: 'Show less',
                        maxLines: 1,
                        linkColor: Colors.blue,
                      ),
                      trailing:IconButton(
                        onPressed: () async{
                          final deleteOrNot=await showGenericDialog(context: context,message: "Ar you sure you want to delete this",
                              tittle: "Alert",optionBuilder: () => {'yes':true,'NO':false});
                          if(deleteOrNot??false){
                            //onDeleteNote(note);
                            try{
                              await noteService.deleteNotes(note['id'] as int);
                              noteService.cacheNotes();
                              setState(() {
                                // Rebuild the widget after the delete operation
                              });
                            }on UnsupportedError catch(e){
                              print(e.message);
                            }
                          }
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    );
                  },
                );
              }else{
                return const Text("no data found");
              }
            case ConnectionState.done:
              return const Text("done");
            case ConnectionState.none:
              return const Text("none");
            case ConnectionState.waiting:
              return const Text("please enter some notes");
            default:
              return  const Text('default');
          }
        },
      ),
    );
  }
}