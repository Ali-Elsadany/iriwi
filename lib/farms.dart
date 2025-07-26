
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:irwi/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'directory.dart';


Future<bool> logoutASYNC(String username, String password, String confirmPass, String phone,String cookie) async {
  var mydata = jsonEncode({
  });


  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Account/LogOff'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
    body: mydata,
  );

  if (response.statusCode == 302) {
    //return Album.fromJson(json.decode(response.body));
    //String reqbody = response.request.toString();
    //String resbody = response.body;
    //if(response.headers['location'] == '/Home/farms'){
      SharedPreferences prefs = await SharedPreferences.getInstance();
      //int counter = (prefs.getInt('counter') ?? 0) + 1;
      //print('Pressed $counter times.');
      await prefs.setString('cookie', response.headers['set-cookie']!);
      print('Success Man !');
      return true;
    //}
    print(response);
    return false;
  } else {//302
    print(response.body);
    return false;
    throw Exception('Failed to create album.');
  }
}


class farms extends StatefulWidget {

  /*login({Key key, this.title}) : super(key: key);

  final String title;*/
  @override
  _farmsState createState() => _farmsState();
}

class _farmsState extends State<farms> {
  bool checkedValue = false;
  bool isLoading = false;
  String username = '';
  String password = '';
  String confirmPass = '';
  String phone = '';
  String errorMessage = '';
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final TextEditingController _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إروي'),
            Image(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.contain,
              height: AppBar().preferredSize.height -5,
            )
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xff08aeea), Color(0xff2af598)])
          ),
        ),
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Image(
                image: AssetImage('assets/images/logo.png'),
                width: 150,
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  Container(child: Center(child: FaIcon(FontAwesomeIcons.home,color: Colors.grey[600],)),width: 25,margin: EdgeInsets.fromLTRB(10, 0, 0, 0),),
                  Text('مزرعتي'),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(goToFarms());
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Container(child: Center(child: FaIcon(FontAwesomeIcons.info,color: Colors.grey[600],)),width: 25,margin: EdgeInsets.fromLTRB(10, 0, 0, 0),),
                  Text('اعرف عنا'),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(goToAboutUs());
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Container(child: Center(child: FaIcon(FontAwesomeIcons.solidQuestionCircle,color: Colors.grey[600],)),width: 25,margin: EdgeInsets.fromLTRB(10, 0, 0, 0),),
                  Text('المقترحات'),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(goToContactUs());
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Container(child: Center(child: FaIcon(FontAwesomeIcons.wpforms,color: Colors.grey[600],)),width: 25,margin: EdgeInsets.fromLTRB(10, 0, 0, 0),),
                  Text('معلومات ارشادية'),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(goToExtraInfo());
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: Row(
                children: [
                  Container(child: Center(child: FaIcon(FontAwesomeIcons.signOutAlt,color: Colors.grey[600],)),width: 25,margin: EdgeInsets.fromLTRB(10, 0, 0, 0),),
                  Text('تسجيل الخروج'),
                ],
              ),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String cookie = (prefs.getString('cookie') ?? '');
                final user = await  logoutASYNC(username,password,confirmPass,phone,cookie);
                if(user == false){
                  Navigator.pop(context);
                  print('logout failed');
                }else{
                  print('logged out');
                  Navigator.of(context).pushReplacement(goToLogin());
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(goToFarms());
        },
        child: Icon(Icons.home),
        backgroundColor: Color(0xff2af598),
      ),
      body: Container(
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height)/*.tightFor(
                height: MediaQuery.of(context).size.height,//Height of screen
              )*/,
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 25,vertical: 15),
                          alignment: Alignment.bottomRight,
                          child:
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Button background color
                              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushReplacement(goToAddFarm());
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.add_circle, color: Color(0xff039be5), size: 35),
                                SizedBox(width: 5), // Add spacing between icon and text
                                Text(
                                  'أضف مزرعة',
                                  style: TextStyle(
                                    color: Color(0xff039be5),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w100,
                                  ),
                                ),
                              ],
                            ),
                          )

                        ), // Add Farm Button
                        FutureBuilder<List<farmObject>>(
                         future: fetchFarms(http.Client()),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              // WidgetsBinding.instance.addPostFrameCallback((_) {
                              //   Navigator.of(context).pushReplacement(goToLogin());
                              // });
                              return Center(child: CircularProgressIndicator()); // Temporary widget to avoid build issues
                            }

                            return snapshot.hasData
                                ? Column(
                              children: [
                                if (snapshot.data != null)
                                  for (farmObject myfarm in snapshot.data!)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 5,
                                            blurRadius: 7,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      margin: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: <Widget>[
                                              Column(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      print("Image clicked");
                                                      Navigator.of(context).pushReplacement(goToFarmCrops(myfarm.farmId!));
                                                    },
                                                    child: Image.asset('assets/images/farm.png'),
                                                  ),
                                                  SizedBox(height: 25),
                                                ],
                                              ),
                                              Positioned(
                                                left: 5,
                                                bottom: 0,
                                                child: FloatingActionButton(
                                                  heroTag: 'frm' + myfarm.farmId.toString(),
                                                  child: Icon(Icons.edit),
                                                  onPressed: () {
                                                    print('FAB tapped!');
                                                    Navigator.of(context).pushReplacement(goToEditFarms(myfarm.farmId!));
                                                  },
                                                  backgroundColor: Color(0xff2af598),
                                                ),
                                              ),
                                            ],
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              print("Container clicked");
                                              Navigator.of(context).pushReplacement(goToFarmCrops(myfarm.farmId!));
                                            },
                                            child: Container(
                                              margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(myfarm.name!, style: TextStyle(fontSize: 30)),
                                                  Text(myfarm.government!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal)),
                                                  // Text('عدد المحاصيل ' + myfarm.farmcropsCount.toString(),
                                                  //     style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal)),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                              ],
                            )
                                : Center(child: CircularProgressIndicator());
                          },

                        ),
                      ],
                    ),// Body
                    Container(//FOOTER
                      padding: EdgeInsets.all(5),
                      decoration: new BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xff08aeea), Color(0xff2af598)],
                            begin: const FractionalOffset(0.0, 0.0),
                            end: const FractionalOffset(0.7, 0.0),
                            stops: [0.0, 1.0],
                            tileMode: TileMode.clamp
                        ),
                      ),
                      child: Column(
                        children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                                child: Image(image: AssetImage('assets/images/msa.png'),
                                  fit: BoxFit.contain,)
                            ),
                            SizedBox(width: 20),
                            Flexible(
                                child: Image(image: AssetImage('assets/images/iwmi.png'),
                                  fit: BoxFit.contain,)
                            ),
                            SizedBox(width: 20),
                            Flexible(
                                child: Image(image: AssetImage('assets/images/sweri.png'),
                                  fit: BoxFit.contain,)
                            )
                          ],
                        ),
                        Image(
                            image: AssetImage('assets/images/WAPOR.jpg')
                        )
                      ],
                      ),
                    ),// Footer
                  ],
                ),
              )
          )
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
//https://irwicrop.com/Home/RemoteDataSource_GetAllFarms
Future<List<farmObject>> fetchFarms(http.Client client) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  final response = await client.get(
    Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetUserFarms'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
     'Cookie': cookie
    },
  );
print("kkkkk"+" "+response.body.toString());

  // Use the compute function to run parseFarms in a separate isolate.
  return compute(parseFarms, response.body);
}

// A function that converts a response body into a List<Photo>.
List<farmObject> parseFarms(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<farmObject>((json) => farmObject.fromJson(json)).toList();
}


class farmObject {
  // final int? farmId;
  // final String? userId;
  // final int? farmcropsCount;
  // final String? government;
  // final String? name;
  int? farmId;
  String? name;
  String? government;
  String? soiltype;
  bool? salty;
  double? lng;
  double? lat;
  int? dischargerate;
  int? gasuseage;
  int? gasprice;

  farmObject({this.farmId,
    this.name,
    this.government,
    this.soiltype,
    this.salty,
    this.lng,
    this.lat,
    this.dischargerate,
    this.gasuseage,
    this.gasprice});

  factory farmObject.fromJson(Map<String, dynamic> json) {
    return farmObject(
      farmId: json['farmId'] as int,
      // userId: json['userId'] as String,
      // farmcropsCount: json['farmcropsCount'] as int,
      government: json['government'] as String,
      name: json['name'] as String,
    );
  }
}
/*

                                    Fluttertoast.showToast(
                                        msg: "This is Center Short Toast",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.red,
                                        textColor: Colors.white,
                                        fontSize: 16.0
                                    );
                                    * */