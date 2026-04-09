import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';

class FamilyOnboardingScreen extends ConsumerStatefulWidget {
  const FamilyOnboardingScreen({super.key});

  @override
  ConsumerState<FamilyOnboardingScreen> createState() =>
      _FamilyOnboardingScreenState();
}

class _FamilyOnboardingScreenState
    extends ConsumerState<FamilyOnboardingScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isJoin = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .createFamily(_nameController.text.trim());
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinFamily() async {
    if (_codeController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .joinFamily(_codeController.text.trim());
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.family_restroom, size: 64,
                        color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Familie einrichten',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle eine neue Familie oder tritt einer bestehenden bei.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Erstellen')),
                        ButtonSegment(value: true, label: Text('Beitreten')),
                      ],
                      selected: {_isJoin},
                      onSelectionChanged: (v) =>
                          setState(() => _isJoin = v.first),
                    ),
                    const SizedBox(height: 24),
                    if (!_isJoin) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Familienname',
                          prefixIcon: Icon(Icons.home_outlined),
                          hintText: 'z.B. Familie Müller',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createFamily(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _createFamily,
                          child: _loading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Familie erstellen'),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Einladungscode',
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                          hintText: 'Code eingeben',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _joinFamily(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _joinFamily,
                          child: _loading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Familie beitreten'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(authStateProvider.notifier).logout(),
                      child: const Text('Abmelden'),
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
}
