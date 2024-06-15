import 'dart:convert';
import 'dart:typed_data';

import 'package:app/product.dart';
import 'package:http/http.dart' as http;

class RecordWebService {
  final String uploadUrl;

  RecordWebService(this.uploadUrl);
  Future<List<Product>> uploadAudioFile(Uint8List audioData, String fileName) async {
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    print('sending request to $uploadUrl');
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      audioData,
      filename: fileName,
    ));
    var response = await http.Response.fromStream(await request.send());
    var json = jsonDecode(response.body) as Map<String, dynamic>;
    var productsJson = json['products'] as List<dynamic>;
    return productsJson
        .map((productJson) => Product.fromJson(productJson))
        .toList();
  }
}