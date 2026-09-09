
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart';
import 'package:irwi/addfarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'farms.dart';
import 'login.dart';
import 'signup.dart';
import 'pre_login.dart';


Future<bool> checkIfLoggedIn(String cookie) async {


  /*final http.Response response = await http.post(
    'https://irwicrop.com',
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie':cookie,
    },
  );*/
  bool isloggedin = false;
  HttpClient client = new HttpClient();
  await client.getUrl(Uri.parse("https://irwicrop.com"))
      .then((HttpClientRequest request) {
    // Optionally set up headers...
    // Optionally write to the request object...
    // Then call close.
    request.followRedirects = false;
    request.headers.add('Cookie', cookie);
    return request.close();
  })
      .then((HttpClientResponse response) {
        if (response.statusCode == 200) {
          print(response.toString());
          isloggedin = true;
        } else {//302
          print(response.toString());
          isloggedin = false;
          //throw Exception('Failed to create album.');
        }
  });
return isloggedin;
  /*if (response.statusCode == 200) {
    //return Album.fromJson(json.decode(response.body));
    //String reqbody = response.request.toString();
    //String resbody = response.body;
    if(response.headers['location'] == '/Home/farms'){
      SharedPreferences prefs = await SharedPreferences.getInstance();
      //int counter = (prefs.getInt('counter') ?? 0) + 1;
      //print('Pressed $counter times.');
      await prefs.setString('cookie', response.headers['set-cookie']);
      print('Success Man !');
      return true;
    }
    print(response);
    return false;
  } else {//302
    print(response.body);
    return false;
    throw Exception('Failed to create album.');
  }*/
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  if(cookie == ''){
    runApp(MyApp(false));
  }else{
    final LoggedIn = await  checkIfLoggedIn(cookie);
    runApp(MyApp(LoggedIn));
  }
}

class MyApp extends StatelessWidget {
  bool loggedin;
  MyApp(this.loggedin);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'اروي',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        Locale("ar", "AE"), // OR Locale('ar', 'AE') OR Other RTL locales
      ],
      locale: Locale("ar", "AE"),
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        fontFamily: 'IBMPlexSansArabic',
        primarySwatch: Colors.teal,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: loggedin ? 'farms': 'pre_login',
      //home: MyHomePage(title: 'Flutter Demo Home Page'),
      routes: {
        'pre_login': (context) => preLogin(),
        'login': (context) => login(),
        'signup': (context) => signup(),
        'farms': (context) => farms(),
        'addfarm': (context) => addfarm(),
      },
    );
  }
}
/*
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/cover.png"),
            fit: BoxFit.cover,
          ),
        ),
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
              child: Image(
                image: AssetImage('assets/images/logo.png')
              ),
            ),
            Container(
              decoration: new BoxDecoration(
                borderRadius: new BorderRadius.circular(16.0),
                color: Colors.white.withOpacity(0.8),
              ),
              padding: EdgeInsets.all(50),
              margin: EdgeInsets.symmetric(horizontal: 25,vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                              style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
                    decoration: InputDecoration(labelText: 'رقم الهاتف'),
                  ),
                  TextFormField(
                              style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
                    decoration: InputDecoration(labelText: 'كلمة السر'),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: RaisedButton(
                        onPressed: (){},
                      child: Text('الدخول',
                        style: TextStyle(color: Colors.white)
                      ),
                      color: Color(0xff26a69a),
                    ),
                  ),Text('ليس لديك حساب؟ اذهب الى',
                      style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  FlatButton(onPressed: (){}, child: Text('انشاء حساب جديد',
                    style: TextStyle(color: Color(0xff039be5)),
                    textAlign: TextAlign.center,
                  ))
                ],
              ),
            ),
            Container(
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
        ),)
        )
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}*/
