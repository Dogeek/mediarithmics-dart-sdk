import 'dart:convert';

import 'package:advertising_id/advertising_id.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import './interfaces.dart';

class MicsSdk {
  static final MicsSdk _instance = MicsSdk._internal();

  late List<int> secretKey;
  late String keyId;
  late String appId;
  late String datamartId;
  String? _advertisingId;
  bool triedFetchingAdvertisingId = false;
  String domain = "https://api.mediarithmics.com";
  String apiVersion = 'v1';

  factory MicsSdk(
      {required String secretKey,
      required String keyId,
      required String appId,
      required String datamartId}) {
    _instance.secretKey = utf8.encode(secretKey);
    _instance.keyId = keyId;
    _instance.appId = appId;
    _instance.datamartId = datamartId;
    return _instance;
  }

  Future<String?> get advertisingId async {
    if (triedFetchingAdvertisingId) {
      return null;
    }
    if (_advertisingId != null) {
      return _advertisingId;
    }
    _advertisingId = await AdvertisingId.id(true);
    return _advertisingId;
  }

  Map<String, String> makeHeaders(String uri, {Map<String, dynamic>? body}) {
    int ts = DateTime.now().millisecondsSinceEpoch;
    String encodedBody = body != null ? jsonEncode(body) : '';
    String message = '$uri\n$keyId\n$ts\n$encodedBody';
    List<int> encoded = utf8.encode(message);
    Hmac hmacSha256 = Hmac(sha256, secretKey);
    Digest digest = hmacSha256.convert(encoded);
    String signature = digest.toString();

    return {
      'X-Mics-Key-Id': keyId,
      'X-Mics-Ts': ts.toString(),
      'X-Mics-Mac': signature,
    };
  }

  Future<http.Response> _get(String uri) async {
    Uri fullUri = Uri.parse('$domain/$apiVersion/$uri');
    Map<String, String> headers = makeHeaders(uri);
    return await http.get(fullUri, headers: headers);
  }

  Future<http.Response> _post(String uri, {Map<String, dynamic>? body}) async {
    Uri fullUri = Uri.parse('$domain/$apiVersion/$uri');
    Map<String, String> headers = makeHeaders(uri, body: body);
    return await http.post(fullUri, headers: headers, body: body);
  }

  Future<SegmentListResource> getSegmentsByUserAccountId(
      String userAccountId, String compartmentId) async {
    http.Response response = await _get(
        'datamarts/$datamartId/user_points/compartmentId=$compartmentId,user_account_id=$userAccountId/user_segments');
    if (response.statusCode == 200) {
      return SegmentListResource.fromJSON(jsonDecode(response.body));
    }
    throw 'API call responded with status ${response.statusCode}';
  }

  Future<SegmentListResource> getSegmentsByUserEmail(String userEmail,
      {bool doHash = false}) async {
    if (doHash) {
      userEmail = sha256.convert(utf8.encode(userEmail)).toString();
    }
    http.Response response = await _get(
        'datamarts/$datamartId/user_points/email_hash=$userEmail/user_segments');
    if (response.statusCode == 200) {
      return SegmentListResource.fromJSON(jsonDecode(response.body));
    }
    throw 'API call responded with status ${response.statusCode}';
  }

  Future<SegmentListResource> getSegmentsByUserAgent(String userAgentId) async {
    http.Response response = await _get(
        'datamarts/$datamartId/user_points/user_agent_id=$userAgentId/user_segments');
    if (response.statusCode == 200) {
      return SegmentListResource.fromJSON(jsonDecode(response.body));
    }
    throw 'API call responded with status ${response.statusCode}';
  }

  Future<Map<String, dynamic>> postActivity(String eventName,
      {Map<String, dynamic>? properties,
      List<UserIdentifier> identifiers = const [],
      bool aggregated = false}) async {
    // Generate the activity based on the parameters provided to the SDK
    int ts = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic> activity = {
      '\$type': 'APP_VISIT',
      '\$session_status': aggregated ? 'CLOSED_SESSION' : 'IN_SESSION',
      '\$user_agent_id': advertisingId,
      '\$app_id': appId,
      '\$ts': ts,
    };
    Map<String, dynamic> event = {
      '\$event_name': eventName,
      '\$ts': ts
    };
    if (properties != null) {
      event['\$properties'] = properties;
    }
    activity['\$events'] = [event];
    for (UserIdentifier identifier in identifiers) {
      identifier.formatted.forEach((key, value) {
        activity.putIfAbsent(key, () => value);
      });
    }

    http.Response response =
        await _post('datamarts/$datamartId/user_activities', body: activity);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw 'API call responded with status ${response.statusCode}';
  }

  Future<Map<String, dynamic>> postAppOpen(
      {Map<String, dynamic>? properties}) async {
    return await postActivity('\$app_open', properties: properties);
  }

  MicsSdk._internal();
}
