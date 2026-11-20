import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'cloudinary_config.dart';

/// Боркунии акс тавассути Cloudinary. XFile дар ҳама платформаҳо
/// (Android, iOS, Web) кор мекунад.
class StorageService {
  Uri get _uploadUrl =>
      Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');

  Future<String> uploadPropertyPhoto(String companyId, XFile file) async {
    final bytes = await file.readAsBytes();

    // Аксҳо акнун ҳангоми интихоб (дар add_property_screen) хурд карда мешаванд,
    // вале ин санҷиш ҳимояи иловагӣ аст — агар манбаи дигаре акси хеле калон
    // фиристад, хатои фаҳмо медиҳем, на афтодани интизории беохир.
    const maxBytes = 12 * 1024 * 1024; // 12 МБ
    if (bytes.length > maxBytes) {
      throw Exception('Акс хеле калон аст (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} МБ)');
    }

    final request = http.MultipartRequest('POST', _uploadUrl)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'realestate/$companyId'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception('Боргирии акс аз ҳад зиёд тӯл кашид (интернетро санҷед)'),
        );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}
