import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCEdQPWRlQE2FNzBbGXP_g_fL1L8c0deKo',
    authDomain: 'pet-care-app-439dd.firebaseapp.com',
    databaseURL: 'https://pet-care-app-439dd-default-rtdb.firebaseio.com',
    projectId: 'pet-care-app-439dd',
    storageBucket: 'pet-care-app-439dd.firebasestorage.app',
    messagingSenderId: '250967116627',
    appId: '1:250967116627:web:1b9b354b5583215edc6fa6',
    measurementId: 'G-DJN3C9NW4S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCEdQPWRlQE2FNzBbGXP_g_fL1L8c0deKo',
    authDomain: 'pet-care-app-439dd.firebaseapp.com',
    databaseURL: 'https://pet-care-app-439dd-default-rtdb.firebaseio.com',
    projectId: 'pet-care-app-439dd',
    storageBucket: 'pet-care-app-439dd.firebasestorage.app',
    messagingSenderId: '250967116627',
    appId: '1:250967116627:android:6d099f1372d29f18dc6fa6',
  );
}
