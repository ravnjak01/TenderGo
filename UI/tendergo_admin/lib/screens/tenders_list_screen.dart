import 'package:flutter/material.dart';

class TendersListScreen extends StatefulWidget {
  const TendersListScreen({super.key});

  @override
  State<TendersListScreen> createState()=>_TendersListScreenState();

}

class _TendersListScreenState extends State<TendersListScreen>{
  @override
  
  Widget build(BuildContext context){
    return Container(
      child: Column(children: [
        Text("Test"),
        SizedBox(height: 20,),
        ElevatedButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Back"))

      ],)
    );

  
  }
}