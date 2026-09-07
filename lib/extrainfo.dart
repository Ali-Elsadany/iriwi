import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:irwi/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'directory.dart';
import 'widgets/side_menu.dart';


Future<bool> logoutASYNC(String username, String password, String confirmPass, String phone,String cookie) async {
  var mydata = jsonEncode({
  });


  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Account/LogOff'), // Convert String to Uri
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
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


class extraInfo extends StatefulWidget {

  /*login({Key key, this.title}) : super(key: key);

  final String title;*/
  @override
  _extraInfoState createState() => _extraInfoState();
}

class _extraInfoState extends State<extraInfo> {
  bool checkedValue = false;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  String username = '';
  String password = '';
  String confirmPass = '';
  String phone = '';
  late WebViewController _controller;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final TextEditingController _pass = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                isLoading = true;
                hasError = false;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                isLoading = false;
                hasError = true;
                errorMessage = 'خطأ في تحميل المحتوى: ${error.description}';
              });
            },
          ),
        );

      await _loadHtmlFromAssets();
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'خطأ في تهيئة الصفحة: $e';
      });
    }
  }

  Future<void> _loadHtmlFromAssets() async {
    try {
      String fileText = await DefaultAssetBundle.of(context).loadString('assets/extrainfo.html');
      
      await _controller.loadRequest(Uri.dataFromString(
        fileText,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ));
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'خطأ في تحميل الملف: $e';
      });
    }
  }

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
                drawer: SideMenu(currentRoute: '/extrainfo'),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(goToFarms());
          },
          child: Icon(Icons.home),
          backgroundColor: Color(0xff2af598),
        ),
        body: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: isLoading 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff08aeea)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'جاري التحميل...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'حدث خطأ في التحميل',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isLoading = true;
                                    hasError = false;
                                  });
                                  _loadHtmlFromAssets();
                                },
                                child: Text('إعادة المحاولة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff08aeea),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : WebViewWidget(
                          controller: _controller,
                          gestureRecognizers: {
                            Factory<VerticalDragGestureRecognizer>(
                                  () => VerticalDragGestureRecognizer(),
                            ),
                          },
                        ),
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

