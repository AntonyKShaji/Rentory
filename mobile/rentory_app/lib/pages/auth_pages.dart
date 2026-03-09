import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'owner_pages.dart';
import 'tenant_pages.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  static const _brandTeal = Color(0xFF204C4F);
  static const _lightBg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE5E7EB);

  final ApiService _api = ApiService();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  Future<Map<String, dynamic>?> _tryLogin(String role) async {
    try {
      return await _api.login(
        identifier: _identifier.text.trim(),
        password: _password.text,
        role: role,
      );
    } catch (_) {
      return null;
    }
  }

  void _goToRole(Map<String, dynamic> payload) {
    ApiService.setAccessToken(payload['access_token'] as String);
    final role = payload['role'] as String;
    final userId = payload['user_id'] as String;
    if (role == 'owner') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OwnerDashboardPage(ownerId: userId)),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TenantDashboardPage(tenantId: userId)),
    );
  }

  Future<void> _submit() async {
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email/phone and password.')),
      );
      return;
    }

    setState(() => _loading = true);
    final ownerPayload = await _tryLogin('owner');
    final tenantPayload = await _tryLogin('tenant');
    if (!mounted) return;
    setState(() => _loading = false);

    if (ownerPayload == null && tenantPayload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials. Please try again.')),
      );
      return;
    }

    if (ownerPayload != null && tenantPayload != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoleSelectionPage(
            ownerPayload: ownerPayload,
            tenantPayload: tenantPayload,
          ),
        ),
      );
      return;
    }

    _goToRole(ownerPayload ?? tenantPayload!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              color: _lightBg,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton.filled(
                      onPressed: () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        foregroundColor: _brandTeal,
                      ),
                      icon: const Icon(Icons.arrow_back, size: 24),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDdGgADWh00-A4oWnu2RKgUPuho52nrVQPVHPdc11Es-kozsftDF09r_xPAiWfpN6hEpdP1aWQoImyc-dRezE5RgJhFrLCZwiFcz-zZilsnsSNyXz1xuWvh-9OOFwMCDOBIbswLhKYq2Wggz6tig-AWvtbd4yslClLyTiK_Jkx5TicIPg6N3ug9GX7yj4_-eG9f8zAx9Cfb51PeRfMklkPzIljQMtiPrFGllVhpzA-vFZ3Jl2mkYNiS1IQxiwmNWBH314RmA1HlR7td',
                        height: 320,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Let's Sign In",
                      style: TextStyle(fontSize: 46 / 2, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome back! Please enter your details to\nfind your next home.',
                      style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 28),
                    const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _identifier,
                      decoration: _inputDecoration('Enter your email', Icons.mail_outline),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        TextButton(
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                          child: Text(_showPassword ? 'HIDE' : 'SHOW', style: const TextStyle(color: _brandTeal, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: _inputDecoration('••••••••', Icons.lock_outline),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?', style: TextStyle(color: _brandTeal, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: Text(_loading ? 'Signing In...' : 'Sign In', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: _border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                        ),
                        Expanded(child: Divider(color: _border)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _socialButton('Continue with Google', Icons.g_mobiledata),
                    const SizedBox(height: 10),
                    _socialButton('Continue with Facebook', Icons.facebook),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: const Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(text: 'Register', style: TextStyle(color: _brandTeal, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData trailingIcon) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: Icon(trailingIcon, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: _brandTeal, width: 1.3)),
    );
  }

  Widget _socialButton(String label, IconData icon) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          foregroundColor: const Color(0xFF334155),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _brandTeal = Color(0xFF204C4F);
  static const _border = Color(0xFFE2E8F0);

  final ApiService _api = ApiService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _phone.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final payload = await _api.ownerSignup(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ApiService.setAccessToken(payload['access_token'] as String);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerDashboardPage(ownerId: payload['user_id'] as String),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Icon(Icons.home_work_rounded, color: _brandTeal, size: 60),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        const Text('Register New Account', style: TextStyle(fontSize: 36 / 2, fontWeight: FontWeight.w700, color: _brandTeal)),
                        const SizedBox(height: 10),
                        const Text(
                          'Join now and setup your account so you can sale or rent your listing property in our platform.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        _labeledField('Full Name', _name, Icons.person_outline, 'Moni Rent Official'),
                        const SizedBox(height: 12),
                        _labeledField('Email', _email, Icons.mail_outline, 'hello.monistudio@gmail.com'),
                        const SizedBox(height: 12),
                        _labeledField('Phone Number', _phone, Icons.call_outlined, '+40 751 194 005'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('PASSWORD', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0x9964748B), fontWeight: FontWeight.w700)),
                            TextButton(
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                              child: Text(_showPassword ? 'HIDE' : 'SHOW', style: const TextStyle(color: _brandTeal, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.5)),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _password,
                          obscureText: !_showPassword,
                          decoration: _registerDecoration(Icons.lock_outline, '••••••••'),
                        ),
                        const SizedBox(height: 10),
                        _helperBox('Must be at least 8 characters, include one uppercase letter, one number, and one special character.'),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('CONFIRM PASSWORD', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0x9964748B), fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPassword,
                          obscureText: !_showPassword,
                          decoration: _registerDecoration(Icons.verified_user_outlined, '••••••••'),
                        ),
                        const SizedBox(height: 10),
                        _helperBox('Make sure this matches the password above.', icon: Icons.check_circle),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: Text(_loading ? 'Registering...' : 'Register Now', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: _border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('OR', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                      ),
                      Expanded(child: Divider(color: _border)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _socialCompact('Google', Icons.g_mobiledata)),
                      const SizedBox(width: 12),
                      Expanded(child: _socialCompact('Facebook', Icons.facebook)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                        children: [TextSpan(text: 'Sign In', style: TextStyle(color: _brandTeal, fontWeight: FontWeight.w700))],
                      ),
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

  Widget _labeledField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0x9964748B), fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(controller: controller, decoration: _registerDecoration(icon, hint)),
      ],
    );
  }

  InputDecoration _registerDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0x66455A64)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _brandTeal)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _helperBox(String text, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF0F5F5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xCC204C4F)),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xCC204C4F), height: 1.45))),
        ],
      ),
    );
  }

  Widget _socialCompact(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(52),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155))),
    );
  }
}

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({
    super.key,
    required this.ownerPayload,
    required this.tenantPayload,
  });

  final Map<String, dynamic> ownerPayload;
  final Map<String, dynamic> tenantPayload;

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  static const _teal = Color(0xFF204C4F);
  String _selectedRole = 'owner';

  void _continue() {
    final payload = _selectedRole == 'owner' ? widget.ownerPayload : widget.tenantPayload;
    ApiService.setAccessToken(payload['access_token'] as String);
    if (_selectedRole == 'owner') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OwnerDashboardPage(ownerId: payload['user_id'] as String)),
        (route) => false,
      );
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => TenantDashboardPage(tenantId: payload['user_id'] as String)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDaDq9-H9TGCBwddltDPTk4fdNwiORZhBLboX0Lhnmrt_2fXRXunokk-xNAcc7y4jMd8wjSXdXGk55JhH_aT6mk4dI8lcYEq4b0o-3Kgf1apjq9BL6O-gdQvcQp6wfgNcHxUddtH5nDOmp3xaxNvtKANchFTiSvRKC4Xnixph3QAVr6aLdUamwlEameewBzvyclgjdf97-CldzByV-eAQMLHof0OGu3YA7oli8HEGeJXv19CqI5DSDJWbmC1n3SlZSza8fyauAZGGqe',
                    fit: BoxFit.cover,
                    height: 280,
                    width: double.infinity,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Who are you?', style: TextStyle(fontSize: 50 / 2, color: _teal, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        const Text(
                          'To provide you with the best experience, please select your primary role in the Rentory ecosystem.',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.55),
                        ),
                        const SizedBox(height: 28),
                        _roleCard(
                          role: 'owner',
                          title: 'Owner',
                          subtitle: 'List your property for sale or rent directly.',
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: 14),
                        _roleCard(
                          role: 'tenant',
                          title: 'Tenant',
                          subtitle: 'Find and rent your next home with ease.',
                          icon: Icons.key_outlined,
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton(
                            onPressed: _continue,
                            style: FilledButton.styleFrom(backgroundColor: _teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                            child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard({required String role, required String title, required String subtitle, required IconData icon}) {
    final selected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F7F7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? _teal : const Color(0xFFE5E7EB), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(color: selected ? const Color(0xFFE6F0F0) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: _teal, size: 36),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 24 / 2, color: _teal, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.35)),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? _teal : const Color(0xFFD1D5DB), width: 2)),
              child: selected
                  ? Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
