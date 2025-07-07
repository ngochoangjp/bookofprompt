import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:file_picker/file_picker.dart';
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
            'TremoPrompt',
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
                Text('Loading TremoPrompt...'),
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
      // Show file picker to choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export TremoPrompt Library',
        fileName: 'tremoprompt_export_${DateTime.now().toIso8601String().split('T')[0]}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        final jsonData = await provider.exportData();
        final file = File(result);
        await file.writeAsString(jsonData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export saved to: ${file.path}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open Folder',
              onPressed: () => Process.run('explorer', ['/select,', file.path]),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _importData() async {
    try {
      // Show file picker to choose JSON file to import
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Import TremoPrompt Library',
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();
        
        // Show confirmation dialog
        final shouldImport = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import TremoPrompt Library'),
            content: const Text(
              'This will replace all your current prompts and folders with the imported data. '
              'Are you sure you want to continue?\n\n'
              'Note: This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Import'),
              ),
            ],
          ),
        );
        
        if (shouldImport == true) {
          final provider = context.read<PromptProvider>();
          await provider.importData(jsonData);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Import completed successfully!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
  bool _isPortableAvailable = false;
  bool _isVirtualizedEnvironment = false;
  String? _customFolderPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await StorageService.getStorageMode();
    final path = await StorageService.getCurrentDatabasePath();
    final portable = await StorageService.isPortableModeAvailable();
    final virtualized = await StorageService.isVirtualizedEnvironment();
    final customPath = await StorageService.getCustomFolderPath();
    
    setState(() {
      _currentStorageMode = mode;
      _currentDatabasePath = path;
      _isPortableAvailable = portable;
      _isVirtualizedEnvironment = virtualized;
      _customFolderPath = customPath;
    });
  }

  Future<void> _selectCustomFolder() async {
    try {
      // Show folder picker
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select TremoPrompt Data Folder',
      );
      
      if (result != null) {
        // Validate the selected folder
        final isValid = await StorageService.validateCustomFolder(result);
        
        if (isValid) {
          await StorageService.setCustomFolderPath(result);
          setState(() {
            _currentStorageMode = 'custom';
            _customFolderPath = result;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Custom folder set: $result'),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Selected folder is not writable. Please choose another location.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select folder: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Storage Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Virtualized Environment Warning
            if (_isVirtualizedEnvironment)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border.all(color: Colors.orange.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Bootstrap.exclamation_triangle,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Virtualized Environment Detected',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'App appears to be running from Enigma Virtual Box or similar. '
                            'Portable mode may not work correctly. System folder is recommended.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
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
            
            // Custom Folder Option
            RadioListTile<String>(
              title: const Text('Custom Folder'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose your own storage location\n• Full control over data location\n• Easy backup and sync'),
                  if (_customFolderPath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Current: $_customFolderPath',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              value: 'custom',
              groupValue: _currentStorageMode,
              onChanged: (value) async {
                if (value != null) {
                  await _selectCustomFolder();
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Import/Export Section
            Text(
              'Import/Export Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Call import from parent widget
                      final parentState = context.findAncestorStateOfType<_PromptManagerScreenState>();
                      parentState?._importData();
                    },
                    icon: const Icon(Bootstrap.upload, size: 16),
                    label: const Text('Import Library'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Call export from parent widget  
                      final parentState = context.findAncestorStateOfType<_PromptManagerScreenState>();
                      parentState?._exportData();
                    },
                    icon: const Icon(Bootstrap.download, size: 16),
                    label: const Text('Export Library'),
                  ),
                ),
              ],
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

  Future<void> _saveSettings() async {
    final currentMode = await StorageService.getStorageMode();
    
    if (_currentStorageMode != currentMode) {
      try {
        // For custom mode, ensure custom folder is set
        if (_currentStorageMode == 'custom' && _customFolderPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a custom folder first'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
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