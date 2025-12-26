import 'dart:async';
import 'dart:io';


import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LgConnectionModel {
  String username ;
  String ip ;
  int port ;
  String password ;
  int screens ;

  // keys used to store values from shared preferences
  static const String _keyUsername = 'lg_username' ;
  static const String _keyIp = 'lg_ip' ;
  static const String _keyPort = 'lg_port' ;
  static const String _keyPassword = 'lg_password' ;
  static const String _keyScreens = 'lg_screens' ;

  LgConnectionModel({
    this.username = '',
    this.ip = '',
    this.password = '',
    this.port = 22,
    this.screens = 3
  });

  // save the data to Shared Preferences
  Future<void> saveToPreference() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyIp, ip);
    await prefs.setInt(_keyPort, port);
    await prefs.setString(_keyPassword, password);
    await prefs.setInt(_keyScreens, screens);
  }

  // load from preference
  Future<LgConnectionModel> loadFromPreference() async{
    final prefs = await SharedPreferences.getInstance();
    return LgConnectionModel(
      username: prefs.getString(_keyUsername) ?? 'lg',
      ip: prefs.getString(_keyIp) ?? '' ,
      port: prefs.getInt(_keyPort) ?? 22,
      password: prefs.getString(_keyPassword) ?? "lg",
      screens: prefs.getInt(_keyScreens) ?? 3
    );
  }

  void updateConnection({
    String? username,
    String? ip,
    int? port,
    String? password,
    int? screens,
  }) {
    this.username = username ?? this.username;
    this.ip = ip ?? this.ip;
    this.port = port ?? this.port;
    this.password = password ?? this.password;
    this.screens = screens ?? this.screens;
  }

} // LGConnectionModel Completed

class LgService{
  static final LgService _instance = LgService._internal();
  factory LgService() => _instance ;
  LgService._internal();

  final LgConnectionModel _lgConnectionModel =  LgConnectionModel() ;  // underscore for private use
  SSHClient? _client ;

  bool _isConnected = false ;
  bool get isConnected => _isConnected ;

  LgConnectionModel get connectionModel => _lgConnectionModel ;

  Future<void> initializeConnection() async{
    try{
      final savedModel = await _lgConnectionModel.loadFromPreference();
      updateConnectionSettings(
        ip: savedModel.ip,
        port: savedModel.port,
        username: savedModel.username,
        password: savedModel.password,
        screens: savedModel.screens,
      );
      await connectToLG() ;
    }catch(e){
      print("Initialization error");

    }
  }

  void updateConnectionSettings({
    required String ip,
    required int port,
    required String username,
    required String password,
    required int screens,
  }) {
    _lgConnectionModel.updateConnection(
      ip: ip,
      port: port,
      username: username,
      password: password,
      screens: screens,
    );
  }

  // connectToLG method to connect the app to LG rig
  Future<bool?> connectToLG() async {
    try{
      final socket = await SSHSocket.connect(_lgConnectionModel.ip, _lgConnectionModel.port);
      _client = SSHClient(socket, username: _lgConnectionModel.username , onPasswordRequest: ()=> _lgConnectionModel.password);

      _isConnected = true;
      return true ;
    }on SocketException catch(e){
      print('Failed to Connect $e');
      return false ;
    }
  }

  // disconnect method  end the connection and reset the connection
  void disconnect(){
    _client?.close();
    _client = null ;
    _isConnected = false ;
    print('Disconnected');
  }

  //execute() function to send any command to LG rig
  Future<dynamic> execute(String command , String successMsg) async{
    if(_client == null){
      print('SSH client Not Connected');
      return null;
    }
    try{
      final result = await _client!.execute(command) ;
      print(successMsg);
      return result ;
    }catch (e){
      print('There error in executing command $e');
      return null ;
    }
  }

  //query() function to send any text msg to LG rig , this function used inside the flyto() function
  Future<bool> query(String content) async{
    final result = await execute(
      'echo "$content" > /tmp/query.txt',
      'Query Sent : $content'
    );
    return result != null ;
  }

  // flyTo method
  Future<void> flyTo(String kmlViewTag) async{
    await query('flytoview=$kmlViewTag');
  }

  int calculateLeftMostScreen(int screenCount){
    return screenCount == 1 ? 1 : (screenCount/2).floor() + 2 ;
  }

  int calculateRightMostScreen(int screenCount){
    return screenCount == 1 ? 1 : (screenCount/2).floor() + 1 ;
  }

  // send logo
  Future<bool> sendLogo() async{
    int leftMostScreen = calculateLeftMostScreen(_lgConnectionModel.screens);
    String kmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
    <Document>
        <name>Logo</name>
        <ScreenOverlay>
            <name>Logo</name>
            <Icon>
              <href>https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgXmdNgBTXup6bdWew5RzgCmC9pPb7rK487CpiscWB2S8OlhwFHmeeACHIIjx4B5-Iv-t95mNUx0JhB_oATG3-Tq1gs8Uj0-Xb9Njye6rHtKKsnJQJlzZqJxMDnj_2TXX3eA5x6VSgc8aw/s320-rw/LOGO+LIQUID+GALAXY-sq1000-+OKnoline.png</href>
            </Icon>
            <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
            <screenXY x="0.02" y="0.98" xunits="fraction" yunits="fraction"/>
            <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
            <size x="396" y="309" xunits="pixels" yunits="pixels"/>
        </ScreenOverlay>
    </Document>
    </kml>''';
    final result = await execute(
        "echo '$kmlContent' > /var/www/html/kml/slave_$leftMostScreen.kml",
        'Logo Sent Successfully');
    return result !=null ;
  }

  // clean logo
  Future<void> cleanLogo() async{
    int leftMostScreen = calculateLeftMostScreen(_lgConnectionModel.screens);
    const blankKml =
    '''<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2">
        <Document><name>Logo</name></Document></kml>''';
    await execute("echo '$blankKml' > /var/www/html/kml/slave_$leftMostScreen.kml", "Logo Cleaned");
    await forceRefresh(leftMostScreen);

  }

  //force Refresh kml refresh on specific screen
Future<void> forceRefresh(int screenNumber) async{
    try{
      final search =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>';
      final replace =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>1<\\/refreshInterval>';
      final addCommand =
          'echo ${_lgConnectionModel.password} | sudo -S sed -i "s|$search|$replace|" ~/earth/kml/slave/myplaces.kml';

      await execute(
          "sshpass -p ${_lgConnectionModel.password} ssh -t lg$screenNumber '$addCommand'",
        'Refresh interval added to screen $screenNumber',
      );

      await Future.delayed(const Duration(seconds: 1));

      final searchWithRefresh =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>[0-9]+<\\/refreshInterval>';

      final restore =
          '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>';

      final removeCommand =
          'echo ${_lgConnectionModel.password} | sudo -S sed -i "s|$searchWithRefresh|$restore|" ~/earth/kml/slave/myplaces.kml';

      await execute( "sshpass -p ${_lgConnectionModel.password} ssh -t lg$screenNumber '$removeCommand'",
          'Refresh interval removed from screen $screenNumber');
      }catch(e){
      print('Error in forceRefresh');
    }
}

  //Send kml file to lg rig
  Future<void> sendKml (String assetPath) async{
    try{
      final content = await rootBundle.loadString(assetPath);
      final fileName = assetPath.split('/').last;
      await uploadKml(content, fileName);

      if(content.contains('<LookAt>')){
        int start = content.indexOf('<LookAt>');
        int end = content.indexOf('</LookAt>') + 9;
        String lookAt = content.substring(start, end);
        String cleanLookAt = lookAt.replaceAll(RegExp(r'\s+'), '');
        await flyTo(cleanLookAt);
      }else if(content.contains('<Camera>')){
        int start = content.indexOf('<Camera>');
        int end = content.indexOf('</Camera>') + 9;
        String camera = content.substring(start, end);
        String cleanCamera = camera.replaceAll(RegExp(r'\s+'), '');
        await flyTo(cleanCamera);

      }
    }catch(e){
      print('Error in sending kml file $e');
    }
  }


  //used to upload the kml file
  Future<void> uploadKml (String content , String fileName) async{
    //check the SSh client
    if(_client == null){
      print('The SSH client is not connected');
      return;
    }
    try {
      print('Uploading the kml file');
      // generate unique filename to prevent browser caching or overwriting issues
      final randomNumber = DateTime
          .now()
          .millisecondsSinceEpoch % 1000;
      final fileNameWithRandom = fileName.replaceAll(
          '.kml', '_$randomNumber.kml');


      // initialize the sftp
      final sftp = await _client?.sftp();
      if (sftp == null) {
        print('Fail to initialize SFTP client');
      }

      final file = await sftp?.open(
        '/var/www/html/$fileNameWithRandom',
        mode: SftpFileOpenMode.truncate |
        SftpFileOpenMode.create |
        SftpFileOpenMode.write,
      );

      //create a temporary file to stream into sftp
      final currentFile = await _createFile(fileNameWithRandom, content);
      final fileStream = currentFile.openRead();

      int offset = 0;
      await for (final chunk in fileStream) {
        final typedChunk = Uint8List.fromList(chunk);
        await file?.write(Stream.fromIterable([typedChunk]), offset: offset);
        offset += typedChunk.length;
      }

      await execute('echo "http://lg1:81/$fileNameWithRandom" > /var/www/html/kmls.txt', 'Kml file written successfully to kmls.txt');

      print('kml $fileNameWithRandom uploaded & triggered successfully ');
      }catch(e){
      print('Error in uploading kml file $e');
    }
  }



  //createFile Function used in Upload file
  Future<File> _createFile(String fileName , String content) async{
    final directory = await getTemporaryDirectory();

    final file = File('${directory.path}/$fileName');
    return await file.writeAsString(content);
  }


  // basic lg services
  Future<bool> shutdown() async {
    try {
      await connectToLG();
      bool allSuccessful = true;

      for (int i = _lgConnectionModel.screens; i >= 1; i--) {
        final shutdownCommand =
            'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "echo ${_lgConnectionModel.password} | sudo -S shutdown now"';
        final result = await execute(
          shutdownCommand,
          'Liquid Galaxy $i shutdown successfully',
        );
        allSuccessful = allSuccessful && (result != null);
      }

      final shutdownCommandLg1 =
          'sshpass -p ${_lgConnectionModel.password} ssh -t lg1 "echo ${_lgConnectionModel.password} | sudo -S shutdown now"';
      final lg1Result = await execute(
        shutdownCommandLg1,
        'Liquid Galaxy 1 shutdown executed',
      );
      allSuccessful = allSuccessful && (lg1Result != null);
      return allSuccessful;
    } catch (e) {
      print('Error during shutdown: $e');
      return false;
    }
  }


  Future<bool> relaunchLG() async {
    final relaunchCmd =
    """
        RELAUNCH_CMD="\\
        if [ -f /etc/init/lxdm.conf ]; then
          export SERVICE=lxdm
        elif [ -f /etc/init/lightdm.conf ]; then
          export SERVICE=lightdm
        else
          exit 1
        fi

        if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
          echo ${_lgConnectionModel.password} | sudo -S service \\\${SERVICE} start
        else
          echo ${_lgConnectionModel.password} | sudo -S service \\\${SERVICE} restart
        fi
        " && sshpass -p ${_lgConnectionModel.password} ssh -x -t lg@lg1 "\$RELAUNCH_CMD\"""";

    final result = await execute(
      relaunchCmd,
      'Liquid Galaxy relaunched successfully',
    );

    return result != null;
  }

  Future<bool> reboot() async {
    try {
      await connectToLG();
      bool allSuccessful = true;

      for (int i = _lgConnectionModel.screens; i >= 1; i--) {
        final rebootCommand =
            'sshpass -p ${_lgConnectionModel.password} ssh -t lg$i "echo ${_lgConnectionModel.password} | sudo -S reboot"';
        final result = await execute(
          rebootCommand,
          'Liquid Galaxy $i rebooted successfully',
        );
        allSuccessful = allSuccessful && (result != null);

        if (i > 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      final rebootCommandLg1 =
          'sshpass -p ${_lgConnectionModel.password} ssh -t lg1 "echo ${_lgConnectionModel.password} | sudo -S reboot"';
      final lg1RebootResult = await execute(
        rebootCommandLg1,
        'Liquid Galaxy 1 reboot executed',
      );
      allSuccessful = allSuccessful && (lg1RebootResult != null);

      await Future.delayed(const Duration(milliseconds: 100));

      await Future(() {
        _isConnected = false;
        _client?.close();
        _client = null;
      });

      unawaited(
        Future.delayed(const Duration(seconds: 46), () async {
          int retries = 0;
          const maxRetries = 10;
          const retryDelay = Duration(seconds: 5);

          while (retries < maxRetries && !_isConnected) {
            try {
              final result = await connectToLG();
              if (result == true) {
                print(
                  'Reconnection successful',
                );

                await Future.delayed(const Duration(seconds: 1));
                await execute('echo "search=japan" > /tmp/query.txt', 'First cmd sent') ;

                return;
              }
            } catch (e) {
              print('Reconnection attempt ${retries + 1} failed: $e');
            }

            if (!_isConnected && retries < maxRetries - 1) {
              await Future.delayed(retryDelay);
            }
            retries++;
          }

          if (!_isConnected) {
            print('Failed to reconnect after $maxRetries attempts');
          }
        }),
      );

      return allSuccessful;
    } catch (e) {
      print('Error during reboot: $e');
      return false;
    }
  }


  Future<bool> cleanKML() async{
    bool allSuccessful = true ;
    final clearCommand =  'echo "exittour=true" > /tmp/query.txt && > /var/www/html/kmls.txt';

    final headerCleared = await execute(clearCommand, 'KMLs.txt cleared');

    allSuccessful = allSuccessful && (headerCleared != null);
    int rightMost = calculateRightMostScreen(_lgConnectionModel.screens);
    const blankKml =
    '''<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2">
        <Document><name>Empty</name></Document></kml>''';

    final cleared = await execute("echo '$blankKml' > /var/www/html/kml/slave_$rightMost.kml",'Rightmost screen cleared');

    allSuccessful = allSuccessful && (cleared != null);

    await forceRefresh(rightMost);
    return allSuccessful ;

  }






}
