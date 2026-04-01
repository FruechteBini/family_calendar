import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/knuspr_repository.dart';
import '../domain/knuspr.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/utils/date_utils.dart' as utils;
import '../../../core/api/api_client.dart';

class KnusprScreen extends ConsumerStatefulWidget {
  const KnusprScreen({super.key});

  @override
  ConsumerState<KnusprScreen> createState() => _KnusprScreenState();
}

class _KnusprScreenState extends ConsumerState<KnusprScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<KnusprProduct> _products = [];
  List<KnusprDeliverySlot> _deliverySlots = [];
  bool _searching = false;
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _products = await ref.read(knusprRepositoryProvider).searchProducts(_searchController.text.trim());
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addToCart(KnusprProduct product) async {
    try {
      await ref.read(knusprRepositoryProvider).addToCart(product.id);
      if (mounted) showAppToast(context, message: '${product.name} im Warenkorb', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _loadDeliverySlots() async {
    setState(() => _loadingSlots = true);
    try {
      _deliverySlots = await ref.read(knusprRepositoryProvider).getDeliverySlots();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _clearCart() async {
    try {
      await ref.read(knusprRepositoryProvider).clearCart();
      if (mounted) showAppToast(context, message: 'Warenkorb geleert', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knuspr'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Suche'),
            Tab(text: 'Warenkorb'),
            Tab(text: 'Lieferung'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Search tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(hintText: 'Produkt suchen...', prefixIcon: Icon(Icons.search)),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: _search, icon: const Icon(Icons.search)),
                  ],
                ),
              ),
              if (_searching)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('${p.price.toStringAsFixed(2)} EUR${p.unit != null ? ' / ${p.unit}' : ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () => _addToCart(p),
                        ),
                        leading: p.available
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                            : const Icon(Icons.cancel, color: Colors.red, size: 18),
                      );
                    },
                  ),
                ),
            ],
          ),

          // Cart tab
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Warenkorb-Verwaltung'),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Warenkorb leeren'),
                ),
              ],
            ),
          ),

          // Delivery slots tab
          Column(
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
                const Center(child: CircularProgressIndicator())
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
                        title: Text(
                          '${utils.AppDateUtils.formatDate(slot.start)} ${utils.AppDateUtils.formatTime(slot.start)} - ${utils.AppDateUtils.formatTime(slot.end)}',
                        ),
                        subtitle: slot.fee != null ? Text('${slot.fee!.toStringAsFixed(2)} EUR') : null,
                        enabled: slot.available,
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
