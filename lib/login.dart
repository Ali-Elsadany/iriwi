import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'directory.dart';

Future<bool> loginASYNC(String username, String password, String cookie) async {
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

  if (response.statusCode == 302) {
    if (response.headers['set-cookie'] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cookie', response.headers['set-cookie']!);
    }
    print('Success Man !');
    return true;
  } else {
    print(response.body);
    return false;
  }
}

class login extends StatefulWidget {
  @override
  _loginState createState() => _loginState();
}

class _loginState extends State<login> {
  bool isLoading = false;
  bool isPasswordHidden = true;
  bool hasError = false;
  String username = '';
  String password = '';
  String errorMessage = '';
  GlobalKey<FormState> formkey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topHeight = screenHeight * 0.37;

    return Scaffold(
      backgroundColor: const Color(0xffE7FBE5),
      body: SafeArea(
        child: Stack(
          children: [
            // Top Section Background (SVG Illustration)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: SvgPicture.asset(
                'assets/images/BG.svg',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                placeholderBuilder: (context) => const SizedBox(),
              ),
            ),

            // Main Content Area
            Column(
              children: [
                SizedBox(height: topHeight - 20),

                // Bottom White Card
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
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                        child: Form(
                          key: formkey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Right Logo
                              Align(
                                alignment: Alignment.topRight,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/farmer.png',
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Header Title ("تسجيل الدخول")
                              const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff006837),
                                ),
                                textAlign: TextAlign.right,
                              ),

                              const SizedBox(height: 4),

                              // Subtitle
                              const Text(
                                'ادخل رقم الموبايل وكلمة السر للدخول إلى حسابك',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff8E8E93),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),

                              const SizedBox(height: 14),

                              // Phone Field Label
                              const Text(
                                'رقم الموبايل',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff1C1C1C),
                                ),
                                textAlign: TextAlign.right,
                              ),

                              const SizedBox(height: 6),

                              // Phone Field Input
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xff1C1C1C),
                                ),
                                onChanged: (_) {
                                  if (hasError) {
                                    setState(() {
                                      hasError = false;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'اكتب رقم الموبايل',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xffA5A5A5),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffFAFAFA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: hasError ? const Color(0xffD32F2F) : const Color(0xffE0E0E0),
                                      width: hasError ? 1.5 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: hasError ? const Color(0xffD32F2F) : const Color(0xff006837),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'برجاء ادخال رقم الهاتف';
                                  }
                                  return null;
                                },
                                onSaved: (String? value) {
                                  username = value!.trim();
                                },
                              ),

                              const SizedBox(height: 12),

                              // Password Field Label
                              const Text(
                                'كلمة السر',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff1C1C1C),
                                ),
                                textAlign: TextAlign.right,
                              ),

                              const SizedBox(height: 6),

                              // Password Field Input
                              TextFormField(
                                controller: passwordController,
                                obscureText: isPasswordHidden,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xff1C1C1C),
                                ),
                                onChanged: (_) {
                                  if (hasError) {
                                    setState(() {
                                      hasError = false;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'اكتب كلمة السر',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xffA5A5A5),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffFAFAFA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  suffixIcon: IconButton(
                                    iconSize: 20,
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    icon: Icon(
                                      isPasswordHidden
                                          ? Icons.remove_red_eye_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xff007047),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPasswordHidden = !isPasswordHidden;
                                      });
                                    },
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: hasError ? const Color(0xffD32F2F) : const Color(0xffE0E0E0),
                                      width: hasError ? 1.5 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: hasError ? const Color(0xffD32F2F) : const Color(0xff006837),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'برجاء ادخال كلمة السر';
                                  }
                                  return null;
                                },
                                onSaved: (String? value) {
                                  password = value!.trim();
                                },
                              ),

                              const SizedBox(height: 4),

                              // Forgot Password & Error Message Row
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Forgot Password Link on the Left
                                    TextButton(
                                      onPressed: () {
                                        // Forgot password
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'نسيت حسابك ؟',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff8E8E93),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    // Red Error Text on the Right (when error occurs)
                                    if (hasError)
                                      const Text(
                                        'رقم الموبايل او كلمة السر خطأ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xffD32F2F),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Submit Button (" <  تسجيل الدخول")
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
                                            hasError = false;
                                          });

                                          SharedPreferences prefs = await SharedPreferences.getInstance();
                                          String cookie = (prefs.getString('cookie') ?? '');
                                          final user = await loginASYNC(username, password, cookie);

                                          if (user == false) {
                                            setState(() {
                                              isLoading = false;
                                              hasError = true;
                                              errorMessage = 'رقم الموبايل او كلمة السر خطأ';
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
                                            Text(
                                              'تسجيل الدخول',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              '  >',
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

                              const SizedBox(height: 12),

                              // Footer Register Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '  ليس لديك حساب ؟ ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xff777777),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(goToSignup());
                                    },
                                    child: const Text(
                                      'انشئ حساب',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff006837),
                                      ),
                                    ),
                                  ),

                                ],
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
    );
  }
}
