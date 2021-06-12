import 'dart:async';
import './login_signup.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_lock/main.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'lock_settings.dart';
import 'login_signup.dart';
import 'main.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void doesValidTokenExist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await getUser(prefs.getString('Token'), prefs.getInt("UserId"));
  }

  Future<void> getUser(String _bToken, int _userId) async {
    final url = Uri.https(baseUrl, "/Accounts/$_userId");
    await http.get(
      url,
      headers: <String, String>{
        'Authorization': _bToken,
      },
    ).then((response) {
      if (response.statusCode == 200) {
        var _userObj = json.decode(response.body);
        print(_userObj);
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(_bToken, _userObj)));
      } else {
        print("isLoggedIn statusCode: " + response.statusCode.toString());
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LogInSignup()));
      }
    });
  }

  @override
  void initState() {
    Timer(Duration(seconds: 1),
        () => Future.delayed(Duration.zero, () => doesValidTokenExist()));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          color: Color(0xff101010),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 4,
                      ),
                      Image(
                        image: new AssetImage("assets/smartlock1218.png"),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "TEAM 1218",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: "Century-Gothic"),
                    ),
                  )
                ],
              ))),
    );
  }
}
