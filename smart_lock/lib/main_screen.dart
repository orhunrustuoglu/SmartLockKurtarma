import 'package:flutter/material.dart';
import 'package:smart_lock/home_screen.dart';
import 'login_signup.dart';
import 'profile_settings.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';

class MainScreen extends StatefulWidget {
  final String bToken;
  final user;

  MainScreen(this.bToken, this.user);
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Widget> pages;
  HomeScreen homeScreen;
  ProfileAndSettings profileAndSettings;
  FlutterBluetoothSerial _bluetooth =
      FlutterBluetoothSerial.instance; // Get the instance of the Bluetooth
  BluetoothConnection
      connection; // Track the Bluetooth connection with the remote device
  int _deviceState;
  bool isDisconnecting = false;
  bool get isConnected =>
      connection != null &&
      connection
          .isConnected; // To track whether the device is still connected to Bluetooth
  List<BluetoothDevice> _devicesList =
      []; // Define some variables, which will be required later
  BluetoothDevice _device;
  bool _connected = false;
  List<dynamic> locksList = [];
  var _userObj;
  bool _waiting = false;
  var currentLock;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    homeScreen = HomeScreen(widget.bToken, widget.user);
    profileAndSettings = ProfileAndSettings(widget.bToken, widget.user);
    pages = [homeScreen, profileAndSettings];
    super.initState();
  }

  // Method to connect to bluetooth
  void _connect(macAddress) async {
    if (!isConnected) {
      await BluetoothConnection.toAddress(macAddress).then((_connection) {
        print('Connected to the device');
        connection = _connection;
        if (mounted)
          setState(() {
            _connected = true;
          });

        connection.input.listen(null).onDone(() {
          if (isDisconnecting) {
            print('Disconnecting locally!');
          } else {
            print('Disconnected remotely!');
          }
        });
      }).catchError((error) {
        print('Cannot connect, exception occurred');
        print(error);
      });
      //show('Device connected');
      //if (mounted) setState(() => _isButtonUnavailable = false);
    }
  }

  void _sendMessage(String text, bToken, theCurrentLock, int index) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        print(text);
        /*
        _devicesList
            .forEach((device) => print(device.name + " ==> " + device.address));*/
        connection.output.add(utf8.encode(text));
        await connection.output.allSent.then((bResponse) {
          if (text == "door" &&
              (bResponse == "DoorUnlocked" || bResponse == "DoorLocked"))
            useLock(
                bToken, theCurrentLock["name"], theCurrentLock["keyId"], index);
        });
      } catch (e) {
        // Ignore error, but notify state
        print("_sendMessage error occured!");
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> useLock(
      //creates an usage history
      String bToken,
      name,
      id,
      int index) async {
    final url = Uri.https(baseUrl, "/History/CreateHistory");
    await http
        .post(url,
            headers: <String, String>{
              'Authorization': bToken,
              'Content-Type': 'application/json'
            },
            body: json.encode({"name": name, "keyId": id}))
        .then((response) {
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        if (mounted)
          setState(() {
            locksList[index]["isLocked"] = !locksList[index]["isLocked"];
          });
      } else {
        print("useLock statusCode: " + response.statusCode.toString());
      }
    });
  }

  Future<void> getLocks(String bToken) async {
    final url = Uri.https(baseUrl, "/Key/ListKey");
    await http.get(
      url,
      headers: <String, String>{
        'Authorization': bToken,
      },
    ).then((response) {
      if (response.statusCode == 200) {
        print(json.decode(response.body));
        var responseObj = json.decode(response.body) as List;
        responseObj.forEach((element) {
          if ((element["permitted"] as List).contains(widget.user["id"]) ||
              element["owner"] ==
                  (widget.user["firstName"] +
                      " " +
                      widget.user["lastName"])) if (mounted)
            setState(() {
              locksList.add(element);
            });
        });
      } else {
        print("getLocks statusCode: " + response.statusCode.toString());
      }
      if (mounted)
        setState(() {
          _waiting = false;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xff101010),
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 100,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(right: 10, left: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Image(
                    image: new AssetImage("assets/smartlock1218.png"),
                  ),
                ),
                Container(
                    child: _selectedIndex == 0
                        ? /*Padding(
                            padding: const EdgeInsets.all(10),
                            child: _waiting
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 40),
                                    child: Center(
                                      child: CircularProgressIndicator.adaptive(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white70),
                                        backgroundColor: Colors.transparent,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 1.0,
                                            offset: Offset(0.0, 6.5),
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                            colors: [
                                              Color(0xff1c1c1c),
                                              Colors.white70
                                            ],
                                            begin: const FractionalOffset(
                                                0.0, 0.0),
                                            end: const FractionalOffset(
                                                0.0, 50.0),
                                            stops: [0.0, 0.1],
                                            tileMode: TileMode.clamp),
                                        borderRadius:
                                            BorderRadius.circular(25)),
                                    child: FlatButton(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _waiting = true;
                                          });
                                          for (int i = 0;
                                              i < locksList.length;
                                              i++) {
                                            currentLock = locksList[i];
                                            if ((currentLock["permitted"]
                                                        as List)
                                                    .contains(_userObj["id"]) ||
                                                currentLock["owner"] ==
                                                    (_userObj["firstName"] +
                                                        " " +
                                                        _userObj["lastName"]))
                                              //if statement above
                                              Future.delayed(
                                                  Duration.zero,
                                                  () => _connect(currentLock[
                                                      "macAddress"])).then((_) {
                                                if (isConnected)
                                                  _sendMessage(
                                                      locksList[i]
                                                          ["keyPassword"],
                                                      widget.bToken,
                                                      currentLock,
                                                      i);
                                              }).then((_) {
                                                Future.delayed(
                                                    Duration(seconds: 1),
                                                    () => _sendMessage(
                                                        "door",
                                                        widget.bToken,
                                                        currentLock,
                                                        i));
                                              });
                                          }
                                          setState(() {
                                            _waiting = false;
                                          });
                                        },
                                        child: FittedBox(
                                          fit: BoxFit.fitWidth,
                                          child: Text(
                                            "LOCK ALL",
                                            style: TextStyle(
                                                fontSize: 22,
                                                color: Colors.white70),
                                          ),
                                        )),
                                  ),
                          )*/
                        Container()
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              width: MediaQuery.of(context).size.width / 3,
                              decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 1.0,
                                      offset: Offset(0.0, 6.5),
                                    ),
                                  ],
                                  gradient: LinearGradient(
                                      colors: [
                                        Color(0xff1c1c1c),
                                        Colors.white70
                                      ],
                                      begin: const FractionalOffset(0.0, 0.0),
                                      end: const FractionalOffset(0.0, 50.0),
                                      stops: [0.0, 0.1],
                                      tileMode: TileMode.clamp),
                                  borderRadius: BorderRadius.circular(25)),
                              child: FlatButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                  onPressed: () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                LogInSignup()),
                                      ),
                                  child: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Text(
                                      "LOG OUT",
                                      style: TextStyle(
                                          fontSize: 22, color: Colors.white70),
                                    ),
                                  )),
                            ),
                          ))
              ],
            ),
          ),
          backgroundColor: Color(0xff101010),
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xff101010),
          type: BottomNavigationBarType.fixed,
          elevation: 16,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                size: 36,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 1
                    ? Icons.person_rounded
                    : Icons.person_outline_rounded,
                size: 36,
              ),
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          unselectedItemColor: Colors.white38,
          selectedItemColor: Colors.white70,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
