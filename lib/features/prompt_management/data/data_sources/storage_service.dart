import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prompt_model.dart';

class StorageService {
  static const String _foldersKey = 'prompt_folders';
  static const String _historyKey = 'prompt_history';
  
  static Future<void> saveFolders(List<PromptFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = folders.map((folder) => _folderToJson(folder)).toList();
    await prefs.setString(_foldersKey, jsonEncode(foldersJson));
  }
  
  static Future<List<PromptFolder>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersString = prefs.getString(_foldersKey);
    
    if (foldersString == null) {
      return [];
    }
    
    try {
      final foldersJson = jsonDecode(foldersString) as List;
      return foldersJson.map((json) => _folderFromJson(json)).toList();
    } catch (e) {
      print('Error loading folders: $e');
      return [];
    }
  }
  
  static Future<void> saveHistory(Map<String, List<GeneratedPromptHistory>> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = <String, List<Map<String, dynamic>>>{};
    
    history.forEach((key, value) {
      historyJson[key] = value.map((item) => _historyToJson(item)).toList();
    });
    
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }
  
  static Future<Map<String, List<GeneratedPromptHistory>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey);
    
    if (historyString == null) {
      return {};
    }
    
    try {
      final historyJson = jsonDecode(historyString) as Map<String, dynamic>;
      final result = <String, List<GeneratedPromptHistory>>{};
      
      historyJson.forEach((key, value) {
        final historyList = (value as List).map((item) => _historyFromJson(item)).toList();
        result[key] = historyList;
      });
      
      return result;
    } catch (e) {
      print('Error loading history: $e');
      return {};
    }
  }
  
  static Map<String, dynamic> _folderToJson(PromptFolder folder) {
    return {
      'id': folder.id,
      'name': folder.name,
      'description': folder.description,
      'prompts': folder.prompts.map((prompt) => _promptToJson(prompt)).toList(),
      'subFolders': folder.subFolders.map((subFolder) => _folderToJson(subFolder)).toList(),
      'createdAt': folder.createdAt.toIso8601String(),
      'lastModified': folder.lastModified?.toIso8601String(),
      'isExpanded': folder.isExpanded,
      'sortOrder': folder.sortOrder,
    };
  }
  
  static PromptFolder _folderFromJson(Map<String, dynamic> json) {
    return PromptFolder(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      prompts: (json['prompts'] as List).map((prompt) => _promptFromJson(prompt)).toList(),
      subFolders: (json['subFolders'] as List).map((subFolder) => _folderFromJson(subFolder)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified']) : null,
      isExpanded: json['isExpanded'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
  
  static Map<String, dynamic> _promptToJson(Prompt prompt) {
    return {
      'id': prompt.id,
      'name': prompt.name,
      'description': prompt.description,
      'template': prompt.template,
      'createdAt': prompt.createdAt.toIso8601String(),
      'lastModified': prompt.lastModified?.toIso8601String(),
      'tags': prompt.tags,
      'isFavorite': prompt.isFavorite,
      'usageCount': prompt.usageCount,
    };
  }
  
  static Prompt _promptFromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      template: json['template'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified']) : null,
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      usageCount: json['usageCount'] ?? 0,
    );
  }
  
  static Map<String, dynamic> _historyToJson(GeneratedPromptHistory history) {
    return {
      'id': history.id,
      'sourcePromptId': history.sourcePromptId,
      'generatedText': history.generatedText,
      'timestamp': history.timestamp.toIso8601String(),
    };
  }
  
  static GeneratedPromptHistory _historyFromJson(Map<String, dynamic> json) {
    return GeneratedPromptHistory(
      id: json['id'],
      sourcePromptId: json['sourcePromptId'],
      generatedText: json['generatedText'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
} 