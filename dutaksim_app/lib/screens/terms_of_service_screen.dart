import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Acceptance of Terms',
              'By accessing and using DuTaksim, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these Terms of Service, please do not use our application.',
            ),

            _buildSection(
              'Description of Service',
              'DuTaksim is a bill-splitting mobile application that helps users:\n\n'
              '• Split bills among multiple participants\n'
              '• Scan receipts using OCR technology\n'
              '• Create collaborative bill sessions\n'
              '• Track debts and payments\n'
              '• Find nearby active bill sessions\n'
              '• Calculate optimized payment transactions',
            ),

            _buildSection(
              'User Accounts',
              'To use DuTaksim, you must:\n\n'
              '• Provide accurate and complete registration information\n'
              '• Maintain the security of your account\n'
              '• Be at least 13 years of age\n'
              '• Use the service in compliance with all applicable laws\n\n'
              'You are responsible for all activities that occur under your account.',
            ),

            _buildSection(
              'Acceptable Use',
              'You agree NOT to:\n\n'
              '• Use the service for any illegal purpose\n'
              '• Attempt to gain unauthorized access to the system\n'
              '• Interfere with or disrupt the service\n'
              '• Upload malicious code or viruses\n'
              '• Impersonate another user\n'
              '• Harass, abuse, or harm other users\n'
              '• Use the service to spam or send unsolicited messages\n'
              '• Collect user information without consent\n'
              '• Reverse engineer or decompile the application',
            ),

            _buildSection(
              'Bill and Payment Information',
              'DuTaksim is a bill-splitting calculator and organizer:\n\n'
              '• We do NOT process actual payments\n'
              '• We do NOT store payment card information\n'
              '• Bill calculations are provided as-is\n'
              '• Users are responsible for actual payment transactions\n'
              '• We are not liable for payment disputes between users\n'
              '• Debt tracking is for informational purposes only',
            ),

            _buildSection(
              'Collaborative Sessions',
              'When using collaborative session features:\n\n'
              '• Session creators are responsible for managing participants\n'
              '• All participants can add items to shared sessions\n'
              '• Sessions automatically expire after 6 hours\n'
              '• GPS-based session discovery requires location permission\n'
              '• Session codes should be shared only with trusted individuals',
            ),

            _buildSection(
              'Receipt Scanning',
              'The OCR receipt scanning feature:\n\n'
              '• Is provided as a convenience tool\n'
              '• May not be 100% accurate\n'
              '• Requires users to verify scanned information\n'
              '• Does not permanently store receipt images\n'
              '• Processes images locally on your device when possible',
            ),

            _buildSection(
              'Intellectual Property',
              'DuTaksim and its original content, features, and functionality are owned by the developers and are protected by international copyright, trademark, and other intellectual property laws.\n\n'
              'The DuTaksim name, logo, and all related graphics are trademarks and may not be used without permission.',
            ),

            _buildSection(
              'Disclaimer of Warranties',
              'DuTaksim is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied, including but not limited to:\n\n'
              '• Accuracy of bill calculations\n'
              '• Uninterrupted or error-free service\n'
              '• Correctness of OCR-scanned data\n'
              '• Security of transmitted data\n\n'
              'Users should always verify calculations before making payments.',
            ),

            _buildSection(
              'Limitation of Liability',
              'To the maximum extent permitted by law, DuTaksim shall not be liable for:\n\n'
              '• Incorrect bill calculations or splits\n'
              '• Payment disputes between users\n'
              '• Loss of data or information\n'
              '• Unauthorized access to user accounts\n'
              '• Any indirect, incidental, or consequential damages\n\n'
              'Our total liability shall not exceed the amount you paid to use the service (currently free).',
            ),

            _buildSection(
              'Data and Privacy',
              'Your use of DuTaksim is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices regarding the collection and use of your information.',
            ),

            _buildSection(
              'Termination',
              'We reserve the right to terminate or suspend your account immediately, without prior notice, for conduct that:\n\n'
              '• Violates these Terms of Service\n'
              '• Is harmful to other users\n'
              '• Is harmful to the service\n'
              '• Violates applicable laws\n\n'
              'You may also terminate your account at any time through the app settings.',
            ),

            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify these terms at any time. We will notify users of any material changes by:\n\n'
              '• Posting an update in the app\n'
              '• Sending a notification (if enabled)\n\n'
              'Continued use of the service after changes constitutes acceptance of the new terms.',
            ),

            _buildSection(
              'Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of Tajikistan, without regard to its conflict of law provisions.',
            ),

            _buildSection(
              'Competition Entry',
              'DuTaksim was created as an entry for the Bank Eskhata App Competition. All features and services are provided in accordance with competition rules and guidelines.',
            ),

            _buildSection(
              'Contact Information',
              'If you have questions about these Terms of Service, please contact us:\n\n'
              'Email: support@dutaksim.app\n'
              'Competition: Bank Eskhata App Contest ${DateTime.now().year}',
            ),

            const SizedBox(height: 32),

            Center(
              child: Text(
                '© ${DateTime.now().year} DuTaksim. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                'Made with ❤️ for easier bill splitting',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
