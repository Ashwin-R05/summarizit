import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:summarizit/screens/home_screen.dart';
import 'package:summarizit/theme/theme_provider.dart';

void main() {
  runApp(const SummarizItApp());
}

class SummarizItApp extends StatefulWidget {
  const SummarizItApp({super.key});

  @override
  State<SummarizItApp> createState() => _SummarizItAppState();
}

class _SummarizItAppState extends State<SummarizItApp> {
  final ThemeProvider themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    themeProvider.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final darkText = GoogleFonts.outfitTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
    final lightText = GoogleFonts.outfitTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    );

    return MaterialApp(
      title: 'SummarizIt',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // ── Dark theme ──
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          brightness: Brightness.dark,
        ),
        textTheme: darkText,
        useMaterial3: true,
      ),

      // ── Light theme ──
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          brightness: Brightness.light,
        ),
        textTheme: lightText,
        useMaterial3: true,
      ),

      home: HomeScreen(themeProvider: themeProvider),
    );
  }
}
