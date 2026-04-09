import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/member_repository.dart';
import '../domain/family_member.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';

final membersListProvider = FutureProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
});

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersListProvider);
    final authState = ref.watch(authStateProvider);
    final linkedMemberId = authState.user?.memberId;

    return Scaffold(
      appBar: AppBar(title: const Text('Familienmitglieder')),
      body: membersAsync.when(
        data: (members) => members.isEmpty
            ? const EmptyState(
                icon: Icons.people_outline, title: 'Keine Mitglieder')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(membersListProvider),
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (_, i) => _MemberTile(
                    member: members[i],
                    onEdit: () => _showForm(context, ref, member: members[i]),
                    onDelete: () => _delete(context, ref, members[i]),
                    isLinkedToMe: linkedMemberId == members[i].id,
                    onLink: () => _linkToMe(context, ref, members[i]),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
            icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMember',
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref,
      {FamilyMember? member}) async {
    final nameController = TextEditingController(text: member?.name ?? '');
    final emojiController = TextEditingController(text: member?.emoji ?? '');
    final colorController =
        TextEditingController(text: member?.color ?? '#1565C0');
    final isEdit = member != null;
    final canOfferLink = !isEdit; // we link right after creating a new member
    var linkAfterCreate = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Mitglied bearbeiten' : 'Neues Mitglied'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledOutlineTextField(
                label: 'Name',
                controller: nameController,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 12),
              LabeledOutlineTextField(
                label: 'Emoji (optional)',
                controller: emojiController,
                prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              LabeledOutlineTextField(
                label: 'Farbe (Hex)',
                controller: colorController,
                hintText: '#1565C0',
                prefixIcon: const Icon(Icons.palette_outlined),
              ),
              if (canOfferLink) ...[
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Danach mit mir verknüpfen'),
                  subtitle: const Text(
                      'Wählt dieses Familienmitglied als „ich“ in der App.'),
                  value: linkAfterCreate,
                  onChanged: (v) => setState(() => linkAfterCreate = v),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Speichern' : 'Erstellen')),
        ],
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;
    try {
      final data = {
        'name': nameController.text.trim(),
        'emoji': emojiController.text.trim().isEmpty
            ? null
            : emojiController.text.trim(),
        'color': colorController.text.trim(),
      };
      final repo = ref.read(memberRepositoryProvider);
      if (isEdit) {
        await repo.updateMember(member.id, data);
      } else {
        final created = await repo.createMember(data);
        if (linkAfterCreate) {
          await ref.read(authStateProvider.notifier).linkMember(created.id);
          if (context.mounted) {
            showAppToast(context,
                message: 'Mit "${created.name}" verknüpft',
                type: ToastType.success);
          }
        }
      }
      ref.invalidate(membersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, FamilyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mitglied löschen?'),
        content: Text('"${member.name}" wirklich löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(memberRepositoryProvider).deleteMember(member.id);
      ref.invalidate(membersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _linkToMe(
      BuildContext context, WidgetRef ref, FamilyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verknüpfen?'),
        content: Text('Deinen Benutzer mit "${member.name}" verknüpfen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Verknüpfen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(authStateProvider.notifier).linkMember(member.id);
      if (context.mounted) {
        showAppToast(context,
            message: 'Mit "${member.name}" verknüpft', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } catch (e) {
      if (context.mounted) {
        showAppToast(context, message: 'Fehler: $e', type: ToastType.error);
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isLinkedToMe;
  final VoidCallback onLink;

  const _MemberTile({
    required this.member,
    required this.onEdit,
    required this.onDelete,
    required this.isLinkedToMe,
    required this.onLink,
  });

  Color _parseColor() {
    if (member.color == null) return Colors.grey;
    try {
      return Color(
          int.parse('FF${member.color!.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Text(member.emoji ?? member.name[0].toUpperCase(),
            style: TextStyle(color: color, fontSize: 18)),
      ),
      title: Text(member.name),
      subtitle: isLinkedToMe ? const Text('Verknüpft mit dir') : null,
      trailing: Wrap(
        spacing: 4,
        children: [
          if (isLinkedToMe)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.verified, color: Colors.green),
            )
          else
            TextButton(
              onPressed: onLink,
              child: const Text('Verknüpfen'),
            ),
          IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit),
          IconButton(
              icon:
                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: onDelete),
        ],
      ),
    );
  }
}
