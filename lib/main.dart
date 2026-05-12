import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tzxpzxiymslswlymykxo.supabase.co',
    anonKey: 'sb_publishable_MJTq0A7I6i0Rv4k9gx9B-Q_6rJ9IxTc',
  );
  runApp(const ImpostorCardsApp());
}

class ImpostorCardsApp extends StatelessWidget {
  const ImpostorCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impostor Cards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}