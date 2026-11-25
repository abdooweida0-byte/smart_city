import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';

class CloudinaryService {
  static Future<String> upload(XFile file) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudName}/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ));
    final res = await req.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) {
      throw Exception('فشل رفع الصورة (تأكد من إعدادات Cloudinary)');
    }
    return (jsonDecode(body) as Map<String, dynamic>)['secure_url'] as String;
  }
}
