import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationManager {
  PushNotificationManager._();

  factory PushNotificationManager() => _instance;
  static final PushNotificationManager _instance = PushNotificationManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<void> init() async {
    if (!this._initialized) {
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          print("onMessage: $message");
        },
      );

      String token = await _firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");

      _initialized = true;
    }
  }
}
