import 'package:flutter/material.dart';
import 'package:liquidgalaxy_task2_gsoc2026/screens/home_screen.dart';
import 'package:liquidgalaxy_task2_gsoc2026/screens/setting_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LG Task 2',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0 ;
  static const List<Widget> _screens = <Widget>[HomeScreen(), SettingScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index ;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Liquid Galaxy Task 2" , style: TextStyle(color: Colors.white , fontSize: 24 , fontWeight: FontWeight.bold),)
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black26, spreadRadius: 0, blurRadius: 10),
          ]
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home) , label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.settings) , label: 'Settings'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),


    );
  }
}

