import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/splitwise_provider.dart';
import 'providers/sms_provider.dart';
import 'providers/language_provider.dart';
import 'package:finzo/l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/home/debt_list_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splitwise/splitwise_home_screen.dart';
import 'features/financial_calculator/finance_manager_screen.dart';
import 'screens/feature_selection_screen.dart';
import 'screens/auth/login_screen.dart';

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
        ChangeNotifierProvider(create: (_) => LanguageProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            onGenerateTitle: (context) => context.l10n.t('app_title'),
            debugShowCheckedModeBanner: false,
            theme: FinzoAppTheme.light(),
            darkTheme: FinzoAppTheme.dark(),
            themeMode: themeProvider.themeMode,
            locale: context.watch<LanguageProvider>().locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/login':
                  return MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                    settings: settings,
                  );
                case '/home':
                  return MaterialPageRoute(
                    builder: (context) => const FeatureSelectionScreen(),
                    settings: settings,
                  );
                case '/personal-finance':
                  return MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                    settings: settings,
                  );
                case '/group-finance':
                  return MaterialPageRoute(
                    builder: (context) => const SplitwiseHomeScreen(),
                    settings: settings,
                  );
                case '/finance-manager':
                  return MaterialPageRoute(
                    builder: (context) => const FinanceManagerScreen(),
                    settings: settings,
                  );
                case '/debts':
                  return MaterialPageRoute(
                    builder: (context) => const DebtListScreen(),
                    settings: settings,
                  );
                default:
                  return MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                    settings: settings,
                  );
              }
            },
            builder: (context, child) {
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}


