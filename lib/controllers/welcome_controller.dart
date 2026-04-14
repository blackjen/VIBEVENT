import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class WelcomeController {
  void goToLogin(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  void goToRegister(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.register);
  }
}
