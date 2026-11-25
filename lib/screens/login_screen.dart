import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  bool _admin = false;
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _key,
              child: Column(
                children: [
                  Icon(Icons.location_city,
                      size: 90, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('مدينتي الذكية',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text('بلّغ عن مشكلة في الشارع وتابع حلها'),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'اكتب اسمك' : null,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('مواطن'),
                          icon: Icon(Icons.person_outline)),
                      ButtonSegment(
                          value: true,
                          label: Text('مسؤول'),
                          icon: Icon(Icons.admin_panel_settings_outlined)),
                    ],
                    selected: {_admin},
                    onSelectionChanged: (s) => setState(() => _admin = s.first),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_key.currentState!.validate()) {
                          context
                              .read<AppProvider>()
                              .login(_name.text, admin: _admin);
                        }
                      },
                      child: const Text('دخول'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
