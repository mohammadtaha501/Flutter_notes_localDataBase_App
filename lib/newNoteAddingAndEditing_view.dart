import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'generic_message.dart';
import 'Notes_service_database.dart';

class NewNotesView extends StatefulWidget {
  final int id;
  final String newTextToAdd;
  const NewNotesView({
    super.key,
    required this.id,
    required this.newTextToAdd,
  });
  @override
  State<NewNotesView> createState() => _NewNotesViewState();
}

class _NewNotesViewState extends State<NewNotesView> {
  @override
  void initState() {
    print("${widget.id} in new notes view");
    super.initState();
  }
  TextEditingController textController=TextEditingController();
  Map<String,Object?>? note={};
  Future<void> createNote()async{
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final email = currentUser.email!;
      note=await noteService.createNote(email, textController.text);
    }on CouldNotFindUser{
      print("something went wrong");
    }
  }

  Future<void> saveNoteIfNotEmpty()async {
    if(textController.text.isNotEmpty){
      await createNote();
    }
  }
  @override
  void dispose() {            //when the screen is killed this function is called in this when back arrow is pressed
    if(widget.id==0){
      print('creating note');
      saveNoteIfNotEmpty();
    }     //and in this function it will automatically save the note when the screen is killed
    else{
      print("updating the value");
      noteService.updateNotes(widget.id,textController.text);
    }
    noteService.cacheNotes();
    textController.dispose();//deleting the text controller so that it dont remain in the memory or when come back
    super.dispose();         //to this page
  }
  @override
  Widget build(BuildContext context) {
    if(widget.newTextToAdd!=' '){
      textController.text=widget.newTextToAdd;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("New Note"),
        actions: [
          IconButton(onPressed: () async{
            if(textController.text.isEmpty){
              await showGenericDialog(context: context,message:'cant share empty text',tittle:'',optionBuilder:() => {"ok":null,});
            }
            else{
              Share.share(textController.text);//this will show the share menu which you see in instagram when click share to other
              //and need to run flutter pub add share_plus ,flutter clean,flutter pub get
            }
          },
              icon: const Icon(Icons.share))
        ],
      ),
      body:  Column(
        children: [
          const Center(
            child: Text("text will be saved/updated automatically",
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'enter your note here',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
