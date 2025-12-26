import 'package:flutter/material.dart';
import 'package:liquidgalaxy_task2_gsoc2026/services/lg_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final LgService _lgService = LgService();

  String? selectedKml;
  final List<String> kmlList = [
    "Plate Boundaries",
    "Quadrilateral",
  ];


  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
})async{
    return showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title , style: const TextStyle(color: Colors.white),),
            content: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(content,style: const TextStyle(color: Colors.white70),)
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: (){
              Navigator.of(context).pop();
            }, child: const Text('Cancel' , style: TextStyle(color: Colors.blueAccent),)
            ),
              TextButton(onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              }, child: const Text('OK' , style: TextStyle(color: Colors.blueAccent),))
            ],

          );
        });
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //logo image
                  SizedBox(
                    width: double.infinity,
                    height:100,
                    child: Image.asset("assets/lg_logo.png" , scale:2,),
                  ),
                  const SizedBox(height: 30,),
                  // Send Logo button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async{
                        if(!_lgService.isConnected){
                          await _lgService.connectToLG();
                        }
                        if(_lgService.isConnected){
                          await _lgService.sendLogo();
                        }
                      },   // function to add for adding the logo
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                        ), child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Send Logo",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 5),
                    child: Text("Select Kml File" , style: TextStyle(color: Colors.white , fontSize: 20 , fontWeight: FontWeight.bold)),
                  ),
              
                  const SizedBox(height: 15,),

                  //kml dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedKml,
                            hint: const Text("Select KML" , style: TextStyle(color: Colors.white),),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: kmlList.map((kml){
                                return DropdownMenuItem(
                                    value: kml,
                                    child: Text(kml));
                              }).toList(),
                            onChanged: (value){
                            setState(() {
                              selectedKml = value ;
                            });
                            }
                            )
                    ),
                  ),
                  
                  const SizedBox(height: 20,),
              
                  // Show KML  button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                        onPressed: ()async{
                          if(!_lgService.isConnected){
                            await _lgService.connectToLG();
                          }
                          if(_lgService.isConnected){
                             // check the selection from the drop box accordingly send the kml
                            if(selectedKml == "Plate Boundaries"){
                              await _lgService.sendKml('assets/plates.kml');
                            }else if(selectedKml == "Quadrilateral"){
                              await _lgService.sendKml('assets/Quadrilateral.kml');
                            }
                          }
                        },  // for showing the kml to screen function
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                        ),
                        child: const Text("Show KML in Screen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600 , color: Colors.black),)),
                  ),
                  const SizedBox(height: 50,),
              
                  // clean buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      cleanButton("Clean Logo", Icons.cleaning_services, Colors.redAccent),
                      cleanButton("Clean KML", Icons.cleaning_services, Colors.redAccent)
                    ],
                  ),
              
                  const SizedBox(height: 40,),
                  // control buttons
              
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      controlButton("Reboot", Icons.restart_alt, Colors.grey),
                      const SizedBox(height: 15,),
                      controlButton("Shutdown", Icons.power_settings_new, Colors.grey),
                      const SizedBox(height: 15,),
                      controlButton("Relaunch", Icons.not_started_rounded, Colors.grey),
                      const SizedBox(height: 15,),
                      ]
                  )
              
                ],
              ),
            ),
          )),
    );
  }

  Widget controlButton(String title ,IconData icon , Color color) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(onPressed: ()async{
        _showConfirmationDialog(
            title: '$title',
            content: 'Are you sure you want to $title the Liquid Galaxy rig?',
            onConfirm: ()async{
              if(title == "Reboot"){
                await _lgService.reboot();
              }else if(title == "Shutdown"){
                await _lgService.shutdown();
              }else if(title == "Relaunch"){
                await _lgService.relaunchLG();
              }
            });

      }, // functions for basic controls
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon , color: Colors.white,size: 20,),
              const SizedBox(width: 8,),
              Text(title , style: const TextStyle(fontSize: 20 , fontWeight: FontWeight.w600 ,color: Colors.white),)
            ],
          )),
    );
  }


  Widget cleanButton(String title ,IconData icon , Color color) {
    return SizedBox(
      width: 160,
      height: 100,
      child: ElevatedButton(onPressed: (){
        if(title == "Clean Logo"){
          _lgService.cleanLogo();
        }else if(title == "Clean KML"){
          _lgService.cleanKML();
        }
      }, // for clean logo and kml function
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon , color: Colors.white, size: 20,),
              const SizedBox(height: 8,),
              Text(title , style: const TextStyle(fontSize: 18 , fontWeight: FontWeight.w600 ,color: Colors.white),)
            ],
          )),

    );
  }








}
