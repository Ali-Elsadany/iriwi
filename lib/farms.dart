import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'directory.dart';
import 'widgets/side_menu.dart';

Future<bool> logoutASYNC(String username, String password, String confirmPass, String phone, String cookie) async {
  var mydata = jsonEncode({});

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
    if (response.headers['set-cookie'] != null) {
      await prefs.setString('cookie', response.headers['set-cookie']!);
    }
    print('Success Man !');
    return true;
  } else {
    print(response.body);
    return false;
  }
}

class farms extends StatefulWidget {
  @override
  _farmsState createState() => _farmsState();
}

class _farmsState extends State<farms> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topHeight = mediaQuery.size.height * 0.16;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xffE7FBE5),
      drawer: SideMenu(currentRoute: '/farms'),
      body: SafeArea(
        child: Stack(
          children: [
            // Top Section (Header with Farmer Avatar and Greeting)
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
                      child: FutureBuilder<List<farmObject>>(
                        future: fetchFarms(http.Client()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff006837),
                              ),
                            );
                          }

                          final farmList = snapshot.data ?? [];
                          final isEmpty = farmList.isEmpty;

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 90.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header Row ("مزارعي" + optional Add Farm button)
                                if (isEmpty)
                                  const Align(
                                    alignment: Alignment.topRight,
                                    child: Text(
                                      'مزارعي',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff1C1C1C),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pushReplacement(goToAddFarm());
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xff006837), width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        icon: const Icon(Icons.add, size: 18, color: Color(0xff006837)),
                                        label: const Text(
                                          'أضف مزرعة',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff006837),
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'مزارعي',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff1C1C1C),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 12),

                                // EMPTY STATE
                                if (isEmpty) ...[
                                  const SizedBox(height: 10),

                                  // Plant Watering Vector (OBJECTS.svg)
                                  SizedBox(
                                    height:  MediaQuery.of(context).size.height * 0.40,
                                    width: double.infinity,
                                    child: SvgPicture.asset(
                                      'assets/images/OBJECTS.svg',
                                      fit: BoxFit.contain,
                                      placeholderBuilder: (context) => Image.asset(
                                        'assets/images/farm.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  const Text(
                                    'لا يوجد مزارع مُضافة',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff006837),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 6),

                                  const Text(
                                    'أضف مزرعة جديدة وتحكم في محاصيلك',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xff8E8E93),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 20),

                                  // Add Farm Button
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pushReplacement(goToAddFarm());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xff006837),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.add, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'أضف مزرعة جديدة',
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
                                ]
                                // POPULATED STATE (Cards list)
                                else ...[
                                  for (farmObject myfarm in farmList)
                                    _buildFarmCard(context, myfarm),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Compact Floating Bottom Navigation Pill Bar
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 220,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xffEAF8E6),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left Item: Options / SideMenu Trigger
                      InkWell(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: const Icon(Icons.more_horiz_rounded, color: Color(0xff006837), size: 26),
                      ),

                      // Center Active Item: Eco Leaf Icon inside green circle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff006837),
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                      ),

                      // Right Item: Notification Bell
                      InkWell(
                        onTap: () {
                          // Notifications action
                        },
                        child: const Icon(Icons.notifications_none_rounded, color: Color(0xff006837), size: 26),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmCard(BuildContext context, farmObject myfarm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffEEEEEE), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Farm Title & Location (Right) + Weather (Left)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Weather info
              Row(
                children: const [
                  Text(
                    '33° مشمس',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff777777),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20),
                ],
              ),

              // Right: Farm Title & Location Pin
              GestureDetector(
                onTap: () {
                  if (myfarm.farmId != null) {
                    Navigator.of(context).pushReplacement(goToFarmCrops(myfarm.farmId!));
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      myfarm.name ?? 'مزرعة',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1C1C1C),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          myfarm.government ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff777777),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.location_on_rounded, color: Color(0xff006837), size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xffEEEEEE), height: 1),
          ),

          // Row 2: Crops count & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date
              Row(
                children: const [
                  Text(
                    '6 سبتمبر 2026 / 12:21 مساء',
                    style: TextStyle(fontSize: 11, color: Color(0xff777777)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.access_time_rounded, size: 14, color: Color(0xff777777)),
                ],
              ),

              // Crops Count
              Row(
                children: const [
                  Text(
                    '4 عدد المحاصيل',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff1C1C1C)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.grass_rounded, size: 16, color: Color(0xff006837)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 3: Humidity & Wind
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Wind speed
              Row(
                children: const [
                  Text(
                    '0.38 متر/ثانية',
                    style: TextStyle(fontSize: 11, color: Color(0xff777777)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.air_rounded, size: 14, color: Color(0xff006837)),
                ],
              ),

              // Humidity
              Row(
                children: const [
                  Text(
                    '60% الرطوبة',
                    style: TextStyle(fontSize: 11, color: Color(0xff777777)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.water_drop_outlined, size: 14, color: Color(0xff006837)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Button: Add New Crop
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                if (myfarm.farmId != null) {
                  Navigator.of(context).pushReplacement(goToFarmCrops(myfarm.farmId!));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff006837),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'أضف محصول جديد',
                    style: TextStyle(
                      fontSize: 14,
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
    );
  }
}

// API endpoint: https://irwicrop.com/Home/RemoteDataSource_GetUserFarms
Future<List<farmObject>> fetchFarms(http.Client client) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String cookie = (prefs.getString('cookie') ?? '');
  final response = await client.get(
    Uri.parse('https://irwicrop.com/Home/RemoteDataSource_GetUserFarms'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
    },
  );
  print("Farms response: " + response.body.toString());

  return compute(parseFarms, response.body);
}

List<farmObject> parseFarms(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<farmObject>((json) => farmObject.fromJson(json)).toList();
}

class farmObject {
  int? farmId;
  String? name;
  String? government;
  String? soiltype;
  bool? salty;
  double? lng;
  double? lat;
  int? dischargerate;
  int? gasuseage;
  int? gasprice;

  farmObject({
    this.farmId,
    this.name,
    this.government,
    this.soiltype,
    this.salty,
    this.lng,
    this.lat,
    this.dischargerate,
    this.gasuseage,
    this.gasprice,
  });

  factory farmObject.fromJson(Map<String, dynamic> json) {
    return farmObject(
      farmId: json['farmId'] as int?,
      government: json['government'] as String?,
      name: json['name'] as String?,
    );
  }
}
