import 'package:smart_lock/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import 'package:http/http.dart' as http;
import 'package:smart_lock/main.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class LogInSignup extends StatefulWidget {
  @override
  _LogInSignupState createState() => _LogInSignupState();
}

class _LogInSignupState extends State<LogInSignup> {
  bool exists = true;
  bool _validLogin = false;
  bool _waiting = false;
  bool _firstTryLog = true;
  bool _firstTrySign = true;
  String bToken;
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final repeatPasswordController = TextEditingController();
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  String verifyToken;

  Future<void> saveToken(String bToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('Token', bToken);
  }

  Future<void> saveUserId(int _userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('UserId', _userId);
  }

  Future<void> signUp(
      String firstName, lastName, userName, email, password) async {
    final url = Uri.https(baseUrl, "/Accounts/register");
    await http
        .post(url,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode({
              "userName": userName,
              "firstName": firstName,
              "lastName": lastName,
              "email": email,
              "password": password,
              "confirmPassword": password,
              "acceptTerms": true
            }))
        .then((response) {
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        print(response.body);
      } else {
        print(response.body);
        setState(() {
          _validLogin = false;
          _waiting = false;
          _firstTrySign = false;
        });
      }
    });
  }

  Future<void> forgotPassword(String email) async {
    final url = Uri.https(baseUrl, "/Accounts/forgot-password");
    await http
        .post(url,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode({
              "email": email,
            }))
        .then((response) {
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        print("forgot success");

        print(response.body);
      } else {
        print("failed to forgot");
        print(response.body);
        setState(() {
          _waiting = false;
        });
      }
    });
  }

  Future<void> resetPassword(String _token, password) async {
    final url = Uri.https(baseUrl, "/Accounts/forgot-password");
    await http
        .post(url,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode({
              "token": _token,
              "password": password,
              "confirmPassword": password
            }))
        .then((response) {
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        print(response.body);
        print("reset success");
      } else {
        print(response.body);
        print("failed to reset");
        setState(() {
          _waiting = false;
        });
      }
    });
  }

  Future<void> verifyEmail(String _token) async {
    final url = Uri.https(baseUrl, "/Accounts/verify-email");
    await http
        .post(url,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode({
              "token": _token,
            }))
        .then((response) {
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        logIn(emailController.text.toString(),
            passwordController.text.toString());
        print(response.body);
      } else {
        print(response.body);
        setState(() {
          _waiting = false;
        });
      }
    });
  }

  Future<void> logIn(String email, password) async {
    final url = Uri.https(baseUrl, "/Accounts/authenticate");
    await http
        .post(url,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode({
              "email": email,
              "password": password,
            }))
        .then((response) {
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        var responseObj = json.decode(utf8.decode(response.bodyBytes));
        print("Logged-in response object: " + responseObj.toString());
        setState(() {
          bToken = "Bearer " + responseObj["jwtToken"].toString();
        });
        print("token: " + bToken);
        saveToken(bToken); //saved with shared pref
        saveUserId(responseObj["id"]);
        setState(() {
          _validLogin = true;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MainScreen(bToken, responseObj)),
        );
        print("successful login");
      } else {
        setState(() {
          _validLogin = false;
          _waiting = false;
          _firstTryLog = false;
        });
        print("failed login");
      }
    });
  }

  Widget logInWidget() {
    return Column(
      children: [
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: emailController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'Email',
                hintStyle: TextStyle(color: Colors.white38)),
          ),
        ),
        SizedBox(
          height: 30,
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: passwordController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'Password',
                hintStyle: TextStyle(color: Colors.white38)),
            obscureText: true,
          ),
        ),
        SizedBox(
          height: 20,
        ),
        _firstTryLog
            ? Container()
            : Text(
                "Please enter valid values!",
                style: TextStyle(fontSize: 15, color: Colors.red),
              ),
        SizedBox(
          height: 20,
        ),
        _waiting
            ? CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                backgroundColor: Colors.transparent,
              )
            : Container(
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
                  onPressed: () => {
                    FocusScope.of(context).unfocus(),
                    setState(() {
                      _waiting = true;
                    }),
                    logIn(emailController.text.toString(),
                        passwordController.text.toString())
                  },
                  child: Text(
                    "LOG IN",
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                ),
              ),
        SizedBox(
          height: 20,
        ),
        TouchableOpacity(
            child: Text(
              "Forgot My Password...",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () => Future.delayed(
                Duration.zero,
                () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                          backgroundColor: Color(0xff212121),
                          title: Text("Forgot My Password...",
                              style: TextStyle(color: Colors.white38)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 1.0,
                                        offset: Offset(0.0, 5),
                                      ),
                                    ],
                                    color: Color(0xff303030),
                                    borderRadius: BorderRadius.circular(25)),
                                child: TextField(
                                  controller: emailController,
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
                                      hintText: 'Email',
                                      hintStyle:
                                          TextStyle(color: Colors.white38)),
                                ),
                              ),
                              SizedBox(
                                height: 10,
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
                                    Navigator.pop(context);
                                    Future.delayed(
                                        Duration.zero,
                                        () => forgotPassword(emailController
                                            .text)).then((_) => showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                              backgroundColor:
                                                  Color(0xff212121),
                                              title: Text(
                                                  "Forgot My Password...",
                                                  style: TextStyle(
                                                      color: Colors.white38)),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Password change mail is sent to your address.\nPlease check your email.",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white70),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 10),
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black12,
                                                                blurRadius: 1.0,
                                                                offset: Offset(
                                                                    0.0, 3),
                                                              ),
                                                            ],
                                                            color: Color(
                                                                0xff1c1c1c),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25)),
                                                        padding:
                                                            EdgeInsets.all(20),
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            10 *
                                                            9,
                                                        child: Container(
                                                          height: 15,
                                                          child: TextField(
                                                            obscureText: true,
                                                            controller:
                                                                tokenController,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                            decoration:
                                                                new InputDecoration(
                                                                    focusedBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color: Colors
                                                                              .transparent,
                                                                          width:
                                                                              1),
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(90.0)),
                                                                    ),
                                                                    enabledBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color: Colors
                                                                              .transparent,
                                                                          width:
                                                                              1),
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(90.0)),
                                                                    ),
                                                                    hintText:
                                                                        'ENTER THE GIVEN CODE HERE',
                                                                    hintStyle: TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        color: Colors
                                                                            .white38)),
                                                          ),
                                                        )),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 10),
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black12,
                                                                blurRadius: 1.0,
                                                                offset: Offset(
                                                                    0.0, 3),
                                                              ),
                                                            ],
                                                            color: Color(
                                                                0xff1c1c1c),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25)),
                                                        padding:
                                                            EdgeInsets.all(20),
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            10 *
                                                            9,
                                                        child: Container(
                                                          height: 15,
                                                          child: TextField(
                                                            obscureText: true,
                                                            controller:
                                                                passwordController,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white70),
                                                            decoration:
                                                                new InputDecoration(
                                                                    focusedBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color: Colors
                                                                              .transparent,
                                                                          width:
                                                                              1),
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(90.0)),
                                                                    ),
                                                                    enabledBorder:
                                                                        OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color: Colors
                                                                              .transparent,
                                                                          width:
                                                                              1),
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(90.0)),
                                                                    ),
                                                                    hintText:
                                                                        'ENTER THE NEW PASSWORD HERE',
                                                                    hintStyle: TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        color: Colors
                                                                            .white38)),
                                                          ),
                                                        )),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color:
                                                                Colors.black12,
                                                            blurRadius: 1.0,
                                                            offset: Offset(
                                                                0.0, 6.5),
                                                          ),
                                                        ],
                                                        gradient: LinearGradient(
                                                            colors: [
                                                              Color(0xff1c1c1c),
                                                              Colors.white
                                                            ],
                                                            begin:
                                                                const FractionalOffset(
                                                                    0.0, 0.0),
                                                            end:
                                                                const FractionalOffset(
                                                                    0.0, 50.0),
                                                            stops: [0.0, 0.1],
                                                            tileMode:
                                                                TileMode.clamp),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(25)),
                                                    child: FlatButton(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(18.0),
                                                      ),
                                                      onPressed: () {
                                                        resetPassword(
                                                            tokenController.text
                                                                .toString(),
                                                            passwordController
                                                                .text
                                                                .toString());
                                                        Navigator.pop(context);
                                                        showDialog(
                                                            context: context,
                                                            builder:
                                                                (_) =>
                                                                    AlertDialog(
                                                                      backgroundColor:
                                                                          Color(
                                                                              0xff212121),
                                                                      title: Text(
                                                                          "Change Account Password",
                                                                          style:
                                                                              TextStyle(color: Colors.white38)),
                                                                      content:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                                                            child:
                                                                                Text(
                                                                              "Do you confirm to change the account password?",
                                                                              textAlign: TextAlign.center,
                                                                              style: TextStyle(fontSize: 14, color: Colors.white70),
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
                                                                            child:
                                                                                FlatButton(
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(18.0),
                                                                              ),
                                                                              onPressed: () {
                                                                                resetPassword(tokenController.text.toString(), passwordController.text.toString());

                                                                                Navigator.pop(context);
                                                                              },
                                                                              child: Text(
                                                                                "OK",
                                                                                style: TextStyle(fontSize: 18, color: Colors.white70),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ));
                                                      },
                                                      child: Text(
                                                        "OK",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )));
                                  },
                                  child: Text(
                                    "CHANGE PASSWORD",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white70),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))))
      ],
    );
  }

  Widget signUpWidget() {
    return Column(
      children: [
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: firstNameController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'First Name',
                hintStyle: TextStyle(color: Colors.white38)),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: lastNameController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'Last Name',
                hintStyle: TextStyle(color: Colors.white38)),
          ),
        ),
        SizedBox(
          height: 30,
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: userNameController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'Username',
                hintStyle: TextStyle(color: Colors.white38)),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: emailController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'Email',
                hintStyle: TextStyle(color: Colors.white38)),
          ),
        ),
        SizedBox(
          height: 30,
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: passwordController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'Password',
                hintStyle: TextStyle(color: Colors.white38)),
            obscureText: true,
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 5),
            ),
          ], color: Color(0xff303030), borderRadius: BorderRadius.circular(25)),
          child: TextField(
            controller: repeatPasswordController,
            style: TextStyle(color: Colors.white70),
            decoration: new InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(90.0)),
                ),
                hintText: 'Repeat Password',
                hintStyle: TextStyle(color: Colors.white38)),
            obscureText: true,
          ),
        ),
        SizedBox(
          height: 20,
        ),
        _firstTrySign
            ? Container()
            : Text(
                "Please enter valid values!",
                style: TextStyle(fontSize: 15, color: Colors.red),
              ),
        SizedBox(
          height: 10,
        ),
        _waiting
            ? CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                backgroundColor: Colors.transparent,
              )
            : Container(
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
                  onPressed: () => {
                    FocusScope.of(context).unfocus(),
                    setState(() {
                      _waiting = true;
                    }),
                    if (passwordController.text.toString() ==
                        repeatPasswordController.text.toString())
                      Future.delayed(
                          Duration.zero,
                          () => signUp(
                              firstNameController.text.toString(),
                              lastNameController.text.toString(),
                              userNameController.text.toString(),
                              emailController.text.toString(),
                              passwordController.text.toString())).then((_) {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  backgroundColor: Color(0xff212121),
                                  title: Text("Account Verification",
                                      style: TextStyle(color: Colors.white38)),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15, horizontal: 10),
                                          child: Text(
                                            "Please check your email and enter the given code.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Container(
                                              height: 100,
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
                                                      BorderRadius.circular(
                                                          25)),
                                              padding: EdgeInsets.all(20),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  10 *
                                                  9,
                                              child: Container(
                                                child: TextField(
                                                  obscureText: true,
                                                  controller: tokenController,
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                  decoration:
                                                      new InputDecoration(
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .transparent,
                                                                width: 1),
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius.circular(
                                                                        90.0)),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .transparent,
                                                                width: 1),
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius.circular(
                                                                        90.0)),
                                                          ),
                                                          hintText:
                                                              'ENTER THE CODE HERE',
                                                          hintStyle: TextStyle(
                                                              color: Colors
                                                                  .white38)),
                                                ),
                                              )),
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
                                              verifyEmail(tokenController.text
                                                  .toString());
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              "OK",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white70),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ));
                      })
                    else
                      {
                        setState(() {
                          _waiting = false;
                          _firstTrySign = false;
                        }),
                        print("not the same password")
                      }
                  },
                  child: Text(
                    "SIGN UP",
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 25),
          height: MediaQuery.of(context).size.height,
          color: Color(0xff101010),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 35),
                  width: MediaQuery.of(context).size.width / 2,
                  child: Image(
                    image: new AssetImage("assets/smartlock1218.png"),
                  ),
                ),
                Container(
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TouchableOpacity(
                              onTap: () {
                                setState(() {
                                  if (exists != true) exists = true;
                                });
                              },
                              child: Text("LOG IN",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: exists
                                          ? Colors.white70
                                          : Colors.white38)),
                            ),
                            Container(
                              color: Colors.white38,
                              width: 1,
                              height: 25,
                            ),
                            TouchableOpacity(
                              onTap: () {
                                setState(() {
                                  if (exists != false) exists = false;
                                });
                              },
                              child: Text("SIGN UP",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: exists
                                          ? Colors.white38
                                          : Colors.white70)),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        exists ? logInWidget() : signUpWidget()
                      ],
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
