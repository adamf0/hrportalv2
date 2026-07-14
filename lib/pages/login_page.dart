import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../core/sso_helper.dart';
import '../core/responsive_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    // Check for active login session
    _checkAutoLogin();
    
    // Check for SSO callback (for web platforms)
    _checkSsoCallback();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _checkAutoLogin() async {
    try {
      final validToken = await SsoHelper.getValidToken();
      if (validToken != null) {
        final name = await SsoHelper.getLoggedInName();
        if (name != null) {
          if (!mounted) return;
          final appState = Provider.of<AppState>(context, listen: false);
          appState.login(name, "");
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Masuk otomatis kembali sebagai $name."),
              backgroundColor: const Color(0xff00b55d),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Auto Login Error: $e");
    }
  }

  void _checkSsoCallback() async {
    try {
      final ssoData = await SsoHelper.checkAndExchangeCode();
      if (ssoData != null) {
        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        appState.login(ssoData['name'] ?? "User", "");
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selamat Datang, ${ssoData['name']}! Berhasil masuk via SSO."),
            backgroundColor: const Color(0xff00b55d),
          ),
        );
      }
    } catch (e) {
      debugPrint("SSO Callback Check Error: $e");
    }
  }

  void _handleSsoLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final ssoData = await SsoHelper.loginWithSso();
      if (ssoData != null) {
        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        appState.login(ssoData['name'] ?? "User", "");
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Selamat Datang, ${ssoData['name']}! Berhasil masuk via SSO."),
            backgroundColor: const Color(0xff00b55d),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("SSO Login failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleDemoBypass() {
    // Secret double tap bypass for testing
    final appState = Provider.of<AppState>(context, listen: false);
    appState.login("Budi Santoso", "");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Berhasil masuk via Demo Bypass (Aditama)."),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    const primaryColor = Color(0xFF003D9B);
    const secondaryColor = Color(0xFF535F73);
    const outlineVariant = Color(0x4DC3C6D6);
    const onSurfaceVariant = Color(0xFF434654);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryColor.withOpacity(0.06),
              ),
            ),
          ),
          // Scrollable content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isWatch ? 10.0 : 24.0,
                  vertical: context.isWatch ? 8.0 : 16.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo Section (Double tap acts as developer bypass for testing)
                      GestureDetector(
                        onDoubleTap: _handleDemoBypass,
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -6 * _floatController.value),
                              child: child,
                            );
                          },
                          child: Container(
                            width: context.w(64),
                            height: context.w(64),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.corporate_fare,
                              color: Colors.white,
                              size: context.w(36),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.h(16)),
                      Text(
                        'HR Portal',
                        style: GoogleFonts.inter(
                          fontSize: context.sp(22),
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          letterSpacing: -0.01,
                        ),
                      ),
                      SizedBox(height: context.h(24)),
                      
                      // Welcome text
                      Text(
                        'Selamat Datang',
                        style: GoogleFonts.inter(
                          fontSize: context.sp(24),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF191C1E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Silakan masuk dengan akun SSO Universitas Pakuan Anda',
                        style: GoogleFonts.inter(
                          fontSize: context.sp(13),
                          fontWeight: FontWeight.w400,
                          color: onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.h(24)),
 
                      // SSO Login Card
                      Container(
                        padding: EdgeInsets.all(context.isWatch ? 12 : 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: outlineVariant, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Single Sign-On',
                              style: GoogleFonts.inter(
                                fontSize: context.sp(13),
                                fontWeight: FontWeight.bold,
                                color: onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            
                            _isLoading
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      child: CircularProgressIndicator(color: primaryColor),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _handleSsoLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: context.isWatch ? 10 : 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(Icons.badge_outlined, size: context.w(20)),
                                    label: Text(
                                      'Masuk dengan Unpak SSO',
                                      style: GoogleFonts.inter(
                                        fontSize: context.sp(13),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.h(24)),
 
                      // HR Help Text
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Butuh bantuan akses? ',
                            style: GoogleFonts.inter(fontSize: context.sp(13), color: onSurfaceVariant),
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Menghubungi HRD (021-xxxx-xxxx)')),
                              );
                            },
                            child: Text(
                              'Hubungi HRD',
                              style: GoogleFonts.inter(
                                fontSize: context.sp(13),
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Language Selection
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Bahasa Indonesia',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            color: Colors.grey[300],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'English',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Copyright Text
                      Text(
                        '© 2024 HR Portal Solutions. All rights reserved.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
