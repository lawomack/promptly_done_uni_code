import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:uni_project/promptly_done.dart';
import 'package:intl/date_symbol_data_local.dart';


var kColorScheme = ColorScheme.fromSeed(seedColor: Colors.lightBlue);
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  // ensure date is displayed in UK format
  await initializeDateFormatting('en_GB', null);
  runApp(
    // Phoenix enables the app to be restarted automatically
    Phoenix(
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        debugShowCheckedModeBanner: false,
        theme: ThemeData().copyWith(
          colorScheme: kColorScheme,
          appBarTheme: const AppBarTheme().copyWith(
            backgroundColor: kColorScheme.onPrimaryContainer,
            foregroundColor: kColorScheme.primaryContainer,
          ),
          cardTheme: CardThemeData().copyWith(
            color: kColorScheme.secondaryContainer,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kColorScheme.primaryContainer,
            ),
          ),
          textTheme: ThemeData().textTheme.copyWith(
            titleLarge: TextStyle(fontWeight: FontWeight.bold, color: kColorScheme.onSecondaryContainer, fontSize: 24),
          ),
        ),
        home: PromptlyDone(),
      ),
    ),
  );
}

