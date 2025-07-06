import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prompt_manager/features/prompt_management/presentation/screens/prompt_manager_screen.dart';
import 'package:prompt_manager/features/prompt_management/presentation/providers/prompt_provider.dart';
import 'package:prompt_manager/core/theme/app_theme.dart';

void main() {
  runApp(const PromptManagerApp());
}

class PromptManagerApp extends StatelessWidget {
  const PromptManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Using ChangeNotifierProvider as specified in the architecture plan
    return ChangeNotifierProvider(
      create: (context) => PromptProvider()..loadInitialData(),
      child: MaterialApp(
        title: 'Prompt Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // Light theme from your specs
        darkTheme: AppTheme.darkTheme, // Dark theme from your specs
        themeMode: ThemeMode.system, // Or allow user to choose
        home: const PromptManagerScreen(),
      ),
    );
  }
} 