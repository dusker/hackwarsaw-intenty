import 'dart:typed_data';

import 'package:http/http.dart' as http;

class RecordWebService {
  final String uploadUrl;

  RecordWebService(this.uploadUrl);
  Future<String?> uploadAudioFile(Uint8List audioData, String fileName) async {
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      audioData,
      filename: fileName,
    ));

    try {
      var response = await http.Response.fromStream(await request.send());
      print(response.body);

      return response.body;
    } catch(error) {
      print(error);
      return null;
    }
  }
}