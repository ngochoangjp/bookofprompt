import 'package:flutter/material.dart';
import 'package:prompt_manager/features/prompt_management/data/data_sources/mock_prompt_data_source.dart';
import 'package:prompt_manager/features/prompt_management/data/models/prompt_model.dart';
import 'package:uuid/uuid.dart';

class PromptProvider extends ChangeNotifier {
  final MockPromptDataSource _dataSource = MockPromptDataSource();
  final Uuid _uuid = Uuid();

  bool _isLoading = true;
  List<PromptFolder> _folders = [];
  List<Prompt> _openPrompts = [];
  int _activeTabIndex = 0;
  final Map<String, List<GeneratedPromptHistory>> _history = {};

  // Getters
  bool get isLoading => _isLoading;
  List<PromptFolder> get folders => _folders;
  List<Prompt> get openPrompts => _openPrompts;
  int get activeTabIndex => _activeTabIndex;
  Prompt? get activePrompt => _openPrompts.isNotEmpty ? _openPrompts[_activeTabIndex] : null;
  List<GeneratedPromptHistory> get currentPromptHistory => _history[activePrompt?.id] ?? [];


  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    _folders = await _dataSource.getPromptFolders();
    _isLoading = false;
    notifyListeners();
  }
  
  void openPromptInTab(Prompt prompt) {
    if (!_openPrompts.any((p) => p.id == prompt.id)) {
      _openPrompts.add(prompt);
      _activeTabIndex = _openPrompts.length - 1;
    } else {
      _activeTabIndex = _openPrompts.indexWhere((p) => p.id == prompt.id);
    }
    notifyListeners();
  }

  void closePromptTab(int index) {
      _openPrompts.removeAt(index);
      if (_activeTabIndex >= _openPrompts.length) {
          _activeTabIndex = _openPrompts.length - 1;
      }
      if (_activeTabIndex < 0) _activeTabIndex = 0;
      notifyListeners();
  }
  
  void setActiveTabIndex(int index) {
      _activeTabIndex = index;
      notifyListeners();
  }
  
  String generatePrompt(Prompt prompt, Map<String, String> variables) {
    String generatedText = prompt.template;
    variables.forEach((key, value) {
      generatedText = generatedText.replaceAll('{{$key}}', value);
    });

    // Add to history
    final historyEntry = GeneratedPromptHistory(
        id: _uuid.v4(),
        sourcePromptId: prompt.id,
        generatedText: generatedText,
        timestamp: DateTime.now()
    );

    if (_history.containsKey(prompt.id)) {
        _history[prompt.id]!.insert(0, historyEntry); // Add to top
    } else {
        _history[prompt.id] = [historyEntry];
    }
    
    notifyListeners();
    return generatedText;
  }

  void createNewFolder(String name) {
    final newFolder = PromptFolder(
      id: _uuid.v4(),
      name: name,
      prompts: [],
      subFolders: [],
    );
    _folders.add(newFolder);
    notifyListeners();
  }

  void createNewPrompt(String name, String description, String folderId) {
    final newPrompt = Prompt(
      id: _uuid.v4(),
      name: name,
      description: description.isEmpty ? '' : description,
      template: 'Enter your prompt template here...',
    );

    // Find the folder and add the prompt
    _addPromptToFolder(newPrompt, folderId);
    notifyListeners();
  }

  void _addPromptToFolder(Prompt prompt, String folderId) {
    for (var folder in _folders) {
      if (folder.id == folderId) {
        folder.prompts.add(prompt);
        return;
      }
      _addPromptToSubFolder(prompt, folderId, folder);
    }
  }

  void _addPromptToSubFolder(Prompt prompt, String folderId, PromptFolder folder) {
    for (var subFolder in folder.subFolders) {
      if (subFolder.id == folderId) {
        subFolder.prompts.add(prompt);
        return;
      }
      _addPromptToSubFolder(prompt, folderId, subFolder);
    }
  }

  void renameFolder(String folderId, String newName) {
    _renameFolderRecursive(_folders, folderId, newName);
    notifyListeners();
  }

  void _renameFolderRecursive(List<PromptFolder> folders, String folderId, String newName) {
    for (var folder in folders) {
      if (folder.id == folderId) {
        // Use copyWith method to create updated folder
        final updatedFolder = folder.copyWith(name: newName);
        final index = folders.indexOf(folder);
        folders[index] = updatedFolder;
        return;
      }
      _renameFolderRecursive(folder.subFolders, folderId, newName);
    }
  }

  void renamePrompt(String promptId, String newName) {
    _renamePromptRecursive(_folders, promptId, newName);
    
    // Also update in open tabs if the prompt is open
    for (int i = 0; i < _openPrompts.length; i++) {
      if (_openPrompts[i].id == promptId) {
        _openPrompts[i] = _openPrompts[i].copyWith(name: newName);
        break;
      }
    }
    
    notifyListeners();
  }

  void _renamePromptRecursive(List<PromptFolder> folders, String promptId, String newName) {
    for (var folder in folders) {
      // Check prompts in current folder
      for (int i = 0; i < folder.prompts.length; i++) {
        if (folder.prompts[i].id == promptId) {
          folder.prompts[i] = folder.prompts[i].copyWith(name: newName);
          return;
        }
      }
      // Check subfolders
      _renamePromptRecursive(folder.subFolders, promptId, newName);
    }
  }

  void updatePromptDetails(String promptId, String newName, String newDescription) {
    _updatePromptDetailsRecursive(_folders, promptId, newName, newDescription);
    
    // Also update in open tabs if the prompt is open
    for (int i = 0; i < _openPrompts.length; i++) {
      if (_openPrompts[i].id == promptId) {
        _openPrompts[i] = _openPrompts[i].copyWith(name: newName, description: newDescription);
        break;
      }
    }
    
    notifyListeners();
  }

  void _updatePromptDetailsRecursive(List<PromptFolder> folders, String promptId, String newName, String newDescription) {
    for (var folder in folders) {
      // Check prompts in current folder
      for (int i = 0; i < folder.prompts.length; i++) {
        if (folder.prompts[i].id == promptId) {
          folder.prompts[i] = folder.prompts[i].copyWith(name: newName, description: newDescription);
          return;
        }
      }
      // Check subfolders
      _updatePromptDetailsRecursive(folder.subFolders, promptId, newName, newDescription);
    }
  }

  void duplicatePrompt(String promptId, String newName) {
    final originalPrompt = _findPromptById(promptId);
    if (originalPrompt != null) {
      final duplicatedPrompt = Prompt(
        id: _uuid.v4(),
        name: newName,
        description: originalPrompt.description,
        template: originalPrompt.template,
      );
      
      // Add to the same folder as original
      final folderId = _findFolderIdByPromptId(promptId);
      if (folderId != null) {
        _addPromptToFolder(duplicatedPrompt, folderId);
        notifyListeners();
      }
    }
  }

  void deletePrompt(String promptId) {
    _deletePromptRecursive(_folders, promptId);
    
    // Also remove from open tabs if the prompt is open
    _openPrompts.removeWhere((prompt) => prompt.id == promptId);
    if (_activeTabIndex >= _openPrompts.length) {
      _activeTabIndex = _openPrompts.length - 1;
    }
    if (_activeTabIndex < 0) _activeTabIndex = 0;
    
    // Remove from history
    _history.remove(promptId);
    
    notifyListeners();
  }

  void _deletePromptRecursive(List<PromptFolder> folders, String promptId) {
    for (var folder in folders) {
      // Check prompts in current folder
      folder.prompts.removeWhere((prompt) => prompt.id == promptId);
      
      // Check subfolders
      _deletePromptRecursive(folder.subFolders, promptId);
    }
  }

  void movePrompt(String promptId, String targetFolderId) {
    final prompt = _findPromptById(promptId);
    if (prompt != null) {
      // Remove from current location
      _deletePromptRecursive(_folders, promptId);
      
      // Add to target folder
      _addPromptToFolder(prompt, targetFolderId);
      
      notifyListeners();
    }
  }

  Prompt? _findPromptById(String promptId) {
    return _findPromptByIdRecursive(_folders, promptId);
  }

  Prompt? _findPromptByIdRecursive(List<PromptFolder> folders, String promptId) {
    for (var folder in folders) {
      // Check prompts in current folder
      for (var prompt in folder.prompts) {
        if (prompt.id == promptId) {
          return prompt;
        }
      }
      // Check subfolders
      final found = _findPromptByIdRecursive(folder.subFolders, promptId);
      if (found != null) return found;
    }
    return null;
  }

  String? _findFolderIdByPromptId(String promptId) {
    return _findFolderIdByPromptIdRecursive(_folders, promptId);
  }

  String? _findFolderIdByPromptIdRecursive(List<PromptFolder> folders, String promptId) {
    for (var folder in folders) {
      // Check prompts in current folder
      for (var prompt in folder.prompts) {
        if (prompt.id == promptId) {
          return folder.id;
        }
      }
      // Check subfolders
      final found = _findFolderIdByPromptIdRecursive(folder.subFolders, promptId);
      if (found != null) return found;
    }
    return null;
  }

  List<PromptFolder> getAllFolders() {
    List<PromptFolder> allFolders = [];
    _getAllFoldersRecursive(_folders, allFolders);
    return allFolders;
  }

  void _getAllFoldersRecursive(List<PromptFolder> folders, List<PromptFolder> result) {
    for (var folder in folders) {
      result.add(folder);
      _getAllFoldersRecursive(folder.subFolders, result);
    }
  }

  void deleteFolder(String folderId) {
    // First, close any open tabs from prompts in this folder
    _closeFolderPromptTabs(folderId);
    
    // Remove folder from structure
    _deleteFolderRecursive(_folders, folderId);
    
    notifyListeners();
  }

  void _closeFolderPromptTabs(String folderId) {
    final folderPrompts = _getFolderPrompts(folderId);
    for (var prompt in folderPrompts) {
      _openPrompts.removeWhere((p) => p.id == prompt.id);
      _history.remove(prompt.id);
    }
    
    // Adjust active tab index
    if (_activeTabIndex >= _openPrompts.length) {
      _activeTabIndex = _openPrompts.length - 1;
    }
    if (_activeTabIndex < 0) _activeTabIndex = 0;
  }

  List<Prompt> _getFolderPrompts(String folderId) {
    List<Prompt> prompts = [];
    _getFolderPromptsRecursive(_folders, folderId, prompts);
    return prompts;
  }

  void _getFolderPromptsRecursive(List<PromptFolder> folders, String folderId, List<Prompt> result) {
    for (var folder in folders) {
      if (folder.id == folderId) {
        // Add all prompts from this folder
        result.addAll(folder.prompts);
        // Add all prompts from subfolders
        _getAllPromptsFromSubfolders(folder.subFolders, result);
        return;
      }
      _getFolderPromptsRecursive(folder.subFolders, folderId, result);
    }
  }

  void _getAllPromptsFromSubfolders(List<PromptFolder> folders, List<Prompt> result) {
    for (var folder in folders) {
      result.addAll(folder.prompts);
      _getAllPromptsFromSubfolders(folder.subFolders, result);
    }
  }

  void _deleteFolderRecursive(List<PromptFolder> folders, String folderId) {
    folders.removeWhere((folder) => folder.id == folderId);
    
    for (var folder in folders) {
      _deleteFolderRecursive(folder.subFolders, folderId);
    }
  }
} 