import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prompt_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Database? _database;
  static const String _dbName = 'prompt_manager.db';
  static const int _dbVersion = 2;

  // Table names
  static const String _promptsTable = 'prompts';
  static const String _foldersTable = 'folders';
  static const String _historyTable = 'generated_prompts';

  // Storage mode preference
  static const String _storageMode = 'storage_mode';
  static const String _systemMode = 'system';
  static const String _portableMode = 'portable';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Get storage mode preference
  static Future<String> getStorageMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageMode) ?? _systemMode;
  }

  // Set storage mode preference
  static Future<void> setStorageMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageMode, mode);
    
    // Close current database and reinitialize with new path
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Get database path based on storage mode
  static Future<String> getDatabasePath() async {
    final mode = await getStorageMode();
    
    if (mode == _portableMode) {
      // Portable mode: Use application directory
      final executableDir = File(Platform.resolvedExecutable).parent.path;
      
      // Check if running from Enigma Virtual Box or similar virtualizer
      if (await _isVirtualizedEnvironment()) {
        print('WARNING: Detected virtualized environment (Enigma Virtual Box?)');
        print('Portable mode may not work correctly. Using Documents folder instead.');
        
        // Force use Documents folder for virtualized apps
        final documentsDir = await getApplicationDocumentsDirectory();
        return join(documentsDir.path, 'PromptManager', _dbName);
      }
      
      return join(executableDir, 'data', _dbName);
    } else {
      // System mode: Use standard OS location
      try {
        final dbPath = await getDatabasesPath();
        return join(dbPath, _dbName);
      } catch (e) {
        // Fallback to app directory
        final appDir = await getApplicationDocumentsDirectory();
        return join(appDir.path, _dbName);
      }
    }
  }

  // Detect if running in virtualized environment (Enigma Virtual Box, etc.)
  static Future<bool> _isVirtualizedEnvironment() async {
    try {
      final executablePath = Platform.resolvedExecutable;
      final executableDir = File(executablePath).parent.path;
      
      // Check common signs of virtualized environment
      // 1. Running from temp directory
      if (executableDir.contains('Temp') || executableDir.contains('TEMP')) {
        return true;
      }
      
      // 2. Check if directory is read-only or temporary
      final testPath = join(executableDir, 'test_write_evb.tmp');
      final testFile = File(testPath);
      
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
        
        // 3. Check if path looks like EVB extraction path
        if (executableDir.contains('EnigmaVB') || 
            executableDir.contains('_virtual_') ||
            executableDir.length > 200) { // Very long paths often indicate virtualization
          return true;
        }
        
        return false;
      } catch (e) {
        // Cannot write = likely virtualized
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<Database> _initDatabase() async {
    try {
      final path = await getDatabasePath();
      
      // Ensure directory exists for portable mode
      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      print('===== DATABASE DEBUG =====');
      print('Storage mode: ${await getStorageMode()}');
      print('Database path: $path');
      print('==========================');

      // Test write permissions
      try {
        final testFile = File('${dirname(path)}/test_write.txt');
        await testFile.writeAsString('test');
        await testFile.delete();
        print('Write permissions: OK');
      } catch (e) {
        print('Write permissions: FAILED - $e');
        // Force fallback to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fallbackPath = join(appDir.path, _dbName);
        print('Using fallback path: $fallbackPath');
        
        return await openDatabase(
          fallbackPath,
          version: _dbVersion,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
        );
      }

      final db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
      
      print('Database opened successfully');
      
      // Test database with simple query
      final testResult = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
      print('Database tables: $testResult');
      
      return db;
    } catch (e) {
      print('CRITICAL ERROR in _initDatabase: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Migration helper: Move database between storage modes
  static Future<void> migrateDatabaseLocation(String newMode) async {
    final currentMode = await getStorageMode();
    if (currentMode == newMode) return;
    
    try {
      // Get current and new paths
      await setStorageMode(currentMode); // Ensure current mode is set
      final oldPath = await getDatabasePath();
      
      await setStorageMode(newMode);
      final newPath = await getDatabasePath();
      
      // Copy database if old one exists
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        final newDirectory = Directory(dirname(newPath));
        if (!await newDirectory.exists()) {
          await newDirectory.create(recursive: true);
        }
        
        await oldFile.copy(newPath);
        print('Database migrated from $oldPath to $newPath');
        
        // Optionally delete old file (ask user)
        // await oldFile.delete();
      }
      
      // Close current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
    } catch (e) {
      print('Database migration failed: $e');
      // Revert to old mode
      await setStorageMode(currentMode);
      rethrow;
    }
  }

  // Get current database file path for user information
  static Future<String> getCurrentDatabasePath() async {
    return await getDatabasePath();
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
    final db = await database;
    return await db.insert(
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
    final db = await database;
    return await db.insert(
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