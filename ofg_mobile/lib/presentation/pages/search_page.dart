import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/ofg_theme.dart';
import '../widgets/ofg_ui.dart';
import '../widgets/striped_media.dart';
import '../../models/ofg_models.dart';
import '../../logic/providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  final Function(OfgVideo) onVideoTap;
  const SearchPage({super.key, required this.onVideoTap});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  List<String> _recentSearches = [];
  bool _isSearchingLocally = false;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('recent_searches');
    if (str != null) {
      setState(() {
        _recentSearches = List<String>.from(jsonDecode(str));
      });
    }
  }

  Future<void> _addRecent(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 5) _recentSearches.removeLast();
    await prefs.setString('recent_searches', jsonEncode(_recentSearches));
    setState(() {});
  }

  void _onSearchSubmit(String query) {
    if (query.trim().isEmpty) return;
    ref.read(searchQueryProvider.notifier).state = query.trim();
    _addRecent(query.trim());
    setState(() => _isSearchingLocally = true);
    
    // reset flag after a delay to allow future provider to take over
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isSearchingLocally = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: kPanel,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _onSearchSubmit,
                        decoration: InputDecoration(
                          hintText: 'Search OFG Connects',
                          hintStyle: const TextStyle(color: kMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchQueryProvider.notifier).state = '';
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            
            Expanded(
              child: query.isEmpty
                  ? _buildRecents()
                  : _isSearchingLocally 
                      ? const Center(child: CircularProgressIndicator())
                      : resultsAsync.when(
                          data: (results) {
                            if (results.isEmpty) {
                              return const OfgEmptyState(
                                icon: Icons.search_off,
                                title: 'No results found',
                                subtitle: 'Try searching with different keywords',
                              );
                            }
                            return ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) => _buildResultRow(results[index]),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Center(child: Text('Error performing search')),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((r) => ActionChip(
                label: Text(r),
                backgroundColor: kPanel,
                side: const BorderSide(color: kBorder),
                onPressed: () {
                  _searchController.text = r;
                  _onSearchSubmit(r);
                },
              )).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          const Text('Trending Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: kCategories.where((c) => c != 'For You').map((c) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kPanel2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(OfgVideo video) {
    return InkWell(
      onTap: () => widget.onVideoTap(video),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 160,
                height: 90,
                child: StripedMedia(imageUrl: video.thumbnailUrl, label: video.duration),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(video.creator, style: const TextStyle(color: kMuted, fontSize: 12)),
                      if (video.creatorVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${video.views} views', style: const TextStyle(color: kMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
