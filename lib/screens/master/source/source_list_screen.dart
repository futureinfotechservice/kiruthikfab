import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/source_master_model.dart';
import '../../../../services/source_apiservice.dart';
import '../../../indigator/main.dart';
import '../../navigation_provider.dart';
import 'source_entry.dart';

class SourceListScreen extends StatefulWidget {
  const SourceListScreen({super.key});

  @override
  State<SourceListScreen> createState() => _SourceListScreenState();
}

class _SourceListScreenState extends State<SourceListScreen> {
  final SourceApiService _apiService = SourceApiService();

  final ScrollController _scrollController = ScrollController();

  List<SourceMasterModel> _sources = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String total = '';
  int _page = 1;
  final int _limit = 50;

  String _searchQuery = '';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _loadSources();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _page = 1;
    });

    try {
      final response = await _apiService.fetchSources1(
        context,
        page: _page,
        limit: _limit,
        search: _searchQuery,
      );

      setState(() {
        _sources = response.data;
        _hasMore = response.hasMore;
        total = response.total.toString();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error : $e"), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _page++;

      final response = await _apiService.fetchSources1(
        context,
        page: _page,
        limit: _limit,
        search: _searchQuery,
      );

      setState(() {
        _sources.addAll(response.data);
        _hasMore = response.hasMore;
        total = response.total.toString();
      });
    } catch (e) {
      setState(() {});
    }

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadSources();
  }

  Future<void> _deleteSource(String sourceId, int index) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete"),
        content: const Text("Are you sure you want to delete this source?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.deleteSource(context, sourceId);

      if (result == "Success") {
        setState(() {
          _sources.removeAt(index);
        });
      }
    } catch (e) {
      setState(() {});
    }
  }

  void _navigateToSourceForm({SourceMasterModel? source}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SourceEntryScreen(source: source)),
    );

    if (result == true) {
      _loadSources();
    }
  }

  Widget _buildSourceTile(SourceMasterModel source, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green,
            child: Text(
              source.name.isEmpty ? "S" : source.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            source.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),

              Text("No : ${source.sourceNo}"),
              Text("Mobile : ${source.mobileNo}"),
              Text("Branch : ${source.branch}"),
              Text("Mode : ${source.sourcingMode}"),

              if (source.companyName.isNotEmpty) Text(source.companyName),
            ],
          ),
          trailing: SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToSourceForm(source: source),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSource(source.id, index),
                ),
              ],
            ),
          ),
          onTap: () {
            _navigateToSourceForm(source: source);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            navProvider.updateIndex(
              selectedIndex: 0,
              reportSubIndex: 0,
              masterSubIndex: 0,
              entrySubIndex: 0,
            );
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _loadSources,
            icon: Icon(Icons.refresh, color: const Color(0xFFFFFFFF)),
          ),
        ],
        title: const Text("Sources"),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Source",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) {
                  _debounce!.cancel();
                }

                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _searchQuery = value;
                  _loadSources();
                });
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Loaded : ${_sources.length}"),
                if (_isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularWaveProgress(),
                  ),
                const Spacer(),
                Text("Total : $total"),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _scrollController,

                itemCount: _sources.length + (_hasMore ? 1 : 0),

                itemBuilder: (context, index) {
                  if (index >= _sources.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularWaveProgress()),
                    );
                  }

                  return _buildSourceTile(_sources[index], index);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add source list',
        heroTag: 'Add source list',
        onPressed: () => _navigateToSourceForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// import '../../models/source_master_model.dart';
// import '../../services/source_apiservice.dart';
// import 'source_entry.dart';
//
// class SourceListScreen extends StatefulWidget {
//   const SourceListScreen({super.key});
//
//   @override
//   State<SourceListScreen> createState() => _SourceListScreenState();
// }
//
// class _SourceListScreenState extends State<SourceListScreen> {
//   final SourceApiService _apiService = SourceApiService();
//   List<SourceMasterModel> _sources = [];
//   bool _isLoading = true;
//   String _searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSources();
//   }
//
//   Future<void> _loadSources() async {
//     setState(() => _isLoading = true);
//     try {
//       final sources = await _apiService.fetchSources(context);
//       setState(() {
//         _sources = sources;
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error loading sources: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _deleteSource(String sourceId, int index) async {
//     final confirmed = await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: const Text('Are you sure you want to delete this source?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed == true) {
//       try {
//         final result = await _apiService.deleteSource(context, sourceId);
//         if (result == "Success" && mounted) {
//           setState(() {
//             _sources.removeAt(index);
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Source deleted successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error deleting source: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   void _navigateToSourceForm({SourceMasterModel? source}) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SourceEntryScreen(source: source),
//       ),
//     );
//     if (result == true && mounted) {
//       _loadSources();
//     }
//   }
//
//   List<SourceMasterModel> get _filteredSources {
//     if (_searchQuery.isEmpty) return _sources;
//     return _sources.where((source) {
//       return source.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           source.mobileNo.contains(_searchQuery) ||
//           source.sourceNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           source.branch.toLowerCase().contains(_searchQuery.toLowerCase());
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text('Sources'),
//         backgroundColor: const Color(0xFF1E293B),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             onPressed: _loadSources,
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Search source...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value;
//                 });
//               },
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Total Sources: ${_filteredSources.length}',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 if (_isLoading)
//                   const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 8),
//
//           Expanded(
//             child: _isLoading
//                 ? const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 16),
//                         Text(
//                           'Loading sources...',
//                           style: TextStyle(fontSize: 16, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   )
//                 : _filteredSources.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.people_outline,
//                           size: 80,
//                           color: Colors.grey[300],
//                         ),
//                         const SizedBox(height: 16),
//                         const Text(
//                           'No sources found',
//                           style: TextStyle(fontSize: 18, color: Colors.grey),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           _searchQuery.isNotEmpty
//                               ? 'Try a different search term'
//                               : 'Add your first source',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                         if (_searchQuery.isEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 16.0),
//                             child: ElevatedButton(
//                               onPressed: () => _navigateToSourceForm(),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF4318D1),
//                               ),
//                               child: const Text('Add Source'),
//                             ),
//                           ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     itemCount: _filteredSources.length,
//                     itemBuilder: (context, index) {
//                       final source = _filteredSources[index];
//                       return Card(
//                         margin: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 4,
//                         ),
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.green,
//                             child: Text(
//                               source.name.isNotEmpty
//                                   ? source.name[0].toUpperCase()
//                                   : 'S',
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ),
//                           title: Text(
//                             source.name,
//                             style: const TextStyle(fontWeight: FontWeight.w500),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const SizedBox(height: 4),
//                               Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.confirmation_number,
//                                     size: 14,
//                                     color: Colors.grey,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(source.sourceNo),
//                                 ],
//                               ),
//                               const SizedBox(height: 2),
//                               Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.phone,
//                                     size: 14,
//                                     color: Colors.grey,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(source.mobileNo),
//                                 ],
//                               ),
//                               const SizedBox(height: 2),
//                               Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.location_on,
//                                     size: 14,
//                                     color: Colors.grey,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(source.branch),
//                                 ],
//                               ),
//                               const SizedBox(height: 2),
//                               Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.category,
//                                     size: 14,
//                                     color: Colors.grey,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text('Mode: ${source.sourcingMode}'),
//                                 ],
//                               ),
//                               if (source.companyName.isNotEmpty) ...[
//                                 const SizedBox(height: 2),
//                                 Row(
//                                   children: [
//                                     const Icon(
//                                       Icons.business,
//                                       size: 14,
//                                       color: Colors.grey,
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(source.companyName),
//                                   ],
//                                 ),
//                               ],
//                             ],
//                           ),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               IconButton(
//                                 onPressed: () =>
//                                     _navigateToSourceForm(source: source),
//                                 icon: const Icon(
//                                   Icons.edit,
//                                   color: Colors.blue,
//                                 ),
//                                 tooltip: 'Edit',
//                               ),
//                               IconButton(
//                                 onPressed: () =>
//                                     _deleteSource(source.id, index),
//                                 icon: const Icon(
//                                   Icons.delete,
//                                   color: Colors.red,
//                                 ),
//                                 tooltip: 'Delete',
//                               ),
//                             ],
//                           ),
//                           onTap: () {
//                             _navigateToSourceForm(source: source);
//                           },
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         heroTag: 'add_source',
//         onPressed: () => _navigateToSourceForm(),
//         backgroundColor: const Color(0xFF4318D1),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }
