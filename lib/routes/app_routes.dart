import 'package:flutter/material.dart';
import 'package:vibevent/views/main_view.dart';
import '../views/welcome_view.dart';
import '../views/login_view.dart';
import '../views/register_view.dart';

class AppRoutes {

  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String mainview = '/mainview';


  static Map<String, WidgetBuilder> get routes {
    return {
      welcome: (context) => const WelcomeView(),
      login: (context) => const LoginView(),
      register: (context) => const RegisterView(),
      mainview: (context) => const MainView(),
    };
  }
}
