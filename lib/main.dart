import 'package:flutter/material.dart';
// Note: We use the local file imports for the distributed code structure
import 'package:areax/services/auth_service.dart'; 
import 'package:areax/screens/auth_screen.dart';
import 'package:areax/screens/main_navigator.dart';
import 'package:areax/config/constants.dart';

// The AuthService instance is created here and passed down.
// In a larger app, this might be managed by a global service locator or a dedicated Provider.
final AuthService _authService = AuthService();

void main() {
  // Ensure that Flutter bindings are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AreaxApp());
}

class AreaxApp extends StatefulWidget {
  const AreaxApp({super.key});

  @override
  State<AreaxApp> createState() => _AreaxAppState();
}

class _AreaxAppState extends State<AreaxApp> {
  // Note: Since _authService is final and initialized outside the build method, 
  // we can safely use it here.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Areax',
      // Define the application theme using constants from lib/config/constants.dart
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          error: kErrorColor,
          background: kBackgroundColor,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4.0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: kPrimaryColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        ),
      ),
      // ListenableBuilder listens to the AuthService for state changes (login/logout)
      // and rebuilds the home widget accordingly.
      home: ListenableBuilder(
        listenable: _authService,
        builder: (context, child) {
          if (_authService.isLoading) {
            // Show a loading screen while checking for existing tokens
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (_authService.isAuthenticated) {
            // User is logged in, show the main application navigator
            return BottomBarNavigator(authService: _authService);
          } else {
            // User is logged out, show the login screen
            return AuthScreen(authService: _authService);
          }
        },
      ),
    );
  }
}
