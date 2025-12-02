import 'package:firebase_core/firebase_core.dart';


const String apiKey = "AIzaSyCNX19bfr4qH17ChGoeOGufaUHPF_YZfIo"; 
const String authDomain = "goinfo-caa1c.firebaseapp.com";
const String projectId = "goinfo-caa1c";
const String storageBucket = "goinfo-caa1c.firebasestorage.app";
const String messagingSenderId = "338519783622";
const String appId = "1:338519783622:web:d7b4f43b12dc6e1191bfc7";


FirebaseOptions get currentPlatform {
  return const FirebaseOptions(
    apiKey: apiKey,
    authDomain: authDomain,
    projectId: projectId,
    storageBucket: storageBucket,
    messagingSenderId: messagingSenderId,
    appId: appId,
  );
}