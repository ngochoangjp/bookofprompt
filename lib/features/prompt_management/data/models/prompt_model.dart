import 'package:flutter/material.dart';

class Prompt {
  final String id;
  final String name;
  final String description;
  String template; // Can be modified
  final DateTime createdAt;
  final DateTime? lastModified;
  final List<String> tags;
  final IconData? icon;
  final Color? color;
  final bool isFavorite;
  final int usageCount;

  Prompt({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    DateTime? createdAt,
    this.lastModified,
    List<String>? tags,
    this.icon,
    this.color,
    this.isFavorite = false,
    this.usageCount = 0,
  }) : createdAt = createdAt ?? DateTime.now(),
       tags = tags ?? [];

  // Copy with method for easy updates
  Prompt copyWith({
    String? name,
    String? description,
    String? template,
    DateTime? lastModified,
    List<String>? tags,
    IconData? icon,
    Color? color,
    bool? isFavorite,
    int? usageCount,
  }) {
    return Prompt(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      template: template ?? this.template,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
      tags: tags ?? this.tags,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  // Helper method to get display color
  Color getDisplayColor(BuildContext context) {
    if (color != null) return color!;
    
    // Return theme-appropriate default colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use different colors based on usage or category
    if (isFavorite) return colorScheme.tertiary;
    if (usageCount > 10) return colorScheme.primary;
    if (usageCount > 5) return colorScheme.secondary;
    return colorScheme.surfaceVariant;
  }

  // Helper method to get display icon
  IconData getDisplayIcon() {
    if (icon != null) return icon!;
    
    // Return contextual icons based on content
    if (isFavorite) return Icons.star_rounded;
    if (template.toLowerCase().contains('email')) return Icons.email_rounded;
    if (template.toLowerCase().contains('code')) return Icons.code_rounded;
    if (template.toLowerCase().contains('write')) return Icons.edit_rounded;
    if (template.toLowerCase().contains('analyze')) return Icons.analytics_rounded;
    if (template.toLowerCase().contains('summarize')) return Icons.summarize_rounded;
    return Icons.description_rounded;
  }

  // Helper method to check if prompt matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           description.toLowerCase().contains(lowerQuery) ||
           template.toLowerCase().contains(lowerQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }
}

class PromptFolder {
  final String id;
  final String name;
  final String? description;
  final List<Prompt> prompts;
  final List<PromptFolder> subFolders;
  final DateTime createdAt;
  final DateTime? lastModified;
  final IconData? icon;
  final Color? color;
  final bool isExpanded;
  final int sortOrder;

  PromptFolder({
    required this.id,
    required this.name,
    this.description,
    List<Prompt>? prompts,
    List<PromptFolder>? subFolders,
    DateTime? createdAt,
    this.lastModified,
    this.icon,
    this.color,
    this.isExpanded = false,
    this.sortOrder = 0,
  }) : prompts = prompts ?? [],
       subFolders = subFolders ?? [],
       createdAt = createdAt ?? DateTime.now();

  // Copy with method for easy updates
  PromptFolder copyWith({
    String? name,
    String? description,
    List<Prompt>? prompts,
    List<PromptFolder>? subFolders,
    DateTime? lastModified,
    IconData? icon,
    Color? color,
    bool? isExpanded,
    int? sortOrder,
  }) {
    return PromptFolder(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      prompts: prompts ?? this.prompts,
      subFolders: subFolders ?? this.subFolders,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isExpanded: isExpanded ?? this.isExpanded,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Helper method to get total prompt count including subfolders
  int get totalPromptCount {
    int count = prompts.length;
    for (var folder in subFolders) {
      count += folder.totalPromptCount;
    }
    return count;
  }

  // Helper method to get display color
  Color getDisplayColor(BuildContext context) {
    if (color != null) return color!;
    
    // Return theme-appropriate default colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use different colors based on content
    if (totalPromptCount > 20) return colorScheme.primary;
    if (totalPromptCount > 10) return colorScheme.secondary;
    if (totalPromptCount > 5) return colorScheme.tertiary;
    return colorScheme.surfaceVariant;
  }

  // Helper method to get display icon
  IconData getDisplayIcon() {
    if (icon != null) return icon!;
    
    // Return contextual icons based on name or content
    final lowerName = name.toLowerCase();
    if (lowerName.contains('work') || lowerName.contains('business')) {
      return Icons.work_rounded;
    }
    if (lowerName.contains('personal') || lowerName.contains('private')) {
      return Icons.person_rounded;
    }
    if (lowerName.contains('creative') || lowerName.contains('writing')) {
      return Icons.create_rounded;
    }
    if (lowerName.contains('code') || lowerName.contains('technical')) {
      return Icons.code_rounded;
    }
    if (lowerName.contains('email') || lowerName.contains('communication')) {
      return Icons.email_rounded;
    }
    if (lowerName.contains('social') || lowerName.contains('media')) {
      return Icons.share_rounded;
    }
    return isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded;
  }

  // Helper method to search within folder and subfolders
  List<Prompt> searchPrompts(String query) {
    List<Prompt> results = [];
    
    // Search in this folder's prompts
    results.addAll(prompts.where((prompt) => prompt.matchesSearch(query)));
    
    // Search in subfolders
    for (var folder in subFolders) {
      results.addAll(folder.searchPrompts(query));
    }
    
    return results;
  }

  // Helper method to check if folder matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           (description?.toLowerCase().contains(lowerQuery) ?? false) ||
           searchPrompts(query).isNotEmpty;
  }
}

class GeneratedPromptHistory {
  final String id;
  final String sourcePromptId;
  final String generatedText;
  final DateTime timestamp;
  final String? title;
  final List<String> tags;
  final bool isFavorite;
  final double? rating;
  final String? notes;
  final Map<String, String> metadata;

  GeneratedPromptHistory({
    required this.id,
    required this.sourcePromptId,
    required this.generatedText,
    required this.timestamp,
    this.title,
    List<String>? tags,
    this.isFavorite = false,
    this.rating,
    this.notes,
    Map<String, String>? metadata,
  }) : tags = tags ?? [],
       metadata = metadata ?? {};

  // Copy with method for easy updates
  GeneratedPromptHistory copyWith({
    String? title,
    List<String>? tags,
    bool? isFavorite,
    double? rating,
    String? notes,
    Map<String, String>? metadata,
  }) {
    return GeneratedPromptHistory(
      id: id,
      sourcePromptId: sourcePromptId,
      generatedText: generatedText,
      timestamp: timestamp,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to get display title
  String getDisplayTitle() {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    
    // Generate title from first few words of generated text
    final words = generatedText.split(' ');
    if (words.length > 5) {
      return '${words.take(5).join(' ')}...';
    }
    return generatedText;
  }

  // Helper method to get formatted timestamp
  String getFormattedTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to check if history matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return (title?.toLowerCase().contains(lowerQuery) ?? false) ||
           generatedText.toLowerCase().contains(lowerQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
           (notes?.toLowerCase().contains(lowerQuery) ?? false);
  }

  // Helper method to get word count
  int get wordCount {
    return generatedText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  // Helper method to get character count
  int get characterCount {
    return generatedText.length;
  }
}