import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/prompt_management/presentation/providers/prompt_provider.dart';
import 'features/prompt_management/presentation/screens/prompt_manager_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => PromptProvider(),
        ),
      ],
      child: Consumer<PromptProvider>(
        builder: (context, promptProvider, child) {
          return MaterialApp(
            title: 'Prompt Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: promptProvider.themeMode,
            home: const PromptManagerScreen(),
          );
        },
      ),
    );
  }
} 