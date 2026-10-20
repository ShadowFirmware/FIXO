import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_session.dart';

/// Pantalla de arranque: revisa si hay una sesión guardada y decide si
/// mostrar el login o entrar directo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await AuthSession.instance.restore();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      user == null ? RouteNames.login : RouteNames.homeFor(user.role),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.logo, height: 88),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
