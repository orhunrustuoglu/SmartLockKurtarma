import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;
import 'package:smart_lock/main.dart';
import 'dart:convert';
import 'main.dart';

class CreateLockScreen extends StatefulWidget {
  final String bToken;
  final user;

  CreateLockScreen(this.bToken, this.user);
  @override
  _CreateLockScreenState createState() => _CreateLockScreenState();
}

class _CreateLockScreenState extends State<CreateLockScreen>
    with TickerProviderStateMixin {
  TabController _controller;
  bool _waiting = false;
  List<String> permittedsList = [];
  List<dynamic> locks = [];
  final lockIdController = TextEditingController();
  final lockPasswordController = TextEditingController();
  final lockNameController = TextEditingController();
  final permissionController = TextEditingController();

  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;
  int _deviceState;
  bool isDisconnecting = false;
  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;
  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

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
    setState(() {
      _devicesList = devices;
    });
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
          child: Text(device.name, style: TextStyle(color: Colors.white70)),
          value: device,
        ));
      });
    }
    return items;
  }

  Widget permittedUsersWidget(String permittedUserId) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 3),
            ),
          ], color: Colors.white12, borderRadius: BorderRadius.circular(25)),
          padding: EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width / 1.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                permittedUserId,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() {
                        permittedsList.removeWhere(
                            (element) => element == permittedUserId);
                      }))
            ],
          )),
    );
  }

  Future<void> createLock(String bToken, name, keyPassword, owner, userId,
      macAddress, var thePermittedsList) async {
    final url = Uri.https(baseUrl, "/Key/CreateKey");
    await http
        .post(url,
            headers: <String, String>{
              'Authorization': bToken,
              'Content-Type': 'application/json'
            },
            body: json.encode({
              "name": name, //REQUIRED
              "keyPassword": keyPassword, //Optional
              "owner": owner, //Optional
              "permitted": thePermittedsList, //Optional
              "userId": userId, //Optional
              "macAddress": macAddress,
              "isLocked": false
            }))
        .then((response) {
      if (response.statusCode == 201) {
        print(json.decode(response.body));
        Navigator.pop(context);
      } else {
        print("createLock statusCode: " + response.statusCode.toString());
        print("createLock body: " + response.body.toString());
        setState(() {
          _waiting = false;
        });
      }
    });
  }

  @override
  void initState() {
    _controller = new TabController(length: 2, vsync: this);
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    enableBluetooth();

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
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
                Text(
                  "ADD LOCK",
                  style: TextStyle(fontSize: 24, color: Colors.white70),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
          backgroundColor: Color(0xff101010),
        ),
        body: Center(
          child: Column(
            children: [
              /*Container(
                child: TabBar(
                    indicatorColor: Colors.white70,
                    controller: _controller,
                    labelColor: Colors.white70,
                    unselectedLabelColor: Colors.white38,
                    tabs: [
                      Tab(
                        text: "ADD AN EXISTING LOCK",
                      ),
                      Tab(
                        text: "CREATE A LOCK",
                      )
                    ]),
              ),*/
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                              decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 1.0,
                                      offset: Offset(0.0, 3),
                                    ),
                                  ],
                                  color: Color(0xff1c1c1c),
                                  borderRadius: BorderRadius.circular(25)),
                              padding: EdgeInsets.all(20),
                              width: MediaQuery.of(context).size.width / 10 * 9,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 45,
                                    child: TextField(
                                      controller: lockNameController,
                                      style: TextStyle(color: Colors.white70),
                                      decoration: new InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 1),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(90.0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 1),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(90.0)),
                                          ),
                                          hintText: 'LOCK NAME',
                                          hintStyle:
                                              TextStyle(color: Colors.white38)),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 5),
                                    color: Colors.white38,
                                    height: 1,
                                    width: double.infinity,
                                  ),
                                  Container(
                                    height: 45,
                                    child: TextField(
                                      obscureText: true,
                                      controller: lockPasswordController,
                                      style: TextStyle(color: Colors.white70),
                                      decoration: new InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 1),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(90.0)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 1),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(90.0)),
                                          ),
                                          hintText: 'PASSWORD',
                                          hintStyle:
                                              TextStyle(color: Colors.white38)),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 5),
                                    color: Colors.white38,
                                    height: 1,
                                    width: double.infinity,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          'DEVICE:',
                                          style:
                                              TextStyle(color: Colors.white38),
                                        ),
                                        DropdownButton(
                                          dropdownColor: Color(0xff101010),
                                          items: _getDeviceItems(),
                                          onChanged: (value) =>
                                              setState(() => _device = value),
                                          value: _devicesList.isNotEmpty
                                              ? _device
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 1.0,
                                    offset: Offset(0.0, 3),
                                  ),
                                ],
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(25)),
                            padding: EdgeInsets.only(top: 10),
                            width: MediaQuery.of(context).size.width / 10 * 9,
                            child: Column(children: [
                              Container(
                                  margin: EdgeInsets.symmetric(horizontal: 15),
                                  height: 40,
                                  decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 1.0,
                                          offset: Offset(0.0, 5),
                                        ),
                                      ],
                                      color: Color(0xff1c1c1c),
                                      borderRadius: BorderRadius.circular(25)),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: permissionController,
                                          style:
                                              TextStyle(color: Colors.white70),
                                          decoration: new InputDecoration(
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.transparent,
                                                    width: 1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(90.0)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.transparent,
                                                    width: 1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(90.0)),
                                              ),
                                              hintText:
                                                  'Add Permitted User Id\'s here...',
                                              hintStyle: TextStyle(
                                                  color: Colors.white38)),
                                        ),
                                      ),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 15),
                                          child: IconButton(
                                            icon: Icon(Icons.add,
                                                color: Colors.white38),
                                            onPressed:
                                                permissionController
                                                        .text.isEmpty
                                                    ? null
                                                    : () {
                                                        if (!permittedsList.contains(
                                                            permissionController
                                                                .text
                                                                .toString()))
                                                          setState(() {
                                                            permittedsList.add(
                                                                permissionController
                                                                    .text
                                                                    .toString());
                                                            permissionController
                                                                .text = "";
                                                          });
                                                        else
                                                          showDialog(
                                                              context: context,
                                                              builder: (_) =>
                                                                  AlertDialog(
                                                                    backgroundColor:
                                                                        Color(
                                                                            0xff212121),
                                                                    title: Text(
                                                                        "This user has already been permitted!",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white38)),
                                                                    content:
                                                                        Container(
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
                                                                                Colors.white
                                                                              ],
                                                                              begin: const FractionalOffset(0.0,
                                                                                  0.0),
                                                                              end: const FractionalOffset(0.0,
                                                                                  50.0),
                                                                              stops: [
                                                                                0.0,
                                                                                0.1
                                                                              ],
                                                                              tileMode: TileMode
                                                                                  .clamp),
                                                                          borderRadius:
                                                                              BorderRadius.circular(25)),
                                                                      child:
                                                                          FlatButton(
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(18.0),
                                                                        ),
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.pop(context),
                                                                        child:
                                                                            Text(
                                                                          "OK",
                                                                          style: TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.white70),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ));
                                                      },
                                          ))
                                    ],
                                  )),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                    decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 1.0,
                                            offset: Offset(0.0, 3),
                                          ),
                                        ],
                                        color: Color(0xff1c1c1c),
                                        borderRadius:
                                            BorderRadius.circular(25)),
                                    width: double.infinity,
                                    child: Container(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                5,
                                        child: permittedsList.isNotEmpty
                                            ? ListView.builder(
                                                shrinkWrap: true,
                                                itemCount:
                                                    permittedsList.length,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  return permittedUsersWidget(
                                                      permittedsList[index]);
                                                })
                                            : Container())),
                              ),
                            ]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: _waiting
                              ? CircularProgressIndicator.adaptive(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70),
                                  backgroundColor: Colors.transparent,
                                )
                              : Container(
                                  height:
                                      MediaQuery.of(context).size.height / 11,
                                  width: MediaQuery.of(context).size.width /
                                      10 *
                                      9,
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
                                          begin:
                                              const FractionalOffset(0.0, 0.0),
                                          end:
                                              const FractionalOffset(0.0, 50.0),
                                          stops: [0.0, 0.1],
                                          tileMode: TileMode.clamp),
                                      borderRadius: BorderRadius.circular(25)),
                                  child: TextButton(
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                        ),
                                      )),
                                      onPressed: () {
                                        setState(() {
                                          _waiting = true;
                                        });
                                        createLock(
                                            widget.bToken,
                                            lockNameController.text.toString(),
                                            lockPasswordController.text
                                                .toString(),
                                            widget.user["firstName"] +
                                                " " +
                                                widget.user["lastName"],
                                            widget.user["id"].toString(),
                                            // _device.address
                                            "",
                                            permittedsList);
                                      },
                                      child: Text(
                                        "CREATE LOCK",
                                        style: TextStyle(
                                            fontSize: 22,
                                            color: Colors.white70),
                                        textAlign: TextAlign.center,
                                      )),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
