import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class LockSettings extends StatefulWidget {
  final String bToken;
  final currentLock;
  final devicesList;
  final _user;

  LockSettings(this.bToken, this.currentLock, this.devicesList, this._user);

  @override
  _LockSettingsState createState() => _LockSettingsState();
}

List<dynamic> permittedsList = [];
var userObj;
final GlobalKey<ScaffoldState> _scaffoldKey2 = new GlobalKey<ScaffoldState>();
BluetoothConnection connection;

bool get isConnected => connection != null && connection.isConnected;
bool _connected = false;
bool isDisconnecting = false;
final newKeyController = TextEditingController();
bool _passwordChanged = false;
bool _waiting = false;

class _LockSettingsState extends State<LockSettings> {
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
              "isLocked": isLocked
            }))
        .then((response) {
      if (response.statusCode == 204) {
        print("new password: " + keyPassword);
      } else {
        print("updateLock statusCode: " + response.statusCode.toString());
      }
    });
  }

  @override
  void initState() {
    print("currentLock: " + widget.currentLock.toString());
    print("user: " + widget._user.toString());
    print("devicesList: " + widget.devicesList.toString());

    super.initState();
  }

  void _sendMessage(String text) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        print(text);
        /*
        _devicesList
            .forEach((device) => print(device.name + " ==> " + device.address));*/
        connection.output.add(utf8.encode(text));
        await connection.output.allSent.then((bResponse) {
          if (text != "changepassword")
            setState(() {
              newKeyController.text = "";
              _waiting = false;
              _passwordChanged = true;
            });
        });
      } catch (e) {
        // Ignore error, but notify state
        print("_sendMessage error occured!");
        if (mounted) setState(() {});
      }
    }
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
    }
  }

  // Method to disconnect to bluetooth
  void _disconnect() async {
    if (isConnected) await connection.close();
    print('Device disconnected');
    if (!connection.isConnected) {
      if (mounted)
        setState(() {
          _connected = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey2,
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
                  "LOCK SETTINGS",
                  style: TextStyle(fontSize: 24, color: Colors.white70),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
          backgroundColor: Color(0xff101010),
        ),
        body: SingleChildScrollView(
          physics: WidgetsBinding.instance.window.viewInsets.bottom > 0.0
              ? null
              : NeverScrollableScrollPhysics(),
          child: Center(
            child: Column(
              children: [
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
                        color: Color(0xff1c1c1c),
                        borderRadius: BorderRadius.circular(25)),
                    padding: EdgeInsets.all(10),
                    width: MediaQuery.of(context).size.width / 10 * 9,
                    child: Text(
                      widget.currentLock["name"].toString(),
                      style: TextStyle(fontSize: 30, color: Colors.white70),
                    ),
                  ),
                ),
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
                          Text(
                            "LOCK ID: " +
                                widget.currentLock["keyId"].toString(),
                            style:
                                TextStyle(fontSize: 18, color: Colors.white54),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 15),
                            color: Colors.white38,
                            height: 1,
                            width: double.infinity,
                          ),
                          Text(
                            "PASSWORD: " +
                                widget.currentLock["keyPassword"].toString(),
                            style:
                                TextStyle(fontSize: 18, color: Colors.white54),
                          )
                        ],
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          height: MediaQuery.of(context).size.height / 15,
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
                          child: FlatButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                        backgroundColor: Color(0xff212121),
                                        title: Text("Change Lock Password",
                                            style: TextStyle(
                                                color: Colors.white38)),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black12,
                                                          blurRadius: 1.0,
                                                          offset:
                                                              Offset(0.0, 3),
                                                        ),
                                                      ],
                                                      color: Color(0xff1c1c1c),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              25)),
                                                  padding: EdgeInsets.all(20),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      10 *
                                                      9,
                                                  child: Container(
                                                    // height: 45,
                                                    child: TextField(
                                                      obscureText: true,
                                                      controller:
                                                          newKeyController,
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white70),
                                                      decoration:
                                                          new InputDecoration(
                                                              focusedBorder:
                                                                  OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1),
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            90.0)),
                                                              ),
                                                              enabledBorder:
                                                                  OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1),
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            90.0)),
                                                              ),
                                                              hintText:
                                                                  'NEW PASSWORD',
                                                              hintStyle: TextStyle(
                                                                  color: Colors
                                                                      .white38)),
                                                    ),
                                                  )),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: _waiting
                                                  ? CircularProgressIndicator
                                                      .adaptive(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white70),
                                                      backgroundColor:
                                                          Colors.transparent,
                                                    )
                                                  : Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height /
                                                              15,
                                                      decoration: BoxDecoration(
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black12,
                                                              blurRadius: 1.0,
                                                              offset: Offset(
                                                                  0.0, 6.5),
                                                            ),
                                                          ],
                                                          gradient: LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xff1c1c1c),
                                                                Colors.white70
                                                              ],
                                                              begin:
                                                                  const FractionalOffset(
                                                                      0.0, 0.0),
                                                              end:
                                                                  const FractionalOffset(
                                                                      0.0,
                                                                      50.0),
                                                              stops: [0.0, 0.1],
                                                              tileMode: TileMode
                                                                  .clamp),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      25)),
                                                      child: FlatButton(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        18.0),
                                                          ),
                                                          onPressed: () {
                                                            if (newKeyController
                                                                .text
                                                                .isNotEmpty)
                                                              setState(() {
                                                                _waiting = true;
                                                              });
                                                            print("asufjasnfkasgfksagsa: " +
                                                                newKeyController
                                                                    .text
                                                                    .toString());

                                                            Future.delayed(Duration.zero, () => _connect(widget.currentLock["macAddress"]))
                                                                .then((_) =>
                                                                    Future.delayed(Duration(seconds: 1), () => _sendMessage("changepassword"))
                                                                        .then((_) =>
                                                                            Future.delayed(Duration(seconds: 1), () => _sendMessage(newKeyController.text.toString())))
                                                                        .then((_) {
                                                                      updateLock(
                                                                          widget
                                                                              .bToken,
                                                                          widget.currentLock[
                                                                              "name"],
                                                                          newKeyController
                                                                              .text
                                                                              .toString(),
                                                                          (widget._user["firstName"] +
                                                                              " " +
                                                                              widget._user[
                                                                                  "lastName"]),
                                                                          widget._user["id"]
                                                                              .toString(),
                                                                          widget.currentLock[
                                                                              "keyId"],
                                                                          widget.currentLock[
                                                                              "macAddress"],
                                                                          widget.currentLock[
                                                                              "permitted"],
                                                                          widget
                                                                              .currentLock["isLocked"]);
                                                                      setState(
                                                                          () {
                                                                        _waiting =
                                                                            false;
                                                                        //_disconnect();
                                                                      });
                                                                      if (_passwordChanged) {
                                                                        _disconnect();
                                                                        Navigator.pop(
                                                                            context);
                                                                        Navigator.pop(
                                                                            context);
                                                                      }
                                                                    }));
                                                          },
                                                          child: Text(
                                                            "OK",
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: Colors
                                                                    .white70),
                                                            textAlign: TextAlign
                                                                .center,
                                                          )),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      )),
                              child: Text(
                                "CHANGE PASSWORD",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white70),
                                textAlign: TextAlign.center,
                              )),
                        ),
                      ),
                      /*Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          height: MediaQuery.of(context).size.height / 15,
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
                          child: FlatButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              onPressed: () => print(
                                  "edit"), //TODO düzenlenen bilgiler backend aracılığıyla kaydedilmeli
                              child: Text(
                                "EDIT",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white70),
                                textAlign: TextAlign.center,
                              )),
                        ),
                      ),*/
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
