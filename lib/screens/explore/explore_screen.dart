import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/event_card.dart';
import '../event/event_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  EventProvider? _eventProvider;
  String _sort = 'Semua';
  String? _city;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      if (provider.events.isEmpty) provider.loadEvents();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<EventProvider>();
    if (!identical(_eventProvider, provider)) {
      _eventProvider?.removeListener(_syncSearchField);
      _eventProvider = provider;
      _eventProvider!.addListener(_syncSearchField);
      _syncSearchField();
    }
  }

  void _syncSearchField() {
    final query = _eventProvider?.query ?? '';
    if (_searchController.text == query) return;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  void dispose() {
    _eventProvider?.removeListener(_syncSearchField);
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(Event e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)),
    );
  }

  /// Kota diambil dari event nyata di backend.
  List<String> _cityOptions(EventProvider provider) {
    final cities = <String>{};
    for (final event in provider.events) {
      final city = cityOf(event.location).trim();
      if (city.isNotEmpty) cities.add(city);
    }
    final sorted = cities.toList()..sort();
    return sorted;
  }

  void _showCityPicker() {
    final cities = _cityOptions(context.read<EventProvider>());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Filter Lokasi',
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 20),
            _cityTile(ctx, 'Semua Kota', null),
            for (final c in cities) _cityTile(ctx, c, c),
          ],
        ),
      ),
    );
  }

  Widget _cityTile(BuildContext ctx, String label, String? value) {
    final active = _city == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() => _city = value);
          Navigator.pop(ctx);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: active ? AppTheme.violetSoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppTheme.violet : AppTheme.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                value == null
                    ? Icons.public_rounded
                    : Icons.location_on_rounded,
                size: 20,
                color: active ? AppTheme.violet : AppTheme.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppTheme.violetDark : AppTheme.ink,
                  ),
                ),
              ),
              if (active)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.violet,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();

    var events = provider.events;
    if (_city != null) {
      final selected = _city!.trim().toLowerCase();
      events = events
          .where((e) => cityOf(e.location).trim().toLowerCase() == selected)
          .toList();
    }
    events = [...events];
    if (_sort == 'Terpopuler') {
      events.sort((a, b) => b.quota.compareTo(a.quota));
    } else if (_sort == 'Terdekat' || _sort == 'Semua') {
      events.sort((a, b) => a.date.compareTo(b.date));
    }

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isWide = w >= Breakpoints.mobile;
            final columns = eventGridColumns(w);
            final hPadding = contentPadding(w);

            return ConstrainedContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jelajahi Event',
                                style: TextStyle(
                                  fontFamily: AppTheme.headingFont,
                                  fontSize: w < Breakpoints.mobile ? 30 : 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: AppTheme.ink,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (Navigator.canPop(context))
                          _roundButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: AppSearchBar(
                      hint: 'Cari event, kategori, atau lokasi...',
                      controller: _searchController,
                      onChanged: provider.setQuery,
                      onFilterTap: _showCityPicker,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: hPadding),
                      itemCount: EventProvider.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final c = EventProvider.categories[i];
                        return CategoryChip(
                          label: c,
                          selected: provider.category == c,
                          onTap: () => provider.setCategory(c),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: _buildQuickFilter(w, events.length),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: provider.loading && provider.events.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.violet,
                            ),
                          )
                        : provider.error != null && provider.events.isEmpty
                        ? _buildErrorState(provider)
                        : events.isEmpty
                        ? _buildEmptyState(provider)
                        : isWide
                        ? GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              hPadding,
                              2,
                              hPadding,
                              40,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  childAspectRatio: eventGridAspect(w),
                                ),
                            itemCount: events.length,
                            itemBuilder: (_, i) => EventGridCard(
                              event: events[i],
                              onTap: () => _openDetail(events[i]),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              hPadding,
                              2,
                              hPadding,
                              40,
                            ),
                            itemCount: events.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (_, i) => EventCard(
                              event: events[i],
                              onTap: () => _openDetail(events[i]),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickFilter(double width, int count) {
    final compact = width < 420;
    final chips = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEFF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quickItem('Semua', compact),
          _quickItem('Terpopuler', compact),
          _quickItem('Terdekat', compact),
        ],
      ),
    );
    final countLabel = Text(
      '${_city == null ? '' : '$_city · '}$count event',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: compact ? TextAlign.left : TextAlign.right,
      style: const TextStyle(
        color: AppTheme.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: chips),
          const SizedBox(height: 8),
          countLabel,
        ],
      );
    }

    return Row(
      children: [
        chips,
        const SizedBox(width: 12),
        Expanded(child: countLabel),
      ],
    );
  }

  Widget _quickItem(String label, bool compact) {
    final selected = _sort == label;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: () => setState(() => _sort = label),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _sort = label),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x1A140F3C),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? AppTheme.ink : AppTheme.muted,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return AppIconButton(
      icon: icon,
      label: 'Kembali',
      onPressed: onTap,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.ink,
      borderColor: AppTheme.border,
      iconSize: 22,
    );
  }

  Widget _buildErrorState(EventProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.violetSoft,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: AppTheme.violet,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gagal Memuat Event',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.error ?? 'Periksa koneksi internet lalu coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadEvents(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(EventProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.violetSoft,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 50,
                color: AppTheme.violet,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Event Tidak Ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coba ubah kata kunci atau filter untuk menemukan event menarik lainnya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                provider.setCategory('Semua');
                provider.setQuery('');
                setState(() => _city = null);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                minimumSize: const Size(200, 54),
              ),
              child: const Text('Reset Pencarian'),
            ),
          ],
        ),
      ),
    );
  }
}
