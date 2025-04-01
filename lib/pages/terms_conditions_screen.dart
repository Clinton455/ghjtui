import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_car/pages/login.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool _isAccepted = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  void _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App logo
              Center(
                child: Image.asset(
                  'assets/icons/trademaxlg.png',
                  width: 50,
                  height: 30,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Terms & Conditions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Please read and accept our Terms & Conditions before continuing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 24),

              // Terms and conditions content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Effective Date: 24 February 2025',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Introduction
                        const Text(
                          'Introduction',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'These Terms and Conditions govern your use of the FreshCar Products mobile application ("App").',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Acceptance
                        const Text(
                          'Acceptance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'By using the App, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the App.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // App Description
                        const Text(
                          'App Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The App provides carwash services and loyalty program features. This app is an affiliate of the carwash that you signed up with.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // User Obligations
                        const Text(
                          'User Obligations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You agree to:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'Use the App for personal purposes only, unless you are an authorized carwash business partner with a formal agreement with FreshCar Products (Pty) Ltd',
                        ),
                        _buildBulletPoint(
                          'Provide accurate and complete registration information',
                        ),
                        _buildBulletPoint(
                          'Keep your account credentials secure',
                        ),
                        _buildBulletPoint(
                          'Comply with applicable laws and regulations',
                        ),
                        const SizedBox(height: 16),

                        // Intellectual Property
                        const Text(
                          'Intellectual Property',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The App and its content are owned by FreshCar Products and protected by intellectual property laws. You may not reproduce, distribute, or display the App\'s content without permission.\n\nIf you are interested in developing a similar platform, you are welcome to contact us. However, copying the application features or functionality without prior written consent is prohibited. If carwash owners copy the App without informing us and there is valid proof, we will seek legal action.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Disclaimers
                        const Text(
                          'Disclaimers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'The App is provided "as is" and "as available" without warranties of any kind.',
                        ),
                        _buildBulletPoint(
                          'We are not responsible for the loss or damage of any property, accidents, or injuries that may occur in the carwash.',
                        ),
                        _buildBulletPoint(
                          'This app is subject to display advertisements.',
                        ),
                        const SizedBox(height: 16),

                        // Limitation of Liability
                        const Text(
                          'Limitation of Liability',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'In no event shall FreshCar Products be liable for any damages, including but not limited to incidental, consequential, or punitive damages, arising out of your use of the App or services provided by affiliated carwashes.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Termination
                        const Text(
                          'Termination',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We may terminate your account and access to the App at any time, without notice, if we believe you have violated these Terms and Conditions.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Governing Law
                        const Text(
                          'Governing Law',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'These Terms and Conditions shall be governed by and construed in accordance with the laws of South Africa.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact Us
                        const Text(
                          'Contact Us',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'If you have any questions or concerns about these Terms and Conditions, please contact us at info@freshcarproducts.co.za.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Changes to Terms
                        const Text(
                          'Changes to These Terms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We may update these Terms and Conditions from time to time. If we make material changes, we will notify you through the App or by email.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),

                        // Privacy Policy section
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Effective Date: 24 February 2025',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Introduction
                        const Text(
                          'Introduction',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'At FreshCar Products, we are committed to protecting the privacy and security of our users\' personal information. This Privacy Policy explains how we collect, use, and protect personal information through our mobile application.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // What Personal Information Do We Collect
                        const Text(
                          'What Personal Information Do We Collect?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We collect the following types of personal information:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'Registration information: When you create an account, we collect your email address, username, and password.',
                        ),
                        _buildBulletPoint(
                          'Vehicle information: We collect information about your vehicle name and vehicle type.',
                        ),
                        _buildBulletPoint(
                          'Device information: We collect information about your device, including the device type, operating system, and IP address.',
                        ),
                        _buildBulletPoint(
                          'Location information: We collect your location information to provide you with location-based services such as finding the nearest carwash.',
                        ),
                        const SizedBox(height: 16),

                        // How Do We Use Personal Information
                        const Text(
                          'How Do We Use Personal Information?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We use personal information for the following purposes:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'To provide the App\'s services and features',
                        ),
                        _buildBulletPoint(
                          'To improve the App\'s performance and user experience',
                        ),
                        _buildBulletPoint(
                          'To communicate with you about the App and its services',
                        ),
                        _buildBulletPoint(
                          'To comply with applicable laws and regulations',
                        ),
                        const SizedBox(height: 16),

                        // Sharing Information with Third Parties
                        const Text(
                          'Sharing Information with Third Parties',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We may share your personal information with third parties in the following circumstances:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'With affiliated carwashes to provide services',
                        ),
                        _buildBulletPoint(
                          'With service providers who perform services on our behalf',
                        ),
                        _buildBulletPoint(
                          'With advertising partners to display relevant advertisements',
                        ),
                        _buildBulletPoint(
                          'When required by law or to protect our rights',
                        ),
                        const SizedBox(height: 16),

                        // How Do We Protect Personal Information
                        const Text(
                          'How Do We Protect Personal Information?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We take reasonable measures to protect personal information from unauthorized access, disclosure, alteration, or destruction. These measures include:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint('Encrypting personal information'),
                        _buildBulletPoint(
                          'Implementing access controls and authentication measures',
                        ),
                        _buildBulletPoint(
                          'Regularly updating and patching our systems',
                        ),
                        const SizedBox(height: 16),

                        // Data Deletion
                        const Text(
                          'Data Deletion Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'If you would like your data to be deleted from our systems, please contact us at info@freshcarproducts.co.za with your request. We will process your request in accordance with applicable laws.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Advertisements
                        const Text(
                          'Advertisements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This App is subject to display advertisements. These advertisements may be targeted based on your usage of the App and other information collected about you.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isAccepted,
                    onChanged:
                        _hasScrolledToBottom
                            ? (value) {
                              setState(() {
                                _isAccepted = value!;
                              });
                            }
                            : null,
                    activeColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'I have read and agree to the Terms & Conditions and Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        color:
                            _hasScrolledToBottom
                                ? Colors.black
                                : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Accept button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isAccepted && _hasScrolledToBottom)
                          ? _acceptTerms
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),

              if (!_hasScrolledToBottom)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(
                      'Please scroll to the bottom to continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
            ),
          ),
        ],
      ),
    );
  }
}
