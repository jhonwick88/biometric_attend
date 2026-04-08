import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAc36o1jTBlLGREynXzC-zLjSjYpk6dOms',
    appId: '1:1015248726425:web:758d390fffd19cdfd48b08',
    messagingSenderId: '1015248726425',
    projectId: 'biometric-pintar',
    authDomain: 'biometric-pintar.firebaseapp.com',
    storageBucket: 'biometric-pintar.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    
    apiKey: 'AIzaSyCoI5E4CpdcDdIiWwut2bRVwJQGI3FmyVI',
    appId: '1:1015248726425:android:5ddb954ed63d1ecad48b08',
    messagingSenderId: '1015248726425',
    projectId: 'biometric-pintar',
    storageBucket: 'biometric-pintar.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_ios_api_key',
    appId: '1:1234567890:ios:placeholder123',
    messagingSenderId: '1234567890',
    projectId: 'biometric-attend-placeholder',
    storageBucket: 'biometric-attend-placeholder.appspot.com',
    iosBundleId: 'com.example.biometricAttend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_macos_api_key',
    appId: '1:1234567890:ios:placeholder123_mac',
    messagingSenderId: '1234567890',
    projectId: 'biometric-attend-placeholder',
    storageBucket: 'biometric-attend-placeholder.appspot.com',
    iosBundleId: 'com.example.biometricAttend',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_windows_api_key',
    appId: '1:1234567890:web:placeholder123_win',
    messagingSenderId: '1234567890',
    projectId: 'biometric-attend-placeholder',
    authDomain: 'biometric-attend-placeholder.firebaseapp.com',
    storageBucket: 'biometric-attend-placeholder.appspot.com',
    measurementId: 'G-placeholderXYZ2',
  );
}