import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../shared/widgets/toast.dart';

class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrl = ref.watch(serverUrlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Info')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server-URL'),
            subtitle: Text(serverUrl),
            onTap: () => _editServerUrl(context, ref, serverUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _editServerUrl(BuildContext context, WidgetRef ref, String currentUrl) async {
    final controller = TextEditingController(text: currentUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server-URL'),
        content: LabeledOutlineTextField(
          label: 'Basis-URL des Backends',
          controller: controller,
          hintText: kDefaultServerUrl,
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Speichern')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(authStateProvider.notifier).setServerUrl(result);
      if (context.mounted) showAppToast(context, message: 'Server-URL aktualisiert', type: ToastType.info);
    }
  }
}
