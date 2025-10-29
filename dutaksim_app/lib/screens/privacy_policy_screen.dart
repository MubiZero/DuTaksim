import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
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
              'Introduction',
              'DuTaksim ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our bill-splitting mobile application.',
            ),

            _buildSection(
              'Information We Collect',
              'We collect information that you provide directly to us:\n\n'
              '• Personal Information: Name and phone number when you register\n'
              '• Bill Information: Bill details, items, and amounts you create or participate in\n'
              '• Session Data: Information about collaborative sessions you create or join\n'
              '• Contact Data: Phone numbers of contacts you choose to share (stored locally on your device)\n'
              '• Location Data: GPS coordinates when you create or search for nearby sessions (only with your permission)\n'
              '• Receipt Images: Photos of receipts you scan (processed locally and not permanently stored)',
            ),

            _buildSection(
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide and maintain our service\n'
              '• Process and calculate bill splits\n'
              '• Enable collaborative session features\n'
              '• Find nearby active sessions based on location\n'
              '• Send notifications about bills and payments\n'
              '• Improve and optimize our application\n'
              '• Respond to your requests and provide customer support',
            ),

            _buildSection(
              'Data Storage and Security',
              'We implement appropriate technical and organizational measures to protect your personal information:\n\n'
              '• Data is stored securely on encrypted servers\n'
              '• We use industry-standard security protocols\n'
              '• Access to personal data is restricted to authorized personnel only\n'
              '• We do not store receipt images permanently\n'
              '• Session data is automatically deleted after expiration',
            ),

            _buildSection(
              'Data Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n'
              '• With other users: Bill and session information is shared with participants you add\n'
              '• With your consent: When you explicitly agree to share your information\n'
              '• For legal purposes: If required by law or to protect our legal rights',
            ),

            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
              '• Access your personal information\n'
              '• Update or correct your information\n'
              '• Delete your account and associated data\n'
              '• Withdraw consent for data processing\n'
              '• Export your data',
            ),

            _buildSection(
              'Location Data',
              'Location data is only collected when you:\n\n'
              '• Create a collaborative session with GPS enabled\n'
              '• Search for nearby sessions\n\n'
              'You can disable location services at any time in your device settings. Location data is only used to enable the nearby sessions feature and is not tracked continuously.',
            ),

            _buildSection(
              'Contact Information',
              'Contact data from your device is:\n\n'
              '• Accessed only with your permission\n'
              '• Used only to help you add participants to bills and sessions\n'
              '• Not permanently stored on our servers\n'
              '• Never shared with third parties',
            ),

            _buildSection(
              'Data Retention',
              'We retain your information for as long as necessary to provide our services. You can request deletion of your account and data at any time. After deletion:\n\n'
              '• Your personal information will be removed from our active databases\n'
              '• Some information may be retained in backups for up to 30 days\n'
              '• Bills and sessions you participated in will be anonymized',
            ),

            _buildSection(
              'Children\'s Privacy',
              'DuTaksim is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            ),

            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the app. Changes are effective when posted.',
            ),

            _buildSection(
              'Contact Us',
              'If you have questions about this Privacy Policy, please contact us:\n\n'
              'Email: privacy@dutaksim.app\n'
              'Created for Bank Eskhata App Competition',
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
