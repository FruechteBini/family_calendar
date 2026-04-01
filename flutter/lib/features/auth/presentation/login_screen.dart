import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverUrlController = TextEditingController();
  bool _isRegister = false;
  bool _showServerConfig = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = ref.read(serverUrlProvider);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authStateProvider.notifier);
    try {
      if (_showServerConfig) {
        await auth.setServerUrl(_serverUrlController.text.trim());
      }
      if (_isRegister) {
        await auth.register(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        await auth.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Familienkalender',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Benutzername',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.required(v, 'Benutzername'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => _isRegister
                            ? Validators.minLength(v, 6, 'Passwort')
                            : Validators.required(v, 'Passwort'),
                      ),
                      if (_showServerConfig) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _serverUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Server-URL',
                            prefixIcon: Icon(Icons.dns_outlined),
                            hintText: 'http://192.168.1.100:8000',
                          ),
                          keyboardType: TextInputType.url,
                          validator: Validators.serverUrl,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: authState.isLoading ? null : _submit,
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isRegister ? 'Registrieren' : 'Anmelden'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _isRegister = !_isRegister),
                        child: Text(_isRegister
                            ? 'Bereits registriert? Anmelden'
                            : 'Noch kein Konto? Registrieren'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _showServerConfig = !_showServerConfig),
                        icon: Icon(
                          _showServerConfig
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                        ),
                        label: const Text('Server konfigurieren'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
