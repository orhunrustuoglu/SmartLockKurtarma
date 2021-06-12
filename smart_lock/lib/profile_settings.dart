import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_lock/main.dart';
import 'dart:convert';
import 'main.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileAndSettings extends StatefulWidget {
  final String bToken;
  final user;

  ProfileAndSettings(this.bToken, this.user);
  @override
  _ProfileAndSettingsState createState() => _ProfileAndSettingsState();
}

class _ProfileAndSettingsState extends State<ProfileAndSettings> {
  Future<void> updatePassword(String email) async {
    final url =
        Uri.https(baseUrl, "/api/user"); //TODO update updatePassword url
    await http
        .post(url,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode({
              "email": email,
            }))
        .then((response) {
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        print(response.body);
      } else {
        print(response.body);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      //alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              width: 125,
              margin: EdgeInsets.symmetric(vertical: 15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image(
                  image: new AssetImage("assets/lock.png"),
                ),
              )),
          Text(
            (widget.user["firstName"] ?? "name").toString() +
                " " +
                (widget.user["lastName"] ?? "surname").toString(),
            style: TextStyle(fontSize: 30, color: Colors.white70),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 30, bottom: 10, right: 20, left: 20),
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
                          Row(
                            children: [
                              Text(
                                "USER ID: ",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white70),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  widget.user["id"].toString(),
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 15),
                            color: Colors.white38,
                            height: 1,
                            width: double.infinity,
                          ),
                          Text(
                            "E-MAIL: " + widget.user["email"].toString() ??
                                "email",
                            style:
                                TextStyle(fontSize: 20, color: Colors.white70),
                          ),
                        ],
                      )),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 1.0,
                    offset: Offset(0.0, 6.5),
                  ),
                ],
                gradient: LinearGradient(
                    colors: [Color(0xff1c1c1c), Colors.white],
                    begin: const FractionalOffset(0.0, 0.0),
                    end: const FractionalOffset(0.0, 50.0),
                    stops: [0.0, 0.1],
                    tileMode: TileMode.clamp),
                borderRadius: BorderRadius.circular(25)),
            child: FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
              ),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                          backgroundColor: Color(0xff212121),
                          title: Text("Change Account Password",
                              style: TextStyle(color: Colors.white38)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 10),
                                child: Text(
                                  "Do you confirm to change the account password?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70),
                                ),
                              ),
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
                                        begin: const FractionalOffset(0.0, 0.0),
                                        end: const FractionalOffset(0.0, 50.0),
                                        stops: [0.0, 0.1],
                                        tileMode: TileMode.clamp),
                                    borderRadius: BorderRadius.circular(25)),
                                child: FlatButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                  onPressed: () {
                                    updatePassword(
                                        widget.user["email"].toString());

                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "OK",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white70),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ));
                print("Change Account Password");
              },
              child: Text(
                "CHANGE PASSWORD",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
