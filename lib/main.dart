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
  const MyApp({super.key});

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
        ),
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthService>(
          builder: (context, auth, child) {
            if (auth.isLoggedIn) {
              if (auth.userRole == 'admin') {
                return const AdminDashboardScreen();
              } else {
                return const UserDashboardScreen();
              }
            }
            return const LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/user': (context) => const UserDashboardScreen(),
        },
      ),
    );
  }
}
