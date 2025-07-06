import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prompt_model.dart';

class StorageService {
  static Database? _database;
  static const String _dbName = 'prompt_manager.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _promptsTable = 'prompts';
  static const String _foldersTable = 'folders';
  static const String _historyTable = 'generated_prompts';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      
      print('Database path: $path');

      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    // Create prompts table
    await db.execute('''
      CREATE TABLE $_promptsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        template TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        tags TEXT NOT NULL DEFAULT '[]',
        variables TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        parent_folder_id TEXT
      )
    ''');

    // Create folders table
    await db.execute('''
      CREATE TABLE $_foldersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_expanded INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create generated prompts history table
    await db.execute('''
      CREATE TABLE $_historyTable (
        id TEXT PRIMARY KEY,
        prompt_id TEXT NOT NULL,
        content TEXT NOT NULL,
        variables TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (prompt_id) REFERENCES $_promptsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create default folders
    await _createDefaultData(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades
    if (oldVersion < newVersion) {
      // Add upgrade logic here when needed
    }
  }

  static Future<void> _createDefaultData(Database db) async {
    // Create default folders
    final defaultFolders = [
      {
        'id': 'general',
        'name': 'General',
        'parent_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_expanded': 1,
      },
      {
        'id': 'work',
        'name': 'Work',
        'parent_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_expanded': 1,
      },
      {
        'id': 'personal',
        'name': 'Personal',
        'parent_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_expanded': 1,
      },
    ];

    for (final folder in defaultFolders) {
      await db.insert(_foldersTable, folder);
    }

    // Create sample prompts
    final samplePrompts = [
      {
        'id': 'sample1',
        'name': 'Email Writer',
        'description': 'Professional email template',
        'template': 'Write a professional email to {{recipient}} about {{subject}}. The tone should be {{tone}} and include {{details}}.',
        'category': 'Communication',
        'tags': '["email", "professional", "communication"]',
        'variables': '{"recipient": "", "subject": "", "tone": "formal", "details": ""}',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_favorite': 0,
        'parent_folder_id': 'work',
      },
      {
        'id': 'sample2',
        'name': 'Code Reviewer',
        'description': 'Code review template',
        'template': 'Review the following {{language}} code for:\n- Code quality\n- Performance\n- Security\n- Best practices\n\nCode:\n{{code}}',
        'category': 'Development',
        'tags': '["code", "review", "development"]',
        'variables': '{"language": "Python", "code": ""}',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_favorite': 1,
        'parent_folder_id': 'work',
      },
    ];

    for (final prompt in samplePrompts) {
      await db.insert(_promptsTable, prompt);
    }
  }

  // Test database connection
  static Future<bool> testConnection() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1');
      print('Database test successful: $result');
      return true;
    } catch (e) {
      print('Database test failed: $e');
      return false;
    }
  }

  // CRUD operations for Prompts
  static Future<List<PromptModel>> getAllPrompts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_promptsTable);

    return List.generate(maps.length, (i) {
      return PromptModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        template: maps[i]['template'],
        category: maps[i]['category'],
        tags: List<String>.from(jsonDecode(maps[i]['tags'])),
        variables: Map<String, String>.from(jsonDecode(maps[i]['variables'])),
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
        isFavorite: maps[i]['is_favorite'] == 1,
        parentFolderId: maps[i]['parent_folder_id'],
      );
    });
  }

  static Future<PromptModel?> getPromptById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _promptsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return PromptModel(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        template: map['template'],
        category: map['category'],
        tags: List<String>.from(jsonDecode(map['tags'])),
        variables: Map<String, String>.from(jsonDecode(map['variables'])),
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
        isFavorite: map['is_favorite'] == 1,
        parentFolderId: map['parent_folder_id'],
      );
    }
    return null;
  }

  static Future<int> insertPrompt(PromptModel prompt) async {
    try {
      print('Attempting to insert prompt: ${prompt.name} with ID: ${prompt.id}');
      final db = await database;
      final result = await db.insert(
        _promptsTable,
        {
          'id': prompt.id,
          'name': prompt.name,
          'description': prompt.description,
          'template': prompt.template,
          'category': prompt.category,
          'tags': jsonEncode(prompt.tags),
          'variables': jsonEncode(prompt.variables),
          'created_at': prompt.createdAt.toIso8601String(),
          'updated_at': prompt.updatedAt.toIso8601String(),
          'is_favorite': prompt.isFavorite ? 1 : 0,
          'parent_folder_id': prompt.parentFolderId,
        },
      );
      print('Successfully inserted prompt with result: $result');
      return result;
    } catch (e) {
      print('Error inserting prompt: $e');
      rethrow;
    }
  }

  static Future<int> updatePrompt(PromptModel prompt) async {
    final db = await database;
    return await db.update(
      _promptsTable,
      {
        'name': prompt.name,
        'description': prompt.description,
        'template': prompt.template,
        'category': prompt.category,
        'tags': jsonEncode(prompt.tags),
        'variables': jsonEncode(prompt.variables),
        'updated_at': DateTime.now().toIso8601String(),
        'is_favorite': prompt.isFavorite ? 1 : 0,
        'parent_folder_id': prompt.parentFolderId,
      },
      where: 'id = ?',
      whereArgs: [prompt.id],
    );
  }

  static Future<int> deletePrompt(String id) async {
    final db = await database;
    return await db.delete(
      _promptsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Folders
  static Future<List<PromptFolder>> getAllFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_foldersTable);

    // Get all prompts to organize them into folders
    final prompts = await getAllPrompts();

    return List.generate(maps.length, (i) {
      final folderId = maps[i]['id'];
      final folderPrompts = prompts.where((p) => p.parentFolderId == folderId).toList();

      return PromptFolder(
        id: folderId,
        name: maps[i]['name'],
        parentId: maps[i]['parent_id'],
        prompts: folderPrompts,
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
        isExpanded: maps[i]['is_expanded'] == 1,
      );
    });
  }

  static Future<int> insertFolder(PromptFolder folder) async {
    try {
      print('Attempting to insert folder: ${folder.name} with ID: ${folder.id}');
      final db = await database;
      final result = await db.insert(
        _foldersTable,
        {
          'id': folder.id,
          'name': folder.name,
          'parent_id': folder.parentId,
          'created_at': folder.createdAt.toIso8601String(),
          'updated_at': folder.updatedAt.toIso8601String(),
          'is_expanded': folder.isExpanded ? 1 : 0,
        },
      );
      print('Successfully inserted folder with result: $result');
      return result;
    } catch (e) {
      print('Error inserting folder: $e');
      rethrow;
    }
  }

  static Future<int> updateFolder(PromptFolder folder) async {
    final db = await database;
    return await db.update(
      _foldersTable,
      {
        'name': folder.name,
        'parent_id': folder.parentId,
        'updated_at': DateTime.now().toIso8601String(),
        'is_expanded': folder.isExpanded ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  static Future<int> deleteFolder(String id) async {
    final db = await database;
    return await db.delete(
      _foldersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Generated Prompts History
  static Future<List<GeneratedPrompt>> getHistoryForPrompt(String promptId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _historyTable,
      where: 'prompt_id = ?',
      whereArgs: [promptId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return GeneratedPrompt(
        id: maps[i]['id'],
        promptId: maps[i]['prompt_id'],
        content: maps[i]['content'],
        variables: Map<String, String>.from(jsonDecode(maps[i]['variables'])),
        createdAt: DateTime.parse(maps[i]['created_at']),
        isFavorite: maps[i]['is_favorite'] == 1,
      );
    });
  }

  static Future<int> insertGeneratedPrompt(GeneratedPrompt generatedPrompt) async {
    final db = await database;
    return await db.insert(
      _historyTable,
      {
        'id': generatedPrompt.id,
        'prompt_id': generatedPrompt.promptId,
        'content': generatedPrompt.content,
        'variables': jsonEncode(generatedPrompt.variables),
        'created_at': generatedPrompt.createdAt.toIso8601String(),
        'is_favorite': generatedPrompt.isFavorite ? 1 : 0,
      },
    );
  }

  static Future<int> deleteGeneratedPrompt(String id) async {
    final db = await database;
    return await db.delete(
      _historyTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Utility methods
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_promptsTable);
    await db.delete(_foldersTable);
    await db.delete(_historyTable);
    await _createDefaultData(db);
  }

  static Future<void> exportData() async {
    // Implementation for data export
    final prompts = await getAllPrompts();
    final folders = await getAllFolders();
    
    final exportData = {
      'prompts': prompts.map((p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'template': p.template,
        'category': p.category,
        'tags': p.tags,
        'variables': p.variables,
        'created_at': p.createdAt.toIso8601String(),
        'updated_at': p.updatedAt.toIso8601String(),
        'is_favorite': p.isFavorite,
        'parent_folder_id': p.parentFolderId,
      }).toList(),
      'folders': folders.map((f) => {
        'id': f.id,
        'name': f.name,
        'parent_id': f.parentId,
        'created_at': f.createdAt.toIso8601String(),
        'updated_at': f.updatedAt.toIso8601String(),
        'is_expanded': f.isExpanded,
      }).toList(),
    };

    // Return JSON string for export
    print('Export data: ${jsonEncode(exportData)}');
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
} 