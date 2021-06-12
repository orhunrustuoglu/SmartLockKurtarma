import 'package:flutter/material.dart';
import 'main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LockUsageHistory extends StatefulWidget {
  final String bToken;
  final int keyId;

  LockUsageHistory(this.bToken, this.keyId);
  @override
  _LockUsageHistoryState createState() => _LockUsageHistoryState();
}

class _LockUsageHistoryState extends State<LockUsageHistory> {
  var lockObj;
  var historyList = [];
  bool _waiting = true;

  Future<void> getHistories(String bToken) async {
    final url = Uri.https(baseUrl, "/History/ListHistories");
    await http.get(
      url,
      headers: <String, String>{
        'Authorization': bToken,
        'Content-Type': 'application/json'
      },
    ).then((response) {
      var obj = json.decode(response.body);
      if (response.statusCode == 200) {
        obj = json.decode(response.body) as List;
        obj.forEach((element) {
          if (element["keyId"] == widget.keyId)
            //getHistory(bToken, element["keyId"]);
            setState(() {
              historyList.add(element);
            });
        });
        print("Histories retrieval success!");
      } else {
        print("Histories retrieval failed!");
      }
      if (response.body.isNotEmpty) {
        print("histories body: " + obj.toString());
      }
      setState(() {
        _waiting = false;
      });
    });
  }

  Future<void> getHistory(String bToken, int _keyId) async {
    final url = Uri.https(baseUrl, "/History/ListHistoryByKeyId$_keyId");
    await http.get(
      url,
      headers: <String, String>{
        'Authorization': bToken,
        'Content-Type': 'application/json'
      },
    ).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          historyList.add(json.decode(response.body));
        });
        print(response.body);
        print("History retrieval success!");
      } else {
        print(response.body);
        print("History retrieval failed!");
      }
      if (response.body.isNotEmpty) {
        var obj = json.decode(response.body);
        print("history body: " + obj.toString());
      }
    });
  }

  Widget prevUser(String name, id, date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 1.0,
              offset: Offset(0.0, 3),
            ),
          ], color: Colors.white12, borderRadius: BorderRadius.circular(25)),
          padding: EdgeInsets.only(top: 15),
          width: MediaQuery.of(context).size.width / 10 * 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(name,
                    style: TextStyle(fontSize: 16, color: Colors.white70)),
              ),
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
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25))),
                    padding: EdgeInsets.all(10),
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("USER ID: " + id.toString(),
                            style:
                                TextStyle(fontSize: 16, color: Colors.white54)),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: Colors.greenAccent),
                            SizedBox(
                              width: 5,
                            ),
                            Text(date,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white54)),
                          ],
                        )
                      ],
                    )),
              )
            ],
          )),
    );
  }

  @override
  void initState() {
    print("keyId: " + widget.keyId.toString());
    getHistories(widget.bToken);
    super.initState();
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
                    "LOCK USAGE\nHISTORY",
                    style: TextStyle(fontSize: 24, color: Colors.white70),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
            backgroundColor: Color(0xff101010),
          ),
          body: _waiting
              ? Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    backgroundColor: Colors.transparent,
                  ),
                )
              : historyList.isEmpty
                  ? Center(
                      child: Text(
                        "No History",
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: historyList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return prevUser(
                            historyList[index]["name"] ?? "name",
                            historyList[index]["keyId"] ?? "keyId",
                            /*historyList[index]["date"]
                                    .toString()
                                    .substring(0, 10) ??*/
                            "date");
                      })),
    );
  }
}
