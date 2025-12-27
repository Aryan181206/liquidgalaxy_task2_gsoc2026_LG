import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquidgalaxy_task2_gsoc2026/services/lg_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}


class _SettingScreenState extends State<SettingScreen> {
  final LgService _lgService = LgService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _screensController = TextEditingController();

  bool isPasswordVisible = false ;
  bool _isConnected = false ;


  LgConnectionModel _model = LgConnectionModel() ;

  @override
  void initState(){
    super.initState();
    _loadSetting();
  }
  @override
  void dispose(){
    _usernameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    _screensController.dispose();
    super.dispose();
  }

  Future<void> _loadSetting() async {
    // load the model
    final loadedModel = await _model.loadFromPreference();
    setState(() {
      _model = loadedModel ;
      _usernameController.text = _model.username;
      _ipController.text = _model.ip;
      _portController.text = _model.port.toString();
      _passwordController.text = _model.password;
      _screensController.text = _model.screens.toString();
      _isConnected = _lgService.isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusChip(isConnected: _isConnected),
            SizedBox(height: 10,),
            Text('Username'),
            SizedBox(height: 5,),
            CustomTextField(label: "lg", controller: _usernameController , prefixIcon: Icon(Icons.person),),
            SizedBox(height: 8,),
            Text('IP Address'),
            SizedBox(height: 5,),
            CustomTextField(label: "192.168.201.3", controller: _ipController , prefixIcon: Icon(Icons.network_wifi),),
            SizedBox(height: 8,),
            Text('Port'),
            SizedBox(height: 5,),
            CustomTextField(label: "22", controller: _portController , prefixIcon: Icon(Icons.cable), keyboardType: TextInputType.number,),
            SizedBox(height: 8,),
            Text('Password'),
            SizedBox(height: 5,),
            CustomTextField(label: "lg1234", controller: _passwordController , prefixIcon: Icon(Icons.lock), obscureText: !isPasswordVisible, suffixIcon: IconButton(onPressed: (){
              setState(() {
                isPasswordVisible = !isPasswordVisible ;
              });
            },
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey,)),),
            SizedBox(height: 8,),
            Text('No. of Screen'),
            SizedBox(height: 5,),
            CustomTextField(label: "3", controller: _screensController , prefixIcon: Icon(Icons.computer), keyboardType: TextInputType.number,),

            SizedBox(height: 24,),


            // connect button we have to add the function here
            ElevatedButton(onPressed: () async{
              // validation
              if(_usernameController.text.isEmpty ||
                  _ipController.text.isEmpty ||
                  _portController.text.isEmpty ||
                  _passwordController.text.isEmpty ||
                  _screensController.text.isEmpty
              ) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all the fields'))
                );
              }
              // update _model with current text from controller
              _model.username = _usernameController.text;
              _model.ip = _ipController.text;
              _model.port = int.parse(_portController.text);
              _model.password = _passwordController.text;
              _model.screens = int.parse(_screensController.text);

              // Save these to values to Preferences
              await _model.saveToPreference();

              // update the services with the new settings
              _lgService.updateConnectionSettings(
                  ip: _model.ip,
                  port: _model.port,
                  username: _model.username,
                  password: _model.password,
                  screens: _model.screens
              );

              // now connect
              bool? success = await _lgService.connectToLG();
              if(success==true){
                print("Connected Successfully");
                await _lgService.execute('echo "search=spain" > /tmp/query.txt', 'First cmd Sent');
                setState(() {
                  _isConnected = success ?? false ;
                });
              }else{
                print("Failed to connect");
              }
            },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)
                  )
                ),
                child: Text('Connect',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold , color: Colors.white),)
            ),

            SizedBox(height: 20,),

            // diconnect
            ElevatedButton(onPressed: (){
              _lgService.disconnect();
              setState(() {
                _isConnected = false ;
              });
            }, style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)
              )
            ) ,child: Text('Disconnect' , style: TextStyle(fontSize: 18 , fontWeight: FontWeight.bold , color: Colors.white),))
          ],
        ),
      )),
    );
  }
}






class StatusChip extends StatelessWidget {
  final bool isConnected;
  
  const StatusChip({super.key , required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14 , vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8,),
            Text(
              isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(fontSize: 13)
            )
          ],
        ),
      ),
    );
  }
}


class CustomTextField extends StatelessWidget {
  final String label ;
  final TextEditingController controller ;
  final bool obscureText ;
  final Widget? prefixIcon ;
  final Widget? suffixIcon ;
  final TextInputType keyboardType ;


  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: Colors.grey,
          fontSize: 15
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),

    );
  }
}


