import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import '../providers/prompt_provider.dart';
import '../../data/models/prompt_model.dart';

class HistoryPanel extends StatefulWidget {
  const HistoryPanel({super.key});

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, today, week, month

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilter(),
          const SizedBox(height: 8),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Bootstrap.clock_history,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          Consumer<PromptProvider>(
            builder: (context, provider, child) {
              final historyCount = provider.currentHistory.length;
              if (historyCount > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    historyCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search history...',
              prefixIcon: const Icon(Bootstrap.search, size: 16),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Bootstrap.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter dropdown
          Row(
            children: [
              Icon(
                Bootstrap.funnel,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All time')),
                    DropdownMenuItem(value: 'today', child: Text('Today')),
                    DropdownMenuItem(value: 'week', child: Text('This week')),
                    DropdownMenuItem(value: 'month', child: Text('This month')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Consumer<PromptProvider>(
      builder: (context, provider, child) {
        if (provider.selectedPrompt == null) {
          return _buildEmptyState('Select a prompt to view its history');
        }

        final history = _filterHistory(provider.currentHistory);

        if (history.isEmpty) {
          return _buildEmptyState(
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? 'No history found matching your criteria'
                : 'No history yet\nGenerate prompts to see them here',
          );
        }

        // Group history by date
        final groupedHistory = _groupHistoryByDate(history);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: groupedHistory.length,
          itemBuilder: (context, index) {
            final group = groupedHistory[index];
            return _buildHistoryGroup(group['date'] as String, group['items'] as List<GeneratedPrompt>, provider);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Bootstrap.clock_history,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryGroup(String date, List<GeneratedPrompt> items, PromptProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            date,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items.map((item) => _buildHistoryItem(item, provider)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHistoryItem(GeneratedPrompt item, PromptProvider provider) {
    final timeFormat = DateFormat('HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _loadHistoryItem(item, provider),
        onLongPress: () => _showHistoryItemMenu(item, provider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Bootstrap.clock,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(item.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (item.isFavorite)
                    Icon(
                      Bootstrap.star_fill,
                      size: 14,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Bootstrap.three_dots,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem(
                        value: 'load',
                        child: Row(
                          children: [
                            const Icon(Bootstrap.upload, size: 16),
                            const SizedBox(width: 8),
                            const Text('Load Variables'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            const Icon(Bootstrap.copy, size: 16),
                            const SizedBox(width: 8),
                            const Text('Copy Content'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              item.isFavorite ? Bootstrap.star : Bootstrap.star_fill,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(item.isFavorite ? 'Remove Favorite' : 'Add Favorite'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Bootstrap.trash,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'load':
                          _loadHistoryItem(item, provider);
                          break;
                        case 'copy':
                          _copyToClipboard(item.content);
                          break;
                        case 'favorite':
                          _toggleFavorite(item, provider);
                          break;
                        case 'delete':
                          _deleteHistoryItem(item, provider);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getPreviewText(item.content),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.variables.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: item.variables.entries.take(3).map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.key}: ${_truncateValue(entry.value)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (item.variables.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${item.variables.length - 3} more variables',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<GeneratedPrompt> _filterHistory(List<GeneratedPrompt> history) {
    var filtered = history;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.content.toLowerCase().contains(query) ||
               item.variables.values.any((value) => value.toLowerCase().contains(query));
      }).toList();
    }

    // Apply date filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        filtered = filtered.where((item) {
          return item.createdAt.isAfter(today);
        }).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((item) {
          return item.createdAt.isAfter(weekAgo);
        }).toList();
        break;
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filtered = filtered.where((item) {
          return item.createdAt.isAfter(monthAgo);
        }).toList();
        break;
    }

    return filtered;
  }

  List<Map<String, dynamic>> _groupHistoryByDate(List<GeneratedPrompt> history) {
    final groups = <String, List<GeneratedPrompt>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in history) {
      final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      
      String dateKey;
      if (itemDate == today) {
        dateKey = 'Today';
      } else if (itemDate == yesterday) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat('MMM d, yyyy').format(item.createdAt);
      }

      groups.putIfAbsent(dateKey, () => []).add(item);
    }

    // Sort groups by date (most recent first)
    final sortedGroups = groups.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Today') return -1;
        if (b.key == 'Today') return 1;
        if (a.key == 'Yesterday') return -1;
        if (b.key == 'Yesterday') return 1;
        
        // For other dates, sort by the first item's date
        return b.value.first.createdAt.compareTo(a.value.first.createdAt);
      });

    return sortedGroups.map((entry) => {
      'date': entry.key,
      'items': entry.value..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    }).toList();
  }

  String _getPreviewText(String content) {
    const maxLength = 120;
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  String _truncateValue(String value) {
    const maxLength = 20;
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  void _loadHistoryItem(GeneratedPrompt item, PromptProvider provider) {
    provider.loadHistoryItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Variables loaded from history'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHistoryItemMenu(GeneratedPrompt item, PromptProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'History Item',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Bootstrap.upload),
              title: const Text('Load Variables'),
              onTap: () {
                Navigator.pop(context);
                _loadHistoryItem(item, provider);
              },
            ),
            ListTile(
              leading: const Icon(Bootstrap.copy),
              title: const Text('Copy Content'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(item.content);
              },
            ),
            ListTile(
              leading: Icon(item.isFavorite ? Bootstrap.star : Bootstrap.star_fill),
              title: Text(item.isFavorite ? 'Remove Favorite' : 'Add Favorite'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(item, provider);
              },
            ),
            ListTile(
              leading: Icon(
                Bootstrap.trash,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteHistoryItem(item, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite(GeneratedPrompt item, PromptProvider provider) {
    // Note: This would need to be implemented in the provider
    // final updatedItem = item.copyWith(isFavorite: !item.isFavorite);
    // provider.updateHistoryItem(updatedItem);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.isFavorite ? 'Removed from favorites' : 'Added to favorites'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteHistoryItem(GeneratedPrompt item, PromptProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History Item'),
        content: const Text('Are you sure you want to delete this history item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteHistoryItem(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History item deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 