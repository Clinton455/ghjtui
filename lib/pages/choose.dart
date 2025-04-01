import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fresh_car/pages/home_page.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart'; // Add this package to pubspec.yaml

class ChoosePage extends StatelessWidget {
  // Store URLs for different platforms
  final String _appStoreUrl =
      'https://apps.apple.com/app/yourappid'; // Replace with your App Store URL
  final String _googlePlayUrl =
      'https://play.google.com/store/apps/details?id=your.package.name'; // Replace with your Play Store URL
  final String _appGalleryUrl =
      'https://appgallery.huawei.com/app/C103457387'; // Random AppGallery URL

  const ChoosePage({super.key});

  // Launch app store based on platform
  Future<void> _launchAppStore(BuildContext context) async {
    String storeUrl;

    if (Platform.isIOS) {
      storeUrl = _appStoreUrl;
    } else if (Platform.isAndroid) {
      // For Android, we'll try to detect if it's a Huawei device
      // This is a simplified check - you might need a more robust solution
      bool isHuaweiDevice = false;
      try {
        // This is a basic check - you might need a more sophisticated method
        // like checking for HMS availability
        isHuaweiDevice = await _isHuaweiDevice();
      } catch (e) {
        isHuaweiDevice = false;
      }

      storeUrl = isHuaweiDevice ? _appGalleryUrl : _googlePlayUrl;
    } else {
      // Fallback for other platforms
      storeUrl = _googlePlayUrl;
    }

    final Uri url = Uri.parse(storeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Handle case where we can't launch the URL
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open app store')),
        );
      }
    }
  }

  // Basic method to check if device is Huawei
  // In a real app, you'd use a more reliable method like checking for HMS availability
  Future<bool> _isHuaweiDevice() async {
    // This is a simplified example that checks the manufacturer
    // A more robust solution would be to check for HMS Core availability
    String manufacturer = '';
    try {
      // You would need a method to get the device manufacturer
      // For example, using device_info_plus package:
      // final androidInfo = await DeviceInfoPlugin().androidInfo;
      // manufacturer = androidInfo.manufacturer.toLowerCase();

      // Mock implementation for this example:
      manufacturer = 'unknown'; // Replace with actual implementation
    } catch (e) {
      manufacturer = 'unknown';
    }

    return manufacturer.toLowerCase().contains('huawei');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(CupertinoIcons.back, color: Colors.black),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Update Available',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Icon(
              Icons.system_update,
              size: 100,
              color: Color(0xFF4A90E2),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Update Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Please update the version of the App, A new version has been released.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Unlock exclusive discounts! 🚗✨ Visit your carwash today and have our staff activate your account to keep enjoying special savings and free washes!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to car wash page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Carwash',
                        style: TextStyle(
                          fontSize: 16,
                          //fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Launch appropriate app store based on platform
                        _launchAppStore(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 16,
                          //fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
