import 'package:uuid/uuid.dart';

class PromptModel {
  final String id;
  final String name;
  final String description;
  final String template;
  final String category;
  final List<String> tags;
  final Map<String, String> variables;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String? parentFolderId;
  final int sortOrder;

  PromptModel({
    String? id,
    required this.name,
    required this.description,
    required this.template,
    this.category = 'General',
    this.tags = const [],
    this.variables = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
    this.parentFolderId,
    this.sortOrder = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Get headline from template (first line)
  String get headline {
    final lines = template.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim();
      if (firstLine.length > 50) {
        return '${firstLine.substring(0, 50)}...';
      }
      return firstLine.isNotEmpty ? firstLine : 'No content';
    }
    return 'No content';
  }

  // Extract template variables
  List<String> get templateVariables {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(template);
    return matches.map((match) => match.group(1)!.trim()).toSet().toList();
  }

  // Generate final prompt by replacing variables
  String generatePrompt(Map<String, String> variableValues) {
    String result = template;
    for (final entry in variableValues.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  // Copy with method
  PromptModel copyWith({
    String? id,
    String? name,
    String? description,
    String? template,
    String? category,
    List<String>? tags,
    Map<String, String>? variables,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? parentFolderId,
    int? sortOrder,
  }) {
    return PromptModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      template: template ?? this.template,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      variables: variables ?? this.variables,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'template': template,
      'category': category,
      'tags': tags.join(','),
      'variables': variables.entries.map((e) => '${e.key}:${e.value}').join('|'),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'parent_folder_id': parentFolderId,
      'sort_order': sortOrder,
    };
  }

  // Create from map
  factory PromptModel.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String? ?? '';
    final tags = tagsString.isEmpty ? <String>[] : tagsString.split(',');
    
    final variablesString = map['variables'] as String? ?? '';
    final variables = <String, String>{};
    if (variablesString.isNotEmpty) {
      final pairs = variablesString.split('|');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          variables[parts[0]] = parts[1];
        }
      }
    }

    return PromptModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      template: map['template'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      tags: tags,
      variables: variables,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      parentFolderId: map['parent_folder_id'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}

class PromptFolder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isExpanded;
  final List<PromptModel> prompts;
  final int sortOrder;

  PromptFolder({
    String? id,
    required this.name,
    this.parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isExpanded = true,
    this.prompts = const [],
    this.sortOrder = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method
  PromptFolder copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isExpanded,
    List<PromptModel>? prompts,
    int? sortOrder,
  }) {
    return PromptFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isExpanded: isExpanded ?? this.isExpanded,
      prompts: prompts ?? this.prompts,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_expanded': isExpanded ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  // Create from map
  factory PromptFolder.fromMap(Map<String, dynamic> map) {
    return PromptFolder(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isExpanded: (map['is_expanded'] as int? ?? 1) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}

class GeneratedPrompt {
  final String id;
  final String promptId;
  final String content;
  final Map<String, String> variables;
  final DateTime createdAt;
  final bool isFavorite;

  GeneratedPrompt({
    String? id,
    required this.promptId,
    required this.content,
    required this.variables,
    DateTime? createdAt,
    this.isFavorite = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Copy with method
  GeneratedPrompt copyWith({
    String? id,
    String? promptId,
    String? content,
    Map<String, String>? variables,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return GeneratedPrompt(
      id: id ?? this.id,
      promptId: promptId ?? this.promptId,
      content: content ?? this.content,
      variables: variables ?? this.variables,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'promptId': promptId,
      'content': content,
      'variables': variables.entries.map((e) => '${e.key}:${e.value}').join('|'),
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  // Create from map
  factory GeneratedPrompt.fromMap(Map<String, dynamic> map) {
    final variablesString = map['variables'] as String? ?? '';
    final variables = <String, String>{};
    if (variablesString.isNotEmpty) {
      final pairs = variablesString.split('|');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          variables[parts[0]] = parts[1];
        }
      }
    }

    return GeneratedPrompt(
      id: map['id'] as String,
      promptId: map['promptId'] as String,
      content: map['content'] as String,
      variables: variables,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }
}