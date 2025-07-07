import 'package:flutter/material.dart';
import 'dart:convert';
import '../../data/models/prompt_model.dart';
import '../../data/services/storage_service.dart';

class PromptProvider extends ChangeNotifier {
  // Core data
  List<PromptFolder> _folders = [];
  List<PromptModel> _allPrompts = [];
  List<GeneratedPrompt> _currentHistory = [];
  
  // Current selections
  PromptModel? _selectedPrompt;
  PromptFolder? _selectedFolder;
  
  // UI state
  bool _isLoading = false;
  String _searchQuery = '';
  ThemeMode _themeMode = ThemeMode.dark;
  
  // Auto-save state
  Map<String, String> _currentVariables = {};
  bool _hasUnsavedChanges = false;
  
  // Getters
  List<PromptFolder> get folders => _folders;
  List<PromptModel> get allPrompts => _allPrompts;
  List<GeneratedPrompt> get currentHistory => _currentHistory;
  PromptModel? get selectedPrompt => _selectedPrompt;
  PromptFolder? get selectedFolder => _selectedFolder;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ThemeMode get themeMode => _themeMode;
  Map<String, String> get currentVariables => _currentVariables;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  
  // Filtered prompts based on search
  List<PromptModel> get filteredPrompts {
    if (_searchQuery.isEmpty) return _allPrompts;
    
    return _allPrompts.where((prompt) {
      final query = _searchQuery.toLowerCase();
      return prompt.name.toLowerCase().contains(query) ||
             prompt.description.toLowerCase().contains(query) ||
             prompt.template.toLowerCase().contains(query) ||
             prompt.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }
  
  // Favorite prompts
  List<PromptModel> get favoritePrompts {
    return _allPrompts.where((prompt) => prompt.isFavorite).toList();
  }

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadData();
    } catch (e) {
      debugPrint('Error initializing PromptProvider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load data from storage
  Future<void> _loadData() async {
    _folders = await StorageService.getAllFolders();
    _allPrompts = await StorageService.getAllPrompts();
    
    // Organize prompts into folders
    for (final folder in _folders) {
      final folderPrompts = _allPrompts.where((p) => p.parentFolderId == folder.id).toList();
      final updatedFolder = folder.copyWith(prompts: folderPrompts);
      final index = _folders.indexOf(folder);
      _folders[index] = updatedFolder;
    }
    
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Theme management
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Folder operations
  Future<void> createNewFolder({
    required String name,
    String? parentId,
  }) async {
    final folder = PromptFolder(
      name: name,
      parentId: parentId,
    );
    
    await StorageService.insertFolder(folder);
    await _loadData();
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final folder = _folders.firstWhere((f) => f.id == folderId);
    final updatedFolder = folder.copyWith(name: newName);
    
    await StorageService.updateFolder(updatedFolder);
    await _loadData();
  }

  Future<void> deleteFolder(String folderId) async {
    // Move prompts to general folder before deleting
    final promptsInFolder = _allPrompts.where((p) => p.parentFolderId == folderId).toList();
    for (final prompt in promptsInFolder) {
      final updatedPrompt = prompt.copyWith(parentFolderId: 'general');
      await StorageService.updatePrompt(updatedPrompt);
    }
    
    await StorageService.deleteFolder(folderId);
    await _loadData();
  }

  // Prompt operations
  Future<void> createNewPrompt({
    required String name,
    required String description,
    String template = '',
    String? folderId,
  }) async {
    final prompt = PromptModel(
      name: name,
      description: description,
      template: template,
      parentFolderId: folderId ?? 'general',
    );
    
    await StorageService.insertPrompt(prompt);
    await _loadData();
  }

  Future<void> updatePrompt(PromptModel prompt) async {
    await StorageService.updatePrompt(prompt);
    
    // Update local state
    final index = _allPrompts.indexWhere((p) => p.id == prompt.id);
    if (index != -1) {
      _allPrompts[index] = prompt;
    }
    
    // Update selected prompt if it's the same
    if (_selectedPrompt?.id == prompt.id) {
      _selectedPrompt = prompt;
    }
    
    _hasUnsavedChanges = false;
    await _loadData();
  }

  Future<void> deletePrompt(String promptId) async {
    await StorageService.deletePrompt(promptId);
    
    // Clear selection if deleted prompt was selected
    if (_selectedPrompt?.id == promptId) {
      _selectedPrompt = null;
      _currentHistory.clear();
      _currentVariables.clear();
    }
    
    await _loadData();
  }

  Future<void> duplicatePrompt(String promptId) async {
    final originalPrompt = _allPrompts.firstWhere((p) => p.id == promptId);
    final duplicatedPrompt = PromptModel(
      name: '${originalPrompt.name} (Copy)',
      description: originalPrompt.description,
      template: originalPrompt.template,
      category: originalPrompt.category,
      tags: List.from(originalPrompt.tags),
      variables: Map.from(originalPrompt.variables),
      parentFolderId: originalPrompt.parentFolderId,
    );
    
    await StorageService.insertPrompt(duplicatedPrompt);
    await _loadData();
  }

  Future<void> movePrompt(String promptId, String newFolderId) async {
    final prompt = _allPrompts.firstWhere((p) => p.id == promptId);
    final updatedPrompt = prompt.copyWith(parentFolderId: newFolderId);
    
    await StorageService.updatePrompt(updatedPrompt);
    await _loadData();
  }

  Future<void> togglePromptFavorite(String promptId) async {
    final prompt = _allPrompts.firstWhere((p) => p.id == promptId);
    final updatedPrompt = prompt.copyWith(isFavorite: !prompt.isFavorite);
    
    await StorageService.updatePrompt(updatedPrompt);
    await _loadData();
  }

  // Selection management
  Future<void> selectPrompt(PromptModel prompt) async {
    _selectedPrompt = prompt;
    
    // Load history for this prompt
    _currentHistory = await StorageService.getHistoryForPrompt(prompt.id);
    
    // Initialize variables with prompt defaults
    _currentVariables = Map.from(prompt.variables);
    
    // Extract template variables
    final templateVars = prompt.templateVariables;
    for (final varName in templateVars) {
      if (!_currentVariables.containsKey(varName)) {
        _currentVariables[varName] = '';
      }
    }
    
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void selectFolder(PromptFolder folder) {
    _selectedFolder = folder;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPrompt = null;
    _selectedFolder = null;
    _currentHistory.clear();
    _currentVariables.clear();
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // Variable management
  void updateVariable(String key, String value) {
    _currentVariables[key] = value;
    _hasUnsavedChanges = true;
    notifyListeners();
    
    // Auto-save after a delay
    _autoSave();
  }

  void updateVariables(Map<String, String> variables) {
    _currentVariables.addAll(variables);
    _hasUnsavedChanges = true;
    notifyListeners();
    
    // Auto-save after a delay
    _autoSave();
  }

  // Auto-save functionality
  void _autoSave() {
    if (_selectedPrompt == null) return;
    
    // Save variables to prompt
    Future.delayed(const Duration(seconds: 2), () async {
      if (_selectedPrompt != null && _hasUnsavedChanges) {
        final updatedPrompt = _selectedPrompt!.copyWith(
          variables: _currentVariables,
        );
        await StorageService.updatePrompt(updatedPrompt);
        _hasUnsavedChanges = false;
        notifyListeners();
      }
    });
  }

  // Manual save
  Future<void> saveCurrentPrompt() async {
    if (_selectedPrompt == null) return;
    
    final updatedPrompt = _selectedPrompt!.copyWith(
      variables: _currentVariables,
    );
    await updatePrompt(updatedPrompt);
  }

  // Generate prompt
  String generateFinalPrompt() {
    if (_selectedPrompt == null) return '';
    return _selectedPrompt!.generatePrompt(_currentVariables);
  }

  // Save generated prompt to history
  Future<void> saveToHistory(String generatedContent) async {
    if (_selectedPrompt == null) return;
    
    final historyItem = GeneratedPrompt(
      promptId: _selectedPrompt!.id,
      content: generatedContent,
      variables: Map.from(_currentVariables),
    );
    
    await StorageService.insertGeneratedPrompt(historyItem);
    
    // Reload history
    _currentHistory = await StorageService.getHistoryForPrompt(_selectedPrompt!.id);
    notifyListeners();
  }

  // History management
  Future<void> deleteHistoryItem(String historyId) async {
    await StorageService.deleteGeneratedPrompt(historyId);
    
    // Reload history
    if (_selectedPrompt != null) {
      _currentHistory = await StorageService.getHistoryForPrompt(_selectedPrompt!.id);
      notifyListeners();
    }
  }

  Future<void> loadHistoryItem(GeneratedPrompt historyItem) async {
    _currentVariables = Map.from(historyItem.variables);
    notifyListeners();
  }

  // Drag & Drop support
  Future<void> reorderFolders(List<PromptFolder> newOrder) async {
    _folders = newOrder;
    notifyListeners();
    
    // Save new order to storage (if needed)
    // This could be implemented with a sort_order field
  }

  Future<void> reorderPrompts(String folderId, List<PromptModel> newOrder) async {
    // Update local state
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      final updatedFolder = _folders[folderIndex].copyWith(prompts: newOrder);
      _folders[folderIndex] = updatedFolder;
      notifyListeners();
    }
    
    // Save new order to storage (if needed)
    // This could be implemented with a sort_order field
  }

  // Export/Import functionality
  Future<String> exportData() async {
    final data = {
      'folders': _folders.map((f) => f.toMap()).toList(),
      'prompts': _allPrompts.map((p) => p.toMap()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'app_name': 'TremoPrompt',
      'total_prompts': _allPrompts.length,
      'total_folders': _folders.length,
    };
    
    // Return formatted JSON string
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<void> importData(String jsonData) async {
    _setLoading(true);
    
    try {
      // Parse JSON
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Validate format
      if (!data.containsKey('folders') || !data.containsKey('prompts')) {
        throw Exception('Invalid TremoPrompt export format');
      }
      
      // Clear existing data
      await StorageService.clearAllData();
      
      // Import folders
      final folders = data['folders'] as List<dynamic>;
      for (final folderData in folders) {
        final folder = PromptFolder.fromMap(folderData);
        await StorageService.insertFolder(folder);
      }
      
      // Import prompts
      final prompts = data['prompts'] as List<dynamic>;
      for (final promptData in prompts) {
        final prompt = PromptModel.fromMap(promptData);
        await StorageService.insertPrompt(prompt);
      }
      
      // Reload data
      await _loadData();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Utility methods
  PromptFolder? getFolderById(String folderId) {
    try {
      return _folders.firstWhere((f) => f.id == folderId);
    } catch (e) {
      return null;
    }
  }

  PromptModel? getPromptById(String promptId) {
    try {
      return _allPrompts.firstWhere((p) => p.id == promptId);
    } catch (e) {
      return null;
    }
  }

  List<PromptModel> getPromptsInFolder(String folderId) {
    return _allPrompts.where((p) => p.parentFolderId == folderId).toList();
  }

  // Statistics
  int get totalPrompts => _allPrompts.length;
  int get totalFolders => _folders.length;
  int get favoriteCount => favoritePrompts.length;
  
  Map<String, int> get promptsByCategory {
    final Map<String, int> categories = {};
    for (final prompt in _allPrompts) {
      categories[prompt.category] = (categories[prompt.category] ?? 0) + 1;
    }
    return categories;
  }

  @override
  void dispose() {
    // Save any pending changes before disposing
    if (_hasUnsavedChanges && _selectedPrompt != null) {
      saveCurrentPrompt();
    }
    super.dispose();
  }
} 