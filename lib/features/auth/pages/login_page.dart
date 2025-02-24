import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.jpg',
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 80.0,
                      maxHeight: 80.0,
                    ),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email/Handle',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        floatingLabelStyle: TextStyle(
                          backgroundColor: Colors.white,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or handle.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 80.0,
                      maxHeight: 80.0,
                    ),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'App Password',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        floatingLabelStyle: TextStyle(
                          backgroundColor: Colors.white,
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8.0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Text(
                  'Image by syd. trgt ✪ on pexels.com',
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [
                      BoxShadow(
                        blurRadius: 4.0,
                        spreadRadius: 4.0,
                        color: Colors.black,
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
