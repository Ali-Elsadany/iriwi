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
import 'package:webview_flutter/webview_flutter.dart' show WebViewCookieManager, WebViewCookie;
import 'package:webview_flutter/webview_flutter.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math' as math;
import 'directory.dart';
import 'widgets/side_menu.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Debug configuration for API logging
const bool API_DEBUG_MODE = true; // Set to false in production

void apiLog(String message) {
  if (API_DEBUG_MODE) {
    print(message);
  }
}

/*
 * API IMPROVEMENTS MADE:
 * 1. Added comprehensive input validation
 * 2. Added detailed request/response logging
 * 3. Added proper error handling with specific error messages
 * 4. Added timeout handling (30 seconds)
 * 5. Added status code handling (200, 302, 401, 400, 500)
 * 6. Added cookie validation logging
 * 7. Added debug mode toggle for production
 * 8. Improved user feedback with specific error messages
 * 9. Added null safety for optional parameters
 * 10. Added proper exception handling for network errors
 */

Future<bool> logoutASYNC(String username, String password, String confirmPass,
    String phone, String cookie) async {
  var mydata = jsonEncode({});

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
  } else {
    //302
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
  final cookieManager = WebViewCookieManager();
  bool isWebViewInitialized = false;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (String url) {
            print('=== WEATHERBOX PAGE STARTED ===');
            print('URL: $url');
            print('==============================');
          },
          onPageFinished: (url) {
            print('=== WEATHERBOX PAGE FINISHED ===');
            print('URL: $url');
            print('===============================');
            // Check if content is loaded properly
            _checkContent();
            // Log the full response content
            _logResponseContent();
          },
          onWebResourceError: (WebResourceError error) {
            print('=== WEATHERBOX ERROR ===');
            print('Error code: ${error.errorCode}');
            print('Error description: ${error.description}');
            print('========================');
            setState(() {
              hasError = true;
              errorMessage = 'خطأ في تحميل البيانات';
            });
          },
        ));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String cookie = prefs.getString('cookie') ?? '';

      String myurl =
          'https://irwicrop.com/Home/GetWeatherBoxHtml?farmId=${widget.farmid}';
      
      // Log the URL and farm ID for debugging
      print('=== WEATHERBOX DEBUG INFO ===');
      print('Farm ID: ${widget.farmid}');
      print('Loading weatherbox URL: $myurl');
      print('Cookie length: ${cookie.length}');
      print(
          'Cookie preview: ${cookie.isNotEmpty ? cookie.substring(0, math.min(50, cookie.length)) + '...' : 'EMPTY'}');
      print('============================');

      // Clean and validate the cookie
      String cleanCookie = _cleanCookie(cookie);
      print('=== COOKIE CLEANING ===');
      print('Original cookie: $cookie');
      print('Cleaned cookie: $cleanCookie');
      print('======================');

      // Set Cookie Correctly with cleaned cookie
      if (cleanCookie.isNotEmpty) {
        try {
          await cookieManager.setCookie(
              WebViewCookie(name: 'Cookie', value: cleanCookie, domain: 'irwicrop.com', path: '/'));
          print('✅ Cookie set successfully via cookie manager');
        } catch (e) {
          print('⚠️ Cookie manager failed: $e');
          print('🔄 Trying alternative cookie method...');
          // Alternative: Set cookie via headers only
          await _setCookieViaHeaders(cleanCookie);
        }
      } else {
        print('⚠️ WARNING: Cleaned cookie is empty, proceeding without cookie');
      }

      // Add timeout to prevent infinite loading
      await _controller.loadRequest(
        Uri.parse(myurl), 
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': cookie,
        },
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print('=== WEATHERBOX TIMEOUT ===');
          print('Request timed out after 15 seconds');
          print('URL: $myurl');
          print('=======================');
          setState(() {
            hasError = true;
            errorMessage = 'انتهت مهلة الاتصال';
          });
          throw TimeoutException('WebView timeout');
        },
      );

      setState(() {
        isWebViewInitialized = true;
      });
    } catch (e) {
      print('=== WEATHERBOX INITIALIZATION ERROR ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('===============================');
      setState(() {
        hasError = true;
        errorMessage = 'خطأ في التحميل';
      });
    }
  }

  /// Clean and validate the cookie string to fix format issues
  String _cleanCookie(String cookie) {
    try {
      if (cookie.isEmpty) return '';
      
      print('=== COOKIE CLEANING DETAILED ===');
      print('Original cookie: $cookie');
      
      // Extract only the ApplicationCookie part which seems to be the valid one
      String cleaned = '';
      
      // Look for the ApplicationCookie part
      RegExp appCookieRegex = RegExp(r'\.AspNet\.ApplicationCookie=[^;]+');
      Match? appCookieMatch = appCookieRegex.firstMatch(cookie);
      
      if (appCookieMatch != null) {
        cleaned = appCookieMatch.group(0)!;
        print('Found ApplicationCookie: $cleaned');
      } else {
        // If no ApplicationCookie found, try to clean the whole cookie
        cleaned = cookie;
        
        // Remove problematic parts
        cleaned =
            cleaned.replaceAll(RegExp(r'\.AspNet\.ExternalCookie=[^;]*;?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'expires=[^;]*GMT;?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'path=/;?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'secure;?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'HttpOnly;?'), '');
        
        // Clean up multiple commas and semicolons
        cleaned = cleaned.replaceAll(RegExp(r'[,;]+'), ';');
        cleaned = cleaned.replaceAll(RegExp(r'^[,;]+|[,;]+$'), '');
        
        print('Cleaned cookie (fallback): $cleaned');
      }
      
      // Final validation
      if (cleaned.trim().isEmpty) {
        print('Cookie is empty after cleaning');
        return '';
      }
      
      print('Final cleaned cookie: $cleaned');
      print('===============================');
      return cleaned.trim();
    } catch (e) {
      print('Cookie cleaning error: $e');
      return '';
    }
  }

  /// Check if the WebView content is valid
  Future<void> _checkContent() async {
    try {
      print('=== CHECKING CONTENT ===');
      // Wait a bit for content to render
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Check if page has content
      String? content = await _controller
          .runJavaScriptReturningResult('document.body.innerText') as String?;
      
      print('Content length: ${content?.length ?? 0}');
      print(
          'Content preview: ${content != null && content.isNotEmpty ? content.substring(0, math.min(100, content.length)) + '...' : 'EMPTY'}');
      
      if (content == null || content.trim().isEmpty) {
        print('Content is empty - setting error state');
        setState(() {
          hasError = true;
          errorMessage = 'لا توجد بيانات متاحة';
        });
      } else {
        print('Content is valid');
      }
      print('=======================');
    } catch (e) {
      print('=== CONTENT CHECK ERROR ===');
      print('Error: $e');
      print('==========================');
      // Don't set error here, let the WebView show what it can
    }
  }

  /// Alternative method to set cookie via headers only
  Future<void> _setCookieViaHeaders(String cookie) async {
    try {
      print('=== SETTING COOKIE VIA HEADERS ===');
      print('Cookie to set: $cookie');
      
      // Set cookie via JavaScript after page loads
      await _controller.runJavaScript('''
        document.cookie = "$cookie; domain=.irwicrop.com; path=/";
      ''');
      
      print('✅ Cookie set via JavaScript');
      print('==============================');
    } catch (e) {
      print('❌ Failed to set cookie via JavaScript: $e');
    }
  }

  /// Log the full response content from the WebView
  Future<void> _logResponseContent() async {
    try {
      print('=== FULL RESPONSE CONTENT ===');
      
      // Get the full HTML content
      String? htmlContent = await _controller.runJavaScriptReturningResult(
          'document.documentElement.outerHTML') as String?;
      
      print('HTML Content Length: ${htmlContent?.length ?? 0}');
      if (htmlContent != null && htmlContent.isNotEmpty) {
        print(
            'HTML Content Preview: ${htmlContent.substring(0, math.min(500, htmlContent.length))}');
        if (htmlContent.length > 500) {
          print('... (truncated)');
        }
      } else {
        print('HTML Content: EMPTY');
      }
      
      // Get the page title
      String? title = await _controller
          .runJavaScriptReturningResult('document.title') as String?;
      print('Page Title: ${title ?? 'NO TITLE'}');
      
      // Get the current URL
      String? currentUrl = await _controller
          .runJavaScriptReturningResult('window.location.href') as String?;
      print('Current URL: ${currentUrl ?? 'NO URL'}');
      
      // Check for common error indicators in the content
      if (htmlContent != null) {
        if (htmlContent.contains('error') || htmlContent.contains('Error')) {
          print('⚠️ ERROR INDICATOR FOUND in content');
        }
        if (htmlContent.contains('404') || htmlContent.contains('Not Found')) {
          print('⚠️ 404 NOT FOUND INDICATOR FOUND');
        }
        if (htmlContent.contains('500') ||
            htmlContent.contains('Internal Server Error')) {
          print('⚠️ 500 SERVER ERROR INDICATOR FOUND');
        }
        if (htmlContent.contains('login') || htmlContent.contains('Login')) {
          print('⚠️ LOGIN REQUIRED INDICATOR FOUND');
        }
      }
      
      print('=============================');
    } catch (e) {
      print('=== RESPONSE LOGGING ERROR ===');
      print('Error: $e');
      print('=============================');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      height: 160,
      child: hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 32),
                  SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        hasError = false;
                        errorMessage = '';
                      });
                      _initializeWebView();
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
          : isWebViewInitialized
              ? WebViewWidget(controller: _controller)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xff08aeea)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'جاري التحميل...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _farmcropState extends State<farmcrop>
    with SingleTickerProviderStateMixin {
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
  late PREVIOUSFarmcropFilterObject PREVIOUSselectedfarmCropFilter;
  late PREVIOUSDailyDataSource PREVIOUSdailyDataSource;
  late PREVIOUSPracticalDataSource PREVIOUSpracticalDataSource;
  late PREVIOUSIdealDataSource PREVIOUSidealDataSource;
  late TabController tb;
  final cookieManager = WebViewCookieManager();
  int NotificationCounter = 0;
  int farmid;

  _farmcropState(this.farmid);
  @override
  void initState() {
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
        requestSoundPermission: false);

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);

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
      int id, String? title, String? body, String? payload) {
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

  Future scheduleNotificationMan(
      DateTime notifdate, int id, String crop) async {
    var androidDetails = AndroidNotificationDetails(
      'irwi' + id.toString(),
      'irwi',
      channelDescription:
          'irwi', // 'description' renamed to 'channelDescription'
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Notification Scheduled id: ' +
        id.toString() +
        ' , Time: ' +
        notTime.toString());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
                height: AppBar().preferredSize.height - 5,
              )
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xff08aeea), Color(0xff2af598)])),
          ),
        ),
        drawer: SideMenu(currentRoute: '/farmcrop'),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            //Navigator.pop(context);
            Navigator.of(context).pushReplacement(goToFarms());
          },
          child: Icon(Icons.home),
          backgroundColor: Color(0xff2af598),
        ),
        body: FutureBuilder<List<String>>(
          future: fetchAll(http.Client(), farmid, http.Client(), http.Client(),
              http.Client()),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error.toString());
            }

            if (snapshot.hasError) {
              print('Error in FutureBuilder: ${snapshot.error}');
              return Center(
                child: Text(
                    'حدث خطأ في تحميل البيانات. الرجاء المحاولة مرة أخرى.'),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.length < 12) {
              return Center(
                child: Text('البيانات غير مكتملة. الرجاء المحاولة مرة أخرى.'),
              );
            }

            if (isLoading) {
              try {
              isLoading = false;

                if (snapshot.data != null && snapshot.data!.length >= 6) {
              allfarmcrops = parseFarmcrops(snapshot.data![0]);
              cropTypes = parseCrops(snapshot.data![1]);
              measuringUnits = parseMeasring(snapshot.data![2]);
              irrigationMethods = parseIrrigationMethod(snapshot.data![3]);
              DailyRecords = parseDailyRecords(snapshot.data![4]);
              PracticalGrid = parsePracticalGrid(snapshot.data![5]);
                } else {
                  throw Exception('Data not fully loaded');
                }
              } catch (e) {
                print('Error parsing data: $e');
                return Center(
                  child: Text(
                      'حدث خطأ في معالجة البيانات. الرجاء المحاولة مرة أخرى.'),
                );
              }
              IdealGrid = parseIdealGrid(snapshot.data![6]);
              PREVIOUSDailyRecords =
                  parsePREVIOUSDailyRecords(snapshot.data![7]);
              PREVIOUSPracticalGrid =
                  parsePREVIOUSPracticalGrid(snapshot.data![8]);
              PREVIOUSIdealGrid = parsePREVIOUSIdealGrid(snapshot.data![9]);
              FarmcropFilter = parseFarmcropFilter(snapshot.data![10]);
              PREVIOUSFarmcropFilter =
                  parsePREVIOUSFarmcropFilter(snapshot.data![11]);

              selectedfarmCropFilter =
                  FarmcropFilter != null && FarmcropFilter!.isNotEmpty
                  ? FarmcropFilter![0]
                  : FarmcropFilterObject();

              dailyDataSource = DailyDataSource(
                  DailyRecords ?? [], selectedfarmCropFilter.farmcropId ?? '0');
              practicalDataSource = PracticalDataSource(PracticalGrid ?? [],
                  selectedfarmCropFilter.farmcropId ?? '0');
              idealDataSource = IdealDataSource(
                  IdealGrid ?? [], selectedfarmCropFilter.farmcropId ?? '0');

              PREVIOUSselectedfarmCropFilter = PREVIOUSFarmcropFilter != null &&
                      PREVIOUSFarmcropFilter!.isNotEmpty
                  ? PREVIOUSFarmcropFilter![0]
                  : PREVIOUSFarmcropFilterObject();

              PREVIOUSdailyDataSource = PREVIOUSDailyDataSource(
                  PREVIOUSDailyRecords ?? [],
                  PREVIOUSselectedfarmCropFilter.farmcropId ?? '0');
              PREVIOUSpracticalDataSource = PREVIOUSPracticalDataSource(
                  PREVIOUSPracticalGrid ?? [],
                  PREVIOUSselectedfarmCropFilter.farmcropId ?? '0');
              PREVIOUSidealDataSource = PREVIOUSIdealDataSource(
                  PREVIOUSIdealGrid ?? [],
                  PREVIOUSselectedfarmCropFilter.farmcropId ?? '0');

              NotificationCounter = 0;
              for (farmcropObject myfarmcrop in allfarmcrops ?? []) {
                if (myfarmcrop.nextirrigationdate != null &&
                    myfarmcrop.nextirrigationdate!.isAfter(DateTime.now())) {
                  scheduleNotificationMan(myfarmcrop.nextirrigationdate!,
                      ++NotificationCounter, myfarmcrop.cropname ?? '');
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
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 25, vertical: 15),
                                alignment: Alignment.center,
                                child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                  children: [
                                              Icon(
                                                Icons.local_florist,
                                                color: Colors.blue[900],
                                                size: 35,
                                              ),
                                    Text(
                                      'المزرعة',
                                                style: TextStyle(
                                                    color: Colors.blue[900],
                                                    fontSize: 30,
                                                    fontWeight:
                                                        FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  width: 300,
                                  height: 100,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 25, vertical: 15),
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors
                                                    .white, // Background color
                                                padding: EdgeInsets.fromLTRB(
                                                    10, 10, 10, 10),
                                  ),
                                  onPressed: () {
                                                showAddFarmCropDialog(
                                                    context,
                                                    cropTypes,
                                                    irrigationMethods,
                                                    measuringUnits,
                                                    farmid);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                                  Icon(Icons.add_circle,
                                                      color: Color(0xff039be5),
                                                      size: 35),
                                                  SizedBox(
                                                      width:
                                                          8), // Add space between icon and text
                                      Text(
                                        'أضف محصول',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff039be5),
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w100),
                                      ),
                                    ],
                                  ),
                                            )),
                            ],
                                    )),
                      ),
                          expandedHeight: 250.0,

                          /// your Carousel + Tabbar height(50)
                    floating: true,
                    bottom: TabBar(
                      controller: tb,
                      tabs: [
                      Tab(text: "المراقبة"),
                      Tab(text: "الموسم الحالي"),
                      Tab(text: "المواسم السابقة"),
                            ],
                            labelColor: Color(0xff1a237e),
                            indicatorColor: Colors.blue,
                            unselectedLabelColor: Colors.grey,
                          ),
                  ),
                ];
              },
              body: TabBarView(
                //physics: NeverScrollableScrollPhysics(),
                controller: tb,
                children: <Widget>[
                  SingleChildScrollView(
                    child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          WeatherBoxWebview(farmid),
                          Column(
                            children: [
                                    for (farmcropObject myfarmcrop
                                        in allfarmcrops!)
                                Container(
                                  decoration: new BoxDecoration(
                                    //borderRadius: new BorderRadius.circular(16.0),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                        spreadRadius: 5,
                                        blurRadius: 7,
                                              offset: Offset(0,
                                                  3), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  //padding: EdgeInsets.all(50),
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 25, vertical: 15),
                                  child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Stack(
                                        children: <Widget>[
                                          Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  print("Image clicked");
                                                  //Navigator.of(context).pushReplacement(goToFarmCrops(myfarmcrop.farmcropId));
                                                },
                                                child: (myfarmcrop.cropimg != null && myfarmcrop.cropimg!.isNotEmpty)
                                                    ? Image(
                                                        image: AssetImage(
                                                          'assets/images/crops/' + myfarmcrop.cropimg!.trim(),
                                                        ),
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Icon(
                                                            Icons.grass,
                                                            size: 48,
                                                            color: Color(0xff26a69a),
                                                          );
                                                        },
                                                      )
                                                    : Icon(
                                                        Icons.grass,
                                                        size: 48,
                                                        color: Color(0xff26a69a),
                                                      ),
                                              ),
                                              Container(
                                                height: 25,
                                                color: Colors.transparent,
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            left: 5,
                                            bottom: 0,
                                            child: FloatingActionButton(
                                                    heroTag: 'frm' + (myfarmcrop.farmcropId ?? 0).toString(),
                                                    backgroundColor: Color(0xff2af598),
                                                    child: const Icon(Icons.edit),
                                                    onPressed: () async {
                                                      if (irrigationMethods != null && measuringUnits != null) {
                                                        await showEditFarmCropDialog(
                                                          BASEcontext: context,
                                                          irrigationMethods: irrigationMethods!,
                                                          measures: measuringUnits!,
                                                          farmid: widget.farmid,
                                                          myfarmcrop: myfarmcrop,
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('جاري تحميل البيانات...'),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                          Positioned(
                                            right: 10,
                                            bottom: 25,
                                                  child: Text(
                                                    myfarmcrop.cropname ?? '',
                                                    style: TextStyle(
                                                        fontSize: 30,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                shadows: [
                                                          Shadow(
                                                              // bottomLeft
                                                              offset: Offset(
                                                                  -1.5, -1.5),
                                                              color:
                                                                  Colors.black),
                                                          Shadow(
                                                              // bottomRight
                                                              offset: Offset(
                                                                  1.5, -1.5),
                                                              color:
                                                                  Colors.black),
                                                          Shadow(
                                                              // topRight
                                                              offset: Offset(
                                                                  1.5, 1.5),
                                                              color:
                                                                  Colors.black),
                                                          Shadow(
                                                              // topLeft
                                                              offset: Offset(
                                                                  -1.5, 1.5),
                                                              color:
                                                                  Colors.black),
                                                        ]),
                                                  ),
                                                ),
                                              ],
                                              clipBehavior: Clip.none,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Color(
                                                        0xff2196f3), // ✅ Equivalent to `color` in RaisedButton
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 10),
                                                  ),
                                                  onPressed: () {
                                                    showWaterNeedsDialog(
                                                        context,
                                                        myfarmcrop,
                                                        farmid);
                                                  },
                                            child: Row(
                                              children: [
                                                      Icon(Icons.spa,
                                                          color: Colors.white,
                                                          size: 35),
                                                      Text(
                                                          "الاحتياجات المائية المتوقعة للري",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ],
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                  ),
                                                )
                                        ],
                                      ),
                                      GestureDetector(
                                              onTap: () {
                                          print("Container clicked");
                                        },
                                        child: Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    10, 0, 10, 0),
                                          child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                            children: [
                                                    Text(
                                                      'البيانات المتوقعة',
                                                      style: TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                              Row(
                                                children: [
                                                        Icon(
                                                          Icons.timelapse,
                                                          color: Colors.black,
                                                          size: 22,
                                                        ),
                                                  SizedBox(width: 10),
                                                        Text(
                                                          'الرية القادمة:',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                  SizedBox(width: 5),
                                                        Text(
                                                          formatter.format(
                                                              myfarmcrop
                                                                  .nextirrigationdate!),
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                        Icon(
                                                          Icons.hourglass_empty,
                                                          color: Colors.black,
                                                          size: 22,
                                                        ),
                                                  SizedBox(width: 10),
                                                        Text(
                                                          'تاريخ ايقاف الري:',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                  SizedBox(width: 5),
                                                        Text(
                                                          formatter.format(
                                                              myfarmcrop
                                                                  .stopirrigationdate!),
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                        Icon(
                                                          Icons.local_florist,
                                                          color: Colors.black,
                                                          size: 22,
                                                        ),
                                                  SizedBox(width: 10),
                                                        Text(
                                                          'مرحلة النمو:',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                  SizedBox(width: 5),
                                                        Text(
                                                          myfarmcrop.stage!,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                        Icon(
                                                          Icons.hourglass_empty,
                                                          color: Colors.black,
                                                          size: 22,
                                                        ),
                                                  SizedBox(width: 10),
                                                        Text(
                                                          'تاريخ الحصاد:',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                  SizedBox(width: 5),
                                                        Text(
                                                          formatter.format(
                                                              myfarmcrop
                                                                  .harvestdate!),
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                              ),
                                              Row(
                                                children: [
                                                        Icon(
                                                          Icons.local_florist,
                                                          color: Colors.black,
                                                          size: 22,
                                                        ),
                                                  SizedBox(width: 10),
                                                        Text(
                                                          'حجم الانتاج المتوقع:',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                  SizedBox(width: 5),
                                                        Text(
                                                          myfarmcrop.LASTNPP ==
                                                                      null ||
                                                                  myfarmcrop
                                                                          .LASTNPP ==
                                                                      'null'
                                                              ? '0'
                                                              : '${myfarmcrop.LASTNPP} ${myfarmcrop.measuringunitname ?? ''}/ك',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                    ),
                                                  ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                            ],
                          ),
                                Container(
                                  //FOOTER
                            padding: EdgeInsets.all(5),
                            decoration: new BoxDecoration(
                              gradient: LinearGradient(
                                        colors: [
                                          Color(0xff08aeea),
                                          Color(0xff2af598)
                                        ],
                                  begin: const FractionalOffset(0.0, 0.0),
                                  end: const FractionalOffset(0.7, 0.0),
                                  stops: [0.0, 1.0],
                                        tileMode: TileMode.clamp),
                            ),
                            child: Column(
                              children: [
                                Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                              child: Image(
                                            image: AssetImage(
                                                'assets/images/msa.png'),
                                            fit: BoxFit.contain,
                                          )),
                              SizedBox(width: 20),
                              Flexible(
                                              child: Image(
                                            image: AssetImage(
                                                'assets/images/iwmi.png'),
                                            fit: BoxFit.contain,
                                          )),
                              SizedBox(width: 20),
                              Flexible(
                                              child: Image(
                                            image: AssetImage(
                                                'assets/images/sweri.png'),
                                            fit: BoxFit.contain,
                                          ))
                            ],
                          ),
                                Image(
                                          image: AssetImage(
                                              'assets/images/WAPOR.jpg'))
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
                                child: DropdownButtonFormField<
                                    FarmcropFilterObject>(
                            isExpanded: true,
                            value: selectedfarmCropFilter,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                            onChanged: (FarmcropFilterObject? newValue) {
                              setState(() {
                                selectedfarmCropFilter = newValue!;
                                      dailyDataSource = DailyDataSource(
                                          DailyRecords!,
                                          selectedfarmCropFilter.farmcropId!);
                                      practicalDataSource = PracticalDataSource(
                                          PracticalGrid!,
                                          selectedfarmCropFilter.farmcropId!);
                                      idealDataSource = IdealDataSource(
                                          IdealGrid!,
                                          selectedfarmCropFilter.farmcropId!);
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                                  items: (FarmcropFilter ?? []).map<
                                          DropdownMenuItem<
                                              FarmcropFilterObject>>(
                                      (FarmcropFilterObject value) {
                                    return DropdownMenuItem<
                                        FarmcropFilterObject>(
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
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                            onChanged: (String? newValue) {
                              setState(() {
                                whichGrid = newValue!;
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                                  items: <String>[
                                    'بيانات يوميه',
                                    'جدولة الري الفعليه',
                                    'جدولة الري القياسيه'
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                              if (whichGrid == 'بيانات يوميه')
                                PaginatedDataTable(
                          header: Text('البيانات اليومية'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                                    DataColumn(
                                        label:
                                            Text('معدل البخر والنتح (مم/يوم)')),
                                    DataColumn(
                                        label: Text(
                                            'معدل البخر والنتح للمحصول مم/يوم')),
                                    DataColumn(
                                        label: Text(
                                            'معدل تساقط الامطار الفعلي مم')),
                            DataColumn(label: Text('معامل المحصول')),
                            DataColumn(label: Text('العمر باليوم')),
                                    DataColumn(
                                        label: Text('الاحتياج اليومي م مكعب')),
                          ],
                          source: dailyDataSource,
                        ),
                              if (whichGrid == 'جدولة الري الفعليه')
                                PaginatedDataTable(
                          header: Text('جدولة الري الفعليه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                                    DataColumn(
                                        label: Text(
                                            'كمية المياه المستهلكة م مكعب')),
                                    DataColumn(
                                        label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                                    DataColumn(
                                        label: Text('استهلاك الوقود - لتر')),
                                    DataColumn(
                                        label: Text(
                                            'سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: practicalDataSource,
                        ),
                              if (whichGrid == 'جدولة الري القياسيه')
                                PaginatedDataTable(
                          header: Text('جدولة الري القياسيه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                                    DataColumn(
                                        label: Text(
                                            'كمية المياه المستهلكة م مكعب')),
                                    DataColumn(
                                        label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                                    DataColumn(
                                        label: Text('استهلاك الوقود - لتر')),
                                    DataColumn(
                                        label: Text(
                                            'سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: idealDataSource,
                        ),
                              Container(
                                //FOOTER
                          padding: EdgeInsets.all(5),
                          decoration: new BoxDecoration(
                            gradient: LinearGradient(
                                      colors: [
                                        Color(0xff08aeea),
                                        Color(0xff2af598)
                                      ],
                                begin: const FractionalOffset(0.0, 0.0),
                                end: const FractionalOffset(0.7, 0.0),
                                stops: [0.0, 1.0],
                                      tileMode: TileMode.clamp),
                          ),
                          child: Column(
                            children: [
                              Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                                            child: Image(
                                          image: AssetImage(
                                              'assets/images/msa.png'),
                                          fit: BoxFit.contain,
                                        )),
                            SizedBox(width: 20),
                            Flexible(
                                            child: Image(
                                          image: AssetImage(
                                              'assets/images/iwmi.png'),
                                          fit: BoxFit.contain,
                                        )),
                            SizedBox(width: 20),
                            Flexible(
                                            child: Image(
                                          image: AssetImage(
                                              'assets/images/sweri.png'),
                                          fit: BoxFit.contain,
                                        ))
                          ],
                        ),
                              Image(
                                        image: AssetImage(
                                            'assets/images/WAPOR.jpg'))
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
                                child: DropdownButtonFormField<
                                    PREVIOUSFarmcropFilterObject>(
                            isExpanded: true,
                            value: PREVIOUSselectedfarmCropFilter,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                                  onChanged:
                                      (PREVIOUSFarmcropFilterObject? newValue) {
                              setState(() {
                                      PREVIOUSselectedfarmCropFilter =
                                          newValue!;
                                      PREVIOUSdailyDataSource =
                                          PREVIOUSDailyDataSource(
                                              PREVIOUSDailyRecords!,
                                              PREVIOUSselectedfarmCropFilter
                                                  .farmcropId!);
                                      PREVIOUSpracticalDataSource =
                                          PREVIOUSPracticalDataSource(
                                              PREVIOUSPracticalGrid!,
                                              PREVIOUSselectedfarmCropFilter
                                                  .farmcropId!);
                                      PREVIOUSidealDataSource =
                                          PREVIOUSIdealDataSource(
                                              PREVIOUSIdealGrid!,
                                              PREVIOUSselectedfarmCropFilter
                                                  .farmcropId!);
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                                  items: (PREVIOUSFarmcropFilter ?? []).map<
                                      DropdownMenuItem<
                                          PREVIOUSFarmcropFilterObject>>(
                                  (PREVIOUSFarmcropFilterObject value) {
                                      return DropdownMenuItem<
                                          PREVIOUSFarmcropFilterObject>(
                                  value: value,
                                        child: Text(value.Text ??
                                            "N/A"), // Handle null safely
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
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                            onChanged: (String? newValue) {
                              setState(() {
                                PREVIOUSwhichGrid = newValue!;
                              });
                            },
                            hint: Text('اختر نوع التربة'),
                                  items: <String>[
                                    'بيانات يوميه',
                                    'جدولة الري الفعليه',
                                    'جدولة الري القياسيه'
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                              if (PREVIOUSwhichGrid == 'بيانات يوميه')
                                PaginatedDataTable(
                          header: Text('البيانات اليومية'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                                    DataColumn(
                                        label:
                                            Text('معدل البخر والنتح (مم/يوم)')),
                                    DataColumn(
                                        label: Text(
                                            'معدل البخر والنتح للمحصول مم/يوم')),
                                    DataColumn(
                                        label: Text(
                                            'معدل تساقط الامطار الفعلي مم')),
                            DataColumn(label: Text('معامل المحصول')),
                            DataColumn(label: Text('العمر باليوم')),
                                    DataColumn(
                                        label: Text('الاحتياج اليومي م مكعب')),
                          ],
                          source: PREVIOUSdailyDataSource,
                        ),
                              if (PREVIOUSwhichGrid == 'جدولة الري الفعليه')
                                PaginatedDataTable(
                          header: Text('جدولة الري الفعليه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                                    DataColumn(
                                        label: Text(
                                            'كمية المياه المستهلكة م مكعب')),
                                    DataColumn(
                                        label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                                    DataColumn(
                                        label: Text('استهلاك الوقود - لتر')),
                                    DataColumn(
                                        label: Text(
                                            'سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: PREVIOUSpracticalDataSource,
                        ),
                              if (PREVIOUSwhichGrid == 'جدولة الري القياسيه')
                                PaginatedDataTable(
                          header: Text('جدولة الري القياسيه'),
                          columns: [
                            DataColumn(label: Text('التاريخ')),
                            DataColumn(label: Text('المرحلة')),
                                    DataColumn(
                                        label: Text(
                                            'كمية المياه المستهلكة م مكعب')),
                                    DataColumn(
                                        label: Text('عدد ساعات التشغيل')),
                            DataColumn(label: Text('العمر باليوم')),
                                    DataColumn(
                                        label: Text('استهلاك الوقود - لتر')),
                                    DataColumn(
                                        label: Text(
                                            'سعر الوقود المستهلك بالجنيه')),
                          ],
                          source: PREVIOUSidealDataSource,
                        ),
                              Container(
                                //FOOTER
                          padding: EdgeInsets.all(5),
                          decoration: new BoxDecoration(
                            gradient: LinearGradient(
                                      colors: [
                                        Color(0xff08aeea),
                                        Color(0xff2af598)
                                      ],
                                begin: const FractionalOffset(0.0, 0.0),
                                end: const FractionalOffset(0.7, 0.0),
                                stops: [0.0, 1.0],
                                      tileMode: TileMode.clamp),
                          ),
                          child: Column(
                            children: [
                              Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                                            child: Image(
                                          image: AssetImage(
                                              'assets/images/msa.png'),
                                          fit: BoxFit.contain,
                                        )),
                            SizedBox(width: 20),
                            Flexible(
                                            child: Image(
                                          image: AssetImage(
                                              'assets/images/iwmi.png'),
                                          fit: BoxFit.contain,
                                        )),
                            SizedBox(width: 20),
                            Flexible(
                                            child: Image(
                                          image: AssetImage(
                                              'assets/images/sweri.png'),
                                          fit: BoxFit.contain,
                                        ))
                          ],
                        ),
                              Image(
                                        image: AssetImage(
                                            'assets/images/WAPOR.jpg'))
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

class DailyDataSource extends DataTableSource {
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

 late List<DailyRecordsObject> data;
  late int count; // Ensure it's initialized

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
    return DataRow.byIndex(index: index, cells: [
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

class PracticalDataSource extends DataTableSource {
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  List<PracticalGridObject> data = [];
  int count;

  PracticalDataSource(List<PracticalGridObject> alldata, String cropid)
      : count = 0 {
    // Initialize count before constructor body
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
    return DataRow.byIndex(index: index, cells: [
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

class IdealDataSource extends DataTableSource {
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
    return DataRow.byIndex(index: index, cells: [
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

class PREVIOUSDailyDataSource extends DataTableSource {
  List<PREVIOUSDailyRecordsObject> data = []; // Correct list initialization
  int count = 0; // Initialize count
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  PREVIOUSDailyDataSource(
      List<PREVIOUSDailyRecordsObject> alldata, String cropid) {
    data = []; // Ensure list is empty before adding elements

    for (var item in alldata) {
      if (item.farmcropId == cropid) {
        data.add(item);
      }
    }

    count = data.length; // Set count after processing
  }

  void updateData() {
    //data += '1';
    count--;
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index, cells: [
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

class PREVIOUSPracticalDataSource extends DataTableSource {
  late List<PREVIOUSPracticalGridObject> data;
  late int count;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  PREVIOUSPracticalDataSource(
      List<PREVIOUSPracticalGridObject> alldata, String cropid) {
    data = alldata.where((item) => item.farmcropId == cropid).toList();
    count = data.length;
  }

  void updateData() {
    //data += '1';
    count--;
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index, cells: [
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

class PREVIOUSIdealDataSource extends DataTableSource {
  late List<PREVIOUSIdealGridObject> data;
  late int count; // Marking as `late` ensures it's initialized before use.
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  PREVIOUSIdealDataSource(
      List<PREVIOUSIdealGridObject> alldata, String cropid) {
    data = alldata.where((item) => item.farmcropId == cropid).toList();
    count = data.length;
  }

  void updateData() {
    //data += '1';
    count--;
  }

  @override
  DataRow getRow(int index) {
    // TODO: implement getRow
    return DataRow.byIndex(index: index, cells: [
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
  Widget cancelButton = ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xff26a69a),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    child: Text(
      "اغلاق",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(
      "بيانات المحصول",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xff26a69a),
      ),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    content: Container(
      height: 350,
      child: Scrollbar(
        child: ListView(
          children: [
            Row(
              children: [
                //Icon(Icons.hourglass_empty,color: Colors.black,size: 22,),
                FaIcon(
                  FontAwesomeIcons.leaf,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'المحصول:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  myfarmcrop.cropname!,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.calendar,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'تاريخ الزراعة:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  formatter.format(myfarmcrop.plantingdate!),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.calendar,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'تاريخ الحصاد:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  formatter.format(myfarmcrop.harvestdate!),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.tree,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'المرحلة:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  myfarmcrop.stage!,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.calendar,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'الرية القادمة:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  formatter.format(myfarmcrop.nextirrigationdate!),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.clock,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'عدد ساعات رية الزراعة:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  (myfarmcrop.initirrigationhours ?? 0).toString(),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.water,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'المياه المطلوبة اليوم:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    (double.tryParse(myfarmcrop.irrday!) ?? 0.0)
                        .toStringAsFixed(2),
                    style: TextStyle(fontSize: 18),
                  ),
                )
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.chartArea,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'المساحة:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  (myfarmcrop.area ?? 0).toString() +
                      (myfarmcrop.measuringunitname ?? ''),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.handHoldingWater,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'نوع الري:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 5),
                Text(
                  myfarmcrop.irrigationmethodname!,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            if (myfarmcrop.cropname!.contains('رز'))
              Row(
              children: [
                  FaIcon(
                    FontAwesomeIcons.clock,
                    color: Colors.black,
                  ),
                SizedBox(width: 10),
                  Text(
                    'عدد ساعات طفي الشراقي:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                SizedBox(width: 5),
                  Text(
                    myfarmcrop.irrigtaionshraky.toString(),
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
                mainAxisSize: MainAxisSize.min,
              ),
            if (myfarmcrop.cropname!.contains('رز'))
              Row(
              children: [
                  FaIcon(
                    FontAwesomeIcons.clock,
                    color: Colors.black,
                  ),
                SizedBox(width: 10),
                  Text(
                    'عدد ساعات ري المشتل:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                SizedBox(width: 5),
                  Text(
                    myfarmcrop.irrigationmashtal.toString(),
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
                mainAxisSize: MainAxisSize.min,
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

showWaterNeedsDialog(
    BuildContext context, farmcropObject myfarmcrop, int farmid) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return MyConfirmDateDialog(context, myfarmcrop.farmcropId ?? 0, farmid,
            myfarmcrop.lastirrigationdate ?? DateTime.now());
      });
}

showAddFarmCropDialog(
    context, cropTypes, irrigationMethods, measuringUnits, farmid) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddFarmCropDialog(
            cropTypes, irrigationMethods, measuringUnits, farmid);
      },
      barrierDismissible: false);
}

showEditFarmCropDialog({
  required BuildContext BASEcontext,
  required List<irrigationMethodObject> irrigationMethods,
  required List<MeasringObject> measures,
  required int farmid,
  required farmcropObject myfarmcrop,
}) {
  showDialog(
      context: BASEcontext,
      builder: (BuildContext context) {
        return EditFarmCropDialog(
            irrigationMethods: irrigationMethods,
            measures: measures,
            farmid: farmid,
            myfarmcrop: myfarmcrop,
            BASEcontext: BASEcontext);
      },
      barrierDismissible: false);
}

/////////////// FETCH ALL DATA ////////////////////////
Future<List<String>> fetchAll(
  http.Client client,
  farmid,
  http.Client client2,
  http.Client client3,
  http.Client client4,
) async {
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
Future<String> fetchFarmcrops(http.Client client, farmid) async {
  try {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  var mydata = jsonEncode({
    'farmid': farmid,
  });

    // Log the request
    print('\n=== FARMCROPS API REQUEST ===');
    print('URL: https://irwicrop.com/Home/RemoteDataSource_GetFarmCrops');
    print('Method: POST');
    print('Headers: {');
    print('  Content-Type: application/json; charset=UTF-8');
    print('  Cookie: ${cookie.substring(0, math.min(50, cookie.length))}...');
    print('}');
    print('Body: $mydata');
    print('============================\n');

  final response = await client.post(
      Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetFarmCrops'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
    body: mydata,
  );

    // Log the response
    print('\n=== FARMCROPS API RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body Length: ${response.body.length}');
    print('Response Body: ${response.body}');
    print('=============================\n');

  return response.body;
  } catch (e, stackTrace) {
    print('\n=== FARMCROPS API ERROR ===');
    print('Error: $e');
    print('Stack Trace: $stackTrace');
    print('=========================\n');
    rethrow;
  }
}

// A function that converts a response body into a List<Photo>.
List<farmcropObject> parseFarmcrops(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed
      .map<farmcropObject>((json) => farmcropObject.fromJson(json))
      .toList();
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
  farmcropObject(
      {this.archived,
      this.farmcropId,
      this.lastirrigationdate,
      this.irrigationmethodId,
      this.area,
      this.measuringunitId,
      this.initirrigationhours,
      this.cropname,
      this.cropimg,
      this.croptotaldays,
      this.irrigationmashtal,
      this.irrigtaionshraky,
      this.nextirrigationdate,
      this.stopirrigationdate,
      this.stage,
      this.harvestdate,
      this.LASTNPP,
      this.measuringunitname,
      this.irrigationmethodname,
      this.agebyday,
      this.irrday,
      this.plantingdate});

  factory farmcropObject.fromJson(Map<String, dynamic> json) {
    // Handle null check for nested crop object and provide flat-key fallbacks
    final Map<String, dynamic>? cropData =
        json['crop'] as Map<String, dynamic>?;

    String? _trimOrNull(dynamic v) => v == null ? null : v.toString().trim();

    return farmcropObject(
      archived: json['archived'] as int?,
      farmcropId: json['farmcropId'] as int?,
      lastirrigationdate: json['lastirrigationdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['lastirrigationdate'].substring(6, 19)) ?? 0)
          : null,
      irrigationmethodId: json['irrigationmethodId'] as int?,
      area: json['area'] != null
          ? double.tryParse(json['area'].toString())
          : null,
      measuringunitId: json['measuringunitId'] as int?,
      initirrigationhours: json['initirrigationhours'] as int?,
      // Prefer nested values, fallback to flat API keys like 'cropname', 'cropimg', 'croptotaldays'
      cropname: _trimOrNull(cropData?['name']) ?? _trimOrNull(json['cropname']),
      cropimg: _trimOrNull(cropData?['img']) ?? _trimOrNull(json['cropimg']),
      croptotaldays:
          _trimOrNull(cropData?['totaldays']) ?? _trimOrNull(json['croptotaldays']) ?? _trimOrNull(json['totaldays']),
      irrigationmashtal: json['irrigationmashtal'] as int?,
      irrigtaionshraky: json['irrigtaionshraky'] as int?,
      nextirrigationdate: json['nextirrigationdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['nextirrigationdate'].substring(6, 19)) ?? 0)
          : null,
      stopirrigationdate: json['stopirrigationdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['stopirrigationdate'].substring(6, 19)) ?? 0)
          : null,
      stage: json['stage']?.toString(),
      harvestdate: json['harvestdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['harvestdate'].substring(6, 19)) ?? 0)
          : null,
      LASTNPP: json['LASTNPP']?.toString(),
      measuringunitname: json['measuringunit']?['name']?.toString(),
      irrigationmethodname: json['irrigationmethod']?['name']?.toString(),
      agebyday: json['agebyday']?.toString(),
      irrday: json['irrday']?.toString(),
      plantingdate: json['plantingdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['plantingdate'].substring(6, 19)) ?? 0)
          : null,
    );
  }
}

/////////////// CROPS FETCH DATA ////////////////////////
Future<String> fetchCrops(http.Client client) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cookie = (prefs.getString('cookie') ?? '');

    // Log request
    print('\n=== CROPS API REQUEST ===');
    print('URL: https://irwicrop.com/Home/RemoteDataSource_GetCrops');
    print('Method: GET');
    print('Headers: { Content-Type: application/json; charset=UTF-8, Cookie: ${cookie.isNotEmpty ? '${cookie.substring(0, cookie.length > 50 ? 50 : cookie.length)}...' : ''} }');
    print('==========================');

    final response = await client.get(
      Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetCrops'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie
      },
    );

    // Log response
    print('\n=== CROPS API RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body Length: ${response.body.length}');
    print('Response Body: ${response.body}');
    print('==========================\n');

    // Use the compute function to run parseFarms in a separate isolate.
    //return compute(parseCrops, response.body);
    return response.body;
  } catch (e, st) {
    print('\n=== CROPS API ERROR ===');
    print('Error: $e');
    print('Stack Trace: $st');
    print('========================\n');
    rethrow;
  }
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

  return parsed
      .map<MeasringObject>((json) => MeasringObject.fromJson(json))
      .toList();
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
    Uri.parse(
        'https://irwicrop.com/Home/RemoteDataSource_GetIrrigationMethods'),
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
    Uri.parse(
        'https://irwicrop.com/Home/getPracticalGrid?recordfarmid=${farmid.toString()}'),
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
    Uri.parse(
        'https://irwicrop.com/Home/PREVIOUSgetPracticalGrid?recordfarmid=${farmid ?? ''}'),
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
    Uri.parse(
        'https://irwicrop.com/Home/getIdealGrid?recordfarmid=${farmid ?? ''}'),
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
    Uri.parse(
        'https://irwicrop.com/Home/PREVIOUSgetIdealGrid?recordfarmid=${farmid.toString()}'),
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
    Uri.parse(
        'https://irwicrop.com/Home/PREVIOUSgetIdealGrid?recordfarmid=${farmid.toString()}'),
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
    Uri.parse(
        'https://irwicrop.com/Home/PREVIOUSgetDailyRecords?recordfarmid=${farmid.toString()}'),
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

  final response = await http.Client().get(
    Uri.parse(
      'https://irwicrop.com/Home/getFarmcropFilter?recordfarmid=' +
          farmid.toString(),
    ),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
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

  final response = await http.Client().get(
    Uri.parse(
      'https://irwicrop.com/Home/PREVIOUSgetFarmcropFilter?recordfarmid=' +
          farmid.toString(),
    ),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie
    },
  );

  // Use the compute function to run parseFarms in a separate isolate.
  //return compute(parseIrrigation, response.body);
  return response.body;
}

// A function that converts a response body into a List<Photo>.
List<irrigationMethodObject> parseIrrigationMethod(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed
      .map<irrigationMethodObject>(
          (json) => irrigationMethodObject.fromJson(json))
      .toList();
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
  var temp = jsonDecode(responseBody);
  var temp2 = temp['Data'];
  var temp3 = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed
      .map<DailyRecordsObject>((json) => DailyRecordsObject.fromJson(json))
      .toList();
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
  DailyRecordsObject(
      {this.dailyrecordId,
      this.farmcropId,
      this.date,
      this.stage,
      this.eto,
      this.etc,
      this.pe,
      this.kc,
      this.irrday,
      this.agebyday,
      this.daystillharvest});

  factory DailyRecordsObject.fromJson(Map<String, dynamic> json) {
    return DailyRecordsObject(
      dailyrecordId: json['dailyrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6, 19)) ?? 0),
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
  var temp = jsonDecode(responseBody);
  var temp2 = temp['Data'];
  var temp3 = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed
      .map<PracticalGridObject>((json) => PracticalGridObject.fromJson(json))
      .toList();
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
  PracticalGridObject(
      {this.practicalirrigationrecordId,
      this.farmcropId,
      this.date,
      this.stage,
      this.dischargehours,
      this.irrtotal,
      this.agebyday,
      this.gas,
      this.gasprice});

  factory PracticalGridObject.fromJson(Map<String, dynamic> json) {
    return PracticalGridObject(
      practicalirrigationrecordId:
          json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6, 19)) ?? 0),
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
  var temp = jsonDecode(responseBody);
  var temp2 = temp['Data'];
  var temp3 = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed
      .map<IdealGridObject>((json) => IdealGridObject.fromJson(json))
      .toList();
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
  IdealGridObject(
      {this.practicalirrigationrecordId,
      this.farmcropId,
      this.date,
      this.stage,
      this.dischargehours,
      this.irrtotal,
      this.agebyday,
      this.gas,
      this.gasprice});

  factory IdealGridObject.fromJson(Map<String, dynamic> json) {
    return IdealGridObject(
      practicalirrigationrecordId:
          json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6, 19)) ?? 0),
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
List<PREVIOUSDailyRecordsObject> parsePREVIOUSDailyRecords(
    String responseBody) {
  var temp = jsonDecode(responseBody);
  var temp2 = temp['Data'];
  var temp3 = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed
      .map<PREVIOUSDailyRecordsObject>(
          (json) => PREVIOUSDailyRecordsObject.fromJson(json))
      .toList();
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
  PREVIOUSDailyRecordsObject(
      {this.dailyrecordId,
      this.farmcropId,
      this.date,
      this.stage,
      this.eto,
      this.etc,
      this.pe,
      this.kc,
      this.irrday,
      this.agebyday,
      this.daystillharvest});

  factory PREVIOUSDailyRecordsObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSDailyRecordsObject(
      dailyrecordId: json['dailyrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6, 19)) ?? 0),
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
List<PREVIOUSPracticalGridObject> parsePREVIOUSPracticalGrid(
    String responseBody) {
  var temp = jsonDecode(responseBody);
  var temp2 = temp['Data'];
  var temp3 = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed
      .map<PREVIOUSPracticalGridObject>(
          (json) => PREVIOUSPracticalGridObject.fromJson(json))
      .toList();
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
  PREVIOUSPracticalGridObject(
      {this.practicalirrigationrecordId,
      this.farmcropId,
      this.date,
      this.stage,
      this.dischargehours,
      this.irrtotal,
      this.agebyday,
      this.gas,
      this.gasprice});

  factory PREVIOUSPracticalGridObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSPracticalGridObject(
      practicalirrigationrecordId:
          json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6, 19)) ?? 0),
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
  var temp = jsonDecode(responseBody);
  var temp2 = temp['Data'];
  var temp3 = jsonEncode(temp2);
  final parsed = jsonDecode(temp3).cast<Map<String, dynamic>>();

  return parsed
      .map<PREVIOUSIdealGridObject>(
          (json) => PREVIOUSIdealGridObject.fromJson(json))
      .toList();
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
  PREVIOUSIdealGridObject(
      {this.practicalirrigationrecordId,
      this.farmcropId,
      this.date,
      this.stage,
      this.dischargehours,
      this.irrtotal,
      this.agebyday,
      this.gas,
      this.gasprice});

  factory PREVIOUSIdealGridObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSIdealGridObject(
      practicalirrigationrecordId:
          json['practicalirrigationrecordId'].toString(),
      farmcropId: json['farmcropId'].toString().trim(),
      date: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(json['date'].substring(6, 19)) ?? 0),
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

  return parsed
      .map<FarmcropFilterObject>((json) => FarmcropFilterObject.fromJson(json))
      .toList();
}

class FarmcropFilterObject {
  String? farmcropId;
  String? Text;
  FarmcropFilterObject({
    this.farmcropId,
    this.Text,
  });

  factory FarmcropFilterObject.fromJson(Map<String, dynamic> json) {
    return FarmcropFilterObject(
      farmcropId: json['farmcropId'].toString().trim(),
      Text: json['Text'].toString(),
    );
  }
}

/////////////////////////////  PREVIOUSFarmcropFilter  /////////////////////////
List<PREVIOUSFarmcropFilterObject> parsePREVIOUSFarmcropFilter(
    String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed
      .map<PREVIOUSFarmcropFilterObject>(
          (json) => PREVIOUSFarmcropFilterObject.fromJson(json))
      .toList();
}

class PREVIOUSFarmcropFilterObject {
  String? farmcropId;
  String? Text;
  PREVIOUSFarmcropFilterObject({
    this.farmcropId,
    this.Text,
  });

  factory PREVIOUSFarmcropFilterObject.fromJson(Map<String, dynamic> json) {
    return PREVIOUSFarmcropFilterObject(
      farmcropId: json['farmcropId'].toString().trim(),
      Text: json['Text'].toString(),
    );
  }
}

/////////////// DIALOGS ////////////////////////
class MyConfirmDateDialog extends StatefulWidget {
  final BuildContext mainContext;
  final int farmcropId;
  final int farmid;
  final DateTime lastIrrigationDate;

  MyConfirmDateDialog(
      this.mainContext, this.farmcropId, this.farmid, this.lastIrrigationDate);

  @override
  _confirmDateState createState() => new _confirmDateState(
      mainContext, farmcropId, farmid, lastIrrigationDate);
}

class _confirmDateState extends State<MyConfirmDateDialog> {
  var datecontoler = TextEditingController();
  DateTime? confirmDate = null;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  BuildContext mainContext;
  int farmcropId;

  int farmid;

  _confirmDateState(
      this.mainContext, this.farmcropId, this.farmid, this.confirmDate);
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
          showIrrigateDialog(
              mainContext, farmcropId, formatter.format(confirmDate!), farmid);
        }
      },
    );

    return AlertDialog(
      title: Text(
        "من فضلك قم بتأكيد اخر موعد للري",
        textAlign: TextAlign.center,
      ),
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
            onTap: () {
              showDatePicker(
                  context: context,
                      initialDate:
                          confirmDate == null ? DateTime.now() : confirmDate,
                  firstDate: DateTime.now().add(Duration(days: -200)),
                      lastDate: DateTime.now())
                  .then((value) {
                setState(() {
                  confirmDate = value;
                });
              });
            },
            child: Text(
              confirmDate == null
                  ? "اختر التاريخ"
                  : formatter.format(confirmDate!),
              style: TextStyle(decoration: TextDecoration.underline),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [cancelButton, submitButton],
    );
  }

  showIrrigateDialog(BuildContext context, int myfarmcropid,
      String updatelastirrigationdate, int farmid) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return MyIrrigateDialog(
              myfarmcropid, updatelastirrigationdate, farmid);
        },
        barrierDismissible: true);
  }
}

class AreYouSureDialog extends StatefulWidget {
  BuildContext? mainContext;

  int? farmcropId;

  int? farmid;
  DateTime? lastIrrigationDate;

  AreYouSureDialog(this.farmcropId, this.farmid);

  @override
  _AreYouSureDialogState createState() =>
      new _AreYouSureDialogState(farmcropId!, this.farmid!);
}

class _AreYouSureDialogState extends State<AreYouSureDialog> {
  var datecontoler = TextEditingController();
  DateTime? confirmDate = null;
  final DateFormat formatter = DateFormat('yyyy/MM/dd');

  //BuildContext mainContext;
  int farmcropId;
  bool deleting = false;

  int farmid;

  _AreYouSureDialogState(this.farmcropId, this.farmid);
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
        
        try {
          String result = await deleteFarmCropASYNC(farmcropId.toString());
          
          if (result == 'success') {
            Fluttertoast.showToast(
              msg: "تم حذف المحصول بنجاح",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            
            // Close the dialog and navigate back to farm crops
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(goToFarmCrops(farmid));
          } else {
            Fluttertoast.showToast(
              msg: "فشل حذف المحصول: $result",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            
            setState(() {
              deleting = false;
            });
          }
        } catch (e) {
          Fluttertoast.showToast(
            msg: "حدث خطأ أثناء حذف المحصول: $e",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          
          setState(() {
            deleting = false;
          });
        }
      },
    );

    return AlertDialog(
      title: Text("مسح المحصول"),
      content: deleting
          ? Center(child: CircularProgressIndicator())
          : Text("هل تريد مسح المحصول؟"),
      actions: deleting
          ? []
          : [
        cancelButton,
        continueButton,
      ],
    );
  }

  showIrrigateDialog(BuildContext context, int myfarmcropid,
      String updatelastirrigationdate, int farmid) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return MyIrrigateDialog(
              myfarmcropid, updatelastirrigationdate, farmid);
        },
        barrierDismissible: true);
  }
}

class MyIrrigateDialog extends StatefulWidget {
  final String updatelastirrigationdate;
  final int myfarmcropid;
  final int farmid;

  MyIrrigateDialog(
      this.myfarmcropid, this.updatelastirrigationdate, this.farmid);

  @override
  _IrrigateState createState() =>
      new _IrrigateState(myfarmcropid, updatelastirrigationdate, farmid);
}

class _IrrigateState extends State<MyIrrigateDialog> {
  final DateFormat formatter = DateFormat('yyyy/MM/dd');
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
      title: Text("احتياجات الري", textAlign: TextAlign.center),
      content: Container(
        width: double.maxFinite,
        child: FutureBuilder<String>(
          future: fetchIrrigation(
              http.Client(), myfarmcropid, updatelastirrigationdate),
          builder: (context, snapshot) {
            // Show loading indicator while waiting
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل بيانات الري...', 
                           style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            }
            
            // Handle errors
            if (snapshot.hasError) {
              return Container(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text('خطأ في تحميل البيانات', 
                           style: TextStyle(fontSize: 16, color: Colors.red)),
                    ],
                  ),
                ),
              );
            }
            
            // Handle data
            if (snapshot.hasData) {
              String data = snapshot.data!;
              
              if (data == 'wrong date') {
                return Container(
                  height: 200,
                  child: Center(
                    child: Text('التاريخ لا يمكن ان يسبق تاريخ الزراعة', 
                               style: TextStyle(fontSize: 16, color: Colors.red),
                               textAlign: TextAlign.center),
                  ),
                );
              } else if (data == 'wrong id') {
                return Container(
                  height: 200,
                  child: Center(
                    child: Text('لا يوجد هذا المحصول', 
                               style: TextStyle(fontSize: 16, color: Colors.red),
                               textAlign: TextAlign.center),
                  ),
                );
              } else if (data == 'wrong user') {
                return Container(
                  height: 200,
                  child: Center(
                    child: Text('اعد تسجيل الدخول', 
                               style: TextStyle(fontSize: 16, color: Colors.red),
                               textAlign: TextAlign.center),
                  ),
                );
              } else {
                // Parse and display the data
                try {
                  Map<String, dynamic> jsonData = jsonDecode(data);
                  String hrs = jsonData['dischargehours'].toString();
                  double hrsToDecimal = double.tryParse(hrs) ?? 0;

                  int hoursOnly = hrsToDecimal.floor();
                  int minits = ((hrsToDecimal - hoursOnly) * 60).round();
                  String hrsAndMinStr = '';
                  if (hoursOnly != 0) {
                    hrsAndMinStr += hoursOnly.toString() + ' ساعة ';
                  }
                  if (hoursOnly != 0 && minits != 0) {
                    hrsAndMinStr += " و ";
                  }
                  if (minits != 0) {
                    hrsAndMinStr += minits.toString() + ' دقائق ';
                  }
                  
                  return Container(
                    height: 350,
                    child: Scrollbar(
                      child: ListView(
                        children: [
                          Text(
                            'اجمالي المياه المطلوبة للري',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            jsonData['irrtotal'].toString() + ' متر مكعب ',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'عدد ساعات تشغيل الطلمبة',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            hrsAndMinStr,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'استهلاك الوقود',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            jsonData['gas'].toString() + ' لتر ',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'سعر الوقود المستهلك',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            jsonData['gasprice'].toString() + ' جنيه ',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'هل ستروي اليوم؟',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  return Container(
                    height: 200,
                    child: Center(
                      child: Text('خطأ في تحليل البيانات', 
                                 style: TextStyle(fontSize: 16, color: Colors.red),
                                 textAlign: TextAlign.center),
                    ),
                  );
                }
              }
            }
            
            // Default fallback
            return Container(
              height: 200,
              child: Center(
                child: Text('لا توجد بيانات', 
                           style: TextStyle(fontSize: 16),
                           textAlign: TextAlign.center),
              ),
            );
          },
        ),
      ),
      actions: [cancelButton, submitButton],
    );
  }
}

class AddFarmCropDialog extends StatefulWidget {
  final List<cropObject> cropTypes;
  final List<MeasringObject> measures;
  final List<irrigationMethodObject> irrigationMethods;
  final int farmid;

  //AddFarmCropDialog(this.myfarmcropid, this.updatelastirrigationdate, this.farmid);
  AddFarmCropDialog(
      this.cropTypes, this.irrigationMethods, this.measures, this.farmid);

  @override
  _AddFarmCropState createState() => new _AddFarmCropState(
      this.cropTypes, this.irrigationMethods, this.measures, this.farmid);
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
  TextEditingController lastIrrigationDateController =
      new TextEditingController();
  DateTime? plantingDate = null;
  DateTime? lastIrrigationDate = null;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();

  int farmid;

  _AddFarmCropState(this.allcroptypes, this.irrigationMethods,
      this.measuringUnits, this.farmid);
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
        if (!formkey.currentState!.validate()) {
          // Ensure form validation
          return;
        }

        setState(() {
          loading = true;
          formkey.currentState!.save();
        });

        try {
          apiLog('=== SUBMITTING ADD FARMCROP ===');
          apiLog(
              'Crop Type: ${croptypeobject?.name} (ID: ${croptypeobject?.cropId})');
          apiLog('Farm ID: $farmid');
          apiLog(
              'Irrigation Method: ${irrigationMethod?.name} (ID: ${irrigationMethod?.irrigationmethodId})');
          apiLog('Initial Irrigation Hours: $initialIrrigationHours');
          apiLog('Mashtal: $mashtal');
          apiLog('Shara2y: $shara2y');
          apiLog(
              'Measuring Unit: ${measuringunit?.name} (ID: ${measuringunit?.measuringunitId})');
          apiLog('Area: $area');
          apiLog(
              'Planting Date: ${plantingDate != null ? formatter.format(plantingDate!) : 'NULL'}');
          apiLog(
              'Last Irrigation Date: ${lastIrrigationDate != null ? formatter.format(lastIrrigationDate!) : 'NULL'}');
          apiLog('================================');

        String result = await addFarmCropASYNC(
          croptypeobject!.cropId!,
          farmid.toString(),
          irrigationMethod!.irrigationmethodId!,
            initialIrrigationHours ?? '0',
            mashtal ?? '0',
            shara2y ?? '0',
          measuringunit!.measuringunitId!,
          area!,
          formatter.format(plantingDate!),
          formatter.format(lastIrrigationDate!),
        );

          apiLog('=== ADD FARMCROP RESULT ===');
          apiLog('Result: $result');
          apiLog('==========================');

          // Show appropriate message based on result
          String message;
          Color backgroundColor;

          if (result == 'success') {
            message = "تم اضافة المحصول بنجاح";
            backgroundColor = Colors.green;
          } else if (result.contains('يرجى إعادة تسجيل الدخول')) {
            message = "انتهت صلاحية الجلسة، يرجى إعادة تسجيل الدخول";
            backgroundColor = Colors.orange;
          } else if (result.contains('انتهت مهلة الاتصال')) {
            message = "انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى";
            backgroundColor = Colors.orange;
          } else if (result.contains('خطأ في الاتصال')) {
            message = "خطأ في الاتصال بالخادم، تحقق من اتصال الإنترنت";
            backgroundColor = Colors.red;
          } else {
            message = "فشل اضافة المحصول: $result";
            backgroundColor = Colors.red;
          }

        Fluttertoast.showToast(
            msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
            backgroundColor: backgroundColor,
          textColor: Colors.white,
          fontSize: 16.0,
        );

          // Only navigate if successful
          if (result == 'success') {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(goToFarmCrops(farmid));
          } else {
            // Reset loading state on error
            setState(() {
              loading = false;
            });
          }
        } catch (e) {
          apiLog('=== ADD FARMCROP DIALOG ERROR ===');
          apiLog('Error: $e');
          apiLog('Error type: ${e.runtimeType}');
          apiLog('===============================');

          Fluttertoast.showToast(
            msg: "حدث خطأ غير متوقع: $e",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          setState(() {
            loading = false;
          });
        }
      },
    );
    return AlertDialog(
      title: const Text("إضافة محصول جديد"),
      content: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Form(
            key: formkey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
                    children: [
              Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .teal, // Use `backgroundColor` instead of `color`
                    padding: EdgeInsets.all(0),
                  ),
                            child: FaIcon(FontAwesomeIcons.calendar,
                                color: Colors.white),
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: plantingDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(Duration(days: 200)),
                      lastDate: DateTime.now(),
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          plantingDate = value;
                                    plantingDateController.text =
                                        formatter.format(value);
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
                                  decoration: InputDecoration(
                                      labelText: 'تاريخ الزراعة',
                                      focusColor: Color(0xff26a69a)),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                            return "برجاء ادخال تاريخ الزراعة";
                          }
                                    return null;
                        },
                        onTap: () {
                          showDatePicker(
                              context: context,
                                            initialDate: plantingDate == null
                                                ? DateTime.now()
                                                : plantingDate,
                                            firstDate: DateTime.now()
                                                .add(Duration(days: -200)),
                                            lastDate: DateTime.now())
                                        .then((value) {
                            setState(() {
                              plantingDate = value;
                                        plantingDateController.text =
                                            formatter.format(value!);
                              //mydate = formatter.format(value);
                            });
                          });
                        },
                                  onSaved: (String? value) {
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
                              backgroundColor: Colors
                                  .teal, // Use `backgroundColor` instead of `color`
                      padding: EdgeInsets.all(0),
                    ),
                            child: FaIcon(FontAwesomeIcons.calendar,
                                color: Colors.white),
                    onPressed: () {
                      showDatePicker(
                        context: context,
                                initialDate:
                                    lastIrrigationDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(Duration(days: 200)),
                        lastDate: DateTime.now(),
                      ).then((value) {
                        if (value != null) {
                          setState(() {
                            lastIrrigationDate = value;
                                    lastIrrigationDateController.text =
                                        formatter.format(value);
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
                                  decoration: InputDecoration(
                                      labelText: 'تاريخ اخر رية',
                                      focusColor: Color(0xff26a69a)),
                                  validator: (String? value) {
                                    if (value!.isEmpty) {
                              return "برجاء ادخال تاريخ اخر رية";
                            }
                          },
                          onTap: () {
                            showDatePicker(
                                context: context,
                                            initialDate:
                                                lastIrrigationDate == null
                                                    ? DateTime.now()
                                                    : lastIrrigationDate,
                                            firstDate: DateTime.now()
                                                .add(Duration(days: -200)),
                                            lastDate: DateTime.now())
                                        .then((value) {
                              setState(() {
                                lastIrrigationDate = value;
                                        lastIrrigationDateController.text =
                                            formatter.format(value!);
                                //mydate = formatter.format(value);
                              });
                            });
                          },
                                  onSaved: (String? value) {
                            //farmname = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<cropObject>(
                        validator: (cropObject? value) {
                          if (value == null) {
                    return "اختر نوع المحصول";
                  }
                          return null;
                },
                        onSaved: (cropObject? value) {
                  croptypeobject = value;
                },
                isExpanded: true,
                value: croptypeobject,
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                        style: TextStyle(color: Colors.black, fontSize: 18),
                onChanged: (cropObject? newValue) {
                  this.croptypeobject = newValue;
                          if (croptypeobject!.name!.indexOf('رز') >= 0) {
                    rice = true;
                          } else {
                    rice = false;
                    shara2y = null;
                    mashtal = null;
                  }
                          setState(() {});
                },
                hint: Text('اختر نوع المحصول'),
                        items: allcroptypes.map<DropdownMenuItem<cropObject>>(
                            (cropObject value) {
                  return DropdownMenuItem<cropObject>(
                    value: value,
                    child: Text(value.name!),
                  );
                }).toList(),
              ),
              DropdownButtonFormField<irrigationMethodObject>(
                        validator: (irrigationMethodObject? value) {
                          if (value == null) {
                    return "اختر نوع الري";
                  }
                },
                        onSaved: (irrigationMethodObject? value) {
                  irrigationMethod = value;
                },
                isExpanded: true,
                value: irrigationMethod,
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                        style: TextStyle(color: Colors.black, fontSize: 18),
                onChanged: (irrigationMethodObject? newValue) {
                  this.irrigationMethod = newValue;
                          setState(() {});
                },
                hint: Text('اختر نوع الري'),
                items: irrigationMethods
                            .map<DropdownMenuItem<irrigationMethodObject>>(
                                (irrigationMethodObject value) {
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
                                  decoration: InputDecoration(
                                      labelText: 'المساحة المزروعة',
                                      focusColor: Color(0xff26a69a)),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                              return "برجاء ادخال المساحة";
                            }
                                    return null;
                          },
                                  onSaved: (String? value) {
                            area = value;
                          },
                                  inputFormatters: [
                                    DecimalTextInputFormatter(decimalRange: 2)
                                  ],
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        DropdownButtonFormField<MeasringObject>(
                                  validator: (MeasringObject? value) {
                                    if (value == null) {
                              return "اختر الوحدة";
                            }
                          },
                                  onSaved: (MeasringObject? value) {
                            measuringunit = value;
                          },
                          isExpanded: true,
                          value: measuringunit,
                          icon: Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                          elevation: 16,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                          onChanged: (MeasringObject? newValue) {
                            this.measuringunit = newValue;
                                    setState(() {});
                          },
                          hint: Text('اختر الوحدة'),
                          items: measuringUnits
                                      .map<DropdownMenuItem<MeasringObject>>(
                                          (MeasringObject value) {
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
                        decoration: InputDecoration(
                            labelText: 'عدد ساعات رية الزراعه',
                            focusColor: Color(0xff26a69a)),
                        onSaved: (String? value) {
                  initialIrrigationHours = value;
                },
                        inputFormatters: [
                          DecimalTextInputFormatter(decimalRange: 2)
                        ],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      if (rice)
            TextFormField(
        style: TextStyle(fontFamily: 'OpenSans'),
        //initialValue: 'a7a ya gedy',
        cursorColor: Color(0xff26a69a),
                          decoration: InputDecoration(
                              labelText: 'عدد ساعات ري المشتل',
                              focusColor: Color(0xff26a69a)),
                          onSaved: (String? value) {
          mashtal = value;
        },
                          inputFormatters: [
                            DecimalTextInputFormatter(decimalRange: 2)
                          ],
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      if (rice)
    TextFormField(
      style: TextStyle(fontFamily: 'OpenSans'),
      //initialValue: 'a7a ya gedy',
      cursorColor: Color(0xff26a69a),
                          decoration: InputDecoration(
                              labelText: 'عدد ساعات طفي الشراقي',
                              focusColor: Color(0xff26a69a)),
                          onSaved: (String? value) {
        shara2y = value;
      },
                          inputFormatters: [
                            DecimalTextInputFormatter(decimalRange: 2)
                          ],
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
    ),
    ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () async {
            print('\n=== ADD CROP BUTTON PRESSED ===');
            if (formkey.currentState!.validate()) {
              setState(() {
                loading = true;
              });

              // Save the form data
              formkey.currentState!.save();

              print('Collected Form Data:');
              print(
                  'Crop Type: ${croptypeobject?.name} (ID: ${croptypeobject?.cropId})');
              print('Farm ID: $farmid');
              print(
                  'Irrigation Method: ${irrigationMethod?.name} (ID: ${irrigationMethod?.irrigationmethodId})');
              print('Initial Irrigation Hours: $initialIrrigationHours');
              print('Mashtal: $mashtal');
              print('Sharaky: $shara2y');
              print(
                  'Measuring Unit: ${measuringunit?.name} (ID: ${measuringunit?.measuringunitId})');
              print('Area: $area');
              print(
                  'Planting Date: ${plantingDate != null ? formatter.format(plantingDate!) : "NULL"}');
              print(
                  'Last Irrigation Date: ${lastIrrigationDate != null ? formatter.format(lastIrrigationDate!) : "NULL"}');

              try {
                String result = await addFarmCropASYNC(
                  croptypeobject!.cropId!,
                  farmid.toString(),
                  irrigationMethod!.irrigationmethodId!,
                  initialIrrigationHours ?? '0',
                  mashtal ?? '0',
                  shara2y ?? '0',
                  measuringunit!.measuringunitId!,
                  area!,
                  formatter.format(plantingDate!),
                  formatter.format(lastIrrigationDate!),
                );

                print('\n=== ADD CROP RESULT ===');
                print('Result: $result');

                if (result == 'success') {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(goToFarmCrops(farmid));
                } else {
                  Fluttertoast.showToast(
                    msg: result,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
              } catch (e) {
                print('\n=== ADD CROP ERROR ===');
                print('Error: $e');
                Fluttertoast.showToast(
                  msg: 'حدث خطأ أثناء إضافة المحصول',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              } finally {
                setState(() {
                  loading = false;
                });
              }
            }
          },
          child: loading
              ? CircularProgressIndicator(color: Colors.white)
              : const Text("حفظ"),
        ),
      ],
    );
    // return AlertDialog(
    //   title: Text("اضافة محصول", textAlign: TextAlign.center,),
    //   content: loading? Center(child: CircularProgressIndicator()) : Form(
    //     key: formkey,
    //     child: Container(
    //       height: 350,
    //       child: Scrollbar(
    //         child: ListView(
    //           children: [
    //             Row(
    //               crossAxisAlignment: CrossAxisAlignment.end,
    //               children: [
    //                 ElevatedButton(
    //                   style: ElevatedButton.styleFrom(
    //                     backgroundColor: Colors.teal, // Use `backgroundColor` instead of `color`
    //                     padding: EdgeInsets.all(0),
    //                   ),
    //                   child: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
    //                   onPressed: () {
    //                     showDatePicker(
    //                       context: context,
    //                       initialDate: plantingDate ?? DateTime.now(),
    //                       firstDate: DateTime.now().subtract(Duration(days: 200)),
    //                       lastDate: DateTime.now(),
    //                     ).then((value) {
    //                       if (value != null) {
    //                         setState(() {
    //                           plantingDate = value;
    //                           plantingDateController.text = formatter.format(value);
    //                         });
    //                       }
    //                     });
    //                   },
    //                 ),
    //
    //                 SizedBox(width: 10),
    //                 Expanded(
    //                   child: Column(
    //                     children: [
    //                       TextFormField(
    //                           style: TextStyle(fontFamily: 'OpenSans'),
    //                         //initialValue: 'a7a ya gedy',
    //                         controller: plantingDateController,
    //                         cursorColor: Color(0xff26a69a),
    //                         //enabled: false,
    //                         readOnly: true,
    //                         decoration: InputDecoration(labelText: 'تاريخ الزراعة',focusColor: Color(0xff26a69a)),
    //                         validator: (String? value){
    //                           if(value!.isEmpty){
    //                             return "برجاء ادخال تاريخ الزراعة";
    //                           }
    //                         },
    //                         onTap: () {
    //                           showDatePicker(
    //                               context: context,
    //                               initialDate: plantingDate == null ? DateTime.now() : plantingDate,
    //                               firstDate: DateTime.now().add(Duration(days: -200)),
    //                               lastDate: DateTime.now()).then((value){
    //                             setState(() {
    //                               plantingDate = value;
    //                               plantingDateController.text = formatter.format(value!);
    //                               //mydate = formatter.format(value);
    //                             });
    //                           });
    //                         },
    //                         onSaved: (String? value){
    //                           //farmname = value;
    //                         },
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             Row(
    //               crossAxisAlignment: CrossAxisAlignment.end,
    //               children: [
    //                 ElevatedButton(
    //                   style: ElevatedButton.styleFrom(
    //                     backgroundColor: Colors.teal, // Use `backgroundColor` instead of `color`
    //                     padding: EdgeInsets.all(0),
    //                   ),
    //                   child: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
    //                   onPressed: () {
    //                     showDatePicker(
    //                       context: context,
    //                       initialDate: lastIrrigationDate ?? DateTime.now(),
    //                       firstDate: DateTime.now().subtract(Duration(days: 200)),
    //                       lastDate: DateTime.now(),
    //                     ).then((value) {
    //                       if (value != null) {
    //                         setState(() {
    //                           lastIrrigationDate = value;
    //                           lastIrrigationDateController.text = formatter.format(value);
    //                         });
    //                       }
    //                     });
    //                   },
    //                 ),
    //
    //                 SizedBox(width: 10),
    //                 Expanded(
    //                   child: Column(
    //                     children: [
    //                       TextFormField(
    //                           style: TextStyle(fontFamily: 'OpenSans'),
    //                         //initialValue: 'a7a ya gedy',
    //                         controller: lastIrrigationDateController,
    //                         cursorColor: Color(0xff26a69a),
    //                         //enabled: false,
    //                         readOnly: true,
    //                         decoration: InputDecoration(labelText: 'تاريخ اخر رية',focusColor: Color(0xff26a69a)),
    //                         validator: (String? value){
    //                           if(value!.isEmpty){
    //                             return "برجاء ادخال تاريخ اخر رية";
    //                           }
    //                         },
    //                         onTap: () {
    //                           showDatePicker(
    //                               context: context,
    //                               initialDate: lastIrrigationDate == null ? DateTime.now() : lastIrrigationDate,
    //                               firstDate: DateTime.now().add(Duration(days: -200)),
    //                               lastDate: DateTime.now()).then((value){
    //                             setState(() {
    //                               lastIrrigationDate = value;
    //                               lastIrrigationDateController.text = formatter.format(value!);
    //                               //mydate = formatter.format(value);
    //                             });
    //                           });
    //                         },
    //                         onSaved: (String? value){
    //                           //farmname = value;
    //                         },
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             DropdownButtonFormField<cropObject>(
    //               validator: (cropObject? value){
    //                 if(value == null){
    //                   return "اختر نوع المحصول";
    //                 }
    //               },
    //               onSaved: (cropObject? value){
    //                 croptypeobject = value;
    //               },
    //               isExpanded: true,
    //               value: croptypeobject,
    //               icon: Icon(Icons.arrow_drop_down),
    //               iconSize: 24,
    //               elevation: 16,
    //               style: TextStyle(color: Colors.black,fontSize: 18),
    //               onChanged: (cropObject? newValue) {
    //                 this.croptypeobject = newValue;
    //                 if(croptypeobject!.name!.indexOf('رز') >= 0){
    //                   rice = true;
    //                 }else{
    //                   rice = false;
    //                   shara2y = null;
    //                   mashtal = null;
    //                 }
    //                 setState(() {
    //                 });
    //               },
    //               hint: Text('اختر نوع المحصول'),
    //               items: allcroptypes
    //                   .map<DropdownMenuItem<cropObject>>((cropObject value) {
    //                 return DropdownMenuItem<cropObject>(
    //                   value: value,
    //                   child: Text(value.name!),
    //                 );
    //               }).toList(),
    //             ),
    //             DropdownButtonFormField<irrigationMethodObject>(
    //               validator: (irrigationMethodObject? value){
    //                 if(value == null){
    //                   return "اختر نوع الري";
    //                 }
    //               },
    //               onSaved: (irrigationMethodObject? value){
    //                 irrigationMethod = value;
    //               },
    //               isExpanded: true,
    //               value: irrigationMethod,
    //               icon: Icon(Icons.arrow_drop_down),
    //               iconSize: 24,
    //               elevation: 16,
    //               style: TextStyle(color: Colors.black,fontSize: 18),
    //               onChanged: (irrigationMethodObject? newValue) {
    //                 this.irrigationMethod = newValue;
    //                 setState(() {
    //                 });
    //               },
    //               hint: Text('اختر نوع الري'),
    //               items: irrigationMethods
    //                   .map<DropdownMenuItem<irrigationMethodObject>>((irrigationMethodObject value) {
    //                 return DropdownMenuItem<irrigationMethodObject>(
    //                   value: value,
    //                   child: Text(value.name!),
    //                 );
    //               }).toList(),
    //             ),
    //             Row(
    //               crossAxisAlignment: CrossAxisAlignment.end,
    //               children: [
    //                 Expanded(
    //                   child: Column(
    //                     children: [
    //                       TextFormField(
    //                           style: TextStyle(fontFamily: 'OpenSans'),
    //                         //initialValue: 'a7a ya gedy',
    //                         cursorColor: Color(0xff26a69a),
    //                         decoration: InputDecoration(labelText: 'المساحة المزروعة',focusColor: Color(0xff26a69a)),
    //                         validator: (String? value){
    //                           if(value!.isEmpty){
    //                             return "برجاء ادخال المساحة";
    //                           }
    //                         },
    //                         onSaved: (String? value){
    //                           area = value;
    //                         },
    //                         inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
    //                         keyboardType: TextInputType.numberWithOptions(decimal: true),
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //                 SizedBox(width: 10),
    //                 Expanded(
    //                   child: Column(
    //                     children: [
    //                       DropdownButtonFormField<MeasringObject>(
    //                         validator: (MeasringObject? value){
    //                           if(value == null){
    //                             return "اختر الوحدة";
    //                           }
    //                         },
    //                         onSaved: (MeasringObject? value){
    //                           measuringunit = value;
    //                         },
    //                         isExpanded: true,
    //                         value: measuringunit,
    //                         icon: Icon(Icons.arrow_drop_down),
    //                         iconSize: 24,
    //                         elevation: 16,
    //                         style: TextStyle(color: Colors.black,fontSize: 18),
    //                         onChanged: (MeasringObject? newValue) {
    //                           this.measuringunit = newValue;
    //                           setState(() {
    //                           });
    //                         },
    //                         hint: Text('اختر الوحدة'),
    //                         items: measuringUnits
    //                             .map<DropdownMenuItem<MeasringObject>>((MeasringObject value) {
    //                           return DropdownMenuItem<MeasringObject>(
    //                             value: value,
    //                             child: Text(value.name!),
    //                           );
    //                         }).toList(),
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             TextFormField(
    //                           style: TextStyle(fontFamily: 'OpenSans'),
    //               //initialValue: 'a7a ya gedy',
    //               cursorColor: Color(0xff26a69a),
    //               decoration: InputDecoration(labelText: 'عدد ساعات رية الزراعه',focusColor: Color(0xff26a69a)),
    //               onSaved: (String? value){
    //                 initialIrrigationHours = value;
    //               },
    //               inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
    //               keyboardType: TextInputType.numberWithOptions(decimal: true),
    //             ),
    //             if(rice)
    //             TextFormField(
    //                           style: TextStyle(fontFamily: 'OpenSans'),
    //               //initialValue: 'a7a ya gedy',
    //               cursorColor: Color(0xff26a69a),
    //               decoration: InputDecoration(labelText: 'عدد ساعات ري المشتل',focusColor: Color(0xff26a69a)),
    //               onSaved: (String? value){
    //                 mashtal = value;
    //               },
    //               inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
    //               keyboardType: TextInputType.numberWithOptions(decimal: true),
    //             ),
    //             if(rice)
    //             TextFormField(
    //                           style: TextStyle(fontFamily: 'OpenSans'),
    //               //initialValue: 'a7a ya gedy',
    //               cursorColor: Color(0xff26a69a),
    //               decoration: InputDecoration(labelText: 'عدد ساعات طفي الشراقي',focusColor: Color(0xff26a69a)),
    //               onSaved: (String? value){
    //                 shara2y = value;
    //               },
    //               inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
    //               keyboardType: TextInputType.numberWithOptions(decimal: true),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    //   actions: loading?[]:[
    //     cancelButton,
    //     submitButton
    //   ],
    // );
  }
}

class EditFarmCropDialog extends StatefulWidget {
  final List<MeasringObject> measures;
  final List<irrigationMethodObject> irrigationMethods;
  final int farmid;
  final farmcropObject myfarmcrop;
  final BuildContext BASEcontext;

  //AddFarmCropDialog(this.myfarmcropid, this.updatelastirrigationdate, this.farmid);
  EditFarmCropDialog(
      {required this.irrigationMethods,
      required this.measures,
      required this.farmid,
      required this.myfarmcrop,
      required this.BASEcontext});

  @override
  _EditFarmCropState createState() => new _EditFarmCropState(
      irrigationMethods: this.irrigationMethods,
      measuringUnits: this.measures,
      farmid: this.farmid,
      myfarmcrop: this.myfarmcrop,
      BASEcontext: this.BASEcontext);
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
  TextEditingController lastIrrigationDateController =
      new TextEditingController();
  //DateTime plantingDate = null;
  DateTime? lastIrrigationDate = null;
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  farmcropObject? myfarmcrop;
  int? farmid;
  BuildContext? BASEcontext;

  _EditFarmCropState(
      {required this.irrigationMethods,
      required this.measuringUnits,
      required this.farmid,
      required this.myfarmcrop,
      required this.BASEcontext}) {
    rice = (myfarmcrop?.cropname?.indexOf('رز') ?? -1) >= 0;
    /*croptypeobject = allcroptypes[allcroptypes.indexWhere((element) {
      return element.name.trim() == myfarmcrop.cropname.trim();
    })];*/
    int irrigationIndex = irrigationMethods.indexWhere((element) {
      return element.name?.trim() == myfarmcrop?.irrigationmethodname?.trim();
    });
    irrigationMethod = irrigationIndex >= 0 ? irrigationMethods[irrigationIndex] : (irrigationMethods.isNotEmpty ? irrigationMethods[0] : null);
    
    int measuringIndex = measuringUnits.indexWhere((element) {
      return element.name?.trim() == myfarmcrop?.measuringunitname?.trim();
    });
    measuringunit = measuringIndex >= 0 ? measuringUnits[measuringIndex] : (measuringUnits.isNotEmpty ? measuringUnits[0] : null);
    lastIrrigationDate = myfarmcrop?.lastirrigationdate;
    //updatelastirrigationdate =formatter.format(myfarmcrop.lastirrigationdate);
    lastIrrigationDateController.text = myfarmcrop?.lastirrigationdate != null 
        ? formatter.format(myfarmcrop!.lastirrigationdate!)
        : '';
    area = myfarmcrop?.area?.toString() ?? '';
    initialIrrigationHours = myfarmcrop?.initirrigationhours?.toString() ?? '';
    mashtal = myfarmcrop?.irrigationmashtal?.toString() ?? '0';
    shara2y = myfarmcrop?.irrigtaionshraky?.toString() ?? '0';
  }
  showAreYouSureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AreYouSureDialog(this.myfarmcrop?.farmcropId ?? 0, this.farmid);
      },
    );
  }

  // set up the buttons
  @override
  Widget build(BuildContext context) {
    print('=== EDIT DIALOG BUILD ===');
    print('irrigationMethod: $irrigationMethod');
    print('measuringunit: $measuringunit');
    print('area: $area');
    print('initialIrrigationHours: $initialIrrigationHours');
    print('lastIrrigationDate: $lastIrrigationDate');
    print('========================');
    
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
        if (!formkey.currentState!.validate()) {
          // NOT VALID
          return;
        }
        setState(() {
          loading = true;
          formkey.currentState!.save();
        });

        String result = await editFarmCropASYNC(
          myfarmcrop?.farmcropId?.toString() ?? '0',
          irrigationMethod?.irrigationmethodId?.toString() ?? '0',
          measuringunit?.measuringunitId?.toString() ?? '0',
          area ?? '',
          initialIrrigationHours ?? '',
          mashtal ?? '0',
          shara2y ?? '0',
          lastIrrigationDate != null ? formatter.format(lastIrrigationDate!) : '',
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
      title: Text(
        "تعديل محصول",
        textAlign: TextAlign.center,
      ),
      content: loading
          ? Center(child: CircularProgressIndicator())
          : Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Form(
                key: formkey,
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
                            child: FaIcon(FontAwesomeIcons.calendar,
                                color: Colors.white),
            onPressed: () {
              showDatePicker(
                context: context,
                                initialDate:
                                    lastIrrigationDate ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(Duration(days: 200)),
                lastDate: DateTime.now(),
              ).then((value) {
                                if (value != null) {
                                  // Ensure value is not null
                  setState(() {
                    lastIrrigationDate = value;
                                    lastIrrigationDateController.text =
                                        formatter.format(value);
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
                                  decoration: InputDecoration(
                                      labelText: 'تاريخ اخر رية',
                                      focusColor: Color(0xff26a69a)),
                                  validator: (String? value) {
                                    if (value!.isEmpty) {
                                return "برجاء ادخال تاريخ اخر رية";
                              }
                            },
                            onTap: () {
                              showDatePicker(
                                  context: context,
                                            initialDate:
                                                lastIrrigationDate == null
                                                    ? DateTime.now()
                                                    : lastIrrigationDate,
                                            firstDate: DateTime.now()
                                                .add(Duration(days: -200)),
                                            lastDate: DateTime.now())
                                        .then((value) {
                                setState(() {
                                  lastIrrigationDate = value;
                                        lastIrrigationDateController.text =
                                            formatter.format(value!);
                                  //mydate = formatter.format(value);
                                });
                              });
                            },
                                  onSaved: (String? value) {
                              //farmname = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<irrigationMethodObject>(
                        validator: (irrigationMethodObject? value) {
                          if (value == null) {
                      return "اختر نوع الري";
                    }
                  },
                        onSaved: (irrigationMethodObject? value) {
                    irrigationMethod = value;
                  },
                  isExpanded: true,
                  value: irrigationMethod,
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                        style: TextStyle(color: Colors.black, fontSize: 18),
                  onChanged: (irrigationMethodObject? newValue) {
                    this.irrigationMethod = newValue;
                          setState(() {});
                  },
                  hint: Text('اختر نوع الري'),
                  items: irrigationMethods
                            .map<DropdownMenuItem<irrigationMethodObject>>(
                                (irrigationMethodObject value) {
                    return DropdownMenuItem<irrigationMethodObject>(
                      value: value,
                      child: Text(value.name ?? ''),
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
                                  decoration: InputDecoration(
                                      labelText: 'المساحة المزروعة',
                                      focusColor: Color(0xff26a69a)),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                return "برجاء ادخال المساحة";
                              }
                                    return null;
                            },
                                  onSaved: (String? value) {
                              area = value;
                            },
                                  inputFormatters: [
                                    DecimalTextInputFormatter(decimalRange: 2)
                                  ],
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          DropdownButtonFormField<MeasringObject>(
                                  validator: (MeasringObject? value) {
                                    if (value == null) {
                                return "اختر الوحدة";
                              }
                            },
                                  onSaved: (MeasringObject? value) {
                              measuringunit = value;
                            },
                            isExpanded: true,
                            value: measuringunit,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 18),
                            onChanged: (MeasringObject? newValue) {
                              this.measuringunit = newValue;
                                    setState(() {});
                            },
                            hint: Text('اختر الوحدة'),
                            items: measuringUnits
                                      .map<DropdownMenuItem<MeasringObject>>(
                                          (MeasringObject value) {
                              return DropdownMenuItem<MeasringObject>(
                                value: value,
                                child: Text(value.name ?? ''),
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
                        decoration: InputDecoration(
                            labelText: 'عدد ساعات رية الزراعه',
                            focusColor: Color(0xff26a69a)),
                        onSaved: (String? value) {
                    initialIrrigationHours = value;
                  },
                        inputFormatters: [
                          DecimalTextInputFormatter(decimalRange: 2)
                        ],
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      if (rice)
                  TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                    initialValue: mashtal,
                    cursorColor: Color(0xff26a69a),
                          decoration: InputDecoration(
                              labelText: 'عدد ساعات ري المشتل',
                              focusColor: Color(0xff26a69a)),
                          onSaved: (String? value) {
                      mashtal = value;
                    },
                          inputFormatters: [
                            DecimalTextInputFormatter(decimalRange: 2)
                          ],
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                        ),
                      if (rice)
                  TextFormField(
                              style: TextStyle(fontFamily: 'OpenSans'),
                    initialValue: shara2y,
                    cursorColor: Color(0xff26a69a),
                          decoration: InputDecoration(
                              labelText: 'عدد ساعات طفي الشراقي',
                              focusColor: Color(0xff26a69a)),
                          onSaved: (String? value) {
                      shara2y = value;
                    },
                          inputFormatters: [
                            DecimalTextInputFormatter(decimalRange: 2)
                          ],
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                  ),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red, // Button color
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15), // Optional padding
    ),
    onPressed: () {
    Navigator.of(context).pop();
    showAreYouSureDialog(BASEcontext!);
    },
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.delete, color: Colors.white, size: 35),
                            SizedBox(
                                width: 8), // Add spacing between icon and text
                            Text("مسح المحصول",
                                style: TextStyle(color: Colors.white)),
    ],
    ),
    ),
    // Fallback content to ensure dialog is never blank
    if (irrigationMethod == null || measuringunit == null)
      Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('خطأ في تحميل البيانات', style: TextStyle(fontSize: 16, color: Colors.red)),
            SizedBox(height: 10),
            Text('يرجى المحاولة مرة أخرى', style: TextStyle(fontSize: 14)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry by reopening the dialog
                showEditFarmCropDialog(
                  BASEcontext: BASEcontext!,
                  irrigationMethods: irrigationMethods,
                  measures: measuringUnits,
                  farmid: farmid!,
                  myfarmcrop: myfarmcrop!,
                );
              },
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    ],
            ),
          ),
        ),
      ),
      actions: loading ? [] : [cancelButton, submitButton],
    );
  }
}

Future<String> fetchIrrigation(http.Client client, int myfarmcropid,
    String updatelastirrigationdate) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  final response = await client.get(
    Uri.parse(
        'https://irwicrop.com/Home/updateLastIrrigationAndGetWaterReq?myfarmcropid=${myfarmcropid.toString()}&updatelastirrigationdate=$updatelastirrigationdate'),
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

Future<String> addFarmCropASYNC(
    String cropId,
    String farmId,
    String irrigationmethodId,
    String initirrigationhours,
    String irrigationmashtal,
    String irrigtaionshraky,
    String measuringunitId,
    String area,
    String plantingdate,
    String lastirrigationdate) async {
  print('\n=== ADD FARMCROP REQUEST START ===');
  print('Timestamp: ${DateTime.now()}');

  // Input validation
  if (cropId.isEmpty ||
      farmId.isEmpty ||
      irrigationmethodId.isEmpty ||
      measuringunitId.isEmpty ||
      area.isEmpty ||
      plantingdate.isEmpty ||
      lastirrigationdate.isEmpty) {
    print('\n=== ADD FARMCROP VALIDATION ERROR ===');
    print('Missing required parameters:');
    print('cropId: ${cropId.isEmpty ? "EMPTY" : cropId}');
    print('farmId: ${farmId.isEmpty ? "EMPTY" : farmId}');
    print(
        'irrigationmethodId: ${irrigationmethodId.isEmpty ? "EMPTY" : irrigationmethodId}');
    print(
        'measuringunitId: ${measuringunitId.isEmpty ? "EMPTY" : measuringunitId}');
    print('area: ${area.isEmpty ? "EMPTY" : area}');
    print('plantingdate: ${plantingdate.isEmpty ? "EMPTY" : plantingdate}');
    print(
        'lastirrigationdate: ${lastirrigationdate.isEmpty ? "EMPTY" : lastirrigationdate}');
    print('=====================================\n');
    return 'خطأ في البيانات المدخلة';
  }

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

  // Log the request data
  apiLog('=== ADD FARMCROP API REQUEST ===');
  apiLog('URL: https://irwicrop.com/Home/addfarmcrop');
  apiLog('Method: POST');
  apiLog('Request Data: $mydata');
  apiLog('===============================');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  // Log cookie information
  apiLog('=== COOKIE INFO ===');
  apiLog('Cookie length: ${cookie.length}');
  apiLog(
      'Cookie preview: ${cookie.isNotEmpty ? cookie.substring(0, math.min(50, cookie.length)) + '...' : 'EMPTY'}');
  apiLog('==================');

  try {
    print('\n=== ADD FARMCROP API CALL ===');
    print('Making POST request to: https://irwicrop.com/Home/addfarmcrop');
    print('Request Body: $mydata');

    final http.Response response = await http
        .post(
      Uri.parse('https://irwicrop.com/Home/addfarmcrop'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
    )
        .timeout(
      Duration(seconds: 30),
      onTimeout: () {
        print('\n=== ADD FARMCROP TIMEOUT ===');
        print('Request timed out after 30 seconds');
        print('============================\n');
        throw TimeoutException('Request timed out');
      },
    );

    print('\n=== ADD FARMCROP RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: ${response.body}');
    print('===========================\n');

    // Log the response
    apiLog('=== ADD FARMCROP API RESPONSE ===');
    apiLog('Status Code: ${response.statusCode}');
    apiLog('Response Headers: ${response.headers}');
    apiLog('Response Body: ${response.body}');
    apiLog('Response Body Length: ${response.body.length}');
    apiLog('================================');

    // Handle different response scenarios
    if (response.statusCode == 200) {
      // Success response
      if (response.body.toLowerCase().contains('success') ||
          response.body.toLowerCase().contains('تم') ||
          response.body.isEmpty) {
        apiLog('✅ Add farmcrop successful');
        return 'success';
      } else {
        apiLog('⚠️ Unexpected success response body: ${response.body}');
        return 'success'; // Still consider it success if status is 200
      }
    } else if (response.statusCode == 302) {
      // Redirect response (common in this API)
      String? location = response.headers['location'];
      apiLog('Redirect location: $location');

      if (location != null && location.contains('/Home/farmcrops/')) {
        apiLog('✅ Add farmcrop successful (redirect)');
        return 'success';
      } else {
        apiLog('⚠️ Unexpected redirect location: $location');
        return 'خطأ في إعادة التوجيه';
      }
    } else if (response.statusCode == 401) {
      apiLog('❌ Unauthorized - User not logged in');
      return 'يرجى إعادة تسجيل الدخول';
    } else if (response.statusCode == 400) {
      apiLog('❌ Bad Request - Invalid data');
      return 'بيانات غير صحيحة';
    } else if (response.statusCode == 500) {
      apiLog('❌ Server Error');
      return 'خطأ في الخادم';
    } else {
      apiLog('❌ Unexpected status code: ${response.statusCode}');
      return 'خطأ غير متوقع: ${response.statusCode}';
    }
  } catch (e) {
    apiLog('=== ADD FARMCROP ERROR ===');
    apiLog('Error type: ${e.runtimeType}');
    apiLog('Error message: $e');
    apiLog('==========================');

    if (e is TimeoutException) {
      return 'انتهت مهلة الاتصال';
    } else if (e is SocketException) {
      return 'خطأ في الاتصال بالخادم';
    } else {
      return 'خطأ غير متوقع: $e';
    }
  }
}

Future<String> editFarmCropASYNC(
    String farmcropId,
    String irrigationmethodId,
    String measuringunitId,
    String area,
    String initirrigationhours,
    String irrigationmashtal,
    String irrigtaionshraky,
    String lastirrigationdate) async {
  // Input validation
  if (farmcropId.isEmpty ||
      irrigationmethodId.isEmpty ||
      measuringunitId.isEmpty ||
      area.isEmpty ||
      lastirrigationdate.isEmpty) {
    apiLog('=== EDIT FARMCROP VALIDATION ERROR ===');
    apiLog('Missing required parameters');
    apiLog('farmcropId: $farmcropId');
    apiLog('irrigationmethodId: $irrigationmethodId');
    apiLog('measuringunitId: $measuringunitId');
    apiLog('area: $area');
    apiLog('lastirrigationdate: $lastirrigationdate');
    apiLog('=====================================');
    return 'خطأ في البيانات المدخلة';
  }

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

  // Log the request data
  apiLog('=== EDIT FARMCROP API REQUEST ===');
  apiLog('URL: https://irwicrop.com/Home/editfarmcrop');
  apiLog('Method: POST');
  apiLog('Request Data: $mydata');
  apiLog('===============================');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  // Log cookie information
  apiLog('=== COOKIE INFO ===');
  apiLog('Cookie length: ${cookie.length}');
  apiLog(
      'Cookie preview: ${cookie.isNotEmpty ? cookie.substring(0, math.min(50, cookie.length)) + '...' : 'EMPTY'}');
  apiLog('==================');

  try {
    final http.Response response = await http
        .post(
      Uri.parse('https://irwicrop.com/Home/editfarmcrop'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
    )
        .timeout(
      Duration(seconds: 30),
      onTimeout: () {
        apiLog('=== EDIT FARMCROP TIMEOUT ===');
        apiLog('Request timed out after 30 seconds');
        apiLog('============================');
        throw TimeoutException('Request timed out');
      },
    );

    // Log the response
    apiLog('=== EDIT FARMCROP API RESPONSE ===');
    apiLog('Status Code: ${response.statusCode}');
    apiLog('Response Headers: ${response.headers}');
    apiLog('Response Body: ${response.body}');
    apiLog('Response Body Length: ${response.body.length}');
    apiLog('================================');

    // Handle different response scenarios
    if (response.statusCode == 200) {
      // Success response
      if (response.body.toLowerCase().contains('success') ||
          response.body.toLowerCase().contains('تم') ||
          response.body.isEmpty) {
        apiLog('✅ Edit farmcrop successful');
      return 'success';
      } else {
        apiLog('⚠️ Unexpected success response body: ${response.body}');
        return 'success'; // Still consider it success if status is 200
      }
    } else if (response.statusCode == 302) {
      // Redirect response (common in this API)
      String? location = response.headers['location'];
      apiLog('Redirect location: $location');

      if (location != null && location.contains('/Home/farmcrops/')) {
        apiLog('✅ Edit farmcrop successful (redirect)');
        return 'success';
      } else {
        apiLog('⚠️ Unexpected redirect location: $location');
        return 'خطأ في إعادة التوجيه';
      }
    } else if (response.statusCode == 401) {
      apiLog('❌ Unauthorized - User not logged in');
      return 'يرجى إعادة تسجيل الدخول';
    } else if (response.statusCode == 400) {
      apiLog('❌ Bad Request - Invalid data');
      return 'بيانات غير صحيحة';
    } else if (response.statusCode == 500) {
      apiLog('❌ Server Error');
      return 'خطأ في الخادم';
    } else {
      apiLog('❌ Unexpected status code: ${response.statusCode}');
      return 'خطأ غير متوقع: ${response.statusCode}';
    }
  } catch (e) {
    apiLog('=== EDIT FARMCROP ERROR ===');
    apiLog('Error type: ${e.runtimeType}');
    apiLog('Error message: $e');
    apiLog('==========================');

    if (e is TimeoutException) {
      return 'انتهت مهلة الاتصال';
    } else if (e is SocketException) {
      return 'خطأ في الاتصال بالخادم';
    } else {
      return 'خطأ غير متوقع: $e';
    }
  }
}

Future<String> deleteFarmCropASYNC(String farmcropId) async {
  // Input validation
  if (farmcropId.isEmpty) {
    apiLog('=== DELETE FARMCROP VALIDATION ERROR ===');
    apiLog('Missing farmcropId parameter');
    apiLog('farmcropId: $farmcropId');
    apiLog('=====================================');
    return 'خطأ في البيانات المدخلة';
  }

  var mydata = jsonEncode({
    'farmcropId': farmcropId,
  });

  // Log the request data
  apiLog('=== DELETE FARMCROP API REQUEST ===');
  apiLog('URL: https://irwicrop.com/Home/deletefarmcrop');
  apiLog('Method: POST');
  apiLog('Request Data: $mydata');
  apiLog('===============================');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');

  // Log cookie information
  apiLog('=== COOKIE INFO ===');
  apiLog('Cookie length: ${cookie.length}');
  apiLog(
      'Cookie preview: ${cookie.isNotEmpty ? cookie.substring(0, math.min(50, cookie.length)) + '...' : 'EMPTY'}');
  apiLog('==================');

  try {
    final http.Response response = await http
        .post(
      Uri.parse('https://irwicrop.com/Home/deletefarmcrop'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
    )
        .timeout(
      Duration(seconds: 30),
      onTimeout: () {
        apiLog('=== DELETE FARMCROP TIMEOUT ===');
        apiLog('Request timed out after 30 seconds');
        apiLog('============================');
        throw TimeoutException('Request timed out');
      },
    );

    // Log the response
    apiLog('=== DELETE FARMCROP API RESPONSE ===');
    apiLog('Status Code: ${response.statusCode}');
    apiLog('Response Headers: ${response.headers}');
    apiLog('Response Body: ${response.body}');
    apiLog('Response Body Length: ${response.body.length}');
    apiLog('================================');

    // Handle different response scenarios
    if (response.statusCode == 200) {
      // Success response
      if (response.body.toLowerCase().contains('success') ||
          response.body.toLowerCase().contains('تم') ||
          response.body.isEmpty) {
        apiLog('✅ Delete farmcrop successful');
      return 'success';
      } else {
        apiLog('⚠️ Unexpected success response body: ${response.body}');
        return 'success'; // Still consider it success if status is 200
      }
    } else if (response.statusCode == 302) {
      // Redirect response (common in this API)
      String? location = response.headers['location'];
      apiLog('Redirect location: $location');

      if (location != null && location.contains('/Home/farmcrops/')) {
        apiLog('✅ Delete farmcrop successful (redirect)');
        return 'success';
      } else {
        apiLog('⚠️ Unexpected redirect location: $location');
        return 'خطأ في إعادة التوجيه';
      }
    } else if (response.statusCode == 401) {
      apiLog('❌ Unauthorized - User not logged in');
      return 'يرجى إعادة تسجيل الدخول';
    } else if (response.statusCode == 400) {
      apiLog('❌ Bad Request - Invalid data');
      return 'بيانات غير صحيحة';
    } else if (response.statusCode == 500) {
      apiLog('❌ Server Error');
      return 'خطأ في الخادم';
    } else {
      apiLog('❌ Unexpected status code: ${response.statusCode}');
      return 'خطأ غير متوقع: ${response.statusCode}';
    }
  } catch (e) {
    apiLog('=== DELETE FARMCROP ERROR ===');
    apiLog('Error type: ${e.runtimeType}');
    apiLog('Error message: $e');
    apiLog('==========================');

    if (e is TimeoutException) {
      return 'انتهت مهلة الاتصال';
    } else if (e is SocketException) {
      return 'خطأ في الاتصال بالخادم';
    } else {
      return 'خطأ غير متوقع: $e';
    }
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange})
      : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;
    var myDouble = double.tryParse(newValue.text);

    if (myDouble == null && newValue.text.isNotEmpty) {
      return oldValue;
    }

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
  }
