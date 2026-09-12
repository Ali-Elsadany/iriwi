import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'directory.dart';
import 'widgets/side_menu.dart';

Future<bool> addFarmASYNC(
  String name,
  String government,
  String soiltype,
  bool salty,
  double lng,
  double lat,
  double dischargerate,
  double gasuseage,
  double gasprice,
  String cookie,
) async {
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
  });

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Home/addfarm'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
    body: mydata,
  );

  if (response.statusCode == 302 || response.statusCode == 200 || response.statusCode == 201) {
    if (response.headers['set-cookie'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cookie', response.headers['set-cookie']!);
    }
    print('Success Man ! Status: ${response.statusCode}');
    return true;
  } else {
    print("Add farm failed: Status ${response.statusCode}, Body: ${response.body}");
    return false;
  }
}

class addfarm extends StatefulWidget {
  @override
  _addfarmState createState() => _addfarmState();
}

class _addfarmState extends State<addfarm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formkey = GlobalKey<FormState>();

  bool salty = false;
  bool isLoading = false;
  bool movecamera = true;

  String? government;
  String? farmname;
  String? soiltype;
  String? dischargeUnit = 'متر مكعب/ساعة';
  double? dischargeRate;
  double? gasprice;
  double? gasusage;

  double Lat = 30.0444;
  double Lng = 31.235;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dischargeController = TextEditingController();
  final TextEditingController gasUsageController = TextEditingController();
  final TextEditingController gasPriceController = TextEditingController();

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{
    const MarkerId('marker_id_1'): const Marker(
      markerId: MarkerId('marker_id_1'),
      position: LatLng(30.0444, 31.235),
    ),
  };

  Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition cairo = CameraPosition(
    target: LatLng(30.0444, 31.235),
    zoom: 7,
  );

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
    'محافظة الوادي الجديد',
  ];

  CameraPosition getCameraForGovernment(String? gov) {
    if (gov == null) return cairo;
    int index = allGovernments.indexOf(gov);
    switch (index) {
      case 0: return const CameraPosition(target: LatLng(30.8761, 29.7426), zoom: 12);
      case 1: return const CameraPosition(target: LatLng(30.5831, 32.2654), zoom: 12);
      case 2: return const CameraPosition(target: LatLng(23.6966, 32.7181), zoom: 12);
      case 3: return const CameraPosition(target: LatLng(27.2134, 31.4456), zoom: 12);
      case 4: return const CameraPosition(target: LatLng(25.3944, 32.4920), zoom: 12);
      case 5: return const CameraPosition(target: LatLng(24.6826, 34.1532), zoom: 10);
      case 6: return const CameraPosition(target: LatLng(30.8481, 30.3436), zoom: 12);
      case 7: return const CameraPosition(target: LatLng(28.8939, 31.4456), zoom: 12);
      case 8: return const CameraPosition(target: LatLng(31.0759, 32.2654), zoom: 12);
      case 9: return const CameraPosition(target: LatLng(29.3102, 34.1532), zoom: 10);
      case 10: return const CameraPosition(target: LatLng(28.7666, 29.2321), zoom: 11);
      case 11: return const CameraPosition(target: LatLng(31.1656, 31.4913), zoom: 12);
      case 12: return const CameraPosition(target: LatLng(31.3626, 31.6739), zoom: 12);
      case 13: return const CameraPosition(target: LatLng(26.6938, 32.1746), zoom: 12);
      case 14: return const CameraPosition(target: LatLng(29.3682, 32.1746), zoom: 12);
      case 15: return const CameraPosition(target: LatLng(30.7327, 31.7195), zoom: 12);
      case 16: return const CameraPosition(target: LatLng(30.2824, 33.6176), zoom: 11);
      case 17: return const CameraPosition(target: LatLng(30.8754, 31.0335), zoom: 12);
      case 18: return const CameraPosition(target: LatLng(29.3565, 30.6200), zoom: 12);
      case 19: return const CameraPosition(target: LatLng(30.0444, 31.2350), zoom: 12);
      case 20: return const CameraPosition(target: LatLng(30.3292, 31.2168), zoom: 12);
      case 21: return const CameraPosition(target: LatLng(26.2346, 32.9888), zoom: 12);
      case 22: return const CameraPosition(target: LatLng(31.3085, 30.8039), zoom: 12);
      case 23: return const CameraPosition(target: LatLng(29.5696, 26.4194), zoom: 10);
      case 24: return const CameraPosition(target: LatLng(30.5972, 30.9876), zoom: 12);
      case 25: return const CameraPosition(target: LatLng(28.2847, 30.5279), zoom: 12);
      case 26: return const CameraPosition(target: LatLng(24.5456, 27.1735), zoom: 10);
      default: return cairo;
    }
  }

  void _updatePosition(CameraPosition _position) {
    markers.update(
      const MarkerId('marker_id_1'),
      (value) => Marker(
        markerId: const MarkerId('marker_id_1'),
        position: LatLng(_position.target.latitude, _position.target.longitude),
        draggable: true,
      ),
    );
    Lat = _position.target.latitude;
    Lng = _position.target.longitude;
  }

  Future<void> goToTheLocation(CameraPosition _kLake) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  void GetDeviceLocation() async {
    var location = Location();
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      interval: 100,
    );
    location.getLocation().then((value) {
      if (value.latitude != null && value.longitude != null) {
        CameraPosition userlocation = CameraPosition(
          target: LatLng(value.latitude!, value.longitude!),
          zoom: 15,
        );
        goToTheLocation(userlocation);
        _updatePosition(userlocation);
        Fluttertoast.showToast(
          msg: "تم تحديد مكانك بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xff006837),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  void _showMapDialog() {
    final targetCamera = getCameraForGovernment(government);
    Lat = targetCamera.target.latitude;
    Lng = targetCamera.target.longitude;

    markers[const MarkerId('marker_id_1')] = Marker(
      markerId: const MarkerId('marker_id_1'),
      position: targetCamera.target,
      draggable: true,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setMapState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xff1C1C1C), size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'تحديد موقع المزرعة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1C1C1C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          GoogleMap(
                            mapType: MapType.hybrid,
                            initialCameraPosition: targetCamera,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            markers: Set<Marker>.of(markers.values),
                            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                            },
                            onTap: (LatLng position) {
                              setMapState(() {
                                _updatePosition(CameraPosition(target: position));
                              });
                            },
                            onCameraMove: (_position) {
                              setMapState(() {
                                _updatePosition(_position);
                              });
                            },
                            zoomGesturesEnabled: true,
                            zoomControlsEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            onMapCreated: (GoogleMapController controller) {
                              if (!_controller.isCompleted) {
                                _controller.complete(controller);
                              }
                            },
                          ),

                          // Floating My Location Target Button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: FloatingActionButton.small(
                              heroTag: 'myLocationFab',
                              backgroundColor: Colors.white,
                              elevation: 4,
                              onPressed: () {
                                GetDeviceLocation();
                              },
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: Color(0xff006837),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Fluttertoast.showToast(
                          msg: "تم تحديد موقع المزرعة بنجاح",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          backgroundColor: const Color(0xff006837),
                          textColor: Colors.white,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff006837),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'تأكيد المكان',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    dischargeController.dispose();
    gasUsageController.dispose();
    gasPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.16;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(goToFarms());
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xffE7FBE5),
        drawer: SideMenu(currentRoute: '/addfarm'),
        body: SafeArea(
          child: Stack(
            children: [
              // Top Section (Header)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topHeight,
                child: Container(
                  color: const Color(0xffE7FBE5),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Farmer Avatar Container
                      InkWell(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff006837),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Transform.scale(
                            scale: 2,
                            alignment: const Alignment(0, -1.3),
                            child: SvgPicture.asset(
                              'assets/images/Isolation_Mode.svg',
                              fit: BoxFit.contain,
                              placeholderBuilder: (context) => Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),
                      // Greeting & Location Text (InkWell on left side of Avatar)
                      InkWell(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أهلا وسهلا، أنس',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff006837),
                              ),
                            ),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/vuesax_linear_sun.svg',
                                  width: 16,
                                  height: 16,
                                  placeholderBuilder: (context) => const Icon(
                                    Icons.wb_sunny_rounded,
                                    size: 16,
                                    color: Color(0xffFB892C),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'المزرعة الشرقية، 33°',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff006837),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xff006837), size: 18),
                                const SizedBox(width: 2),
                              ],
                            ),
                          ],
                        ),
                      ),



                    ],
                  ),
                ),
              ),

              // Main Content Area (White Card)
              Column(
                children: [
                  SizedBox(height: topHeight - 12),

                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Form(
                            key: formkey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title Row with Close Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'أضف مزرعة جديدة',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff1C1C1C),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Color(0xff1C1C1C), size: 24),
                                      onPressed: () {
                                        Navigator.of(context).pushReplacement(goToFarms());
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // 1. Governate Selection
                                const Text(
                                  'اختار المحافظة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1C1C1C),
                                  ),
                                  textAlign: TextAlign.right,
                                ),

                                const SizedBox(height: 6),

                                DropdownButtonFormField<String>(
                                  validator: (String? value) {
                                    if (value == null) {
                                      return "برجاء اختيار المحافظة";
                                    }
                                    return null;
                                  },
                                  onSaved: (String? value) {
                                    government = value;
                                  },
                                  isExpanded: true,
                                  value: government,
                                  hint: const Text(
                                    'اختر المحافظة',
                                    style: TextStyle(fontSize: 13, color: Color(0xffA5A5A5)),
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xff777777)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xffFAFAFA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xff006837), width: 1.5),
                                    ),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      government = newValue;
                                    });
                                  },
                                  items: allGovernments.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(fontSize: 14, color: Color(0xff1C1C1C)),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 16),

                                // 2. Map Location Button ("تحديد الموقع على الخريطة")
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (government == null || government!.trim().isEmpty) {
                                        Fluttertoast.showToast(
                                          msg: "برجاء اختيار المحافظة أولاً",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          backgroundColor: const Color(0xffD32F2F),
                                          textColor: Colors.white,
                                          fontSize: 16.0,
                                        );
                                        return;
                                      }
                                      _showMapDialog();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xff006837), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.map_outlined, color: Color(0xff006837), size: 20),
                                    label: const Text(
                                      'تحديد الموقع على الخريطة',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff006837),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // 3. Farm Name
                                const Text(
                                  'اسم المزرعة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1C1C1C),
                                  ),
                                  textAlign: TextAlign.right,
                                ),

                                const SizedBox(height: 6),

                                TextFormField(
                                  controller: nameController,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 14, color: Color(0xff1C1C1C)),
                                  decoration: InputDecoration(
                                    hintText: 'اكتب اسم المزرعة',
                                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xffA5A5A5)),
                                    filled: true,
                                    fillColor: const Color(0xffFAFAFA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xff006837), width: 1.5),
                                    ),
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "برجاء ادخال اسم المزرعة";
                                    }
                                    return null;
                                  },
                                  onSaved: (String? value) {
                                    farmname = value!.trim();
                                  },
                                ),

                                const SizedBox(height: 16),

                                // 4. Soil Type
                                const Text(
                                  'نوع التربة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1C1C1C),
                                  ),
                                  textAlign: TextAlign.right,
                                ),

                                const SizedBox(height: 6),

                                DropdownButtonFormField<String>(
                                  validator: (String? value) {
                                    if (value == null) {
                                      return "برجاء اختيار نوع التربة";
                                    }
                                    return null;
                                  },
                                  onSaved: (String? value) {
                                    soiltype = value;
                                  },
                                  isExpanded: true,
                                  value: soiltype,
                                  hint: const Text(
                                    'اختر نوع التربة',
                                    style: TextStyle(fontSize: 13, color: Color(0xffA5A5A5)),
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xff777777)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xffFAFAFA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xff006837), width: 1.5),
                                    ),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      soiltype = newValue;
                                    });
                                  },
                                  items: <String>['رملية', 'سلتية', 'طينية'].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(fontSize: 14, color: Color(0xff1C1C1C)),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 16),

                                // 5. Discharge Rate ("معدل صرف الطرمبة")
                                const Text(
                                  'معدل صرف الطرمبة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1C1C1C),
                                  ),
                                  textAlign: TextAlign.right,
                                ),

                                const SizedBox(height: 6),

                                TextFormField(
                                  controller: dischargeController,
                                  textAlign: TextAlign.right,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                                  style: const TextStyle(fontSize: 14, color: Color(0xff1C1C1C)),
                                  decoration: InputDecoration(
                                    hintText: 'معدل صرف الطرمبة',
                                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xffA5A5A5)),
                                    filled: true,
                                    fillColor: const Color(0xffFAFAFA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    suffixIcon: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: Color(0xffE0E0E0), width: 1),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: dischargeUnit,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xff777777), size: 18),
                                          style: const TextStyle(fontSize: 12, color: Color(0xff1C1C1C)),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              dischargeUnit = newValue;
                                            });
                                          },
                                          items: <String>['متر مكعب/ساعة', 'حصان', 'لتر/ثانية'].map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xff006837), width: 1.5),
                                    ),
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "برجاء ادخال صرف الطرومبة";
                                    }
                                    return null;
                                  },
                                  onSaved: (String? value) {
                                    double rate = double.tryParse(value ?? '0') ?? 0;
                                    if (dischargeUnit == 'حصان') {
                                      rate *= 10;
                                    } else if (dischargeUnit == 'لتر/ثانية') {
                                      rate *= 3.6;
                                    }
                                    dischargeRate = rate;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // 6. Fuel Usage ("استهلاك الوقود")
                                const Text(
                                  'استهلاك الوقود',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1C1C1C),
                                  ),
                                  textAlign: TextAlign.right,
                                ),

                                const SizedBox(height: 6),

                                TextFormField(
                                  controller: gasUsageController,
                                  textAlign: TextAlign.right,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                                  style: const TextStyle(fontSize: 14, color: Color(0xff1C1C1C)),
                                  decoration: InputDecoration(
                                    hintText: 'استهلاك الوقود',
                                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xffA5A5A5)),
                                    filled: true,
                                    fillColor: const Color(0xffFAFAFA),
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      child: Text(
                                        'لتر/ساعة',
                                        style: TextStyle(fontSize: 12, color: Color(0xff777777), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xff006837), width: 1.5),
                                    ),
                                  ),
                                  onSaved: (String? value) {
                                    gasusage = double.tryParse(value ?? '0') ?? 0;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // 7. Fuel Price ("سعر الوقود")
                                const Text(
                                  'سعر الوقود',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1C1C1C),
                                  ),
                                  textAlign: TextAlign.right,
                                ),

                                const SizedBox(height: 6),

                                TextFormField(
                                  controller: gasPriceController,
                                  textAlign: TextAlign.right,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [DecimalTextInputFormatter(decimalRange: 2)],
                                  style: const TextStyle(fontSize: 14, color: Color(0xff1C1C1C)),
                                  decoration: InputDecoration(
                                    hintText: 'سعر الوقود',
                                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xffA5A5A5)),
                                    filled: true,
                                    fillColor: const Color(0xffFAFAFA),
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      child: Text(
                                        'جنيه/لتر',
                                        style: TextStyle(fontSize: 12, color: Color(0xff777777), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xff006837), width: 1.5),
                                    ),
                                  ),
                                  onSaved: (String? value) {
                                    gasprice = double.tryParse(value ?? '0') ?? 0;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // 8. Salty Soil Checkbox
                                CheckboxListTile(
                                  title: const Text(
                                    'هل التربة مالحة؟',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff1C1C1C)),
                                  ),
                                  value: salty,
                                  activeColor: const Color(0xff006837),
                                  onChanged: (newValue) {
                                    setState(() {
                                      salty = newValue ?? false;
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),

                                const SizedBox(height: 16),

                                // Submit Button ("+ إضافة المزرعة")
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            if (!formkey.currentState!.validate()) {
                                              return;
                                            }
                                            formkey.currentState!.save();

                                            setState(() {
                                              isLoading = true;
                                            });

                                            SharedPreferences prefs = await SharedPreferences.getInstance();
                                            String cookie = (prefs.getString('cookie') ?? '');
                                            final user = await addFarmASYNC(
                                              farmname ?? '',
                                              government ?? '',
                                              soiltype ?? '',
                                              salty,
                                              Lng,
                                              Lat,
                                              dischargeRate ?? 0,
                                              gasusage ?? 0,
                                              gasprice ?? 0,
                                              cookie,
                                            );

                                            if (!user) {
                                              Fluttertoast.showToast(
                                                msg: "حاول مرة اخرى",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.CENTER,
                                                backgroundColor: const Color(0xffD32F2F),
                                                textColor: Colors.white,
                                                fontSize: 16.0,
                                              );
                                              setState(() {
                                                isLoading = false;
                                              });
                                            } else {
                                              Navigator.of(context).pushReplacement(goToFarms());
                                              setState(() {
                                                isLoading = false;
                                              });
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff006837),
                                      disabledBackgroundColor: const Color(0xb2006837),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.add, color: Colors.white, size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'إضافة المزرعة',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange}) : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;
    var myDouble = double.tryParse(newValue.text);

    if (myDouble == null && newValue.text.isNotEmpty) return oldValue;
    String value = newValue.text;

    if (value.contains(".") && value.substring(value.indexOf(".") + 1).length > decimalRange) {
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
