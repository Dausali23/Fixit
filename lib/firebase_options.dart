// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyA29m34xSGFkIB7OWfpnStS56pfaXYRmBs',
    appId: '1:921118105926:web:2fd51df53d55ef3005c547',
    messagingSenderId: '921118105926',
    projectId: 'fixit-a8039',
    authDomain: 'fixit-a8039.firebaseapp.com',
    storageBucket: 'fixit-a8039.firebasestorage.app',
    measurementId: 'G-5CG7BFP6XR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuaNhhiJXFXzmvpu5ApYcrwhXXIezDLrk',
    appId: '1:921118105926:android:aae893ebaf578eb305c547',
    messagingSenderId: '921118105926',
    projectId: 'fixit-a8039',
    storageBucket: 'fixit-a8039.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSQEXX6y72rNH8bl7zl7_lZOLoPoCHtbk',
    appId: '1:921118105926:ios:4d8023ce1d3aa73205c547',
    messagingSenderId: '921118105926',
    projectId: 'fixit-a8039',
    storageBucket: 'fixit-a8039.firebasestorage.app',
    iosBundleId: 'com.example.fixit',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCSQEXX6y72rNH8bl7zl7_lZOLoPoCHtbk',
    appId: '1:921118105926:ios:4d8023ce1d3aa73205c547',
    messagingSenderId: '921118105926',
    projectId: 'fixit-a8039',
    storageBucket: 'fixit-a8039.firebasestorage.app',
    iosBundleId: 'com.example.fixit',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA29m34xSGFkIB7OWfpnStS56pfaXYRmBs',
    appId: '1:921118105926:web:45b2216c759ac4f105c547',
    messagingSenderId: '921118105926',
    projectId: 'fixit-a8039',
    authDomain: 'fixit-a8039.firebaseapp.com',
    storageBucket: 'fixit-a8039.firebasestorage.app',
    measurementId: 'G-G9XSPN7QNK',
  );
}
