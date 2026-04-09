import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/cookidoo_repository.dart';
import '../domain/cookidoo.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

class CookidooBrowser extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onImported;

  const CookidooBrowser({super.key, required this.scrollController, required this.onImported});

  @override
  ConsumerState<CookidooBrowser> createState() => _CookidooBrowserState();
}

class _CookidooBrowserState extends ConsumerState<CookidooBrowser> {
  CookidooStatus? _status;
  List<CookidooCollection>? _collections;
  List<CookidooRecipe>? _shoppingList;
  CookidooCollection? _selectedCollection;
  CookidooRecipe? _selectedRecipe;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(cookidooRepositoryProvider);
      _status = await repo.getStatus();
      if (_status!.available) {
        _collections = await repo.getCollections();
        _shoppingList = null;
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
      // Make the UI reflect that we couldn't load Cookidoo content.
      if (mounted) {
        setState(() {
          _collections = const [];
          _shoppingList = null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadShoppingList() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(cookidooRepositoryProvider);
      _shoppingList = await repo.getShoppingList();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importRecipe(String cookidooId) async {
    try {
      await ref.read(cookidooRepositoryProvider).importRecipe(cookidooId);
      if (mounted) {
        showAppToast(context, message: 'Rezept importiert', type: ToastType.success);
        widget.onImported();
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status?.available != true) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Cookidoo nicht verfügbar', style: theme.textTheme.titleMedium),
            if (_status?.message != null) ...[
              const SizedBox(height: 8),
              Text(_status!.message!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      );
    }

    if (_selectedRecipe != null) {
      return _buildRecipeDetail(theme);
    }

    if (_selectedCollection != null) {
      return _buildCollectionRecipes(theme, _selectedCollection!);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Cookidoo Collections',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Neu laden',
                onPressed: _loadStatus,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: _collections == null || _collections!.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const Icon(Icons.collections_bookmark_outlined, size: 44, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('Keine Collections gefunden', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(
                        'Falls du keine verwalteten Collections hast, kannst du auch die Cookidoo-Einkaufsliste nutzen.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _loadShoppingList,
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Einkaufsliste laden'),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _shoppingList == null
                            ? const SizedBox.shrink()
                            : _shoppingList!.isEmpty
                                ? const Center(child: Text('Einkaufsliste ist leer'))
                                : ListView.separated(
                                    controller: widget.scrollController,
                                    itemCount: _shoppingList!.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final r = _shoppingList![i];
                                      return ListTile(
                                        leading: _CookidooRecipeThumb(
                                          cookidooId: r.id,
                                          initialUrl: r.imageUrl,
                                          fallback: const Icon(Icons.restaurant),
                                        ),
                                        title: Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        subtitle: (r.totalTime != null && r.totalTime!.isNotEmpty)
                                            ? Text('Zeit: ${r.totalTime}')
                                            : null,
                                        trailing: IconButton(
                                          tooltip: 'Importieren',
                                          icon: const Icon(Icons.download),
                                          onPressed: () => _importRecipe(r.id),
                                        ),
                                        onTap: () async {
                                          try {
                                            final detail = await ref.read(cookidooRepositoryProvider).getRecipe(r.id);
                                            if (mounted) setState(() => _selectedRecipe = detail);
                                          } on ApiException catch (e) {
                                            if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
                                          }
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _collections!.length,
                  itemBuilder: (_, i) {
                    final col = _collections![i];
                    return ListTile(
                      leading: const Icon(Icons.collections_bookmark),
                      title: Text(col.name),
                      subtitle: Text('${col.recipeCount} Rezepte'),
                      onTap: () => setState(() => _selectedCollection = col),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecipeDetail(ThemeData theme) {
    final recipe = _selectedRecipe!;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedRecipe = null)),
              Expanded(child: Text(recipe.name, style: theme.textTheme.titleMedium)),
            ],
          ),
          if (recipe.imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: recipe.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.restaurant)),
                  ),
                ),
              ),
            ),
          ],
          if (recipe.description != null) ...[
            const SizedBox(height: 8),
            Text(recipe.description!),
          ],
          if (recipe.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Zutaten', style: theme.textTheme.titleSmall),
            ...recipe.ingredients.map((i) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('- $i', style: theme.textTheme.bodySmall),
                )),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _importRecipe(recipe.id),
              icon: const Icon(Icons.download),
              label: const Text('Rezept importieren'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionRecipes(ThemeData theme, CookidooCollection col) {
    final recipes = col.chapters.expand((c) => c.recipes).toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedCollection = null),
              ),
              Expanded(
                child: Text(
                  col.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Neu laden',
                onPressed: _loadStatus,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: recipes.isEmpty
              ? const Center(child: Text('Keine Rezepte in dieser Collection'))
              : ListView.separated(
                  controller: widget.scrollController,
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = recipes[i];
                    return ListTile(
                      leading: _CookidooRecipeThumb(
                        cookidooId: r.id,
                        initialUrl: r.imageUrl,
                        fallback: const Icon(Icons.restaurant),
                      ),
                      title: Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: (r.totalTime != null && r.totalTime!.isNotEmpty)
                          ? Text('Zeit: ${r.totalTime}')
                          : null,
                      trailing: IconButton(
                        tooltip: 'Importieren',
                        icon: const Icon(Icons.download),
                        onPressed: () => _importRecipe(r.id),
                      ),
                      onTap: () async {
                        try {
                          final detail = await ref.read(cookidooRepositoryProvider).getRecipe(r.id);
                          if (mounted) setState(() => _selectedRecipe = detail);
                        } on ApiException catch (e) {
                          if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  final Widget fallback;

  const _Thumb({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = url;
    if (u == null || u.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: fallback,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: u,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          width: 48,
          height: 48,
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: fallback,
        ),
      ),
    );
  }
}

class _CookidooRecipeThumb extends ConsumerStatefulWidget {
  final String cookidooId;
  final String? initialUrl;
  final Widget fallback;

  const _CookidooRecipeThumb({
    required this.cookidooId,
    required this.initialUrl,
    required this.fallback,
  });

  @override
  ConsumerState<_CookidooRecipeThumb> createState() => _CookidooRecipeThumbState();
}

class _CookidooRecipeThumbState extends ConsumerState<_CookidooRecipeThumb> {
  String? _resolvedUrl;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = widget.initialUrl;
  }

  @override
  void didUpdateWidget(covariant _CookidooRecipeThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialUrl?.isNotEmpty ?? false) && widget.initialUrl != oldWidget.initialUrl) {
      _resolvedUrl = widget.initialUrl;
    }
  }

  Future<void> _resolveIfNeeded() async {
    if (_requested) return;
    _requested = true;
    try {
      final detail = await ref.read(cookidooRepositoryProvider).getRecipe(widget.cookidooId);
      final url = detail.imageUrl;
      if (mounted) setState(() => _resolvedUrl = url);
    } catch (_) {
      // Non-critical: keep fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    if (url == null || url.isEmpty) {
      // Collections often don't include thumbnails; fetch lazily.
      _resolveIfNeeded();
    }
    return _Thumb(url: url, fallback: widget.fallback);
  }
}
