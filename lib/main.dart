import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:irwi/addfarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'farms.dart';
import 'login.dart';
import 'signup.dart';
import 'pre_login.dart';

Future<bool> checkIfLoggedIn(String cookie) async {
  bool isloggedin = false;
  HttpClient client = HttpClient();
  try {
    HttpClientRequest request = await client.getUrl(Uri.parse("https://irwicrop.com"));
    request.followRedirects = false;
    request.headers.add('Cookie', cookie);
    HttpClientResponse response = await request.close();
    if (response.statusCode == 200) {
      isloggedin = true;
    } else {
      isloggedin = false;
    }
  } catch (e) {
    isloggedin = false;
  }
  return isloggedin;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  if (cookie == '') {
    runApp(MyApp(false));
  } else {
    final LoggedIn = await checkIfLoggedIn(cookie);
    runApp(MyApp(LoggedIn));
  }
}

class MyApp extends StatelessWidget {
  final bool loggedin;
  const MyApp(this.loggedin, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اروي',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("ar", "AE"),
      ],
      locale: const Locale("ar", "AE"),
      theme: ThemeData(
        fontFamily: 'IBMPlexSansArabic',
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: loggedin ? 'farms' : 'pre_login',
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
