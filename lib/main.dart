import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/habit_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Mandatory initialization for google_sign_in v7.0.0+ with serverClientId
  // serverClientId causes a crash on Web, so we only pass it if not web
  await GoogleSignIn.instance.initialize(
    clientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    serverClientId: kIsWeb ? null : dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
      ],
      child: MaterialApp(
        title: 'Trackify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D9E75),
            primary: const Color(0xFF1D9E75),
            secondary: const Color(0xFF00D2FD),
            surface: const Color(0xFF131318),
            background: const Color(0xFF0D0D15),
            onBackground: Colors.white,
            onSurface: Colors.white,
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.outfitTextTheme(
            Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D15),
          cardTheme: CardThemeData(
            color: const Color(0xFF1F1F25),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
