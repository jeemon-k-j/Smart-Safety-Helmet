// File generated for project scaffolding. Replace values by running:
//   flutterfire configure
//
// Do not commit production secrets. Placeholder values allow the app to
// compile before a Firebase project is linked.

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
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smart-safety-helmet',
    authDomain: 'smart-safety-helmet.firebaseapp.com',
    databaseURL: 'https://smart-safety-helmet-default-rtdb.firebaseio.com',
    storageBucket: 'smart-safety-helmet.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smart-safety-helmet',
    databaseURL: 'https://smart-safety-helmet-default-rtdb.firebaseio.com',
    storageBucket: 'smart-safety-helmet.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smart-safety-helmet',
    databaseURL: 'https://smart-safety-helmet-default-rtdb.firebaseio.com',
    storageBucket: 'smart-safety-helmet.appspot.com',
    iosBundleId: 'com.academicsafety.smartSafetyHelmet',
  );
}
