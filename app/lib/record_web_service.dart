import 'package:http/http.dart' as http;

class RecordWebService {
  final String uploadUrl;

  RecordWebService(this.uploadUrl);

  Future<http.Response> uploadAudioFile(List<int> audioBytes, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      audioBytes,
      filename: filename,
    ));

    var response = await request.send();
    return await http.Response.fromStream(response);
  }
}
