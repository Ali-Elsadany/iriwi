
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:irwi/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'directory.dart';



Future<bool> signupASYNC(String username, String password, String confirmPass, String phone,String cookie) async {
  var mydata = jsonEncode({
    'phone': phone,
    'Password': password,
    'ConfirmPassword': confirmPass,
    'firstname': username,
  });


  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Account/Register'), // ✅ Convert to Uri
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


class signup extends StatefulWidget {

  /*login({Key key, this.title}) : super(key: key);

  final String title;*/
  @override
  _signupState createState() => _signupState();
}

class _signupState extends State<signup> {
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
                          image: AssetImage('assets/images/farmer.png'),
                        width: 150,
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
                            Text('إنشاء حساب جديد',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                              decoration: InputDecoration(labelText: 'الاسم'),
                              validator: (String? value){
                                if(value!.isEmpty){
                                  return "برجاء ادخال الاسم";
                                }
                              },
                              onSaved: (String? value){
                                username = value!;
                              },
                            ),
                            TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                              decoration: InputDecoration(labelText: 'رقم الهاتف'),
                              validator: (String? value){
                                if(value!.isEmpty){
                                  return "برجاء ادخال رقم الهاتف";
                                }else if(value.length != 11){
                                  return "رقم الهاتف يجب ان يكون من 11 رقم";
                                }
                              },
                              onSaved: (String? value){
                                phone = value!;
                              },
                            ),
                            TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                              controller: _pass,
                              decoration: InputDecoration(labelText: 'كلمة السر'),
                              obscureText: true,
                              validator: (String? value){
                                if(value!.isEmpty){
                                  return "برجاء ادخال كلمة السر";
                                }else if(value.length <6){
                                  return "يجب ان تكون 6 احرف او اكتر";
                                }
                              },
                              onSaved: (String? value){
                                password = value!;
                              },
                            ),
                            TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                              decoration: InputDecoration(labelText: 'تأكيد كلمة السر'),
                              obscureText: true,
                              validator: (String? value){
                                if(value!.isEmpty){
                                  return "برجاء ادخال تأكيد كلمة السر";
                                }else if(_pass.text != value){
                                  return "كلمات السر لا تتطابق";
                                }else if(!checkedValue){
                                  return "برجاء الموافقة على الشروط";
                                }
                              },
                              onSaved: (String? value){
                                confirmPass = value!;
                              },
                            ),
                            Container(
                              margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: CheckboxListTile(
                                title: Text('بالنقر على'
                                    '"‏إنشاء حساب‏"'
                                    'فإنك توافق على الشروط'),
                                value: checkedValue,
                                onChanged: (newValue) {
                                  setState(() {
                                    checkedValue = newValue!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                              ),
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
                                      if (!formkey.currentState!.validate()) { // ✅ Add null safety
                                        return;
                                      }
                                      setState(() {
                                        isLoading = true;
                                        formkey.currentState!.save();
                                      });

                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                      String cookie = (prefs.getString('cookie') ?? '');
                                      final user = await signupASYNC(username, password, confirmPass, phone, cookie);

                                      if (!user) { // ✅ `user == false` → `!user`
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
                                      backgroundColor: Color(0xff26a69a), // ✅ Use `backgroundColor`
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    ),
                                    child: Text(
                                      'إنشاء حساب',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                ],
                              ),
                            ),Text('لديك حساب؟ اذهب الى',
                              style: TextStyle(color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(goToLogin());
                              },
                              child: Text(
                                'تسجيل الدخول',
                                style: TextStyle(color: Color(0xff039be5)),
                                textAlign: TextAlign.center,
                              ),
                            )

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
