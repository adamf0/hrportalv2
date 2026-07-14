import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/app_state.dart';
import 'pages/login_page.dart';
import 'pages/main_shell.dart';
import 'pages/splash_page.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const HrPortalApp(),
    ),
  );
}

class HrPortalApp extends StatelessWidget {
  const HrPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    const primaryColor = Color(0xFF003D9B);
    const secondaryColor = Color(0xFF535F73);

    return MaterialApp(
      title: 'HR Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: const Color(0xFFF8F9FB),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      ),
      home: const SplashPage(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Switch between Login and Main Shell depending on logged-in state
    if (appState.isLoggedIn) {
      return const MainShell();
    } else {
      return const LoginPage();
    }
  }
}
