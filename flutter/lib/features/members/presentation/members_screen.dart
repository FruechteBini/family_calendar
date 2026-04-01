import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/member_repository.dart';
import '../domain/family_member.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

final membersListProvider = FutureProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
});

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Familienmitglieder')),
      body: membersAsync.when(
        data: (members) => members.isEmpty
            ? const EmptyState(icon: Icons.people_outline, title: 'Keine Mitglieder')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(membersListProvider),
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (_, i) => _MemberTile(
                    member: members[i],
                    onEdit: () => _showForm(context, ref, member: members[i]),
                    onDelete: () => _delete(context, ref, members[i]),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMember',
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref, {FamilyMember? member}) async {
    final nameController = TextEditingController(text: member?.name ?? '');
    final emojiController = TextEditingController(text: member?.emoji ?? '');
    final colorController = TextEditingController(text: member?.color ?? '#1565C0');
    final isEdit = member != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Mitglied bearbeiten' : 'Neues Mitglied'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: emojiController, decoration: const InputDecoration(labelText: 'Emoji (optional)', prefixIcon: Icon(Icons.emoji_emotions_outlined)), maxLength: 2),
            const SizedBox(height: 12),
            TextField(controller: colorController, decoration: const InputDecoration(labelText: 'Farbe (Hex)', prefixIcon: Icon(Icons.palette_outlined), hintText: '#1565C0')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Speichern' : 'Erstellen')),
        ],
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;
    try {
      final data = {
        'name': nameController.text.trim(),
        'emoji': emojiController.text.trim().isEmpty ? null : emojiController.text.trim(),
        'color': colorController.text.trim(),
      };
      final repo = ref.read(memberRepositoryProvider);
      if (isEdit) {
        await repo.updateMember(member!.id, data);
      } else {
        await repo.createMember(data);
      }
      ref.invalidate(membersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, FamilyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mitglied loeschen?'),
        content: Text('"${member.name}" wirklich loeschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Loeschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(memberRepositoryProvider).deleteMember(member.id);
      ref.invalidate(membersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

class _MemberTile extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberTile({required this.member, required this.onEdit, required this.onDelete});

  Color _parseColor() {
    if (member.color == null) return Colors.grey;
    try {
      return Color(int.parse('FF${member.color!.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Text(member.emoji ?? member.name[0].toUpperCase(), style: TextStyle(color: color, fontSize: 18)),
      ),
      title: Text(member.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }
}
