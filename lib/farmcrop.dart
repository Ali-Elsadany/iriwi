
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:irwi/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math' as math;
import 'directory.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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


class farmcrop extends StatefulWidget {
  int farmid;

  farmcrop(this.farmid);


  /*login({Key key, this.title}) : super(key: key);

  final String title;*/
  @override
  _farmcropState createState() => _farmcropState(farmid);
}

class WeatherBoxWebview extends StatefulWidget {
  final int farmid;
  WeatherBoxWebview(this.farmid);

  @override
  _WeatherBoxWebviewState createState() => _WeatherBoxWebviewState();
}

class _WeatherBoxWebviewState extends State<WeatherBoxWebview>
    with AutomaticKeepAliveClientMixin<WeatherBoxWebview> {
  late final WebViewController _controller;
  final cookieManager = WebviewCookieManager();
  bool isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          print('Page loaded: $url');
        },
      ));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cookie = prefs.getString('cookie') ?? '';

    String myurl = 'https://irwicrop.com/Home/weatherbox/${widget.farmid}';

    // Set Cookie Correctly
    await cookieManager.setCookies([
      Cookie('Cookie', cookie)..domain = 'irwicrop.com'
    ]);

    _controller.loadRequest(Uri.parse(myurl), headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    });

    setState(() {
      isWebViewInitialized = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      height: 160,
      child: isWebViewInitialized
          ? WebViewWidget(controller: _controller)
          : Center(child: CircularProgressIndicator()),
    );
  }

  @override
  bool get wantKeepAlive => true;
}


class _farmcropState extends State<farmcrop> with SingleTickerProviderStateMixin {
  bool checkedValue = false;
  bool isLoading = true;
  String username = '';
  String password = '';
  String confirmPass = '';
  String phone = '';
  String errorMessage = '';
  final DateFormat formatter = DateFormat('yyyy/MM/dd');
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final TextEditingController _pass = TextEditingController();
  List<cropObject>? cropTypes = null;
  List<MeasringObject>? measuringUnits = null;
  List<farmcropObject>? allfarmcrops = null;
  List<irrigationMethodObject>? irrigationMethods = null;
  List<DailyRecordsObject>? DailyRecords = null;
  List<PracticalGridObject>? PracticalGrid = null;
  List<IdealGridObject>? IdealGrid = null;
  List<PREVIOUSDailyRecordsObject>? PREVIOUSDailyRecords = null;
  List<PREVIOUSPracticalGridObject>? PREVIOUSPracticalGrid = null;
  List<PREVIOUSIdealGridObject>? PREVIOUSIdealGrid = null;
  List<FarmcropFilterObject>? FarmcropFilter = null;
  List<PREVIOUSFarmcropFilterObject>? PREVIOUSFarmcropFilter = null;
  String whichGrid = 'بيانات يوميه';
  late FarmcropFilterObject selectedfarmCropFilter;
  late DailyDataSource dailyDataSource;
  late PracticalDataSource practicalDataSource;
  late IdealDataSource idealDataSource;
  String PREVIOUSwhichGrid = 'بيانات يوميه';
  late  PREVIOUSFarmcropFilterObject PREVIOUSselectedfarmCropFilter;
  late PREVIOUSDailyDataSource PREVIOUSdailyDataSource;
  late PREVIOUSPracticalDataSource PREVIOUSpracticalDataSource;
  late PREVIOUSIdealDataSource PREVIOUSidealDataSource;
  late TabController tb;
  final cookieManager = WebviewCookieManager();
  int NotificationCounter = 0;
  int farmid;

  _farmcropState(this.farmid);
  @override
  void initState()
  {

    tb = TabController(initialIndex: 0, length: 3, vsync: this);
    super.initState();
    // dailyDataSource = DailyDataSource(); // Replace with actual initialization
    // practicalDataSource = PracticalDataSource();
    // idealDataSource = IdealDataSource();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        String? payload = response.payload;
        if (payload != null) {
          print("Notification Payload: $payload");
          // Handle notification tap event here
        }
      },
    );
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload)
  {
    // Check if context is available (for safety)
    if (context == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title ?? "Notification"),
        content: Text(body ?? "You have received a notification."),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text("OK"),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // Uncomment if you want to navigate to another screen
              /*
            if (payload != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecondScreen(payload),
                ),
              );
            }
            */
            },
          )
        ],
      ),
    );
  }



  Future scheduleNotificationMan(DateTime notifdate, int id, String crop) async {
    var androidDetails = AndroidNotificationDetails(
      'irwi' + id.toString(),
      'irwi',
      channelDescription: 'irwi', // 'description' renamed to 'channelDescription'
    );

    var iosDetails = DarwinNotificationDetails();

    var generalConqure =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Detroit'));

    var diff = notifdate.difference(DateTime.now());
    print('notif date = ' + notifdate.toString());
    print('diff = ' + diff.toString());

    var notTime = tz.TZDateTime.now(tz.local).add(diff);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'ميعاد ري محصولك اليوم',
      'اليوم ميعاد ري محصول ' + crop,
      notTime,
      generalConqure,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );

    print('Notification Scheduled id: ' + id.toString() + ' , Time: ' + notTime.toString());
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
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
                  //Navigator.pop(context);
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
            //Navigator.pop(context);
            Navigator.of(context).pushReplacement(goToFarms());
          },
          child: Icon(Icons.home),
          backgroundColor: Color(0xff2af598),
        ),
        body: FutureBuilder<List<String>>(
          future: fetchAll(http.Client(), farmid, http.Client(), http.Client(), http.Client()),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error.toString());
            }

            if (isLoading && snapshot.hasData && snapshot.data != null && snapshot.data!.length >= 12) {
              isLoading = false;

              allfarmcrops = parseFarmcrops(snapshot.data![0]);
              cropTypes = parseCrops(snapshot.data![1]);
              measuringUnits = parseMeasring(snapshot.data![2]);
              irrigationMethods = parseIrrigationMethod(snapshot.data![3]);
              DailyRecords = parseDailyRecords(snapshot.data![4]);
              PracticalGrid = parsePracticalGrid(snapshot.data![5]);
              IdealGrid = parseIdealGrid(snapshot.data![6]);
              PREVIOUSDailyRecords = parsePREVIOUSDailyRecords(snapshot.data![7]);
              PREVIOUSPracticalGrid = parsePREVIOUSPracticalGrid(snapshot.data![8]);
              PREVIOUSIdealGrid = parsePREVIOUSIdealGrid(snapshot.data![9]);
              FarmcropFilter = parseFarmcropFilter(snapshot.data![10]);
              PREVIOUSFarmcropFilter = parsePREVIOUSFarmcropFilter(snapshot.data![11]);

              selectedfarmCropFilter = FarmcropFilter != null && FarmcropFilter!.isNotEmpty
                  ? FarmcropFilter![0]
                  : FarmcropFilterObject();

              dailyDataSource = DailyDataSource(DailyRecords!, selectedfarmCropFilter?.farmcropId ?? '0');
              practicalDataSource = PracticalDataSource(PracticalGrid!, selectedfarmCropFilter?.farmcropId ?? '0');
              idealDataSource = IdealDataSource(IdealGrid!, selectedfarmCropFilter?.farmcropId ?? '0');

              PREVIOUSselectedfarmCropFilter =
              PREVIOUSFarmcropFilter != null && PREVIOUSFarmcropFilter!.isNotEmpty
                  ? PREVIOUSFarmcropFilter![0]
                  : PREVIOUSFarmcropFilterObject();

              PREVIOUSdailyDataSource =
                  PREVIOUSDailyDataSource(PREVIOUSDailyRecords!, PREVIOUSselectedfarmCropFilter?.farmcropId ?? '0');
              PREVIOUSpracticalDataSource =
                  PREVIOUSPracticalDataSource(PREVIOUSPracticalGrid!, PREVIOUSselectedfarmCropFilter?.farmcropId ?? '0');
              PREVIOUSidealDataSource =
                  PREVIOUSIdealDataSource(PREVIOUSIdealGrid!, PREVIOUSselectedfarmCropFilter?.farmcropId ?? '0');

              NotificationCounter = 0;
              for (farmcropObject myfarmcrop in allfarmcrops ?? []) {
                if (myfarmcrop.nextirrigationdate != null &&
                    myfarmcrop.nextirrigationdate!.isAfter(DateTime.now())) {
                  scheduleNotificationMan(
                      myfarmcrop.nextirrigationdate!, ++NotificationCounter, myfarmcrop.cropname ?? '');
                }
              }
            }

            return !snapshot.hasData
                ? Center(child: CircularProgressIndicator())
                : NestedScrollView(
              controller: ScrollController(),
              physics: ClampingScrollPhysics(),
              headerSliverBuilder: (context, value) {
                return [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background:
                      /// _buildCarousel() in your case....
                      Container(
                          height: 200,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 25,vertical: 15),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.local_florist,color: Colors.blue[900],size: 35,),
                                    Text(
                                      'المزرعة',
                                      style: TextStyle(color: Colors.blue[900],fontSize: 30,fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 25,vertical: 15),
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white, // Background color
                                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  ),
                                  onPressed: () {
                                    showAddFarmCropDialog(context, cropTypes, irrigationMethods, measuringUnits, farmid);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.add_circle, color: Color(0xff039be5), size: 35),
                                      SizedBox(width: 8), // Add space between icon and text
                                      Text(
                                        'أضف محصول',
                                        style: TextStyle(color: Color(0xff039be5), fontSize: 20, fontWeight: FontWeight.w100),
                                      ),
                                    ],
                                  ),
                                )

                              ),
                            ],
                          )
                      ),
                    ),
                    expandedHeight: 250.0, /// your Carousel + Tabbar height(50)
                    floating: true,
                    bottom: TabBar(
                      controller: tb,
                      tabs: [
                      Tab(text: "المراقبة"),
                      Tab(text: "الموسم الحالي"),
                      Tab(text: "المواسم السابقة"),
                    ],labelColor: Color(0xff1a237e),indicatorColor: Colors.blue,unselectedLabelColor: Colors.grey,),
                  ),
                ];
              },
              body: TabBarView(
                //physics: NeverScrollableScrollPhysics(),
                controller: tb,
                children: <Widget>[
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          WeatherBoxWebview(farmid),
                          Column(
                            children: [
                              for ( farmcropObject myfarmcrop in allfarmcrops! )
                                Container(
                                  decoration: new BoxDecoration(
                                    //borderRadius: new BorderRadius.circular(16.0),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 5,
                                        blurRadius: 7,
                                        offset: Offset(0, 3), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  //padding: EdgeInsets.all(50),
                                  margin: EdgeInsets.symmetric(horizontal: 25,vertical: 15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Stack(
                                        children: <Widget>[
                                          Column(
                                            children: [
                                              GestureDetector(
                                                onTap: (){
                                                  print("Image clicked");
                                                  //Navigator.of(context).pushReplacement(goToFarmCrops(myfarmcrop.farmcropId));
                                                },
                                                child: Image(
                                                  image: AssetImage('assets/images/crops/'+myfarmcrop.cropimg!.trim()),
                                                ),
                                              ),
                                              Container(height: 25, color: Colors.transparent),
                                            ],
                                          ),
                                          Positioned(
                                            left: 5,
                                            bottom: 0,
                                            child: FloatingActionButton(
                                              heroTag: 'frm'+myfarmcrop.farmcropId.toString(),
                                              child: Icon(Icons.edit),
                                              onPressed: () {
                                                print('FAB tapped!');
                                                showEditFarmCropDialog(context,cropTypes, irrigationMethods, measuringUnits, farmid,myfarmcrop);
                                                //Navigator.of(context).pushReplacement(goToEditFarms(myfarm.farmId));
                                              },
                                              backgroundColor: Color(0xff2af598),
                                            ),
                                          ),
                                          Positioned(
                                            right: 10,
                                            bottom: 25,
                                            child: Text(myfarmcrop.cropname!,style: TextStyle(fontSize: 30,color: Colors.white,fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow( // bottomLeft
                                                      offset: Offset(-1.5, -1.5),
                                                      color: Colors.black
                                                  ),
                                                  Shadow( // bottomRight
                                                      offset: Offset(1.5, -1.5),
                                                      color: Colors.black
                                                  ),
                                                  Shadow( // topRight
                                                      offset: Offset(1.5, 1.5),
                                                      color: Colors.black
                                                  ),
                                                  Shadow( // topLeft
                                                      offset: Offset(-1.5, 1.5),
                                                      color: Colors.black
                                                  ),
                                                ]),),
                                          ),
                                        ], clipBehavior: Clip.none,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xff2196f3), // ✅ Equivalent to `color` in RaisedButton
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            ),
                                            onPressed: () { showWaterNeedsDialog(context, myfarmcrop, farmid); },
                                            child: Row(
                                              children: [
                                                Icon(Icons.spa, color: Colors.white, size: 35),
                                                Text("الاحتياجات المائية المتوقعة للري", style: TextStyle(color: Colors.white)),
                                              ],
                                              mainAxisSize: MainAxisSize.min,
                                            ),
                                          )

                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: (){
                                          print("Container clicked");
                                        },
                                        child: Container(
                                          margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Text('البيانات المتوقعة',style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                                              Row(
                                                children: [
                                                  Icon(Icons.timelapse,color: Colors.black,size: 22,),
                                                  SizedBox(width: 10),
                                                  Text('الرية القادمة:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                  SizedBox(width: 5),
                                                  Text(formatter.format(myfarmcrop.nextirrigationdate!),style: TextStyle(fontSize: 18,),),
                                                ],mainAxisSize: MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.hourglass_empty,color: Colors.black,size: 22,),
                                                  SizedBox(width: 10),
                                                  Text('تاريخ ايقاف الري:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                  SizedBox(width: 5),
                                                  Text(formatter.format(myfarmcrop.stopirrigationdate!),style: TextStyle(fontSize: 18,),),
                                                ],mainAxisSize: MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.local_florist,color: Colors.black,size: 22,),
                                                  SizedBox(width: 10),
                                                  Text('مرحلة النمو:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                  SizedBox(width: 5),
                                                  Text(myfarmcrop.stage!,style: TextStyle(fontSize: 18,),),
                                                ],mainAxisSize: MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.hourglass_empty,color: Colors.black,size: 22,),
                                                  SizedBox(width: 10),
                                                  Text('تاريخ الحصاد:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                  SizedBox(width: 5),
                                                  Text(formatter.format(myfarmcrop.harvestdate!),style: TextStyle(fontSize: 18,),),
                                                ],mainAxisSize: MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.local_florist,color: Colors.black,size: 22,),
                                                  SizedBox(width: 10),
                                                  Text('حجم الانتاج المتوقع:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                                                  SizedBox(width: 5),
                                                  Text(myfarmcrop.LASTNPP == 'null' ? '0':myfarmcrop.LASTNPP! + ' ' + myfarmcrop.measuringunitname! + '/ك',style: TextStyle(fontSize: 18,),),
                                                ],mainAxisSize: MainAxisSize.min,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 30),
                                          Expanded(
                                            child:
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              ),
                                              onPressed: () { showMoreInfoDialog(context, myfarmcrop); },
                                              child: Text(
                                                "المزيد",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                              ),
                                            )

                                          ),
                                          SizedBox(width: 30),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                            ],
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
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: DropdownButtonFormField<FarmcropFilterObject>(
                            isExpanded: true,
                            value: selectedfarmCropFilter,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: TextStyle(color: Colors.black,fontSize: 18),
                            onChanged: (FarmcropFilterObject? newValue) {
                              setState(() {
                                selectedfarmCropFilter = newValue!;
                                dailyDataSource = DailyDataSource(DailyRecords!,selectedfarmCropFilter.farmcropId!);
                                practicalDataSource = PracticalDataSource(PracticalGrid!,selectedfarmCropFilter.farmcropId!);
                                idealDataSource = IdealDataSource(IdealGrid!,selectedfarmCropFilter.farmcropId!);
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                            items: (FarmcropFilter ?? [])
                                .map<DropdownMenuItem<FarmcropFilterObject>>((FarmcropFilterObject value) {
                              return DropdownMenuItem<FarmcropFilterObject>(
                                value: value,
                                child: Text(value.Text!),
                              );
                            }).toList(),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: whichGrid,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: TextStyle(color: Colors.black,fontSize: 18),
                            onChanged: (String? newValue) {
                              setState(() {
                                whichGrid = newValue!;
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                            items: <String>[ 'بيانات يوميه', 'جدولة الري الفعليه', 'جدولة الري القياسيه']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        if(whichGrid == 'بيانات يوميه')PaginatedDataTable(
                          header: Text('البيانات اليومية'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                            DataColumn(label: Text('معدل البخر والنتح (مم/يوم)')),
                            DataColumn(label: Text('معدل البخر والنتح للمحصول مم/يوم')),
                            DataColumn(label: Text('معدل تساقط الامطار الفعلي مم')),
                            DataColumn(label: Text('معامل المحصول')),
                            DataColumn(label: Text('العمر باليوم')),
                            DataColumn(label: Text('الاحتياج اليومي م مكعب')),
                          ],
                          source: dailyDataSource,

                        ),
                        if(whichGrid == 'جدولة الري الفعليه')PaginatedDataTable(
                          header: Text('جدولة الري الفعليه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                            DataColumn(label: Text('كمية المياه المستهلكة م مكعب')),
                            DataColumn(label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                            DataColumn(label: Text('استهلاك الوقود - لتر')),
                            DataColumn(label: Text('سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: practicalDataSource,

                        ),
                        if(whichGrid == 'جدولة الري القياسيه')PaginatedDataTable(
                          header: Text('جدولة الري القياسيه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                            DataColumn(label: Text('كمية المياه المستهلكة م مكعب')),
                            DataColumn(label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                            DataColumn(label: Text('استهلاك الوقود - لتر')),
                            DataColumn(label: Text('سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: idealDataSource,

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
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: DropdownButtonFormField<PREVIOUSFarmcropFilterObject>(
                            isExpanded: true,
                            value: PREVIOUSselectedfarmCropFilter,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: TextStyle(color: Colors.black,fontSize: 18),
                            onChanged: (PREVIOUSFarmcropFilterObject? newValue) {
                              setState(() {
                                PREVIOUSselectedfarmCropFilter = newValue!;
                                PREVIOUSdailyDataSource = PREVIOUSDailyDataSource(PREVIOUSDailyRecords!,PREVIOUSselectedfarmCropFilter.farmcropId!);
                                PREVIOUSpracticalDataSource = PREVIOUSPracticalDataSource(PREVIOUSPracticalGrid!,PREVIOUSselectedfarmCropFilter.farmcropId!);
                                PREVIOUSidealDataSource = PREVIOUSIdealDataSource(PREVIOUSIdealGrid!,PREVIOUSselectedfarmCropFilter.farmcropId!);
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                            items: (PREVIOUSFarmcropFilter ?? []).map<DropdownMenuItem<PREVIOUSFarmcropFilterObject>>(
                                  (PREVIOUSFarmcropFilterObject value) {
                                return DropdownMenuItem<PREVIOUSFarmcropFilterObject>(
                                  value: value,
                                  child: Text(value.Text ?? "N/A"), // Handle null safely
                                );
                              },
                            ).toList(),

                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: PREVIOUSwhichGrid,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: TextStyle(color: Colors.black,fontSize: 18),
                            onChanged: (String? newValue) {
                              setState(() {
                                PREVIOUSwhichGrid = newValue!;
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                            items: <String>[ 'بيانات يوميه', 'جدولة الري الفعليه', 'جدولة الري القياسيه']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        if(PREVIOUSwhichGrid == 'بيانات يوميه')PaginatedDataTable(
                          header: Text('البيانات اليومية'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                            DataColumn(label: Text('معدل البخر والنتح (مم/يوم)')),
                            DataColumn(label: Text('معدل البخر والنتح للمحصول مم/يوم')),
                            DataColumn(label: Text('معدل تساقط الامطار الفعلي مم')),
                            DataColumn(label: Text('معامل المحصول')),
                            DataColumn(label: Text('العمر باليوم')),
                            DataColumn(label: Text('الاحتياج اليومي م مكعب')),
                          ],
                          source: PREVIOUSdailyDataSource,

                        ),
                        if(PREVIOUSwhichGrid == 'جدولة الري الفعليه')PaginatedDataTable(
                          header: Text('جدولة الري الفعليه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                            DataColumn(label: Text('كمية المياه المستهلكة م مكعب')),
                            DataColumn(label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                            DataColumn(label: Text('استهلاك الوقود - لتر')),
                            DataColumn(label: Text('سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: PREVIOUSpracticalDataSource,

                        ),
                        if(PREVIOUSwhichGrid == 'جدولة الري القياسيه')PaginatedDataTable(
                          header: Text('جدولة الري القياسيه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                            DataColumn(label: Text('كمية المياه المستهلكة م مكعب')),
                            DataColumn(label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                            DataColumn(label: Text('استهلاك الوقود - لتر')),
                            DataColumn(label: Text('سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: PREVIOUSidealDataSource,

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
                  ),
                ],
              ),
            );
          },
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class DailyDataSource extends DataTableSource{

  final DateFormat formatter = DateFormat('yyyy/MM/dd');

 late List<DailyRecordsObject> data;
 late int count;  // Ensure it's initialized

 DailyDataSource(List<DailyRecordsObject> alldata, String cropid) {
   data = []; // Initialize empty list
   for (int i = 0; i < alldata.length; i++) {
     if (alldata[i].farmcropId == cropid) {
       data.add(alldata[i]);
     }
   }
   count = data.length; // Initialize count
 }

  String updateData() {
    // Declare a variable to return
    String data = 'Updated Data'; // Or some meaningful string

    // Uncomment and modify as needed
    // data += '1';
    count--;

    return data; // Ensure a string is always returned
  }


  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index,cells: [
      DataCell(Text(formatter.format(data[index].date!))),
      DataCell(Text(data[index].stage!)),
      DataCell(Text(data[index].eto!)),
      DataCell(Text(data[index].etc!)),
      DataCell(Text(data[index].pe!)),
      DataCell(Text(data[index].kc!)),
      DataCell(Text(data[index].agebyday!)),
      DataCell(Text(data[index].irrday!)),
    ]);
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => count;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;

}

class PracticalDataSource extends DataTableSource{

  final DateFormat formatter = DateFormat('yyyy/MM/dd');


  List<PracticalGridObject> data = [];
  int count;

  PracticalDataSource(List<PracticalGridObject> alldata, String cropid)
      : count = 0 { // Initialize count before constructor body
    for (var item in alldata) {
      if (item.farmcropId == cropid) {
        data.add(item);
      }
    }
    count = data.length;
  }

  String updateData() {
    count--;

    if (count < 0) {
      return "Count is negative";
    } else {
      return "Count updated";
    }
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index,cells: [
      DataCell(Text(formatter.format(data[index].date!))),
      DataCell(Text(data[index].stage!)),
      DataCell(Text(data[index].irrtotal!)),
      DataCell(Text(data[index].dischargehours!)),
      DataCell(Text(data[index].agebyday!)),
      DataCell(Text(data[index].gas!)),
      DataCell(Text(data[index].gasprice!)),
    ]);
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => count;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;

}

class IdealDataSource extends DataTableSource{
  List<IdealGridObject> data = []; // Initialize with an empty list
  int count = 0;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  IdealDataSource(List<IdealGridObject> alldata, String cropid) {
    data = []; // No need for `new List<IdealGridObject>()`

    for (var item in alldata) {
      if (item.farmcropId == cropid) {
        data.add(item);
      }
    }

    count = data.length;
  }

  void updateData() {
    count--;
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index,cells: [
      DataCell(Text(formatter.format(data[index].date!))),
      DataCell(Text(data[index].stage!)),
      DataCell(Text(data[index].irrtotal!)),
      DataCell(Text(data[index].dischargehours!)),
      DataCell(Text(data[index].agebyday!)),
      DataCell(Text(data[index].gas!)),
      DataCell(Text(data[index].gasprice!)),
    ]);
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => count;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;

}

class PREVIOUSDailyDataSource extends DataTableSource{
  List<PREVIOUSDailyRecordsObject> data = []; // Correct list initialization
  int count = 0; // Initialize count
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  PREVIOUSDailyDataSource(List<PREVIOUSDailyRecordsObject> alldata, String cropid) {
    data = []; // Ensure list is empty before adding elements

    for (var item in alldata) {
      if (item.farmcropId == cropid) {
        data.add(item);
      }
    }

    count = data.length; // Set count after processing
  }

  void updateData(){
    //data += '1';
    count--;
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index,cells: [
      DataCell(Text(formatter.format(data[index].date!))),
      DataCell(Text(data[index].stage!)),
      DataCell(Text(data[index].eto!)),
      DataCell(Text(data[index].etc!)),
      DataCell(Text(data[index].pe!)),
      DataCell(Text(data[index].kc!)),
      DataCell(Text(data[index].agebyday!)),
      DataCell(Text(data[index].irrday!)),
    ]);
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => count;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;

}

class PREVIOUSPracticalDataSource extends DataTableSource{
  late List<PREVIOUSPracticalGridObject> data;
  late int count;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  PREVIOUSPracticalDataSource(List<PREVIOUSPracticalGridObject> alldata, String cropid) {
    data = alldata.where((item) => item.farmcropId == cropid).toList();
    count = data.length;
  }

  void updateData(){
    //data += '1';
    count--;
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index,cells: [
      DataCell(Text(formatter.format(data[index].date!))),
      DataCell(Text(data[index].stage!)),
      DataCell(Text(data[index].irrtotal!)),
      DataCell(Text(data[index].dischargehours!)),
      DataCell(Text(data[index].agebyday!)),
      DataCell(Text(data[index].gas!)),
      DataCell(Text(data[index].gasprice!)),
    ]);
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => count;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;

}

class PREVIOUSIdealDataSource extends DataTableSource{
  late List<PREVIOUSIdealGridObject> data;
  late int count; // Marking as `late` ensures it's initialized before use.
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  PREVIOUSIdealDataSource(List<PREVIOUSIdealGridObject> alldata, String cropid) {
    data = alldata.where((item) => item.farmcropId == cropid).toList();
    count = data.length;
  }

  void updateData(){
    //data += '1';
    count--;
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index,cells: [
      DataCell(Text(formatter.format(data[index].date!))),
      DataCell(Text(data[index].stage!)),
      DataCell(Text(data[index].irrtotal!)),
      DataCell(Text(data[index].dischargehours!)),
      DataCell(Text(data[index].agebyday!)),
      DataCell(Text(data[index].gas!)),
      DataCell(Text(data[index].gasprice!)),
    ]);
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => count;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;

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

showMoreInfoDialog(BuildContext context, farmcropObject myfarmcrop) {
  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text("اغلاق"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("بيانات المحصول", textAlign: TextAlign.center,),
    content: Container(
      height: 350,
      child: Scrollbar(
        child: ListView(
          children: [
            Row(
              children: [
                //Icon(Icons.hourglass_empty,color: Colors.black,size: 22,),
                FaIcon(FontAwesomeIcons.leaf,color: Colors.black,),
                SizedBox(width: 10),
                Text('المحصول:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(myfarmcrop.cropname!,style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.calendar,color: Colors.black,),
                SizedBox(width: 10),
                Text('تاريخ الزراعة:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(formatter.format(myfarmcrop.plantingdate!),style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.calendar,color: Colors.black,),
                SizedBox(width: 10),
                Text('تاريخ الحصاد:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(formatter.format(myfarmcrop.harvestdate!),style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.tree,color: Colors.black,),
                SizedBox(width: 10),
                Text('المرحلة:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(myfarmcrop.stage!,style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.calendar,color: Colors.black,),
                SizedBox(width: 10),
                Text('الرية القادمة:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(formatter.format(myfarmcrop.nextirrigationdate!),style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.clock,color: Colors.black,),
                SizedBox(width: 10),
                Text('عدد ساعات رية الزراعة:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(myfarmcrop.initirrigationhours.toString(),style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.water,color: Colors.black,),
                SizedBox(width: 10),
                Text('المياه المطلوبة اليوم:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    (double.tryParse(myfarmcrop.irrday!) ?? 0.0).toStringAsFixed(2),
                    style: TextStyle(fontSize: 18),
                  ),
                )
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.chartArea,color: Colors.black,),
                SizedBox(width: 10),
                Text('المساحة:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(myfarmcrop.area.toString() + myfarmcrop.measuringunitname!,style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.handHoldingWater,color: Colors.black,),
                SizedBox(width: 10),
                Text('نوع الري:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(myfarmcrop.irrigationmethodname!,style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            if(myfarmcrop.cropname!.contains('رز')) Row(
              children: [
                FaIcon(FontAwesomeIcons.clock,color: Colors.black,),
                SizedBox(width: 10),
                Text('عدد ساعات طفي الشراقي:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(myfarmcrop.irrigtaionshraky.toString(),style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
            if(myfarmcrop.cropname!.contains('رز')) Row(
              children: [
                FaIcon(FontAwesomeIcons.clock,color: Colors.black,),
                SizedBox(width: 10),
                Text('عدد ساعات ري المشتل:',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                SizedBox(width: 5),
                Text(myfarmcrop.irrigationmashtal.toString(),style: TextStyle(fontSize: 18,),),
              ],mainAxisSize: MainAxisSize.min,
            ),
          ],
        ),
      ),
    ),
    actions: [
      cancelButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

showWaterNeedsDialog(BuildContext context, farmcropObject myfarmcrop,int farmid) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return MyConfirmDateDialog(context, myfarmcrop.farmcropId!,farmid,myfarmcrop.lastirrigationdate!);
      }
  );
}

showAddFarmCropDialog(context,cropTypes,irrigationMethods,measuringUnits,farmid) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddFarmCropDialog(cropTypes,irrigationMethods,measuringUnits,farmid);
      },barrierDismissible: false
  );
}
showEditFarmCropDialog(BASEcontext,cropTypes,irrigationMethods,measuringUnits,farmid,myfarmcrop) {
  showDialog(
      context: BASEcontext,
      builder: (BuildContext context) {
        return EditFarmCropDialog(irrigationMethods,measuringUnits,farmid,myfarmcrop,BASEcontext);
      },barrierDismissible: false
  );
}

/////////////// FETCH ALL DATA ////////////////////////
Future<List<String>> fetchAll(http.Client client,farmid,http.Client client2,http.Client client3,http.Client client4,) async {
  await flutterLocalNotificationsPlugin.cancelAll();
  List<String> responses = await Future.wait([
    fetchFarmcrops(client, farmid),
    fetchCrops(client2),
    fetchMeasring(client3),
    fetchIrrigationMethod(client4),
    fetchDailyRecords(farmid),
    fetchPracticalGrid(farmid),
    fetchIdealGrid(farmid),
    fetchPREVIOUSDailyRecords(farmid),
    fetchPREVIOUSPracticalGrid(farmid),
    fetchPREVIOUSIdealGrid(farmid),
    fetchFarmcropFilter(farmid),
    fetchPREVIOUSFarmcropFilter(farmid),
  ]);
  /*String farmcrops = await fetchFarmcrops(client, farmid);
  String cropstypes = await fetchCrops(client2);
  String measuring = await fetchMeasring(client3);
  String irrigationMethods = await fetchIrrigationMethod(client4);
  String DailyRecords = await fetchDailyRecords(farmid);
  String PracticalGrid = await fetchPracticalGrid(farmid);
  String IdealGrid = await fetchIdealGrid(farmid);
  String PREVIOUSDailyRecords = await fetchPREVIOUSDailyRecords(farmid);
  String PREVIOUSPracticalGrid = await fetchPREVIOUSPracticalGrid(farmid);
  String PREVIOUSIdealGrid = await fetchPREVIOUSIdealGrid(farmid);*/
  // Use the compute function to run parseFarms in a separate isolate.
  //return [farmcrops,cropstypes,measuring,irrigationMethods,DailyRecords,PracticalGrid,IdealGrid,PREVIOUSDailyRecords,PREVIOUSPracticalGrid,PREVIOUSIdealGrid].toList();
  return responses;
}

/////////////// FARMCROPS FETCH DATA ////////////////////////
Future<String> fetchFarmcrops(http.Client client,farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  var mydata = jsonEncode({
    'farmid': farmid,
  });
  final response = await client.post(
    Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetFarmCrops'), // Convert String to Uri
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
    body: mydata,
  );


  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseFarmcrops, response.body);
  return response.body;
}

// A function that converts a response body into a List<Photo>.
List<farmcropObject> parseFarmcrops(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<farmcropObject>((json) => farmcropObject.fromJson(json)).toList();
}


class farmcropObject {
  int? archived;
  int? farmcropId;
  DateTime? lastirrigationdate;
  int? irrigationmethodId;
  double? area;
  int? measuringunitId;
  int? initirrigationhours;
  String? cropname;
  String? cropimg;
  String? croptotaldays;
  int? irrigationmashtal;
  int? irrigtaionshraky;
  DateTime? nextirrigationdate;
  DateTime? stopirrigationdate;
  String? stage;
  DateTime? harvestdate;
  //LASTNPP = p.AllNPP.Last().npp;
  String? LASTNPP;
  String? measuringunitname;
  String? irrigationmethodname;
  //agebyday = p.dailyrecords.Last().agebyday;
  String? agebyday;
  //irrday = p.dailyrecords.Last().irrday;
  String? irrday;
  DateTime? plantingdate;
  farmcropObject({this.archived, this.farmcropId, this.lastirrigationdate, this.irrigationmethodId,
    this.area, this.measuringunitId, this.initirrigationhours, this.cropname, this.cropimg, this.croptotaldays,
    this.irrigationmashtal, this.irrigtaionshraky, this.nextirrigationdate, this.stopirrigationdate, this.stage,
    this.harvestdate, this.LASTNPP, this.measuringunitname, this.irrigationmethodname, this.agebyday, this.irrday, this.plantingdate});

  factory farmcropObject.fromJson(Map<String, dynamic> json) {
    return farmcropObject(
      archived: json['archived'] as int,
      farmcropId: json['farmcropId'] as int,
      lastirrigationdate: json['lastirrigationdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['lastirrigationdate'].substring(6, 19)) ?? 0)
          : null,
      irrigationmethodId: json['irrigationmethodId'] as int,
      area: double.tryParse(json['area'].toString()),
      measuringunitId: json['measuringunitId'] as int,
      initirrigationhours: json['initirrigationhours'] as int,
      cropname: json['crop']['name'].toString().trim(),
      cropimg: json['crop']['img'].toString().trim(),
      croptotaldays: json['crop']['totaldays'].toString().trim(),
      irrigationmashtal: json['irrigationmashtal'] as int,
      irrigtaionshraky: json['irrigtaionshraky'] as int,
      nextirrigationdate: json['nextirrigationdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['nextirrigationdate'].substring(6, 19)) ?? 0)
          : null,

      stopirrigationdate: json['stopirrigationdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['stopirrigationdate'].substring(6, 19)) ?? 0)
          : null,
      stage: json['stage'].toString(),
      harvestdate: json['harvestdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['harvestdate'].substring(6, 19)) ?? 0)
          : null,
      LASTNPP: json['LASTNPP'].toString(),
      measuringunitname: json['measuringunit']['name'].toString(),
      irrigationmethodname: json['irrigationmethod']['name'].toString(),
      agebyday: json['agebyday'].toString(),
      irrday: json['irrday'].toString(),
      plantingdate: json['plantingdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['plantingdate'].substring(6, 19)) ?? 0)
          : null,    );
  }
}

/////////////// CROPS FETCH DATA ////////////////////////
Future<String> fetchCrops(http.Client client) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await client.get(
    Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetCrops'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseCrops, response.body);
  return response.body;
}

// A function that converts a response body into a List<Photo>.
List<cropObject> parseCrops(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<cropObject>((json) => cropObject.fromJson(json)).toList();
}


class cropObject {
  String? cropId;
  String? name;
  String? img;
  cropObject({this.cropId, this.name, this.img});

  factory cropObject.fromJson(Map<String, dynamic> json) {
    return cropObject(
      cropId: json['Value'].toString(),
      name: json['Text'].toString().trim(),
      img: json['image'].toString().trim(),
    );
  }
}

/////////////// MEASURING FETCH DATA ////////////////////////
Future<String> fetchMeasring(http.Client client) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await client.get(
    Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetMeasuringUnits'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseCrops, response.body);
  return response.body;
}

// A function that converts a response body into a List<Photo>.
List<MeasringObject> parseMeasring(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<MeasringObject>((json) => MeasringObject.fromJson(json)).toList();
}

class MeasringObject {
  String? measuringunitId;
  String? name;
  MeasringObject({this.measuringunitId, this.name});

  factory MeasringObject.fromJson(Map<String, dynamic> json) {
    return MeasringObject(
      measuringunitId: json['Value'].toString(),
      name: json['Text'].toString(),
    );
  }
}

/////////////// IRRIGATION FETCH DATA ////////////////////////
Future<String> fetchIrrigationMethod(http.Client client) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await client.get(
    Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetIrrigationMethods'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}

/////////////// PracticalGrid FETCH DATA ////////////////////////
Future<String> fetchPracticalGrid(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await http.Client().get(
    Uri.parse('https://irwicrop.com/Home/getPracticalGrid?recordfarmid=${farmid.toString()}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}
/////////////// PREVIOUSPracticalGrid FETCH DATA ////////////////////////
Future<String> fetchPREVIOUSPracticalGrid(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await http.Client().get(
    Uri.parse('https://irwicrop.com/Home/PREVIOUSgetPracticalGrid?recordfarmid=${farmid ?? ''}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}
/////////////// IdealGrid FETCH DATA ////////////////////////
Future<String> fetchIdealGrid(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await http.get(
    Uri.parse('https://irwicrop.com/Home/getIdealGrid?recordfarmid=${farmid ?? ''}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
  );

  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}
/////////////// PREVIOUSIdealGrid FETCH DATA ////////////////////////
Future<String> fetchPREVIOUSIdealGrid(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await http.get(
    Uri.parse('https://irwicrop.com/Home/PREVIOUSgetIdealGrid?recordfarmid=${farmid.toString()}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
  );

  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}
/////////////// DailyRecordslGrid FETCH DATA ////////////////////////
Future<String> fetchDailyRecords(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await http.get(
    Uri.parse('https://irwicrop.com/Home/PREVIOUSgetIdealGrid?recordfarmid=${farmid.toString()}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}
/////////////// PREVIOUSDailyRecordsGrid FETCH DATA ////////////////////////
Future<String> fetchPREVIOUSDailyRecords(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response = await http.get(
    Uri.parse('https://irwicrop.com/Home/PREVIOUSgetDailyRecords?recordfarmid=${farmid.toString()}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
  );

  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}
/////////////// FarmcropFilter FETCH DATA ////////////////////////
Future<String> fetchFarmcropFilter(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response =
  await http.Client().get(Uri.parse('https://irwicrop.com/Home/getFarmcropFilter?recordfarmid='+farmid.toString(),),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie':cookie
    },
  );

  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}
/////////////// FarmcropFilter FETCH DATA ////////////////////////
Future<String> fetchPREVIOUSFarmcropFilter(farmid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final response =
  await http.Client().get(Uri.parse('https://irwicrop.com/Home/PREVIOUSgetFarmcropFilter?recordfarmid='+farmid.toString(),),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie':cookie
    },
  );

  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}

// A function that converts a response body into a List<Photo>.
List<irrigationMethodObject> parseIrrigationMethod(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<irrigationMethodObject>((json) => irrigationMethodObject.fromJson(json)).toList();
}


class irrigationMethodObject {
  String? irrigationmethodId;
  String? name;
  String? img;
  irrigationMethodObject({this.irrigationmethodId, this.name, this.img});

  factory irrigationMethodObject.fromJson(Map<String, dynamic> json) {
    return irrigationMethodObject(
      irrigationmethodId: json['Value'].toString(),
      name: json['Text'].toString().trim(),
      img: json['image'].toString().trim(),
    );
  }
}
 //////////////////////////////// PARSE DailyRecords ///////////////////////////////////
List<DailyRecordsObject> parseDailyRecords(String responseBody) {
  var temp  = jsonDecode(responseBody);
  var temp2  = temp['Data'];
  var temp3  = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed.map<DailyRecordsObject>((json) => DailyRecordsObject.fromJson(json)).toList();
}

class DailyRecordsObject {
  String? dailyrecordId;
  String? farmcropId;
  DateTime? date;
  String? stage;
  String? eto;
  String? etc;
  String? pe;
  String? kc;
  String? irrday;
  String? agebyday;
  String? daystillharvest;
  DailyRecordsObject({this.dailyrecordId, this.farmcropId, this.date,
    this.stage, this.eto, this.etc, this.pe, this.kc, this.irrday, this.agebyday, this.daystillharvest});

  factory DailyRecordsObject.fromJson(Map<String, dynamic> json) {
    return DailyRecordsObject(
      dailyrecordId: json['dailyrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6,19)) ?? 0
      ),

      stage: json['stage'].toString().trim(),
      eto: json['eto'].toString().trim(),
      etc: json['etc'].toString().trim(),
      pe: json['pe'].toString().trim(),
      kc: json['kc'].toString().trim(),
      irrday: json['irrday'].toString().trim(),
      agebyday: json['agebyday'].toString().trim(),
      daystillharvest: json['daystillharvest'].toString().trim(),
    );
  }
}
/////////////////////////////  PracticalGrid  /////////////////////////
List<PracticalGridObject> parsePracticalGrid(String responseBody) {
  var temp  = jsonDecode(responseBody);
  var temp2  = temp['Data'];
  var temp3  = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed.map<PracticalGridObject>((json) => PracticalGridObject.fromJson(json)).toList();
}

class PracticalGridObject {
  String? practicalirrigationrecordId;
  String? farmcropId;
  DateTime? date;
  String? stage;
  String? dischargehours;
  String? irrtotal;
  String? agebyday;
  String? gas;
  String? gasprice;
  PracticalGridObject({this.practicalirrigationrecordId, this.farmcropId, this.date,
    this.stage, this.dischargehours, this.irrtotal, this.agebyday, this.gas, this.gasprice});

  factory PracticalGridObject.fromJson(Map<String, dynamic> json) {
    return PracticalGridObject(
      practicalirrigationrecordId: json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6,19)) ?? 0
      ),
      stage: json['stage'].toString().trim(),
      dischargehours: json['dischargehours'].toString().trim(),
      irrtotal: json['irrtotal'].toString().trim(),
      agebyday: json['agebyday'].toString().trim(),
      gas: json['gas'].toString().trim(),
      gasprice: json['gasprice'].toString().trim(),
    );
  }
}
/////////////////////////////  IdeallGrid  /////////////////////////
List<IdealGridObject> parseIdealGrid(String responseBody) {
  var temp  = jsonDecode(responseBody);
  var temp2  = temp['Data'];
  var temp3  = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed.map<IdealGridObject>((json) => IdealGridObject.fromJson(json)).toList();
}

class IdealGridObject {
  String? practicalirrigationrecordId;
  String? farmcropId;
  DateTime? date;
  String? stage;
  String? dischargehours;
  String? irrtotal;
  String? agebyday;
  String? gas;
  String? gasprice;
  IdealGridObject({this.practicalirrigationrecordId, this.farmcropId, this.date,
    this.stage, this.dischargehours, this.irrtotal, this.agebyday, this.gas, this.gasprice});

  factory IdealGridObject.fromJson(Map<String, dynamic> json) {
    return IdealGridObject(
      practicalirrigationrecordId: json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6,19)) ?? 0
      ),
      stage: json['stage'].toString().trim(),
      dischargehours: json['dischargehours'].toString().trim(),
      irrtotal: json['irrtotal'].toString().trim(),
      agebyday: json['agebyday'].toString().trim(),
      gas: json['gas'].toString().trim(),
      gasprice: json['gasprice'].toString().trim(),
    );
  }
}

 //////////////////////////////// PARSE PREVIOUSDailyRecords ///////////////////////////////////
List<PREVIOUSDailyRecordsObject> parsePREVIOUSDailyRecords(String responseBody) {
  var temp  = jsonDecode(responseBody);
  var temp2  = temp['Data'];
  var temp3  = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed.map<PREVIOUSDailyRecordsObject>((json) => PREVIOUSDailyRecordsObject.fromJson(json)).toList();
}

class PREVIOUSDailyRecordsObject {
  String? dailyrecordId;
  String? farmcropId;
  DateTime? date;
  String? stage;
  String? eto;
  String? etc;
  String? pe;
  String? kc;
  String? irrday;
  String? agebyday;
  String? daystillharvest;
  PREVIOUSDailyRecordsObject({this.dailyrecordId, this.farmcropId, this.date,
    this.stage, this.eto, this.etc, this.pe, this.kc, this.irrday, this.agebyday, this.daystillharvest});

  factory PREVIOUSDailyRecordsObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSDailyRecordsObject(
      dailyrecordId: json['dailyrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6,19)) ?? 0
      ),
      stage: json['stage'].toString().trim(),
      eto: json['eto'].toString().trim(),
      etc: json['etc'].toString().trim(),
      pe: json['pe'].toString().trim(),
      kc: json['kc'].toString().trim(),
      irrday: json['irrday'].toString().trim(),
      agebyday: json['agebyday'].toString().trim(),
      daystillharvest: json['daystillharvest'].toString().trim(),
    );
  }
}
/////////////////////////////  PREVIOUSPracticalGrid  /////////////////////////
List<PREVIOUSPracticalGridObject> parsePREVIOUSPracticalGrid(String responseBody) {
  var temp  = jsonDecode(responseBody);
  var temp2  = temp['Data'];
  var temp3  = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed.map<PREVIOUSPracticalGridObject>((json) => PREVIOUSPracticalGridObject.fromJson(json)).toList();
}

class PREVIOUSPracticalGridObject {
  String? practicalirrigationrecordId;
  String? farmcropId;
  DateTime? date;
  String? stage;
  String? dischargehours;
  String? irrtotal;
  String? agebyday;
  String? gas;
  String? gasprice;
  PREVIOUSPracticalGridObject({this.practicalirrigationrecordId, this.farmcropId, this.date,
    this.stage, this.dischargehours, this.irrtotal, this.agebyday, this.gas, this.gasprice});

  factory PREVIOUSPracticalGridObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSPracticalGridObject(
      practicalirrigationrecordId: json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6,19)) ?? 0
      ),

      stage: json['stage'].toString().trim(),
      dischargehours: json['dischargehours'].toString().trim(),
      irrtotal: json['irrtotal'].toString().trim(),
      agebyday: json['agebyday'].toString().trim(),
      gas: json['gas'].toString().trim(),
      gasprice: json['gasprice'].toString().trim(),
    );
  }
}
/////////////////////////////  IdeallGrid  /////////////////////////
List<PREVIOUSIdealGridObject> parsePREVIOUSIdealGrid(String responseBody) {
  var temp  = jsonDecode(responseBody);
  var temp2  = temp['Data'];
  var temp3  = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed.map<PREVIOUSIdealGridObject>((json) => PREVIOUSIdealGridObject.fromJson(json)).toList();
}

class PREVIOUSIdealGridObject {
  String? practicalirrigationrecordId;
  String? farmcropId;
  DateTime? date;
  String? stage;
  String? dischargehours;
  String? irrtotal;
  String? agebyday;
  String? gas;
  String? gasprice;
  PREVIOUSIdealGridObject({this.practicalirrigationrecordId, this.farmcropId, this.date,
    this.stage, this.dischargehours, this.irrtotal, this.agebyday, this.gas, this.gasprice});

  factory PREVIOUSIdealGridObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSIdealGridObject(
      practicalirrigationrecordId: json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6,19)) ?? 0
      ),

      stage: json['stage'].toString().trim(),
      dischargehours: json['dischargehours'].toString().trim(),
      irrtotal: json['irrtotal'].toString().trim(),
      agebyday: json['agebyday'].toString().trim(),
      gas: json['gas'].toString().trim(),
      gasprice: json['gasprice'].toString().trim(),
    );
  }
}

/////////////////////////////  FarmcropFilter  /////////////////////////
List<FarmcropFilterObject> parseFarmcropFilter(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<FarmcropFilterObject>((json) => FarmcropFilterObject.fromJson(json)).toList();
}

class FarmcropFilterObject {
  String? farmcropId;
  String? Text;
  FarmcropFilterObject({this.farmcropId, this.Text,});

  factory FarmcropFilterObject.fromJson(Map<String, dynamic> json) {
    return FarmcropFilterObject(
      farmcropId: json['farmcropId'].toString().trim(),
      Text: json['Text'].toString(),
    );
  }
}
/////////////////////////////  PREVIOUSFarmcropFilter  /////////////////////////
List<PREVIOUSFarmcropFilterObject> parsePREVIOUSFarmcropFilter(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<PREVIOUSFarmcropFilterObject>((json) => PREVIOUSFarmcropFilterObject.fromJson(json)).toList();
}

class PREVIOUSFarmcropFilterObject {
  String? farmcropId;
  String? Text;
  PREVIOUSFarmcropFilterObject({this.farmcropId, this.Text,});

  factory PREVIOUSFarmcropFilterObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSFarmcropFilterObject(
      farmcropId: json['farmcropId'].toString().trim(),
      Text: json['Text'].toString(),
    );
  }
}

/////////////// DIALOGS ////////////////////////
class MyConfirmDateDialog extends StatefulWidget {
  BuildContext mainContext;

  int farmcropId;

  int farmid;
  DateTime lastIrrigationDate;

  MyConfirmDateDialog(this.mainContext,  this.farmcropId, this.farmid, this.lastIrrigationDate);

  @override
  _confirmDateState createState() => new _confirmDateState(mainContext,farmcropId,farmid, lastIrrigationDate);
}

class _confirmDateState extends State<MyConfirmDateDialog> {
  var datecontoler = TextEditingController();
  DateTime? confirmDate = null;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  BuildContext mainContext;
  int farmcropId;

  int farmid;

  _confirmDateState( this.mainContext, this.farmcropId, this.farmid, this.confirmDate);
  // set up the buttons
  @override
  Widget build(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text("اغلاق"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

// set up the buttons
    Widget submitButton = TextButton(
      child: Text("تأكيد"),
      onPressed: () {
        if (confirmDate != null) {
          Navigator.of(context).pop();
          showIrrigateDialog(mainContext, farmcropId, formatter.format(confirmDate!), farmid);
        }
      },
    );

    return AlertDialog(
      title: Text("من فضلك قم بتأكيد اخر موعد للري", textAlign: TextAlign.center,),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          Container(
            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Button color
                padding: EdgeInsets.all(0),
              ),
              child: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
              onPressed: () {
                showDatePicker(
                  context: context,
                  initialDate: confirmDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(Duration(days: 200)),
                  lastDate: DateTime.now(),
                ).then((value) {
                  setState(() {
                    confirmDate = value;
                  });
                });
              },
            ),

          ),
          GestureDetector(
            onTap: (){
              showDatePicker(
                  context: context,
                  initialDate: confirmDate == null ? DateTime.now() : confirmDate,
                  firstDate: DateTime.now().add(Duration(days: -200)),
                  lastDate: DateTime.now()).then((value){
                setState(() {
                  confirmDate = value;
                });
              });
            },
            child: Text(confirmDate == null? "اختر التاريخ":formatter.format(confirmDate!), style: TextStyle(decoration: TextDecoration.underline),textAlign: TextAlign.center,),
          ),
        ],
      ),
      actions: [
        cancelButton,
        submitButton
      ],
    );
  }


  showIrrigateDialog(BuildContext context, int myfarmcropid,String updatelastirrigationdate,int farmid) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return MyIrrigateDialog(myfarmcropid, updatelastirrigationdate,farmid);
        },barrierDismissible: false
    );
  }

}

class AreYouSureDialog extends StatefulWidget {
  BuildContext? mainContext;

  int? farmcropId;

  int? farmid;
  DateTime? lastIrrigationDate;

  AreYouSureDialog(this.farmcropId,this.farmid );

  @override
  _AreYouSureDialogState createState() => new _AreYouSureDialogState(farmcropId!,this.farmid!);
}

class _AreYouSureDialogState extends State<AreYouSureDialog> {
  var datecontoler = TextEditingController();
  DateTime? confirmDate = null;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  //BuildContext mainContext;
  int farmcropId;
  bool deleting = false;

  int farmid;

  _AreYouSureDialogState( this.farmcropId, this.farmid);
  // set up the buttons
  @override
  Widget build(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("لا"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: Text("نعم"),
      onPressed: () async {
        setState(() {
          deleting = true;
        });
      },
    );

    return AlertDialog(
      title: Text("مسح المحصول"),
      content: deleting ? Center(child: CircularProgressIndicator()) :Text("هل تريد مسح المحصول؟"),
      actions: deleting ? [] : [
        cancelButton,
        continueButton,
      ],
    );
  }


  showIrrigateDialog(BuildContext context, int myfarmcropid,String updatelastirrigationdate,int farmid) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return MyIrrigateDialog(myfarmcropid, updatelastirrigationdate,farmid);
        },barrierDismissible: false
    );
  }

}

class MyIrrigateDialog extends StatefulWidget {
  String updatelastirrigationdate;

  int myfarmcropid;

  int farmid;

  MyIrrigateDialog(this.myfarmcropid, this.updatelastirrigationdate, this.farmid);

  @override
  _IrrigateState createState() => new _IrrigateState(myfarmcropid, updatelastirrigationdate,farmid);
}

class _IrrigateState extends State<MyIrrigateDialog> {
  Map<String, dynamic>? fetchedJson = null;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');
  String? hrsString = null;
  bool? loading = true;
  String? errmsg = null;
  String updatelastirrigationdate;
  int myfarmcropid;

  int farmid;

  _IrrigateState(this.myfarmcropid, this.updatelastirrigationdate, this.farmid);
  // set up the buttons
  @override
  Widget build(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text("لا"),
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(goToFarmCrops(farmid));
      },
    );

// Set up the submit button
    Widget submitButton = TextButton(
      child: Text("نعم"),
      onPressed: () async {
        setState(() {
          loading = true;
        });

        String irrigateman = await userIrrigated(http.Client(), myfarmcropid);

        if (irrigateman == 'success') {
          Fluttertoast.showToast(
            msg: "تم ري المحصول بنجاح",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          Fluttertoast.showToast(
            msg: "فشل ري المحصول",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }

        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(goToFarmCrops(farmid));
      },
    );

// Error button
    Widget errorButton = TextButton(
      child: Text("اغلاق"),
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(goToFarmCrops(farmid));
      },
    );

    return AlertDialog(
      //title: Text("من فضلك قم بتأكيد اخر موعد للري", textAlign: TextAlign.center,),
      content: FutureBuilder<String>(
        future: fetchIrrigation(http.Client(),myfarmcropid, updatelastirrigationdate),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            Navigator.of(context).pushReplacement(goToLogin());
          if(snapshot.hasData && loading! && errmsg == null && fetchedJson == null){
            if(snapshot.data == 'wrong date'){
              errmsg = 'التاريخ لا يمكن ان يسبق تاريخ الزراعة';
            } else if(snapshot.data == 'wrong id'){
              errmsg = 'لا يوجد هذا المحصول';
            } else if(snapshot.data == 'wrong user'){
              errmsg = 'اعد تسجيل الدخول';
            }else{
              fetchedJson = jsonDecode(snapshot.data!);
              String hrs = fetchedJson!['dischargehours'].toString();
              double hrsToDecimal = (double.tryParse(hrs) ?? 0).toStringAsFixed(2) as double;

              int hoursOnly = hrsToDecimal.floor();
              int minits = ((hrsToDecimal - hoursOnly) * 60).round();
              String hrsAndMinStr = '';
              if (hoursOnly != 0) {
                hrsAndMinStr +=  hoursOnly.toString() + ' ساعة ';
              }
              if (hoursOnly != 0 && minits != 0) { hrsAndMinStr += " و "; }
              if (minits != 0) {
                hrsAndMinStr +=  minits.toString() + ' دقائق ';
              }
              hrsString = hrsAndMinStr;
            }
            SchedulerBinding.instance
                .addPostFrameCallback((_) => setState(() {
              loading = false;
            }));
          }
          return snapshot.hasData && !loading!
              ? (fetchedJson == null? Text(errmsg!) :
          Container(
            height: 350,
            child: Scrollbar(
              child: ListView(
                children: [
                  Text('اجمالي المياه المطلوبة للري',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                  Text(fetchedJson!['irrtotal'].toString()+ ' متر مكعب ',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.green),textAlign: TextAlign.center,),
                  Text('عدد ساعات تشغيل الطلمبة',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                  Text(hrsString!,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.green),textAlign: TextAlign.center,),
                  Text('استهلاك الوقود',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                  Text(fetchedJson!['gas'].toString()+ ' لتر ',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.green),textAlign: TextAlign.center,),
                  Text('سعر الوقود المستهلك',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                  Text(fetchedJson!['gasprice'].toString()+ ' جنيه ',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.green),textAlign: TextAlign.center,),
                  Text('هل ستروي اليوم؟',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                ],
              ),
            ),
          ) )
              : Center(child: CircularProgressIndicator());
        },
      ),
      actions: loading!?[]:fetchedJson == null? [errorButton]:[
        cancelButton,
        submitButton
      ],
    );
  }
}


class AddFarmCropDialog extends StatefulWidget {
  List<cropObject> cropTypes;
  List<MeasringObject> measures;
  List<irrigationMethodObject> irrigationMethods;

  /*String updatelastirrigationdate;

  int myfarmcropid;
*/
  int farmid;

  //AddFarmCropDialog(this.myfarmcropid, this.updatelastirrigationdate, this.farmid);
  AddFarmCropDialog(this.cropTypes,this.irrigationMethods,this.measures, this.farmid);

  @override
  _AddFarmCropState createState() => new _AddFarmCropState(this.cropTypes,this.irrigationMethods,this.measures, this.farmid);
}

class _AddFarmCropState extends State<AddFarmCropDialog> {
  Map<String, dynamic>? fetchedJson = null;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');
  String? hrsString = null;
  List<cropObject> allcroptypes;
  List<irrigationMethodObject> irrigationMethods;
  List<MeasringObject> measuringUnits;
  bool rice = false;
  bool loading = false;
  bool firsttime = true;
  String? errmsg = null;
  String? croptype = null;
  cropObject? croptypeobject = null;
  irrigationMethodObject? irrigationMethod = null;
  MeasringObject? measuringunit = null;
  String? updatelastirrigationdate;
  int? myfarmcropid;
  String? area;
  String? initialIrrigationHours;
  String? mashtal;
  String? shara2y;
  TextEditingController plantingDateController = new TextEditingController();
  TextEditingController lastIrrigationDateController = new TextEditingController();
  DateTime? plantingDate = null;
  DateTime? lastIrrigationDate = null;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();

  int farmid;

  _AddFarmCropState(this.allcroptypes,this.irrigationMethods,this.measuringUnits, this.farmid);
  // set up the buttons
  @override
  Widget build(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text("اغلاق"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

// Set up the buttons
    Widget submitButton = TextButton(
      child: Text("أضف"),
      onPressed: () async {
        if (!formkey.currentState!.validate()) { // Ensure form validation
          return;
        }
        setState(() {
          loading = true;
          formkey.currentState!.save();
        });

        String result = await addFarmCropASYNC(
          croptypeobject!.cropId!,
          farmid.toString(),
          irrigationMethod!.irrigationmethodId!,
          initialIrrigationHours.toString(),
          mashtal.toString(),
          shara2y!,
          measuringunit!.measuringunitId!,
          area!,
          formatter.format(plantingDate!),
          formatter.format(lastIrrigationDate!),
        );

        Fluttertoast.showToast(
          msg: result == 'success' ? "تم اضافة المحصول بنجاح" : "فشل اضافة المحصول: $result",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: result == 'success' ? Colors.green : Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(goToFarmCrops(farmid));
      },
    );

    return AlertDialog(
      title: Text("اضافة محصول", textAlign: TextAlign.center,),
      content: loading? Center(child: CircularProgressIndicator()) : Form(
        key: formkey,
        child: Container(
          height: 350,
          child: Scrollbar(
            child: ListView(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // Use `backgroundColor` instead of `color`
                        padding: EdgeInsets.all(0),
                      ),
                      child: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: plantingDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(Duration(days: 200)),
                          lastDate: DateTime.now(),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              plantingDate = value;
                              plantingDateController.text = formatter.format(value);
                            });
                          }
                        });
                      },
                    ),

                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                            //initialValue: 'a7a ya gedy',
                            controller: plantingDateController,
                            cursorColor: Color(0xff26a69a),
                            //enabled: false,
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'تاريخ الزراعة',focusColor: Color(0xff26a69a)),
                            validator: (String? value){
                              if(value!.isEmpty){
                                return "برجاء ادخال تاريخ الزراعة";
                              }
                            },
                            onTap: () {
                              showDatePicker(
                                  context: context,
                                  initialDate: plantingDate == null ? DateTime.now() : plantingDate,
                                  firstDate: DateTime.now().add(Duration(days: -200)),
                                  lastDate: DateTime.now()).then((value){
                                setState(() {
                                  plantingDate = value;
                                  plantingDateController.text = formatter.format(value!);
                                  //mydate = formatter.format(value);
                                });
                              });
                            },
                            onSaved: (String? value){
                              //farmname = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // Use `backgroundColor` instead of `color`
                        padding: EdgeInsets.all(0),
                      ),
                      child: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: lastIrrigationDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(Duration(days: 200)),
                          lastDate: DateTime.now(),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              lastIrrigationDate = value;
                              lastIrrigationDateController.text = formatter.format(value);
                            });
                          }
                        });
                      },
                    ),

                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                            //initialValue: 'a7a ya gedy',
                            controller: lastIrrigationDateController,
                            cursorColor: Color(0xff26a69a),
                            //enabled: false,
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'تاريخ اخر رية',focusColor: Color(0xff26a69a)),
                            validator: (String? value){
                              if(value!.isEmpty){
                                return "برجاء ادخال تاريخ اخر رية";
                              }
                            },
                            onTap: () {
                              showDatePicker(
                                  context: context,
                                  initialDate: lastIrrigationDate == null ? DateTime.now() : lastIrrigationDate,
                                  firstDate: DateTime.now().add(Duration(days: -200)),
                                  lastDate: DateTime.now()).then((value){
                                setState(() {
                                  lastIrrigationDate = value;
                                  lastIrrigationDateController.text = formatter.format(value!);
                                  //mydate = formatter.format(value);
                                });
                              });
                            },
                            onSaved: (String? value){
                              //farmname = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<cropObject>(
                  validator: (cropObject? value){
                    if(value == null){
                      return "اختر نوع المحصول";
                    }
                  },
                  onSaved: (cropObject? value){
                    croptypeobject = value;
                  },
                  isExpanded: true,
                  value: croptypeobject,
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: TextStyle(color: Colors.black,fontSize: 18),
                  onChanged: (cropObject? newValue) {
                    this.croptypeobject = newValue;
                    if(croptypeobject!.name!.indexOf('رز') >= 0){
                      rice = true;
                    }else{
                      rice = false;
                      shara2y = null;
                      mashtal = null;
                    }
                    setState(() {
                    });
                  },
                  hint: Text('اختر نوع المحصول'),
                  items: allcroptypes
                      .map<DropdownMenuItem<cropObject>>((cropObject value) {
                    return DropdownMenuItem<cropObject>(
                      value: value,
                      child: Text(value.name!),
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<irrigationMethodObject>(
                  validator: (irrigationMethodObject? value){
                    if(value == null){
                      return "اختر نوع الري";
                    }
                  },
                  onSaved: (irrigationMethodObject? value){
                    irrigationMethod = value;
                  },
                  isExpanded: true,
                  value: irrigationMethod,
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: TextStyle(color: Colors.black,fontSize: 18),
                  onChanged: (irrigationMethodObject? newValue) {
                    this.irrigationMethod = newValue;
                    setState(() {
                    });
                  },
                  hint: Text('اختر نوع الري'),
                  items: irrigationMethods
                      .map<DropdownMenuItem<irrigationMethodObject>>((irrigationMethodObject value) {
                    return DropdownMenuItem<irrigationMethodObject>(
                      value: value,
                      child: Text(value.name!),
                    );
                  }).toList(),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                            //initialValue: 'a7a ya gedy',
                            cursorColor: Color(0xff26a69a),
                            decoration: InputDecoration(labelText: 'المساحة المزروعة',focusColor: Color(0xff26a69a)),
                            validator: (String? value){
                              if(value!.isEmpty){
                                return "برجاء ادخال المساحة";
                              }
                            },
                            onSaved: (String? value){
                              area = value;
                            },
                            inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          DropdownButtonFormField<MeasringObject>(
                            validator: (MeasringObject? value){
                              if(value == null){
                                return "اختر الوحدة";
                              }
                            },
                            onSaved: (MeasringObject? value){
                              measuringunit = value;
                            },
                            isExpanded: true,
                            value: measuringunit,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: TextStyle(color: Colors.black,fontSize: 18),
                            onChanged: (MeasringObject? newValue) {
                              this.measuringunit = newValue;
                              setState(() {
                              });
                            },
                            hint: Text('اختر الوحدة'),
                            items: measuringUnits
                                .map<DropdownMenuItem<MeasringObject>>((MeasringObject value) {
                              return DropdownMenuItem<MeasringObject>(
                                value: value,
                                child: Text(value.name!),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                  //initialValue: 'a7a ya gedy',
                  cursorColor: Color(0xff26a69a),
                  decoration: InputDecoration(labelText: 'عدد ساعات رية الزراعه',focusColor: Color(0xff26a69a)),
                  onSaved: (String? value){
                    initialIrrigationHours = value;
                  },
                  inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                if(rice)
                TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                  //initialValue: 'a7a ya gedy',
                  cursorColor: Color(0xff26a69a),
                  decoration: InputDecoration(labelText: 'عدد ساعات ري المشتل',focusColor: Color(0xff26a69a)),
                  onSaved: (String? value){
                    mashtal = value;
                  },
                  inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                if(rice)
                TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                  //initialValue: 'a7a ya gedy',
                  cursorColor: Color(0xff26a69a),
                  decoration: InputDecoration(labelText: 'عدد ساعات طفي الشراقي',focusColor: Color(0xff26a69a)),
                  onSaved: (String? value){
                    shara2y = value;
                  },
                  inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: loading?[]:[
        cancelButton,
        submitButton
      ],
    );
  }
}

class EditFarmCropDialog extends StatefulWidget {
  //List<cropObject> cropTypes;
  List<MeasringObject> measures;
  List<irrigationMethodObject> irrigationMethods;

  /*String updatelastirrigationdate;

  int myfarmcropid;
*/
  int farmid;

  farmcropObject myfarmcrop;

  var BASEcontext;

  //AddFarmCropDialog(this.myfarmcropid, this.updatelastirrigationdate, this.farmid);
  EditFarmCropDialog(this.irrigationMethods,this.measures, this.farmid, this.myfarmcrop,this.BASEcontext);

  @override
  _EditFarmCropState createState() => new _EditFarmCropState(this.irrigationMethods,this.measures, this.farmid, this.myfarmcrop,this.BASEcontext);
}

class _EditFarmCropState extends State<EditFarmCropDialog> {
  Map<String, dynamic>? fetchedJson = null;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');
  String? hrsString = null;
  //List<cropObject> allcroptypes;
  List<irrigationMethodObject> irrigationMethods;
  List<MeasringObject> measuringUnits;
  bool rice = false;
  bool loading = false;
  bool firsttime = true;
  String? errmsg = null;
  String? croptype = null;
  //cropObject croptypeobject = null;
  irrigationMethodObject? irrigationMethod = null;
  MeasringObject? measuringunit = null;
  //String updatelastirrigationdate;
  int? myfarmcropid;
  String? area;
  String? initialIrrigationHours;
  String? mashtal;
  String? shara2y;
  TextEditingController plantingDateController = new TextEditingController();
  TextEditingController lastIrrigationDateController = new TextEditingController();
  //DateTime plantingDate = null;
  DateTime? lastIrrigationDate = null;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  farmcropObject? myfarmcrop;
  int? farmid;
  BuildContext? BASEcontext;

  _EditFarmCropState(this.irrigationMethods,this.measuringUnits, this.farmid, this.myfarmcrop,this.BASEcontext){
    rice = myfarmcrop!.cropname!.indexOf('رز') >= 0;
    /*croptypeobject = allcroptypes[allcroptypes.indexWhere((element) {
      return element.name.trim() == myfarmcrop.cropname.trim();
    })];*/
    irrigationMethod = irrigationMethods[irrigationMethods.indexWhere((element) {
      return element.name!.trim() == myfarmcrop!.irrigationmethodname!.trim();
    })];
    measuringunit = measuringUnits[measuringUnits.indexWhere((element) {
      return element.name!.trim() == myfarmcrop!.measuringunitname!.trim();
    })];
    lastIrrigationDate = myfarmcrop!.lastirrigationdate;
    //updatelastirrigationdate =formatter.format(myfarmcrop.lastirrigationdate);
    lastIrrigationDateController.text = formatter.format(myfarmcrop!.lastirrigationdate!);
    area = myfarmcrop!.area.toString();
    initialIrrigationHours = myfarmcrop!.initirrigationhours.toString();
    mashtal = myfarmcrop!.irrigationmashtal.toString();
    shara2y = myfarmcrop!.irrigtaionshraky.toString();
  }
  showAreYouSureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AreYouSureDialog(this.myfarmcrop!.farmcropId!, this.farmid);
      },
    );
  }
  // set up the buttons
  @override
  Widget build(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text("اغلاق"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

// set up the buttons
    Widget submitButton = TextButton(
      child: Text("تعديل"),
      onPressed: () async {
        if (!formkey.currentState!.validate()) { // NOT VALID
          return;
        }
        setState(() {
          loading = true;
          formkey.currentState!.save();
        });

        String result = await editFarmCropASYNC(
          myfarmcrop!.farmcropId.toString(),
          irrigationMethod!.irrigationmethodId.toString(),
          measuringunit!.measuringunitId.toString(),
          area.toString(),
          initialIrrigationHours.toString(),
          mashtal.toString(),
          shara2y!,
          formatter.format(lastIrrigationDate!),
        );

        if (result == 'success') {
          Fluttertoast.showToast(
            msg: "تم تعديل المحصول بنجاح",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          Fluttertoast.showToast(
            msg: "فشل تعديل المحصول : $result",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }

        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(goToFarmCrops(farmid!));
      },
    );

    return AlertDialog(
      title: Text("تعديل محصول", textAlign: TextAlign.center,),
      content: loading? Center(child: CircularProgressIndicator()) : Form(
        key: formkey,
        child: Container(
          height: 350,
          child: Scrollbar(
            child: ListView(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
            ElevatedButton(
            style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // Button color
              padding: EdgeInsets.all(0),
            ),
            child: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
            onPressed: () {
              showDatePicker(
                context: context,
                initialDate: lastIrrigationDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(Duration(days: 200)),
                lastDate: DateTime.now(),
              ).then((value) {
                if (value != null) { // Ensure value is not null
                  setState(() {
                    lastIrrigationDate = value;
                    lastIrrigationDateController.text = formatter.format(value);
                  });
                }
              });
            },
          ),

            SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                            //initialValue: 'a7a ya gedy',
                            controller: lastIrrigationDateController,
                            cursorColor: Color(0xff26a69a),
                            //enabled: false,
                            readOnly: true,
                            decoration: InputDecoration(labelText: 'تاريخ اخر رية',focusColor: Color(0xff26a69a)),
                            validator: (String? value){
                              if(value!.isEmpty){
                                return "برجاء ادخال تاريخ اخر رية";
                              }
                            },
                            onTap: () {
                              showDatePicker(
                                  context: context,
                                  initialDate: lastIrrigationDate == null ? DateTime.now() : lastIrrigationDate,
                                  firstDate: DateTime.now().add(Duration(days: -200)),
                                  lastDate: DateTime.now()).then((value){
                                setState(() {
                                  lastIrrigationDate = value;
                                  lastIrrigationDateController.text = formatter.format(value!);
                                  //mydate = formatter.format(value);
                                });
                              });
                            },
                            onSaved: (String? value){
                              //farmname = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<irrigationMethodObject>(
                  validator: (irrigationMethodObject? value){
                    if(value == null){
                      return "اختر نوع الري";
                    }
                  },
                  onSaved: (irrigationMethodObject? value){
                    irrigationMethod = value;
                  },
                  isExpanded: true,
                  value: irrigationMethod,
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: TextStyle(color: Colors.black,fontSize: 18),
                  onChanged: (irrigationMethodObject? newValue) {
                    this.irrigationMethod = newValue;
                    setState(() {
                    });
                  },
                  hint: Text('اختر نوع الري'),
                  items: irrigationMethods
                      .map<DropdownMenuItem<irrigationMethodObject>>((irrigationMethodObject value) {
                    return DropdownMenuItem<irrigationMethodObject>(
                      value: value,
                      child: Text(value.name!),
                    );
                  }).toList(),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                            initialValue: area,
                            cursorColor: Color(0xff26a69a),
                            decoration: InputDecoration(labelText: 'المساحة المزروعة',focusColor: Color(0xff26a69a)),
                            validator: (String? value){
                              if(value!.isEmpty){
                                return "برجاء ادخال المساحة";
                              }
                            },
                            onSaved: (String? value){
                              area = value;
                            },
                            inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          DropdownButtonFormField<MeasringObject>(
                            validator: (MeasringObject? value){
                              if(value == null){
                                return "اختر الوحدة";
                              }
                            },
                            onSaved: (MeasringObject? value){
                              measuringunit = value;
                            },
                            isExpanded: true,
                            value: measuringunit,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: TextStyle(color: Colors.black,fontSize: 18),
                            onChanged: (MeasringObject? newValue) {
                              this.measuringunit = newValue;
                              setState(() {
                              });
                            },
                            hint: Text('اختر الوحدة'),
                            items: measuringUnits
                                .map<DropdownMenuItem<MeasringObject>>((MeasringObject value) {
                              return DropdownMenuItem<MeasringObject>(
                                value: value,
                                child: Text(value.name!),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                  initialValue: initialIrrigationHours,
                  cursorColor: Color(0xff26a69a),
                  decoration: InputDecoration(labelText: 'عدد ساعات رية الزراعه',focusColor: Color(0xff26a69a)),
                  onSaved: (String? value){
                    initialIrrigationHours = value;
                  },
                  inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                if(rice)
                  TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                    initialValue: mashtal,
                    cursorColor: Color(0xff26a69a),
                    decoration: InputDecoration(labelText: 'عدد ساعات ري المشتل',focusColor: Color(0xff26a69a)),
                    onSaved: (String? value){
                      mashtal = value;
                    },
                    inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                if(rice)
                  TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                    initialValue: shara2y,
                    cursorColor: Color(0xff26a69a),
                    decoration: InputDecoration(labelText: 'عدد ساعات طفي الشراقي',focusColor: Color(0xff26a69a)),
                    onSaved: (String? value){
                      shara2y = value;
                    },
                    inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red, // Button color
    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Optional padding
    ),
    onPressed: () {
    Navigator.of(context).pop();
    showAreYouSureDialog(BASEcontext!);
    },
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.delete, color: Colors.white, size: 35),
    SizedBox(width: 8), // Add spacing between icon and text
    Text("مسح المحصول", style: TextStyle(color: Colors.white)),
    ],
    ),
    ),

    ],
            ),
          ),
        ),
      ),
      actions: loading?[]:[
        cancelButton,
        submitButton
      ],
    );
  }
}


Future<String> fetchIrrigation(http.Client client, int myfarmcropid,String updatelastirrigationdate) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  final response = await client.get(
    Uri.parse('https://irwicrop.com/Home/updateLastIrrigationAndGetWaterReq?myfarmcropid=${myfarmcropid.toString()}&updatelastirrigationdate=$updatelastirrigationdate'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  return response.body;
}

Future<String> userIrrigated(http.Client client, int myfarmcropid) async {

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  final response = await client.get(
    Uri.parse('https://irwicrop.com/Home/UserIrrigated/$myfarmcropid'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
  );


  // Use the compute function to run parseFarms in a separate isolate.
  return response.body;
}



Future<String> addFarmCropASYNC(String cropId, String farmId, String irrigationmethodId, String initirrigationhours,
    String irrigationmashtal,String irrigtaionshraky, String measuringunitId, String area, String plantingdate, String lastirrigationdate) async {
  /*if(soiltype == 'طينية'){
    soiltype = 'clay';
  }else if(soiltype == 'رملية'){
    soiltype = 'sandy';
  }else if(soiltype == 'سلتية'){
    soiltype = 'silt';
  }*/
  var mydata = jsonEncode({
    'cropId': cropId,
    'farmId': farmId,
    'irrigationmethodId': irrigationmethodId,
    'initirrigationhours': initirrigationhours,
    'irrigationmashtal': irrigationmashtal,
    'irrigtaionshraky': irrigtaionshraky,
    'measuringunitId': measuringunitId,
    'area': area,
    'plantingdate': plantingdate,
    'lastirrigationdate': lastirrigationdate,
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Home/addfarmcrop'), // ✅ Convert to Uri
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
  );


  return response.body;
}


Future<String> editFarmCropASYNC(String farmcropId, String irrigationmethodId, String measuringunitId, String area, String initirrigationhours,
    String irrigationmashtal,String irrigtaionshraky, String lastirrigationdate) async
{
  /*if(soiltype == 'طينية'){
    soiltype = 'clay';
  }else if(soiltype == 'رملية'){
    soiltype = 'sandy';
  }else if(soiltype == 'سلتية'){
    soiltype = 'silt';
  }*/
  var mydata = jsonEncode({
    'farmcropId': farmcropId,
    'irrigationmethodId': irrigationmethodId,
    'initirrigationhours': initirrigationhours,
    'irrigationmashtal': irrigationmashtal,
    'irrigtaionshraky': irrigtaionshraky,
    'measuringunitId': measuringunitId,
    'area': area,
    'lastirrigationdate': lastirrigationdate,
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Home/editfarmcrop'), // ✅ Convert to Uri
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
  );


  //return response.body;
  if (response.statusCode == 302) {
    if(response.headers['location']!.indexOf('/Home/farmcrops/') >=0){
      return 'success';
    }else{
      return 'خطأ غير متوقع';
    }
  } else {//302
    print(response.body);
    return 'خطأ غير متوقع';
  }
}

Future<String> deleteFarmCropASYNC(String farmcropId) async {
  /*if(soiltype == 'طينية'){
    soiltype = 'clay';
  }else if(soiltype == 'رملية'){
    soiltype = 'sandy';
  }else if(soiltype == 'سلتية'){
    soiltype = 'silt';
  }*/
  var mydata = jsonEncode({
    'farmcropId': farmcropId,
  });

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Home/deletefarmcrop'), // ✅ Convert to Uri
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
  );


  //return response.body;
  if (response.statusCode == 302) {
    if(response.headers['location']!.indexOf('/Home/farmcrops/') >=0){
      return 'success';
    }else{
      return 'خطأ غير متوقع';
    }
  } else {//302
    print(response.body);
    return 'خطأ غير متوقع';
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange})
      : assert(decimalRange == null || decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, // unused.
      TextEditingValue newValue,
      ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;
    var myDouble = double.tryParse(newValue.text);

    if(myDouble == null && newValue.text.length != 0)
      return oldValue;
    if (decimalRange != null) {
      String value = newValue.text;

      if (value.contains(".") &&
          value.substring(value.indexOf(".") + 1).length > decimalRange) {
        truncated = oldValue.text;
        newSelection = oldValue.selection;
      } else if (value == ".") {
        truncated = "0.";

        newSelection = newValue.selection.copyWith(
          baseOffset: math.min(truncated.length, truncated.length + 1),
          extentOffset: math.min(truncated.length, truncated.length + 1),
        );
      }

      return TextEditingValue(
        text: truncated,
        selection: newSelection,
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}