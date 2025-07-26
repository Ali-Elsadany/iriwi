import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:irwi/farms.dart';
import 'package:irwi/signup.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'directory.dart';

Future<bool> loginASYNC(String username, String password,String cookie) async {
  var mydata = jsonEncode({
    'Phone': username,
    'Password': password,
    'RememberMe': 'true',
  });


  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Account/Login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
    body: mydata,
  );
// print("Login"+response.statusCode.toString()+" "+ response.headers['set-cookie']!);
  if (response.statusCode == 302) {
    //return Album.fromJson(json.decode(response.body));
    //String reqbody = response.request.toString();
    //String resbody = response.body;
    //if(response.headers['location'] == '/Home/farms'){
    if(response.headers['set-cookie'] == null)
      return true;
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


class login extends StatefulWidget {

  /*login({Key key, this.title}) : super(key: key);

  final String title;*/
  @override
  _loginState createState() => _loginState();
}

class _loginState extends State<login> {
  bool isLoading = false;
  String username = '';
  String password = '';
  String errorMessage = '';
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Container(
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
                      child: Form(
                        key: formkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                              decoration: InputDecoration(labelText: 'رقم الهاتف'),
                              validator: (String? value){
                                if(value!.isEmpty){
                                  return "برجاء ادخال رقم الهاتف";
                                }
                              },
                              onSaved: (String? value){
                                username = value!;
                              },
                            ),
                            TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                              decoration: InputDecoration(labelText: 'كلمة السر'),
                              obscureText: true,
                              validator: (String? value){
                                if(value!.isEmpty){
                                  return "برجاء ادخال كلمة السر";
                                }
                              },
                              onSaved: (String? value){
                                password = value!;
                              },
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: isLoading
                                  ? Center(
                                child: CircularProgressIndicator(),
                              )
                                  : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(errorMessage,
                                          style: TextStyle(color: Colors.red),
                                        textAlign: TextAlign.center,
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Navigator.of(context).pushReplacement(goToFarms());
                                          if (!formkey.currentState!.validate()) {
                                            return;
                                          }
                                          setState(() {
                                            isLoading = true;
                                            formkey.currentState!.save();
                                          });
                                          SharedPreferences prefs = await SharedPreferences.getInstance();
                                          String cookie = (prefs.getString('cookie') ?? '');
                                          final user = await loginASYNC(username, password, cookie);
                                          if (user == false) {
                                            errorMessage = 'برجاء التاكد من كلمة السر ورقم الهاتف';
                                            setState(() {
                                              isLoading = false;
                                            });
                                            print('user = false');
                                          } else {
                                            Navigator.of(context).pushReplacement(goToFarms());
                                            setState(() {
                                              isLoading = false;
                                            });
                                            print('user = true');
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xff26a69a), // ✅ Use 'backgroundColor' instead of 'color'
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Optional padding
                                        ),
                                        child: Text(
                                          'الدخول',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),

                                    ],
                                  ),
                            ),Text('ليس لديك حساب؟ اذهب الى',
                              style: TextStyle(color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(goToSignup());
                              },
                              child: Text(
                                'انشاء حساب جديد',
                                style: TextStyle(color: Color(0xff039be5)),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                    Container(
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
                ),)
          )
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
