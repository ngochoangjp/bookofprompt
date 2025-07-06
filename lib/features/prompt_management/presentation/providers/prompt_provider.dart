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
} 