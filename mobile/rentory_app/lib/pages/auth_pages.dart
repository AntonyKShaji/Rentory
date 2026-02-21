import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../widgets/app_widgets.dart';
import 'owner_pages.dart';
import 'tenant_pages.dart';

class OwnerAuthPage extends StatefulWidget {
  const OwnerAuthPage({super.key});

  @override
  State<OwnerAuthPage> createState() => _OwnerAuthPageState();
}

class _OwnerAuthPageState extends State<OwnerAuthPage> {
  final ApiService _api = ApiService();
  final _phone = TextEditingController();
  final _name = TextEditingController(text: 'Owner');
  final _email = TextEditingController(text: 'owner@rentory.local');
  final _password = TextEditingController(text: '1234');
  bool _isSignup = true;
  bool _obscurePassword = true;
  bool _loading = false;
  final Map<String, String?> _errors = {};

  bool _validate() {
    final nextErrors = <String, String?>{};
    if (_isSignup && _name.text.trim().isEmpty) {
      nextErrors['name'] = 'Full name is required';
    }
    if (_phone.text.trim().isEmpty) {
      nextErrors['phone'] = 'Phone is required';
    }
    if (_isSignup && _email.text.trim().isEmpty) {
      nextErrors['email'] = 'Email is required';
    }
    if (_password.text.trim().isEmpty) {
      nextErrors['password'] = 'Password is required';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });
    return nextErrors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      final payload = _isSignup
          ? await _api.ownerSignup(fullName: _name.text, phone: _phone.text, email: _email.text, password: _password.text)
          : await _api.login(identifier: _phone.text, password: _password.text, role: 'owner');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerDashboardPage(ownerId: payload['user_id'] as String)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const shellColor = Color(0xFFF2F2F2);
    const fieldColor = Color(0xFFE9E9EE);
    const primaryTextColor = Color(0xFF1E3363);
    const secondaryTextColor = Color(0xFF6B7391);
    const actionColor = Color(0xFF8CC63F);

    InputDecoration _decoration({
      required String hint,
      required IconData icon,
      String? error,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w500),
        errorText: error,
        filled: true,
        fillColor: fieldColor,
        prefixIcon: Icon(icon, size: 16, color: primaryTextColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryTextColor, width: 1.2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
    }

    return Scaffold(
      backgroundColor: shellColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: shellColor,
              borderRadius: BorderRadius.circular(26),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE8E8ED),
                      foregroundColor: primaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  _isSignup ? 'Create your account' : 'Owner login',
                  style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'quis nostrud exercitation ullamco laboris nisi ut',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 36),
                if (_isSignup) ...[
                  TextField(controller: _name, decoration: _decoration(hint: 'Full name', icon: Icons.person_outline, error: _errors['name'])),
                  const SizedBox(height: 12),
                  TextField(controller: _email, decoration: _decoration(hint: 'Email', icon: Icons.mail_outline, error: _errors['email'])),
                  const SizedBox(height: 12),
                ],
                TextField(controller: _phone, decoration: _decoration(hint: _isSignup ? 'Phone number' : 'Email or phone', icon: Icons.phone_rounded, error: _errors['phone'])),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  decoration: _decoration(hint: 'Password', icon: Icons.lock_outline, error: _errors['password']),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Terms of service', style: TextStyle(fontSize: 12, color: primaryTextColor, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(20, 20), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(_obscurePassword ? 'Show password' : 'Hide password', style: const TextStyle(fontSize: 12, color: primaryTextColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_isSignup ? 'Register' : 'Login'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _isSignup = !_isSignup;
                    _errors.clear();
                  }),
                  child: Text(
                    _isSignup ? 'Already have an account? Login' : 'Need an account? Register',
                    style: const TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TenantAuthPage extends StatefulWidget {
  const TenantAuthPage({super.key});

  @override
  State<TenantAuthPage> createState() => _TenantAuthPageState();
}

class _TenantAuthPageState extends State<TenantAuthPage> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final _identifier = TextEditingController();
  final _password = TextEditingController(text: '1234');
  bool _isRegister = true;
  bool _loading = false;
  final _qr = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  String? _aadharImageDataUri;
  final _email = TextEditingController();
  final Map<String, String?> _errors = {};

  Future<void> _pickAadharImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.toLowerCase().endsWith('png') ? 'png' : 'jpeg';
    setState(() => _aadharImageDataUri = 'data:image/$ext;base64,${base64Encode(bytes)}');
  }

  bool _validate() {
    final nextErrors = <String, String?>{};
    if (_isRegister && _qr.text.trim().isEmpty) nextErrors['qr'] = 'Property QR code is required';
    if (_isRegister && _name.text.trim().isEmpty) nextErrors['name'] = 'Full name is required';
    if (_isRegister && _age.text.trim().isEmpty) {
      nextErrors['age'] = 'Age is required';
    } else if (_isRegister && (int.tryParse(_age.text.trim()) ?? 0) <= 0) {
      nextErrors['age'] = 'Age must be a valid number';
    }
    if (_isRegister && _aadharImageDataUri == null) nextErrors['documents'] = 'Aadhar image is required';
    if (_isRegister && _email.text.trim().isEmpty) nextErrors['email'] = 'Email is required';
    if (_identifier.text.trim().isEmpty) nextErrors['phone'] = 'Phone is required';
    if (_password.text.trim().isEmpty) nextErrors['password'] = 'Password is required';
    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
    });
    return nextErrors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      final payload = _isRegister
          ? await _api.tenantRegister(
              qrCode: _qr.text,
              fullName: _name.text,
              age: int.tryParse(_age.text) ?? 0,
              phone: _identifier.text,
              email: _email.text,
              documents: _aadharImageDataUri!,
              password: _password.text,
            )
          : await _api.login(identifier: _identifier.text, password: _password.text, role: 'tenant');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TenantDashboardPage(tenantId: payload['user_id'] as String)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      title: _isRegister ? 'Tenant Registration via QR' : 'Tenant Login',
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (_isRegister) ...[
              FieldWithTopError(
                errorText: _errors['qr'],
                child: TextField(controller: _qr, decoration: const InputDecoration(labelText: 'Property QR Code')),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['name'],
                child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['age'],
                child: TextField(controller: _age, decoration: const InputDecoration(labelText: 'Age')),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['documents'],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RemoteOrDataImage(imageRef: _aadharImageDataUri, height: 140),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: _pickAadharImage, icon: const Icon(Icons.badge_outlined), label: const Text('Upload Aadhar image')),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FieldWithTopError(
                errorText: _errors['email'],
                child: TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              ),
              const SizedBox(height: 10),
            ],
            FieldWithTopError(
              errorText: _errors['phone'],
              child: TextField(controller: _identifier, decoration: const InputDecoration(labelText: 'Phone')),
            ),
            const SizedBox(height: 10),
            FieldWithTopError(
              errorText: _errors['password'],
              child: TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _submit, child: Text(_isRegister ? 'Register' : 'Login'))),
            TextButton(onPressed: () => setState(() { _isRegister = !_isRegister; _errors.clear(); }), child: Text(_isRegister ? 'Already registered? Login' : 'New tenant? Register with QR')),
          ],
        ),
      ),
    );
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(padding: const EdgeInsets.all(16), child: SurfaceCard(child: child)),
        ),
      ),
    );
  }
}
