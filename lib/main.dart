// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SessionService()),
      ],
      child: MaterialApp(
        title: 'Parking Management System',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.grey[100],
          fontFamily: 'Roboto',
        ),
        debugShowCheckedModeBanner: false, // Remove debug banner
        home: Consumer<AuthService>(
          builder: (context, auth, child) {
            if (auth.isLoggedIn) {
              if (auth.userRole == 'admin') {
                return AdminDashboardScreen();
              } else {
                return UserDashboardScreen();
              }
            }
            return LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/admin': (context) => AdminDashboardScreen(),
          '/user': (context) => UserDashboardScreen(),
        },
      ),
    );
  }
}