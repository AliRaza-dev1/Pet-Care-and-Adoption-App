import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        // Show loading screen while Firebase initializes
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              ),
            ),
          );
        }

        // Show error if Firebase initialization failed
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 60),
                    SizedBox(height: 20),
                    Text(
                      'Firebase initialization failed',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    SizedBox(height: 10),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Firebase initialized successfully
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pet Care App',
          theme: ThemeData(
            primaryColor: Color(0xFFFF6B35),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFFFF6B35),
              primary: Color(0xFFFF6B35),
            ),
            useMaterial3: true,
          ),
          home: SplashScreen(),
        );
      },
    );
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('⚠️ Firebase initialization: $e');
      // If already initialized, that's fine
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }
  }
}
