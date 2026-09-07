
import 'dart:convert';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:irwi/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'directory.dart';
import 'widgets/side_menu.dart';


Future<bool> logoutASYNC(String username, String password, String confirmPass, String phone,String cookie) async {
  var mydata = jsonEncode({
  });


  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Account/LogOff'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
  );


  if (response.statusCode == 302) {
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


class aboutUs extends StatefulWidget {

  /*login({Key key, this.title}) : super(key: key);

  final String title;*/
  @override
  _aboutUsState createState() => _aboutUsState();
}

class _aboutUsState extends State<aboutUs> {
  bool checkedValue = false;
  bool isLoading = false;
  String username = '';
  String password = '';
  String confirmPass = '';
  String phone = '';
  String errorMessage = '';
  late VideoPlayerController videocontroller;
  late ChewieController _chewieController;
  late Future<void> waitForVideoController;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final TextEditingController _pass = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    //videocontroller = VideoPlayerController.asset('assets/video.mp4');
    //waitForVideoController = videocontroller.initialize();
    videocontroller = VideoPlayerController.asset('assets/video.mp4');
    _chewieController = ChewieController(
      videoPlayerController: videocontroller,
      aspectRatio: 9/18,
      autoPlay: false,
      looping: false,
      autoInitialize: true,
    );
    super.initState();
  }
  @override
  void dispose() {
    videocontroller.dispose();
    _chewieController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  _launchURL() async {
    const url = 'http://irwicrop.com/IRWI%20user%20manual.pdf';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(goToFarms());
        return false; // Prevents default back navigation
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
        drawer: SideMenu(currentRoute: '/about'),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(goToFarms());
          },
          child: Icon(Icons.home),
          backgroundColor: Color(0xff2af598),
        ),
        body:  Container(
      decoration: BoxDecoration(
      image: DecorationImage(
          image: AssetImage("assets/images/cover.png"),
      fit: BoxFit.cover,
    ),
    ),
    child: LayoutBuilder(
    builder: (context, constraints) {
    return SingleChildScrollView(
    child: ConstrainedBox(
    constraints: BoxConstraints(minHeight: constraints.maxHeight),
    child: Column(
    children: [
    Padding(
    padding: const EdgeInsets.only(top: 50),
    child: Column(
    children: [
    Container(
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16.0),
    color: Colors.white.withOpacity(0.8),
    ),
    padding: EdgeInsets.all(25),
    margin: EdgeInsets.symmetric(horizontal: 25, vertical: 5),
    child: Form(
    key: formkey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
    AspectRatio(
    aspectRatio: 16 / 9,
    child: Chewie(
    controller: _chewieController,
    ),
    ),
    ],
    ),
    ),
    ),
    Container(
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16.0),
    color: Colors.white.withOpacity(0.8),
    ),
    padding: EdgeInsets.all(25),
    margin: EdgeInsets.symmetric(horizontal: 25, vertical: 5),
    child: GestureDetector(
    onTap: _launchURL,
    child: Image.asset('assets/downpdf.png'),
    ),
    ),
    ],
    ),
    ),

    // Footer Spacer to push content
    SizedBox(height: 20),

    // Footer
    Container(
    width: double.infinity,
    padding: EdgeInsets.all(5),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [Color(0xff08aeea), Color(0xff2af598)],
    begin: Alignment.topLeft,
    end: Alignment.centerRight,
    ),
    ),
    child: Column(
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
    Flexible(
    child: Image.asset('assets/images/msa.png', fit: BoxFit.contain),
    ),
    SizedBox(width: 20),
    Flexible(
    child: Image.asset('assets/images/iwmi.png', fit: BoxFit.contain),
    ),
    SizedBox(width: 20),
    Flexible(
    child: Image.asset('assets/images/sweri.png', fit: BoxFit.contain),
    ),
    ],
    ),
    SizedBox(height: 10),
    Image.asset('assets/images/WAPOR.jpg'),
    ],
    ),
    ),
    ],
    ),
    ),
    );
    },
    ),
    ),


    // SizedBox.expand(
    //       child: Container(
    //           decoration: BoxDecoration(
    //             image: DecorationImage(
    //               image: AssetImage("assets/images/cover.png"),
    //               fit: BoxFit.cover,
    //             ),
    //           ),
    //           child: SingleChildScrollView(
    //               scrollDirection: Axis.vertical,
    //               child: ConstrainedBox(
    //                 constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height)/*.tightFor(
    //                 height: MediaQuery.of(context).size.height,//Height of screen
    //               )*/,
    //                 child:Column(
    //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                   children: <Widget>[
    //                     Container(
    //                       margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
    //                       child: Column(
    //                         children: [
    //                           Container(
    //                             decoration: new BoxDecoration(
    //                               borderRadius: new BorderRadius.circular(16.0),
    //                               color: Colors.white.withOpacity(0.8),
    //                             ),
    //                             padding: EdgeInsets.all(25),
    //                             margin: EdgeInsets.symmetric(horizontal: 25,vertical: 5),
    //                             child: Form(
    //                               key: formkey,
    //                               child: Column(
    //                                 crossAxisAlignment: CrossAxisAlignment.stretch,
    //                                 children: <Widget>[
    //                                   Chewie(
    //                                     controller: _chewieController,
    //                                   )
    //                                 ],
    //                               ),
    //                             ),
    //                           ),
    //                           Container(
    //                             decoration: new BoxDecoration(
    //                               borderRadius: new BorderRadius.circular(16.0),
    //                               color: Colors.white.withOpacity(0.8),
    //                             ),
    //                             padding: EdgeInsets.all(25),
    //                             margin: EdgeInsets.symmetric(horizontal: 25,vertical: 5),
    //                             child: Column(
    //                               crossAxisAlignment: CrossAxisAlignment.stretch,
    //                               children: <Widget>[
    //                                 GestureDetector(
    //                                   onTap: _launchURL,
    //                                   child: Container(
    //                                     child: Image(
    //                                         image: AssetImage('assets/downpdf.png')
    //                                     ),
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                     Container(//FOOTER
    //                       padding: EdgeInsets.all(5),
    //                       decoration: new BoxDecoration(
    //                         gradient: LinearGradient(
    //                             colors: [Color(0xff08aeea), Color(0xff2af598)],
    //                             begin: const FractionalOffset(0.0, 0.0),
    //                             end: const FractionalOffset(0.7, 0.0),
    //                             stops: [0.0, 1.0],
    //                             tileMode: TileMode.clamp
    //                         ),
    //                       ),
    //                       child: Column(
    //                         children: [
    //                           Row(
    //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                         children: <Widget>[
    //                           Flexible(
    //                               child: Image(image: AssetImage('assets/images/msa.png'),
    //                                 fit: BoxFit.contain,)
    //                           ),
    //                           SizedBox(width: 20),
    //                           Flexible(
    //                               child: Image(image: AssetImage('assets/images/iwmi.png'),
    //                                 fit: BoxFit.contain,)
    //                           ),
    //                           SizedBox(width: 20),
    //                           Flexible(
    //                               child: Image(image: AssetImage('assets/images/sweri.png'),
    //                                 fit: BoxFit.contain,)
    //                           )
    //                         ],
    //                       ),
    //                           Image(
    //                               image: AssetImage('assets/images/WAPOR.jpg')
    //                           )
    //                         ],
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               )
    //           )
    //       ),
    //     ), // This trailing comma makes auto-formatting nicer for build methods.
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

