import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // Replace these with your actual values from Cloudinary Dashboard
  final String cloudName = "dx69jhzba";
  final String uploadPreset = "student_app_upload";

  Future<String?> uploadImage(File imageFile) async {
    try {
      // 1. Prepare the URL
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      // 2. Prepare the Request
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // 3. Send Request
      final response = await request.send();

      // 4. Handle Response
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);

        // This is the public URL of your image
        return jsonMap['secure_url'];
      } else {
        print("❌ Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error uploading to Cloudinary: $e");
      return null;
    }
  }
}