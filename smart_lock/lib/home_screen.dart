import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'create_lock_screen.dart';
import 'lock_settings.dart';
import 'lock_usage_history.dart';
import 'dart:convert';
import 'dart:async';
import 'main.dart';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';

class HomeScreen extends StatefulWidget {
  final String bToken;
  final user;

  HomeScreen(this.bToken, this.user);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  BluetoothState _bluetoothState = BluetoothState
      .UNKNOWN; // Initializing the Bluetooth connection state to be unknown
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<
      ScaffoldState>(); // Initializing a global key, as it would help us in showing a SnackBar later
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
  bool _isButtonUnavailable = false;
  var currentLock;
  List<dynamic> locksList = [];
  bool _waiting = true;

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
  void initState() {
    print("user: " + widget.user.toString());
    getLocks(widget.bToken);
    super.initState();
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      if (mounted)
        setState(() {
          _bluetoothState = state;
        });
    });

    _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      if (mounted)
        setState(() {
          _bluetoothState = state;
          if (_bluetoothState == BluetoothState.STATE_OFF) {
            _isButtonUnavailable = true;
          }
          getPairedDevices();
        });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    if (mounted)
      setState(() {
        _devicesList = devices;
      });
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

  Widget lockWidget(String name, bool status, int index) {
    bool isLocked = false;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
      child: Container(
          height: MediaQuery.of(context).size.height / 3,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 3),
            ),
          ], color: Color(0xff1c1c1c), borderRadius: BorderRadius.circular(25)),
          padding: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width / 10 * 9,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: 1,
                child: Transform.scale(
                  scale: 1.5,
                  child: FlutterSwitch(
                    width: 120,
                    height: 80,
                    toggleSize: 70,
                    value: locksList[index]["isLocked"] ?? false,
                    borderRadius: 50,
                    padding: 0,
                    toggleColor: Color(0xff212121),
                    switchBorder: Border.all(
                      color: Color(0xFF303030),
                      width: 5,
                    ),
                    activeColor: Colors.red[900],
                    inactiveColor: Colors.green[700],
                    activeIcon: RotatedBox(
                      quarterTurns: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                    inactiveIcon: RotatedBox(
                      quarterTurns: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.lock_open_outlined,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    onToggle: (val) {
                      /* useLock(widget.bToken, (locksList[index]["name"]),
                          locksList[index]["keyId"], index);*/
                      if (mounted)
                        setState(() {
                          if (locksList[index]["isLocked"] != null)
                            locksList[index]["isLocked"] = val;
                          currentLock = locksList[index];
                        });
                      Future.delayed(Duration.zero,
                          () => _connect(currentLock["macAddress"])).then((_) {
                        if (isConnected)
                          _sendMessage(currentLock["keyPassword"],
                              widget.bToken, currentLock, index);
                      }).then((_) {
                        Future.delayed(
                            Duration(seconds: 1),
                            () => _sendMessage(
                                "door", widget.bToken, currentLock, index));
                      });
                    },
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width / 10 * 9) - 200,
                    child: AutoSizeText(
                      name,
                      maxLines: 1,
                      style: TextStyle(color: Colors.white70, fontSize: 30),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4,
                      decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 1.0,
                              offset: Offset(0.0, 6.5),
                            ),
                          ],
                          gradient: LinearGradient(
                              colors: [Color(0xff1c1c1c), Colors.white70],
                              begin: const FractionalOffset(0.0, 0.0),
                              end: const FractionalOffset(0.0, 50.0),
                              stops: [0.0, 0.1],
                              tileMode: TileMode.clamp),
                          borderRadius: BorderRadius.circular(25)),
                      child: TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                        )),
                        onPressed: () {
                          currentLock = locksList[index];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LockUsageHistory(
                                    widget.bToken, currentLock["keyId"])),
                          );
                        },
                        child: Text(
                          "HISTORY",
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: locksList[index]["owner"] ==
                            (widget.user["firstName"] +
                                " " +
                                widget.user["lastName"])
                        ? Container(
                            width: MediaQuery.of(context).size.width / 4,
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 1.0,
                                    offset: Offset(0.0, 6.5),
                                  ),
                                ],
                                gradient: LinearGradient(
                                    colors: [Color(0xff1c1c1c), Colors.white70],
                                    begin: const FractionalOffset(0.0, 0.0),
                                    end: const FractionalOffset(0.0, 50.0),
                                    stops: [0.0, 0.1],
                                    tileMode: TileMode.clamp),
                                borderRadius: BorderRadius.circular(25)),
                            child: TextButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                              )),
                              onPressed: () {
                                currentLock = locksList[index];
                                print("encoded: " + currentLock.toString());
                                _disconnect();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LockSettings(
                                          widget.bToken,
                                          currentLock,
                                          _devicesList,
                                          widget.user)),
                                );
                              },
                              child: Text(
                                "SETTINGS",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white70),
                              ),
                            ),
                          )
                        : Container(),
                  ),
                ],
              )
            ],
          )),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
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
      show('Device connected');
      if (mounted) setState(() => _isButtonUnavailable = false);
    }
  }

  // Method to disconnect to bluetooth
  void _disconnect() async {
    if (mounted)
      setState(() {
        _isButtonUnavailable = true;
        _deviceState = 0;
      });
    if (isConnected) await connection.close();
    print('Device disconnected');
    if (!connection.isConnected) {
      if (mounted)
        setState(() {
          _connected = false;
          _isButtonUnavailable = false;
        });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  /*void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("1" + "\r\n"));
    await connection.output.allSent;
    show('Device Turned On');
    if (mounted)
      setState(() {
        _deviceState = 1; // device on
      });
  }*/

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
              (bResponse == "DoorUnlocked" || bResponse == "DoorLocked")) {
            useLock(
                bToken, theCurrentLock["name"], theCurrentLock["keyId"], index);
            updateLock(
                widget.bToken,
                theCurrentLock["name"],
                theCurrentLock["keyPassword"],
                widget.user["firstName"] + " " + widget.user["lastName"],
                widget.user["id"].toString(),
                theCurrentLock["keyId"],
                theCurrentLock["macAddress"],
                theCurrentLock["permitted"],
                theCurrentLock["isLocked"]);
          }
        });
      } catch (e) {
        // Ignore error, but notify state
        print("_sendMessage error occured!");
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> updateLock(
    String bToken,
    name,
    keyPassword,
    owner,
    userId,
    int id,
    String macAddress,
    List<dynamic> permitted,
    bool isLocked,
  ) async {
    final url = Uri.https(baseUrl, "/Key/UpdateByKeyId$id");
    await http
        .put(url,
            headers: <String, String>{
              'Authorization': bToken,
              'Content-Type': 'application/json'
            },
            body: json.encode({
              "keyId": id,
              "name": name,
              "keyPassword": keyPassword,
              "owner": owner,
              "permitted": permitted,
              "userId": userId,
              "macAddress": macAddress,
              "isLocked": !isLocked
            }))
        .then((response) {
      if (response.statusCode == 204) {
        print("new password: " + keyPassword);
      } else {
        print("updateLock statusCode: " + response.statusCode.toString());
      }
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      key: _scaffoldKey,
      body: Container(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    height: MediaQuery.of(context).size.height / 10,
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 1.0,
                            offset: Offset(0.0, 6.5),
                          ),
                        ],
                        gradient: LinearGradient(
                            colors: [Color(0xff1c1c1c), Colors.white70],
                            begin: const FractionalOffset(0.0, 0.0),
                            end: const FractionalOffset(0.0, 50.0),
                            stops: [0.0, 0.1],
                            tileMode: TileMode.clamp),
                        borderRadius: BorderRadius.circular(25)),
                    child: TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                        )),
                        onPressed: () {
                          FlutterBluetoothSerial.instance.openSettings();
                        },
                        child: Text(
                          "PAIR DEVICE WITH LOCKS",
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                          textAlign: TextAlign.center,
                        )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    height: MediaQuery.of(context).size.height / 10,
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 1.0,
                            offset: Offset(0.0, 6.5),
                          ),
                        ],
                        gradient: LinearGradient(
                            colors: [Color(0xff1c1c1c), Colors.white70],
                            begin: const FractionalOffset(0.0, 0.0),
                            end: const FractionalOffset(0.0, 50.0),
                            stops: [0.0, 0.1],
                            tileMode: TileMode.clamp),
                        borderRadius: BorderRadius.circular(25)),
                    child: TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                        )),
                        onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreateLockScreen(
                                      widget.bToken, widget.user)),
                            ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Text(
                                "ADD LOCK",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Icon(
                              Icons.add_rounded,
                              size: 26,
                              color: Colors.white70,
                            )
                          ],
                        )),
                  ),
                ),
              ],
            ),
            Expanded(
                child: _waiting
                    ? Center(
                        child: CircularProgressIndicator.adaptive(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white70),
                        backgroundColor: Colors.transparent,
                      ))
                    : ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: locksList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return lockWidget(
                              locksList[index]["name"].toString() ??
                                  "Lock Name",
                              false,
                              index);
                        }))
          ],
        ),
      ),
    );
  }
}
