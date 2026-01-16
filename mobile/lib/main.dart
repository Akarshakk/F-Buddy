import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/splitwise_provider.dart';
import 'providers/sms_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home/debt_list_screen.dart';
import 'screens/feature_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SMS provider
  final smsProvider = SmsProvider();
  await smsProvider.initializeOnStartup();
  
  runApp(MyApp(smsProvider: smsProvider));
}

class MyApp extends StatelessWidget {
  final SmsProvider smsProvider;
  
  const MyApp({super.key, required this.smsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => SplitWiseProvider()),
        ChangeNotifierProvider.value(value: smsProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'F Buddy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            ),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const FeatureSelectionScreen(),
              '/debts': (context) => const DebtListScreen(),
            },
            onUnknownRoute: (settings) {
              // Handle unknown routes gracefully
              return MaterialPageRoute(
                builder: (context) => const FeatureSelectionScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
