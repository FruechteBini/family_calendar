import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/knuspr_repository.dart';
import '../data/knuspr_status_provider.dart';
import '../domain/knuspr.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';

class KnusprScreen extends ConsumerStatefulWidget {
  const KnusprScreen({super.key});

  @override
  ConsumerState<KnusprScreen> createState() => _KnusprScreenState();
}

class _KnusprScreenState extends ConsumerState<KnusprScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<KnusprProduct> _products = [];
  List<KnusprDeliverySlot> _deliverySlots = [];
  KnusprCartSnapshot? _cart;
  List<KnusprMapping> _mappings = [];
  bool _searching = false;
  bool _loadingSlots = false;
  bool _loadingCart = false;
  bool _loadingMaps = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) _refreshCart();
        if (_tabController.index == 3) _loadMappings();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      _products = await ref
          .read(knusprRepositoryProvider)
          .searchProducts(_searchController.text.trim());
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addToCart(KnusprProduct product) async {
    try {
      await ref.read(knusprRepositoryProvider).addToCart(product.id);
      if (mounted) {
        showAppToast(context,
            message: '${product.name} im Warenkorb', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _loadDeliverySlots() async {
    setState(() => _loadingSlots = true);
    try {
      _deliverySlots =
          await ref.read(knusprRepositoryProvider).getDeliverySlots();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _refreshCart() async {
    setState(() => _loadingCart = true);
    try {
      _cart = await ref.read(knusprRepositoryProvider).getCart();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
      _cart = null;
    } finally {
      if (mounted) setState(() => _loadingCart = false);
    }
  }

  Future<void> _clearCart() async {
    try {
      await ref.read(knusprRepositoryProvider).clearCart();
      await _refreshCart();
      if (mounted) {
        showAppToast(context, message: 'Warenkorb geleert', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _removeLine(KnusprCartLine line) async {
    try {
      await ref.read(knusprRepositoryProvider).removeCartLine(line.orderFieldId);
      await _refreshCart();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _bookSlot(KnusprDeliverySlot slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lieferslot buchen?'),
        content: Text(slot.displayLabel),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buchen')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(knusprRepositoryProvider).bookDeliverySlot(slot.id);
      if (mounted) {
        showAppToast(context, message: 'Slot-Anfrage gesendet (bitte in Knuspr prüfen)', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _loadMappings() async {
    setState(() => _loadingMaps = true);
    try {
      _mappings = await ref.read(knusprRepositoryProvider).getMappings();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loadingMaps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(knusprStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knuspr'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Suche'),
            Tab(text: 'Warenkorb'),
            Tab(text: 'Lieferung'),
            Tab(text: 'Zuordnungen'),
          ],
        ),
      ),
      body: Column(
        children: [
          statusAsync.when(
            data: (s) {
              if (s.available) return const SizedBox.shrink();
              return MaterialBanner(
                content: Text(
                  s.message ?? 'Knuspr ist nicht verfügbar',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(knusprStatusProvider),
                    child: const Text('Erneut prüfen'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildCartTab(),
                _buildDeliveryTab(),
                _buildMappingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Produkt suchen...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _search, icon: const Icon(Icons.search)),
            ],
          ),
        ),
        if (_searching)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (_, i) {
                final p = _products[i];
                final priceText = p.price != null
                    ? '${p.price!.toStringAsFixed(2)} EUR'
                    : 'Preis n.v.';
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    '$priceText${p.unit != null && p.unit!.isNotEmpty ? ' · ${p.unit}' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: p.available ? () => _addToCart(p) : null,
                  ),
                  leading: p.available
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                      : const Icon(Icons.cancel, color: Colors.red, size: 18),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCartTab() {
    return RefreshIndicator(
      onRefresh: _refreshCart,
      child: _loadingCart && _cart == null
          ? ListView(
              children: [
                const SizedBox(height: 120),
                const Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _refreshCart,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Aktualisieren'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _clearCart,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Alles leeren'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_cart != null && _cart!.items.isNotEmpty) ...[
                  Text(
                    'Summe: ${_cart!.totalPrice.toStringAsFixed(2)} EUR · ${_cart!.totalItems} Positionen',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ..._cart!.items.map(
                    (line) => Card(
                      child: ListTile(
                        title: Text(line.name),
                        subtitle: Text(
                          '${line.quantity} × ${line.price.toStringAsFixed(2)} EUR',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeLine(line),
                        ),
                      ),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text('Warenkorb ist leer (oder noch nicht geladen)'),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDeliveryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _loadingSlots ? null : _loadDeliverySlots,
            icon: const Icon(Icons.refresh),
            label: const Text('Lieferslots laden'),
          ),
        ),
        if (_loadingSlots)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _deliverySlots.length,
              itemBuilder: (_, i) {
                final slot = _deliverySlots[i];
                return ListTile(
                  leading: Icon(
                    slot.available ? Icons.check_circle : Icons.cancel,
                    color: slot.available ? Colors.green : Colors.red,
                  ),
                  title: Text(slot.displayLabel),
                  subtitle: slot.fee != null
                      ? Text('${slot.fee!.toStringAsFixed(2)} EUR')
                      : null,
                  trailing: slot.available
                      ? TextButton(
                          onPressed: () => _bookSlot(slot),
                          child: const Text('Buchen'),
                        )
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMappingsTab() {
    if (_loadingMaps) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_mappings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Noch keine gespeicherten Zuordnungen'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadMappings,
              child: const Text('Aktualisieren'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMappings,
      child: ListView.builder(
        itemCount: _mappings.length,
        itemBuilder: (_, i) {
          final m = _mappings[i];
          return Dismissible(
            key: ValueKey('map-${m.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              try {
                await ref.read(knusprRepositoryProvider).deleteMapping(m.id);
                notifyDataMutated(ref);
                await _loadMappings();
                return true;
              } on ApiException catch (e) {
                if (mounted) {
                  showAppToast(context, message: e.message, type: ToastType.error);
                }
                return false;
              }
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(m.knusprProductName.isNotEmpty ? m.knusprProductName : m.knusprProductId),
              subtitle: Text('Liste: ${m.itemName} · ${m.useCount}×'),
            ),
          );
        },
      ),
    );
  }
}
