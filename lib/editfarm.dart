import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:irwi/login.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
// import 'package:permission/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math' as math;
import 'directory.dart';
import 'widgets/side_menu.dart';

Future<bool> editFarmASYNC(
    String name,
    String government,
    String soiltype,
    bool salty,
    double lng,
    double lat,
    double dischargerate,
    double gasuseage,
    double gasprice,
    int farmId,
    String cookie) async {
  if (soiltype == 'طينية') {
    soiltype = 'clay';
  } else if (soiltype == 'رملية') {
    soiltype = 'sandy';
  } else if (soiltype == 'سلتية') {
    soiltype = 'silt';
  }
  var mydata = jsonEncode({
    'name': name,
    'government': government,
    'soiltype': soiltype,
    'salty': salty,
    'lng': lng,
    'lat': lat,
    'dischargerate': dischargerate,
    'gasuseage': gasuseage,
    'gasprice': gasprice,
    'farmId': farmId,
  });

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Home/editfarm'), // Convert String to Uri
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
    if (response.headers['set-cookie'] == null) return true;
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

Future<bool> deleteFarmASYNC(int farmId, String cookie) async {
  var mydata = jsonEncode({
    'farmId': farmId,
  });

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Home/deletefarm'), // Convert String to Uri
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
    if (response.headers['set-cookie'] == null) return true;
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

Future<bool> logoutASYNC(String cookie) async {
  var mydata = jsonEncode({});

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Account/LogOff'), // Convert String to Uri
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body:
        mydata, // Ensure `mydata` is a valid String (use `jsonEncode` if needed)
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

class editfarm extends StatefulWidget {
  editfarm(this.farmid);

  final int farmid;
  @override
  _editfarmState createState() => _editfarmState(farmid);
}

class _editfarmState extends State<editfarm> {
  //To Require Permission
  bool checkedValue = false;
  bool salty = false;
  bool isLoading = false;
  bool movecamera = false;
  String? government = null;
  String? farmname = null;
  String? soiltype = null;
  String? dischargeUnit = null;
  double? dischargeRate = null;
  double? gasprice = null;
  double? gasusage = null;
  String confirmPass = '';
  String phone = '';
  String errorMessage = '';
  double Lat = 30.0444;
  double Lng = 31.235;
  bool addedInitialData = false;
  final MarkerId markerId = MarkerId('marker_id_1');
  final Marker marker = Marker(
    markerId: MarkerId('marker_id_1'),
    position: LatLng(30.0444, 31.235),
    infoWindow: InfoWindow(title: 'marker_id_1', snippet: '*'),
    onTap: () {
      //_onMarkerTapped(markerId);
      print('Marker Tapped');
    },
    onDragEnd: (LatLng position) {
      print('Drag Ended');
    },
  );
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{
    MarkerId('marker_id_1'): Marker(
      markerId: MarkerId('marker_id_1'),
      position: LatLng(30.0444, 31.235),
      infoWindow: InfoWindow(title: 'marker_id_1', snippet: '*'),
      onTap: () {
        //_onMarkerTapped(markerId);
        print('Marker Tapped');
      },
      onDragEnd: (LatLng position) {
        print('Drag Ended');
      },
    )
  };

  var farmid;

  _editfarmState(this.farmid);
  void _updatePosition(CameraPosition _position) {
    markers.update(
        MarkerId('marker_id_1'),
        (value) => Marker(
              markerId: MarkerId('marker_id_1'),
              position:
                  LatLng(_position.target.latitude, _position.target.longitude),
              infoWindow: InfoWindow(title: 'marker_id_1', snippet: '*'),
              onTap: () {
                //_onMarkerTapped(markerId);
                print('Marker Tapped');
              },
              onDragEnd: (LatLng position) {
                print('Drag Ended');
              },
            ));
    Lat = _position.target.latitude;
    Lng = _position.target.longitude;
    setState(() {});
  }

  var allGovernments = <String>[
    'محافظة الإسكندرية',
    'محافظة الإسماعيلية',
    'محافظة أسوان',
    'محافظة أسيوط',
    'محافظة الأقصر',
    'محافظة البحر الأحمر',
    'محافظة البحيرة',
    'محافظة بني سويف',
    'محافظة بورسعيد',
    'محافظة جنوب سيناء',
    'محافظة الجيزة',
    'محافظة الدقهلية',
    'محافظة دمياط',
    'محافظة سوهاج',
    'محافظة السويس',
    'محافظة الشرقية',
    'محافظة شمال سيناء',
    'محافظة الغربية',
    'محافظة الفيوم',
    'محافظة القاهرة',
    'محافظة القليوبية',
    'محافظة قنا',
    'محافظة كفر الشيخ',
    'محافظة مطروح',
    'محافظة المنوفية',
    'محافظة المنيا',
    'محافظة الوادي الجديد'
  ];
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final TextEditingController _pass = TextEditingController();
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition cairo = CameraPosition(
    target: LatLng(30.0444, 31.235),
    zoom: 7,
  );
  static final CameraPosition alex = CameraPosition(
    target: LatLng(30.8761, 29.7426),
    zoom: 7,
  );
  static final CameraPosition ismailya = CameraPosition(
    target: LatLng(30.5831, 32.2654),
    zoom: 7,
  );
  static final CameraPosition aswan = CameraPosition(
    target: LatLng(23.6966, 32.7181),
    zoom: 7,
  );
  static final CameraPosition asyout = CameraPosition(
    target: LatLng(27.2134, 31.4456),
    zoom: 7,
  );
  static final CameraPosition luxor = CameraPosition(
    target: LatLng(25.3944, 32.4920),
    zoom: 7,
  );
  static final CameraPosition redsea = CameraPosition(
    target: LatLng(24.6826, 34.1532),
    zoom: 7,
  );
  static final CameraPosition beheira = CameraPosition(
    target: LatLng(30.8481, 30.3436),
    zoom: 7,
  );
  static final CameraPosition benisuef = CameraPosition(
    target: LatLng(28.8939, 31.4456),
    zoom: 7,
  );
  static final CameraPosition portsaid = CameraPosition(
    target: LatLng(31.0759, 32.2654),
    zoom: 7,
  );
  static final CameraPosition southsinai = CameraPosition(
    target: LatLng(29.3102, 34.1532),
    zoom: 7,
  );
  static final CameraPosition giza = CameraPosition(
    target: LatLng(28.7666, 29.2321),
    zoom: 7,
  );
  static final CameraPosition dakahlia = CameraPosition(
    target: LatLng(31.1656, 31.4913),
    zoom: 7,
  );
  static final CameraPosition domyat = CameraPosition(
    target: LatLng(31.3626, 31.6739),
    zoom: 7,
  );
  static final CameraPosition sohag = CameraPosition(
    target: LatLng(26.6938, 32.1746),
    zoom: 7,
  );
  static final CameraPosition suez = CameraPosition(
    target: LatLng(29.3682, 32.1746),
    zoom: 7,
  );
  static final CameraPosition sharkia = CameraPosition(
    target: LatLng(30.7327, 31.7195),
    zoom: 7,
  );
  static final CameraPosition northsinai = CameraPosition(
    target: LatLng(30.2824, 33.6176),
    zoom: 7,
  );
  static final CameraPosition gharbia = CameraPosition(
    target: LatLng(30.8754, 31.0335),
    zoom: 7,
  );
  static final CameraPosition fayoum = CameraPosition(
    target: LatLng(29.3565, 30.6200),
    zoom: 7,
  );
  static final CameraPosition kalyobya = CameraPosition(
    target: LatLng(30.3292, 31.2168),
    zoom: 7,
  );
  static final CameraPosition qena = CameraPosition(
    target: LatLng(26.2346, 32.9888),
    zoom: 7,
  );
  static final CameraPosition kafrelsheikh = CameraPosition(
    target: LatLng(31.3085, 30.8039),
    zoom: 7,
  );
  static final CameraPosition matrouh = CameraPosition(
    target: LatLng(29.5696, 26.4194),
    zoom: 7,
  );
  static final CameraPosition monofeya = CameraPosition(
    target: LatLng(30.5972, 30.9876),
    zoom: 7,
  );
  static final CameraPosition menya = CameraPosition(
    target: LatLng(28.2847, 30.5279),
    zoom: 7,
  );
  static final CameraPosition wadielgedeed = CameraPosition(
    target: LatLng(24.5456, 27.1735),
    zoom: 7,
  );
  Future<void> goToTheLocation(CameraPosition _kLake) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  void GetDeviceLocation() async {
    var location = new Location();
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      interval: 100,
    );
    location.getLocation().then((value) {
      CameraPosition userlocation = CameraPosition(
        target: LatLng(value.latitude!, value.longitude!),
        zoom: 15,
      );
      goToTheLocation(userlocation);
      setState(() {
        Fluttertoast.showToast(
            msg: "تم تحديد مكانك بنجاح",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.teal,
            textColor: Colors.white,
            fontSize: 16.0);
      });
    });
    /*location.onLocationChanged.listen((LocationData currentLocation) {
    });*/
  }

  @override
  Widget build(BuildContext context) {
    // Permission.openSettings;
    return WillPopScope(
      onWillPop: () async {
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
        drawer: SideMenu(currentRoute: '/editfarm'),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            //Navigator.pop(context);
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
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context)
                          .size
                          .height) /*.tightFor(
                  height: MediaQuery.of(context).size.height,//Height of screen
                )*/
                  ,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        decoration: new BoxDecoration(
                          //borderRadius: new BorderRadius.circular(16.0),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(10),
                        margin:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        child: FutureBuilder<detailedfarmObject>(
                          future: fetchDetailedFarms(http.Client(), farmid),
                          builder: (context, snapshot) {
                            // if (snapshot.hasError) {
                            //   WidgetsBinding.instance.addPostFrameCallback((_) {
                            //     Navigator.of(context).pushReplacement(goToLogin());
                            //   });
                            // }
                            print("kkk nerma " + snapshot.error.toString());
                            if (snapshot.hasData && !addedInitialData) {
                              addedInitialData = true;
                              salty = snapshot.data?.salty! ?? false;
                              government = snapshot.data?.government;
                              farmname = snapshot.data?.name;
                              soiltype = snapshot.data?.soiltype;
                              dischargeRate = double.tryParse(
                                      snapshot.data!.dischargerate ?? '0') ??
                                  0.0;

                              dischargeUnit = 'متر مكعب/ساعة';
                              gasprice = double.tryParse(
                                      snapshot.data!.gasprice ?? '0') ??
                                  0.0;
                              gasusage = double.tryParse(
                                      snapshot.data!.gasuseage ?? '0') ??
                                  0.0;
                              Lat = snapshot.data?.lat! ?? 0.0;
                              Lng = snapshot.data?.lng! ?? 0.0;
                              markers.update(
                                  MarkerId('marker_id_1'),
                                  (value) => Marker(
                                        markerId: MarkerId('marker_id_1'),
                                        position: LatLng(Lat, Lng),
                                        infoWindow: InfoWindow(
                                            title: 'marker_id_1', snippet: '*'),
                                        onTap: () {
                                          //_onMarkerTapped(markerId);
                                          print('Marker Tapped');
                                        },
                                        onDragEnd: (LatLng position) {
                                          print('Drag Ended');
                                        },
                                      ));
                            }
                            return !snapshot.hasData
                                ? Center(child: CircularProgressIndicator())
                                : Form(
                                    key: formkey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        Image(
                                          image: AssetImage(
                                              'assets/images/farmer.png'),
                                          height: 150,
                                        ),
                                        Text(
                                          'أضافة مزرعة جديدة',
                                          style: TextStyle(fontSize: 25),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'برجاء اختيار المحافظة اولاً',
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.red),
                                        ),
                                        SizedBox(height: 10),
                                        DropdownButtonFormField<String>(
                                          validator: (String? value) {
                                            if (value == null) {
                                              return "برجاء اختيار المحافظة";
                                            }
                                          },
                                          onSaved: (String? value) {
                                            government = value;
                                          },
                                          isExpanded: true,
                                          value: government,
                                          hint: Text('اختر المحافظة'),
                                          icon: Icon(Icons.arrow_drop_down),
                                          iconSize: 24,
                                          elevation: 16,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20),
                                          /*underline: Container(
                                        height: 2,
                                        color: Color(0xff26a69a),
                                      ),*/
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              government = newValue;
                                              if (allGovernments
                                                      .indexOf(newValue!) ==
                                                  0)
                                                goToTheLocation(alex);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  1)
                                                goToTheLocation(ismailya);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  2)
                                                goToTheLocation(aswan);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  3)
                                                goToTheLocation(asyout);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  4)
                                                goToTheLocation(luxor);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  5)
                                                goToTheLocation(redsea);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  6)
                                                goToTheLocation(beheira);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  7)
                                                goToTheLocation(benisuef);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  8)
                                                goToTheLocation(portsaid);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  9)
                                                goToTheLocation(southsinai);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  10)
                                                goToTheLocation(giza);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  11)
                                                goToTheLocation(dakahlia);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  12)
                                                goToTheLocation(domyat);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  13)
                                                goToTheLocation(sohag);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  14)
                                                goToTheLocation(suez);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  15)
                                                goToTheLocation(sharkia);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  16)
                                                goToTheLocation(northsinai);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  17)
                                                goToTheLocation(gharbia);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  18)
                                                goToTheLocation(fayoum);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  19)
                                                goToTheLocation(cairo);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  20)
                                                goToTheLocation(kalyobya);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  21)
                                                goToTheLocation(qena);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  22)
                                                goToTheLocation(kafrelsheikh);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  23)
                                                goToTheLocation(matrouh);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  24)
                                                goToTheLocation(monofeya);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  25)
                                                goToTheLocation(menya);
                                              else if (allGovernments
                                                      .indexOf(newValue) ==
                                                  26)
                                                goToTheLocation(wadielgedeed);
                                            });
                                          },
                                          items: allGovernments
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(value),
                                                  if (allGovernments
                                                          .indexOf(value) ==
                                                      0)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Alexandria.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      1)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_d\'Ismailiya.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      2)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_d\'Aswan.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      3)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Assiut_Governorate.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      4)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_Egy_Luxor.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      5)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_la_mar_Roja.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      6)
                                                    Image.asset(
                                                      'assets/images/governates/800px-Flag_of_Behira_Govenorate.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      7)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Bani_Suwayf.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      8)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Port_Said_Governorate.PNG',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      9)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Sinai_del_sud.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      10)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Gizeh.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      11)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Daqahliya.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      12)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Damietta_Governorate.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      13)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Suhaj.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      14)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Suez.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      15)
                                                    Image.asset(
                                                      'assets/images/governates/324px-Flag_of_Ash_Sharqiyah.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      16)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Sinai-Sinai_del_nord.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      17)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Gharbiya.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      18)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Faium.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      19)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Cairo.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      20)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Qalubiya_Governorate.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      21)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Qena_flag.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      22)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Kafr_El-Sheikh_Governorate.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      23)
                                                    Image.asset(
                                                      'assets/images/governates/Matrouh_Governorate-logo.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      24)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Menoufia_Governorate.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      25)
                                                    Image.asset(
                                                      'assets/images/governates/Flag_of_Minya_Governorate.png',
                                                      height: 30,
                                                    )
                                                  else if (allGovernments
                                                          .indexOf(value) ==
                                                      26)
                                                    Image.asset(
                                                      'assets/images/governates/Governadorat_de_Wadi_al-Jadid.png',
                                                      height: 30,
                                                    )
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  Fluttertoast.showToast(
                                                    msg: "جاري نحديد مكانك",
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity:
                                                        ToastGravity.CENTER,
                                                    timeInSecForIosWeb: 1,
                                                    backgroundColor:
                                                        Colors.teal,
                                                    textColor: Colors.white,
                                                    fontSize: 16.0,
                                                  );
                                                });
                                                GetDeviceLocation();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Color(0xff26a69a),
                                              ),
                                              child: Text(
                                                'حدد مكاني',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                movecamera = true;
                                                setState(() {
                                                  Fluttertoast.showToast(
                                                    msg:
                                                        "يمكنك الان تحريك الخريطة",
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity:
                                                        ToastGravity.CENTER,
                                                    timeInSecForIosWeb: 1,
                                                    backgroundColor:
                                                        Colors.teal,
                                                    textColor: Colors.white,
                                                    fontSize: 16.0,
                                                  );
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Color(0xff26a69a),
                                              ),
                                              child: Text(
                                                'دعني احدد مكاني',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
//Location buttons
                                        SizedBox(height: 10),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                              .size
                                              .width, // or use fixed size like 200
                                          height:
                                              MediaQuery.of(context).size.width,
                                          child: GoogleMap(
                                            mapType: MapType.normal,
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: LatLng(Lat, Lng),
                                              zoom: 7,
                                            ),
                                            markers:
                                                Set<Marker>.of(markers.values),
                                            gestureRecognizers: movecamera
                                                ? {
                                                    Factory<OneSequenceGestureRecognizer>(
                                                        () =>
                                                            EagerGestureRecognizer())
                                                  }
                                                : <Factory<
                                                    OneSequenceGestureRecognizer>>{},
                                            onCameraMove: ((_position) =>
                                                _updatePosition(_position)),
                                            zoomGesturesEnabled: movecamera,
                                            zoomControlsEnabled: movecamera,
                                            onMapCreated: (GoogleMapController
                                                controller) {
                                              _controller.complete(controller);
                                            },
                                          ),
                                        ), //GOOGLE MAP
                                        SizedBox(height: 10),
                                        TextFormField(
                                          style:
                                              TextStyle(fontFamily: 'OpenSans'),
                                          initialValue: farmname,
                                          cursorColor: Color(0xff26a69a),
                                          decoration: InputDecoration(
                                              labelText: 'اسم المزرعة',
                                              focusColor: Color(0xff26a69a)),
                                          validator: (String? value) {
                                            if (value!.isEmpty) {
                                              return "برجاء ادخال اسم المزرعة";
                                            }
                                          },
                                          onSaved: (String? value) {
                                            farmname = value;
                                          },
                                        ),
                                        SizedBox(height: 10),
                                        DropdownButtonFormField<String>(
                                          validator: (String? value) {
                                            if (value == null) {
                                              return "برجاء نوع التربة";
                                            }
                                          },
                                          onSaved: (String? value) {
                                            soiltype = value!;
                                          },
                                          isExpanded: true,
                                          value: soiltype,
                                          icon: Icon(Icons.arrow_drop_down),
                                          iconSize: 24,
                                          elevation: 16,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              soiltype = newValue!;
                                            });
                                          },
                                          hint: Text('اختر نوع التربة'),
                                          items: <String>[
                                            'رملية',
                                            'سلتية',
                                            'طينية'
                                          ].map<DropdownMenuItem<String>>(
                                              (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(value),
                                                  if (value == 'رملية')
                                                    Image.asset(
                                                      'assets/images/soil/sand.jpg',
                                                      height: 30,
                                                    )
                                                  else if (value == 'سلتية')
                                                    Image.asset(
                                                      'assets/images/soil/silt.jpg',
                                                      height: 30,
                                                    )
                                                  else if (value == 'طينية')
                                                    Image.asset(
                                                      'assets/images/soil/loam.jpg',
                                                      height: 30,
                                                    )
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                style: TextStyle(
                                                    fontFamily: 'OpenSans'),
                                                initialValue:
                                                    dischargeRate.toString(),
                                                cursorColor: Color(0xff26a69a),
                                                decoration: InputDecoration(
                                                    labelText:
                                                        'معدل صرف الطرومبة',
                                                    focusColor:
                                                        Color(0xff26a69a)),
                                                validator: (String? value) {
                                                  if (value!.isEmpty) {
                                                    return "برجاء ادخال صرف الطرومبة";
                                                  }
                                                },
                                                onSaved: (String? value) {
                                                  double parsedValue = double
                                                          .tryParse(
                                                              value ?? '') ??
                                                      0; // Ensure non-null value
                                                  dischargeRate = parsedValue;

                                                  if (dischargeUnit == 'حصان') {
                                                    dischargeRate =
                                                        (dischargeRate! *
                                                            10)!; // Ensuring dischargeRate is always non-null
                                                  } else if (dischargeUnit ==
                                                      'لتر/ثانية') {
                                                    dischargeRate =
                                                        (dischargeRate! * 3.6)!;
                                                  }
                                                },
                                                inputFormatters: [
                                                  DecimalTextInputFormatter(
                                                      decimalRange: 2)
                                                ],
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                              ),
                                            ),
                                            Container(
                                                width: 5,
                                                color: Colors.transparent),
                                            Expanded(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                validator: (String? value) {
                                                  if (value == null) {
                                                    return "برجاء اختيار الوحدة";
                                                  }
                                                },
                                                onSaved: (String? value) {
                                                  dischargeUnit = value!;
                                                },
                                                value: dischargeUnit,
                                                icon:
                                                    Icon(Icons.arrow_drop_down),
                                                iconSize: 24,
                                                elevation: 16,
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    dischargeUnit = newValue!;
                                                  });
                                                },
                                                hint: Text('اختر الوحدة'),
                                                items: <String>[
                                                  'متر مكعب/ساعة',
                                                  'حصان',
                                                  'لتر/ثانية'
                                                ].map<DropdownMenuItem<String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                style: TextStyle(
                                                    fontFamily: 'OpenSans'),
                                                initialValue:
                                                    gasusage.toString(),
                                                cursorColor: Color(0xff26a69a),
                                                decoration: InputDecoration(
                                                    labelText: 'استهلاك الوقود',
                                                    focusColor:
                                                        Color(0xff26a69a)),
                                                inputFormatters: [
                                                  DecimalTextInputFormatter(
                                                      decimalRange: 2)
                                                ],
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                /*keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.digitsOnly
                                        ],*/
                                                onSaved: (String? value) {
                                                  gasusage =
                                                      double.tryParse(value!)!;
                                                  if (gasusage == null)
                                                    gasusage = 0;
                                                },
                                              ),
                                            ),
                                            Container(
                                                width: 20,
                                                color: Colors.transparent),
                                            Text(
                                              'لتر/ساعة',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                style: TextStyle(
                                                    fontFamily: 'OpenSans'),
                                                initialValue:
                                                    gasprice.toString(),
                                                cursorColor: Color(0xff26a69a),
                                                decoration: InputDecoration(
                                                    labelText: 'سعر الوقود',
                                                    focusColor:
                                                        Color(0xff26a69a)),
                                                inputFormatters: [
                                                  DecimalTextInputFormatter(
                                                      decimalRange: 2)
                                                ],
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                onSaved: (String? value) {
                                                  gasprice =
                                                      double.tryParse(value!)!;
                                                  if (gasprice == null)
                                                    gasprice = 0;
                                                },
                                              ),
                                            ),
                                            Container(
                                                width: 20,
                                                color: Colors.transparent),
                                            Text(
                                              'جنيه/لتر',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
                                          child: CheckboxListTile(
                                            title: Text('هل التربة مالحة؟'),
                                            value: salty,
                                            onChanged: (newValue) {
                                              setState(() {
                                                salty = newValue!;
                                              });
                                            },
                                            controlAffinity: ListTileControlAffinity
                                                .leading, //  <-- leading Checkbox
                                          ),
                                        ),
                                        isLoading
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      if (!formkey.currentState!
                                                          .validate()) {
                                                        // NOT VALID
                                                        return;
                                                      }
                                                      setState(() {
                                                        isLoading = true;
                                                        formkey.currentState!
                                                            .save();
                                                      });

                                                      SharedPreferences prefs =
                                                          await SharedPreferences
                                                              .getInstance();
                                                      String cookie =
                                                          (prefs.getString(
                                                                  'cookie') ??
                                                              '');

                                                      final user =
                                                          await editFarmASYNC(
                                                              farmname!,
                                                              government!,
                                                              soiltype!,
                                                              salty,
                                                              Lng,
                                                              Lat,
                                                              dischargeRate!,
                                                              gasusage!,
                                                              gasprice!,
                                                              farmid,
                                                              cookie);

                                                      if (user == false) {
                                                        Fluttertoast.showToast(
                                                            msg:
                                                                "حاول مرة اخرى",
                                                            toastLength: Toast
                                                                .LENGTH_SHORT,
                                                            gravity:
                                                                ToastGravity
                                                                    .CENTER,
                                                            timeInSecForIosWeb:
                                                                1,
                                                            backgroundColor:
                                                                Colors.teal,
                                                            textColor:
                                                                Colors.white,
                                                            fontSize: 16.0);

                                                        setState(() {
                                                          isLoading = false;
                                                        });
                                                        print('user = false');
                                                      } else {
                                                        Navigator.of(context)
                                                            .pushReplacement(
                                                                goToFarms());

                                                        setState(() {
                                                          isLoading = false;
                                                        });
                                                        print('user = true');
                                                      }
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Color(0xff26a69a),
                                                    ),
                                                    child: Text(
                                                      'تعديل المزرعة',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      showAlertDialog(context);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: Text(
                                                      'مسح المزرعة',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              )
                                      ],
                                    ),
                                  );
                          },
                        ),
                      ),
                      Container(
                        //FOOTER
                        padding: EdgeInsets.all(5),
                        decoration: new BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Color(0xff08aeea), Color(0xff2af598)],
                              begin: const FractionalOffset(0.0, 0.0),
                              end: const FractionalOffset(0.7, 0.0),
                              stops: [0.0, 1.0],
                              tileMode: TileMode.clamp),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                    child: Image(
                                  image: AssetImage('assets/images/msa.png'),
                                  fit: BoxFit.contain,
                                )),
                                SizedBox(width: 20),
                                Flexible(
                                    child: Image(
                                  image: AssetImage('assets/images/iwmi.png'),
                                  fit: BoxFit.contain,
                                )),
                                SizedBox(width: 20),
                                Flexible(
                                    child: Image(
                                  image: AssetImage('assets/images/sweri.png'),
                                  fit: BoxFit.contain,
                                ))
                              ],
                            ),
                            Image(image: AssetImage('assets/images/WAPOR.jpg'))
                          ],
                        ),
                      ), //FOOTER
                    ],
                  ),
                ))), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  void showAlertDialog(BuildContext context) {
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
          isLoading = true;
          Navigator.of(context).pop();
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String cookie = (prefs.getString('cookie') ?? '');
        bool myresult = await deleteFarmASYNC(farmid, cookie);

        if (myresult) {
          Navigator.of(context).pushReplacement(goToFarms());
        } else {
          Fluttertoast.showToast(
            msg: "حاول مرة اخرى",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("مسح المزرعة"),
      content: Text("هل تريد مسح المزرعة؟"),
      actions: [
        cancelButton,
        continueButton,
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

    if (myDouble == null && newValue.text.length != 0) return oldValue;
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

Future<detailedfarmObject> fetchDetailedFarms(
    http.Client client, int farmid) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  print("object" + farmid.toString() + " " + cookie);
  var mydata = jsonEncode({
    'farmid': farmid,
  });
  print("ll" + farmid.toString() + cookie.toString());
  final response = await client.get(
    // Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetFarm'),
    Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetFarmById?farmid=' +
        farmid.toString()),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    // body: mydata,
  );

  // Use the compute function to run parseFarms in a separate isolate.
  return parseDetailedFarms(response.body);
}

// A function that converts a response body into a List<Photo>.
detailedfarmObject parseDetailedFarms(String responseBody) {
  //final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  Map<String, dynamic> parsed = jsonDecode(responseBody);
  String tempsoil = '';
  if (parsed['soiltype'].toString() == 'clay') {
    tempsoil = 'طينية';
  } else if (parsed['soiltype'].toString() == 'sandy') {
    tempsoil = 'رملية';
  } else if (parsed['soiltype'].toString() == 'silt') {
    tempsoil = 'سلتية';
  }
  var xc = detailedfarmObject(
    name: parsed['name'] as String,
    government: parsed['government'] as String,
    soiltype: tempsoil,
    salty: parsed['salty'] as bool,
    lng: parsed['lng'] as double,
    lat: parsed['lat'] as double,
    dischargerate: parsed['dischargerate'].toString(),
    gasuseage: parsed['gasuseage'].toString(),
    gasprice: parsed['gasprice'].toString(),
    farmId: parsed['farmId'] as int,
  );
  return xc;
}

class detailedfarmObject {
  final String? name;
  final String? government;
  final String? soiltype;
  final bool? salty;
  final double? lng;
  final double? lat;
  final String? dischargerate;
  final String? gasuseage;
  final String? gasprice;
  final int? farmId;

  detailedfarmObject({
    this.name,
    this.government,
    this.soiltype,
    this.salty,
    this.lng,
    this.lat,
    this.dischargerate,
    this.gasuseage,
    this.gasprice,
    this.farmId,
  });

  factory detailedfarmObject.fromJson(Map<String, dynamic> json) {
    return detailedfarmObject(
      name: json['name'] as String,
      government: json['government'] as String,
      soiltype: json['soiltype'] as String,
      salty: json['salty'] as bool,
      lng: json['lng'] as double,
      lat: json['lat'] as double,
      dischargerate: (json['dischargerate']) as String,
      gasuseage: (json['gasuseage']) as String,
      gasprice: (json['gasprice']) as String,
      farmId: json['farmId'] as int,
    );
  }
}
