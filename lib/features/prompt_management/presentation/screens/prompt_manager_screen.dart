import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';
import 'dart:io';
import '../providers/prompt_provider.dart';
import '../widgets/sidebar_tree_panel.dart';
import '../widgets/main_content_panel.dart';
import '../widgets/history_panel.dart';
import '../../data/services/storage_service.dart';

class PromptManagerScreen extends StatefulWidget {
  const PromptManagerScreen({super.key});

  @override
  State<PromptManagerScreen> createState() => _PromptManagerScreenState();
}

class _PromptManagerScreenState extends State<PromptManagerScreen> with TickerProviderStateMixin {
  bool _isHistoryPanelVisible = true;
  bool _isSidebarVisible = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromptProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildWithKeyboardShortcuts();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Bootstrap.lightning_charge_fill,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Prompt Manager',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        // Theme toggle
        Consumer<PromptProvider>(
          builder: (context, provider, child) {
            final isDark = provider.themeMode == ThemeMode.dark;
            return IconButton(
              icon: Icon(
                isDark ? Bootstrap.sun : Bootstrap.moon,
                size: 20,
              ),
              onPressed: () {
                provider.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
              },
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            );
          },
        ),
        
        // View options
        PopupMenuButton<String>(
          icon: const Icon(Bootstrap.layout_sidebar, size: 20),
          tooltip: 'View Options',
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            PopupMenuItem(
              value: 'toggle_sidebar',
              child: Row(
                children: [
                  Icon(
                    _isSidebarVisible ? Bootstrap.layout_sidebar_inset : Bootstrap.layout_sidebar,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(_isSidebarVisible ? 'Hide Sidebar' : 'Show Sidebar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_history',
              child: Row(
                children: [
                  Icon(
                    _isHistoryPanelVisible ? Bootstrap.columns : Bootstrap.columns,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(_isHistoryPanelVisible ? 'Hide History' : 'Show History'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Bootstrap.gear, size: 16),
                  const SizedBox(width: 8),
                  const Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  const Icon(Bootstrap.download, size: 16),
                  const SizedBox(width: 8),
                  const Text('Export Data'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  const Icon(Bootstrap.upload, size: 16),
                  const SizedBox(width: 8),
                  const Text('Import Data'),
                ],
              ),
            ),
          ],
          onSelected: _handleViewAction,
        ),
        
        // Statistics
        Consumer<PromptProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: const Icon(Bootstrap.graph_up, size: 20),
              onPressed: () => _showStatistics(provider),
              tooltip: 'Statistics',
            );
          },
        ),
        
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<PromptProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading Prompt Manager...'),
              ],
            ),
          );
        }

        return Row(
          children: [
            // Sidebar
            if (_isSidebarVisible) const SidebarTreePanel(),
            
            // Main content
            Expanded(
              child: const MainContentPanel(),
            ),
            
            // History panel
            if (_isHistoryPanelVisible) const HistoryPanel(),
          ],
        );
      },
    );
  }

  Widget? _buildFloatingActionButton() {
    return Consumer<PromptProvider>(
      builder: (context, provider, child) {
        if (provider.selectedPrompt == null) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: () => _quickGenerate(provider),
          icon: const Icon(Bootstrap.lightning, size: 20),
          label: const Text('Quick Generate'),
          tooltip: 'Generate prompt with current variables',
        );
      },
    );
  }

  void _handleViewAction(String action) async {
    switch (action) {
      case 'toggle_sidebar':
        setState(() {
          _isSidebarVisible = !_isSidebarVisible;
        });
        break;
      case 'toggle_history':
        setState(() {
          _isHistoryPanelVisible = !_isHistoryPanelVisible;
        });
        break;
      case 'settings':
        _showSettingsDialog();
        break;
              case 'export':
          _exportData();
          break;
        case 'import':
          _importData();
          break;
    }
  }

  void _quickGenerate(PromptProvider provider) {
    final generated = provider.generateFinalPrompt();
    if (generated.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: generated));
      provider.saveToHistory(generated);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Bootstrap.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('Prompt generated and copied to clipboard!')),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _showGeneratedPromptDialog(generated);
                },
                child: const Text('VIEW'),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showGeneratedPromptDialog(String prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Bootstrap.lightning, size: 20),
            const SizedBox(width: 8),
            const Text('Generated Prompt'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              prompt,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prompt));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Bootstrap.copy, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(PromptProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Bootstrap.graph_up, size: 20),
            const SizedBox(width: 8),
            const Text('Statistics'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Prompts', provider.totalPrompts.toString()),
              _buildStatRow('Total Folders', provider.totalFolders.toString()),
              _buildStatRow('Favorites', provider.favoriteCount.toString()),
              _buildStatRow('History Items', provider.currentHistory.length.toString()),
              const SizedBox(height: 16),
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...provider.promptsByCategory.entries.map((entry) {
                return _buildStatRow(entry.key, entry.value.toString());
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    final provider = context.read<PromptProvider>();
    
    try {
      final data = await provider.exportData();
      
      // In a real app, you would use file_picker to save the file
      // For now, we'll just copy to clipboard
      Clipboard.setData(ClipboardData(text: data.toString()));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export data copied to clipboard'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _importData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Import functionality would typically use file picker to select a JSON file. '
          'This is a placeholder for the import feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import feature coming soon'),
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  // Keyboard shortcuts
  Widget _buildWithKeyboardShortcuts() {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewPromptIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG): const GenerateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (SaveIntent intent) {
              final provider = context.read<PromptProvider>();
              if (provider.hasUnsavedChanges) {
                provider.saveCurrentPrompt();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved successfully (Ctrl+S)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              return null;
            },
          ),
          NewPromptIntent: CallbackAction<NewPromptIntent>(
            onInvoke: (NewPromptIntent intent) {
              _showCreatePromptDialog();
              return null;
            },
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (SearchIntent intent) {
              // Focus search field in sidebar
              return null;
            },
          ),
          GenerateIntent: CallbackAction<GenerateIntent>(
            onInvoke: (GenerateIntent intent) {
              final provider = context.read<PromptProvider>();
              if (provider.selectedPrompt != null) {
                _quickGenerate(provider);
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: _buildAppBar(),
          body: _buildBody(),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  void _showCreatePromptDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedFolderId;

    showDialog(
      context: context,
      builder: (context) => Consumer<PromptProvider>(
        builder: (context, provider, child) => AlertDialog(
          title: const Text('Create New Prompt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Prompt Name',
                  hintText: 'Enter prompt name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter description',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFolderId,
                decoration: const InputDecoration(
                  labelText: 'Folder',
                ),
                items: provider.folders.map((folder) {
                  return DropdownMenuItem(
                    value: folder.id,
                    child: Text(folder.name),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedFolderId = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  provider.createNewPrompt(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    folderId: selectedFolderId,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom intents for keyboard shortcuts
class SaveIntent extends Intent {
  const SaveIntent();
}

class NewPromptIntent extends Intent {
  const NewPromptIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class GenerateIntent extends Intent {
  const GenerateIntent();
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _currentStorageMode = 'system';
  String _currentDatabasePath = '';
  String _customDatabasePath = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await StorageService.getStorageMode();
    final path = await StorageService.getCurrentDatabasePath();
    final customPath = await StorageService.getCustomDatabasePath() ?? '';
    
    setState(() {
      _currentStorageMode = mode;
      _currentDatabasePath = path;
      _customDatabasePath = customPath;
    });
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Data Storage Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // System Storage Option
            RadioListTile<String>(
              title: const Text('System Folder'),
              subtitle: const Text('Recommended: Uses standard OS location\n• Windows: %APPDATA%\n• Backed up with user profile\n• Secure and standard'),
              value: 'system',
              groupValue: _currentStorageMode,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentStorageMode = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 8),
            
            // Custom Storage Option
            RadioListTile<String>(
              title: const Text('Custom Folder'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose your own folder location\n• Sync with cloud storage (Dropbox, OneDrive)\n• Easy manual backup to USB drives\n• Data moves with chosen location'),
                  if (_customDatabasePath.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Bootstrap.folder,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _customDatabasePath,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              value: 'custom',
              groupValue: _currentStorageMode,
              onChanged: (value) async {
                if (value != null) {
                  if (_customDatabasePath.isEmpty) {
                    // Need to select folder first
                    await _selectCustomFolder();
                  } else {
                    setState(() {
                      _currentStorageMode = value;
                    });
                  }
                }
              },
            ),
            
            // Custom folder selection button
            if (_currentStorageMode == 'custom' || _customDatabasePath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Row(
                  children: [
                                         TextButton.icon(
                       onPressed: _selectCustomFolder,
                       icon: const Icon(Bootstrap.folder2_open, size: 16),
                       label: Text(_customDatabasePath.isEmpty ? 'Select Folder' : 'Change Folder'),
                     ),
                     if (_customDatabasePath.isNotEmpty)
                       TextButton.icon(
                         onPressed: () async {
                           setState(() {
                             _customDatabasePath = '';
                             if (_currentStorageMode == 'custom') {
                               _currentStorageMode = 'system';
                             }
                           });
                           await StorageService.setCustomDatabasePath('');
                         },
                         icon: const Icon(Bootstrap.x_circle_fill, size: 16),
                         label: const Text('Clear'),
                         style: TextButton.styleFrom(
                           foregroundColor: Theme.of(context).colorScheme.error,
                         ),
                       ),
                  ],
                ),
              ),

            
            const SizedBox(height: 16),
            
            // Current Database Path
            Text(
              'Current Database Location:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                _currentDatabasePath,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveSettings,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _selectCustomFolder() async {
    try {
      final selectedPath = await StorageService.browseCustomDatabaseFolder();
      if (selectedPath != null) {
        setState(() {
          _customDatabasePath = selectedPath;
          _currentStorageMode = 'custom';
        });
        
        // Save the custom path
        await StorageService.setCustomDatabasePath(selectedPath);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom folder selected: $selectedPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select folder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    final currentMode = await StorageService.getStorageMode();
    
    if (_currentStorageMode != currentMode) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Migrating database...'),
              ],
            ),
          ),
        );
        
        // If switching to custom mode, ensure custom path is set
        if (_currentStorageMode == 'custom' && _customDatabasePath.isEmpty) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a custom folder first'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Migrate database
        await StorageService.migrateDatabaseLocation(_currentStorageMode);
        
        // Close loading dialog
        Navigator.pop(context);
        
        // Close settings dialog
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage location changed to $_currentStorageMode mode'),
            backgroundColor: Colors.green,
          ),
        );
        
      } catch (e) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change storage location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      Navigator.pop(context);
    }
  }
} 