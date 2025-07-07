import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../providers/prompt_provider.dart';
import '../../data/models/prompt_model.dart';

class MainContentPanel extends StatefulWidget {
  const MainContentPanel({super.key});

  @override
  State<MainContentPanel> createState() => _MainContentPanelState();
}

class _MainContentPanelState extends State<MainContentPanel> with TickerProviderStateMixin {
  late TabController _tabController;
  CodeController? _templateController;
  final TextEditingController _templateTextController = TextEditingController();
  final Map<String, TextEditingController> _variableControllers = {};
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  String _generatedPrompt = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _templateController?.dispose();
    _templateTextController.dispose();
    for (final controller in _variableControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromptProvider>(
      builder: (context, provider, child) {
        final selectedPrompt = provider.selectedPrompt;
        
        if (selectedPrompt == null) {
          return _buildEmptyState();
        }

        // Initialize controllers when prompt changes
        _initializeControllers(selectedPrompt, provider);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(selectedPrompt, provider),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEditTab(selectedPrompt, provider),
                    _buildVariablesTab(selectedPrompt, provider),
                    _buildGenerateTab(selectedPrompt, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Bootstrap.lightning,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Select a prompt to get started',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a prompt from the sidebar to edit templates,\nset variables, and generate final prompts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PromptModel prompt, PromptProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                prompt.isFavorite ? Bootstrap.star_fill : Bootstrap.file_text,
                color: prompt.isFavorite
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (provider.hasUnsavedChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Unsaved',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              _buildHeaderActions(prompt, provider),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prompt.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (prompt.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: prompt.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderActions(PromptModel prompt, PromptProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Save (Ctrl+S)',
          child: IconButton(
            icon: const Icon(Bootstrap.save, size: 18),
            onPressed: provider.hasUnsavedChanges
                ? () => provider.saveCurrentPrompt()
                : null,
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Toggle Favorite',
          child: IconButton(
            icon: Icon(
              prompt.isFavorite ? Bootstrap.star_fill : Bootstrap.star,
              size: 18,
            ),
            onPressed: () => provider.togglePromptFavorite(prompt.id),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton(
          icon: const Icon(Bootstrap.three_dots_vertical, size: 18),
          itemBuilder: (context) => <PopupMenuEntry>[
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Bootstrap.copy, size: 16),
                  const SizedBox(width: 8),
                  const Text('Duplicate'),
                ],
              ),
              onTap: () => provider.duplicatePrompt(prompt.id),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Bootstrap.arrow_right, size: 16),
                  const SizedBox(width: 8),
                  const Text('Move to Folder'),
                ],
              ),
              onTap: () => _showMovePromptDialog(prompt, provider),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    Bootstrap.trash,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              onTap: () => _showDeletePromptDialog(prompt, provider),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(
          icon: Icon(Bootstrap.code, size: 16),
          text: 'Template',
        ),
        Tab(
          icon: Icon(Bootstrap.sliders, size: 16),
          text: 'Variables',
        ),
        Tab(
          icon: Icon(Bootstrap.lightning, size: 16),
          text: 'Generate',
        ),
      ],
    );
  }

  Widget _buildEditTab(PromptModel prompt, PromptProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Template Editor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                'Use {{variable}} syntax for dynamic content',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _templateTextController,
                decoration: InputDecoration(
                  hintText: 'Enter your template here...\n\nExample:\nWrite a professional email to {{recipient}} about {{subject}}.\nThe tone should be {{tone}} and include {{details}}.',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (value) {
                  _onTemplateChanged(value, prompt, provider);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _saveTemplate(prompt, provider),
                icon: const Icon(Bootstrap.save, size: 16),
                label: const Text('Save Template'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _addVariable(),
                icon: const Icon(Bootstrap.plus, size: 16),
                label: const Text('Add Variable'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _previewTemplate(prompt),
                icon: const Icon(Bootstrap.eye, size: 16),
                label: const Text('Preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesTab(PromptModel prompt, PromptProvider provider) {
    final templateVariables = prompt.templateVariables;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Template Variables',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Set values for variables used in your template',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (templateVariables.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Bootstrap.sliders,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No variables found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add variables to your template using {{variable}} syntax',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: templateVariables.length,
                itemBuilder: (context, index) {
                  final variable = templateVariables[index];
                  return _buildVariableField(variable, provider);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVariableField(String variable, PromptProvider provider) {
    final controller = _variableControllers[variable]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Bootstrap.braces,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  variable,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter value for $variable',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: controller.text.contains('\n') ? null : 1,
              onChanged: (value) {
                provider.updateVariable(variable, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTab(PromptModel prompt, PromptProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Generate Final Prompt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generatePrompt(provider),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Bootstrap.lightning, size: 16),
                label: Text(_isGenerating ? 'Generating...' : 'Generate'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Final Prompt',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      if (_generatedPrompt.isNotEmpty) ...[
                        TextButton.icon(
                          onPressed: () => _copyToClipboard(_generatedPrompt),
                          icon: const Icon(Bootstrap.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _saveToHistory(provider),
                          icon: const Icon(Bootstrap.save, size: 16),
                          label: const Text('Save to History'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _generatedPrompt.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Bootstrap.lightning,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Click Generate to create your final prompt',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SelectableText(
                              _generatedPrompt,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initializeControllers(PromptModel prompt, PromptProvider provider) {
    // Initialize template controller
    if (_templateTextController.text != prompt.template) {
      _templateTextController.text = prompt.template;
    }
    
    // Keep the old CodeController for backward compatibility (if needed)
    if (_templateController == null || _templateController!.text != prompt.template) {
      _templateController?.dispose();
      _templateController = CodeController(
        text: prompt.template,
      );
    }

    // Initialize variable controllers
    final templateVariables = prompt.templateVariables;
    final currentVariables = provider.currentVariables;

    // Remove controllers for variables that no longer exist
    _variableControllers.removeWhere((key, controller) {
      if (!templateVariables.contains(key)) {
        controller.dispose();
        return true;
      }
      return false;
    });

    // Add controllers for new variables
    for (final variable in templateVariables) {
      if (!_variableControllers.containsKey(variable)) {
        _variableControllers[variable] = TextEditingController(
          text: currentVariables[variable] ?? '',
        );
      } else {
        // Update existing controller if value changed
        final currentValue = currentVariables[variable] ?? '';
        if (_variableControllers[variable]!.text != currentValue) {
          _variableControllers[variable]!.text = currentValue;
        }
      }
    }
  }

  void _saveTemplate(PromptModel prompt, PromptProvider provider) {
    final updatedPrompt = prompt.copyWith(
      template: _templateTextController.text,
    );
    provider.updatePrompt(updatedPrompt);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _previewTemplate(PromptModel prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template Preview'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              _templateTextController.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
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

  void _generatePrompt(PromptProvider provider) {
    setState(() {
      _isGenerating = true;
    });

    // Simulate generation delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final generated = provider.generateFinalPrompt();
      setState(() {
        _generatedPrompt = generated;
        _isGenerating = false;
      });
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveToHistory(PromptProvider provider) {
    provider.saveToHistory(_generatedPrompt);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to history'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMovePromptDialog(PromptModel prompt, PromptProvider provider) {
    String? selectedFolderId = prompt.parentFolderId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Prompt'),
        content: DropdownButtonFormField<String>(
          value: selectedFolderId,
          decoration: const InputDecoration(
            labelText: 'Move to Folder',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedFolderId != null) {
                provider.movePrompt(prompt.id, selectedFolderId!);
                Navigator.pop(context);
              }
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  void _showDeletePromptDialog(PromptModel prompt, PromptProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prompt'),
        content: Text('Are you sure you want to delete "${prompt.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletePrompt(prompt.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onTemplateChanged(String value, PromptModel prompt, PromptProvider provider) {
    // Extract variables from template in real-time
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(value);
    final newVariables = matches.map((match) => match.group(1)!.trim()).toSet().toList();
    
    // Update the prompt with new template
    final updatedPrompt = prompt.copyWith(template: value);
    
    // Update provider with new variables
    final currentVariables = Map<String, String>.from(provider.currentVariables);
    
    // Add new variables with empty values
    for (final variable in newVariables) {
      if (!currentVariables.containsKey(variable)) {
        currentVariables[variable] = '';
      }
    }
    
    // Remove variables that are no longer in template
    currentVariables.removeWhere((key, value) => !newVariables.contains(key));
    
    // Update provider
    provider.updateVariables(currentVariables);
    
    // Mark as having unsaved changes
    provider.updatePrompt(updatedPrompt);
  }

  void _addVariable() {
    final cursorPosition = _templateTextController.selection.start;
    
    // Show dialog to enter variable name
    showDialog(
      context: context,
      builder: (context) {
        String variableName = '';
        return AlertDialog(
          title: const Text('Add Variable'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Variable Name',
              hintText: 'Enter variable name (without braces)',
            ),
            onChanged: (value) {
              variableName = value;
            },
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (variableName.isNotEmpty) {
                  _insertVariable(variableName, cursorPosition);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _insertVariable(String variableName, int cursorPosition) {
    final currentText = _templateTextController.text;
    final variableText = '{{$variableName}}';
    
    String newText;
    int newCursorPosition;
    
    if (cursorPosition >= 0 && cursorPosition <= currentText.length) {
      newText = currentText.substring(0, cursorPosition) +
          variableText +
          currentText.substring(cursorPosition);
      newCursorPosition = cursorPosition + variableText.length;
    } else {
      newText = currentText + variableText;
      newCursorPosition = newText.length;
    }
    
    _templateTextController.text = newText;
    _templateTextController.selection = TextSelection.collapsed(offset: newCursorPosition);
  }
} 