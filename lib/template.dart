
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:irwi/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    return WillPopScope(
      onWillPop: ()async{
      //print('poooooooooooooped');
      Navigator.of(context).pushReplacement(goToFarms());
      return false;
    },
      child: Scaffold(
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
                  // Close the drawer first
                  Navigator.pop(context);
                  
                  // Try to logout from API (but don't wait for result)
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String cookie = (prefs.getString('cookie') ?? '');
                  
                  // Clear stored credentials regardless of API result
                  await prefs.clear();
                  
                  // Navigate to login and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => login()),
                    (Route<dynamic> route) => false,
                  );
                  
                  // Attempt logout API call in background (don't wait for result)
                  logoutASYNC(username, password, confirmPass, phone, cookie);
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
            /*decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/cover.png"),
                fit: BoxFit.cover,
              ),
            ),*/
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height)/*.tightFor(
                  height: MediaQuery.of(context).size.height,//Height of screen
                )*/,
                  child:Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
                        child: Text('asdafsdsafasdg'),
                      ),
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
                      ),
                    ],
                  ),
                )
            )
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

Route goToLogin() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => login(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(-1.0, 0.0);
      var end = Offset.zero;
      var curve = Curves.easeInCirc;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

