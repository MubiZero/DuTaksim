import 'dart:convert';
import '../config/constants.dart';

class QRGenerator {
  static String generatePaymentQR(String phone) {
    final data = {
      'service_id': Constants.bankEskhataServiceId,
      'phone': phone,
    };

    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final base64String = base64.encode(bytes);

    return base64String;
  }
}
