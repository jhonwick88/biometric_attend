import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/config_viewmodel.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
Widget build(BuildContext context) {
  final authState = ref.watch(authControllerProvider);
  final configAsync = ref.watch(appConfigProvider);

  ref.listen<AsyncValue>(
    authControllerProvider,
    (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString())),
        );
      }
    },
  );

  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFE4EC),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint, size: 70, color: Color(0xFFD4AF37)),
                const SizedBox(height: 16),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // CARD LOGIN
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: authState.isLoading
                              ? null
                              : () {
                                  ref.read(authControllerProvider.notifier).login(
                                        _emailCtrl.text.trim(),
                                        _passwordCtrl.text.trim(),
                                      );
                                },
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF6F91),
                                  Color(0xFFD4AF37),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: authState.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // BIOMETRIC
                IconButton(
                  iconSize: 50,
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          ref.read(authControllerProvider.notifier).loginWithBiometrics();
                        },
                  icon: const Icon(Icons.fingerprint, color: Color(0xFFD4AF37)),
                ),
                const Text(
                  'Login cepat dengan Sidik Jari',
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 16),

                configAsync.asData?.value?.showRegister == true 
                  ? TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const Text('Belum punya akun? Register'),
                    )
                  : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
