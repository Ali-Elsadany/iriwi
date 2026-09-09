import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'directory.dart';

Future<bool> signupASYNC(String username, String password, String confirmPass, String phone, String cookie) async {
  var mydata = jsonEncode({
    'phone': phone,
    'Password': password,
    'ConfirmPassword': confirmPass,
    'firstname': username,
  });

  final http.Response response = await http.post(
    Uri.parse('https://irwicrop.com/Account/Register'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Cookie': cookie,
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

class signup extends StatefulWidget {
  @override
  _signupState createState() => _signupState();
}

class _signupState extends State<signup> {
  bool isLoading = false;
  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool hasError = false;

  String username = '';
  String password = '';
  String confirmPass = '';
  String phone = '';
  String errorMessage = '';

  GlobalKey<FormState> formkey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topHeight = screenHeight * 0.25;

    return Scaffold(
      backgroundColor: const Color(0xffE7FBE5),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Top Section Background (BACKGROUND.svg)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: SvgPicture.asset(
                'assets/images/BACKGROUND.svg',
                fit: BoxFit.cover,
                placeholderBuilder: (context) => const SizedBox(),
              ),
            ),

            // 2. Farmer Vector (Positioned behind white card so upper half emerges and wider)
            Positioned(
              top: topHeight - 200,
              left: 0,
              right: 0,
              height: 300,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/Isolation_Mode.svg',
                  width: 300,
                  height: 250,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => const SizedBox(),
                ),
              ),
            ),

            // 3. Main Content Area (White Card covering bottom half of farmer)
            Column(
              children: [
                SizedBox(height: topHeight - 70),

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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 24.0,
                              ),
                              child: IntrinsicHeight(
                                child: Form(
                                  key: formkey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Top Right Logo
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Image.asset(
                                              'assets/images/logo.png',
                                              width: 85,
                                              height: 80,
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

                                          const SizedBox(height: 16),

                                          // Header Title ("إنشاء حساب")
                                          const Text(
                                            'إنشاء حساب',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff006837),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),

                                          const SizedBox(height: 2),

                                          // Subtitle
                                          const Text(
                                            'أنشئ حسابك الآن و سجل دخولك',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xff8E8E93),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),

                                          const SizedBox(height: 16),

                                          // Name Field Label
                                          const Text(
                                            'اسمك بالكامل',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff1C1C1C),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),

                                          const SizedBox(height: 8),

                                          // Name Field Input
                                          TextFormField(
                                            controller: nameController,
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
                                              hintText: 'اكتب اسمك',
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
                                                return 'برجاء ادخال الاسم';
                                              }
                                              return null;
                                            },
                                            onSaved: (String? value) {
                                              username = value!.trim();
                                            },
                                          ),

                                          const SizedBox(height: 16),

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

                                          const SizedBox(height: 8),

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
                                              } else if (value.trim().length != 11) {
                                                return 'رقم الهاتف يجب ان يكون من 11 رقم';
                                              }
                                              return null;
                                            },
                                            onSaved: (String? value) {
                                              phone = value!.trim();
                                            },
                                          ),

                                          const SizedBox(height: 16),

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

                                          const SizedBox(height: 8),

                                          // Password Field Input
                                          TextFormField(
                                            controller: passwordController,
                                            obscureText: isPasswordHidden,
                                            textInputAction: TextInputAction.next,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff1C1C1C),
                                            ),
                                            onChanged: (_) {
                                              setState(() {
                                                if (hasError) hasError = false;
                                              });
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
                                                  color: passwordController.text.isNotEmpty
                                                      ? const Color(0xff007047)
                                                      : const Color(0xffB1B1B1),
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
                                              } else if (value.trim().length < 6) {
                                                return 'يجب ان تكون 6 احرف او اكتر';
                                              }
                                              return null;
                                            },
                                            onSaved: (String? value) {
                                              password = value!.trim();
                                            },
                                          ),

                                          const SizedBox(height: 16),

                                          // Confirm Password Field Label
                                          const Text(
                                            'تأكيد كلمة السر',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xff1C1C1C),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),

                                          const SizedBox(height: 8),

                                          // Confirm Password Field Input
                                          TextFormField(
                                            controller: confirmPassController,
                                            obscureText: isConfirmPasswordHidden,
                                            textInputAction: TextInputAction.done,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff1C1C1C),
                                            ),
                                            onChanged: (_) {
                                              setState(() {
                                                if (hasError) hasError = false;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'تأكيد كلمة السر',
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
                                                  isConfirmPasswordHidden
                                                      ? Icons.remove_red_eye_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: confirmPassController.text.isNotEmpty
                                                      ? const Color(0xff007047)
                                                      : const Color(0xffB1B1B1),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isConfirmPasswordHidden = !isConfirmPasswordHidden;
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
                                                return 'برجاء ادخال تأكيد كلمة السر';
                                              } else if (passwordController.text.trim() != value.trim()) {
                                                return 'كلمات السر لا تتطابق';
                                              }
                                              return null;
                                            },
                                            onSaved: (String? value) {
                                              confirmPass = value!.trim();
                                            },
                                          ),

                                          const SizedBox(height: 6),

                                          // Red Error Message (if error occurs)
                                          if (hasError)
                                            const Text(
                                              'برجاء التاكد من كلمة السر ورقم الهاتف',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xffD32F2F),
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                        ],
                                      ),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 12),

                                          // Submit Button ("أوافق على الشروط و إنشاء حساب  >")
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
                                                      final user = await signupASYNC(username, password, confirmPass, phone, cookie);

                                                      if (!user) {
                                                        setState(() {
                                                          isLoading = false;
                                                          hasError = true;
                                                          errorMessage = 'برجاء التاكد من كلمة السر ورقم الهاتف';
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
                                                          'أوافق على الشروط و إنشاء حساب',
                                                          style: TextStyle(
                                                            fontSize: 15,
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

                                          const SizedBox(height: 10),

                                          // Footer Login Link ("لديك حساب ؟  سجل دخولك")
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                '  لديك حساب ؟ ',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xff777777),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  Navigator.of(context).pushReplacement(goToLogin());
                                                },
                                                child: const Text(
                                                  'سجل دخولك',
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
