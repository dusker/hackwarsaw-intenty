import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class RecordWebService {
  final String uploadUrl;

  RecordWebService(this.uploadUrl);

  Future<http.Response> uploadAudioFile(File audioFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(await http.MultipartFile.fromPath(
      'audio',
      audioFile.path,
      filename: basename(audioFile.path),
    ));

    var response = await request.send();
    return await http.Response.fromStream(response);
  }
}
