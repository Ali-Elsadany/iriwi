import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'directory.dart';

class preLogin extends StatefulWidget {
  @override
  _preLoginState createState() => _preLoginState();
}

class _preLoginState extends State<preLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE7FBE5),
      body: SafeArea(
        child: Stack(
          children: [
            // Bottom SVG Background Illustration (Farmer + Waves)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SvgPicture.asset(
                'assets/images/BG.svg',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                placeholderBuilder: (context) => const SizedBox(),
              ),
            ),

            // Foreground UI Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 20),

                    // Top Right IRWI Logo
                    Align(
                      alignment: Alignment.topRight,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 95,
                        height: 95,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/farmer.png',
                            width: 95,
                            height: 95,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Title Text
                    const Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        'مستقبل ري المحاصيل',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff006837),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle Text
                    const Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        'تحكم في ري المحاصيل بكل سهولة ممكنة\nو راقب مزرعتك',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Color(0xff1C1C1C),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Green Action Button (" <  ابدأ الان")
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(goToLogin());
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
                            Text(
                              'ابدأ الان',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Partner Logo Circles (SWERI, IWMI, MSA)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogoCircle('assets/images/sweri.png', 'SWERI'),
                        const SizedBox(width: 14),
                        _buildLogoCircle('assets/images/iwmi.png', 'IWMI'),
                        const SizedBox(width: 14),
                        _buildLogoCircle('assets/images/msa.png', 'MSA'),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Version Text
                    const Center(
                      child: Text(
                        'Version 2.01',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCircle(String assetPath, String fallbackText) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xd9D9D9D9),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              fallbackText,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            );
          },
        ),
      ),
    );
  }
}
