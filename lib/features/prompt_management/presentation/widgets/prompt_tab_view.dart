import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:provider/provider.dart';
import 'package:prompt_manager/features/prompt_management/data/models/prompt_model.dart';
import 'package:prompt_manager/features/prompt_management/presentation/providers/prompt_provider.dart';

class PromptTabView extends StatefulWidget {
  final Prompt prompt;
  const PromptTabView({super.key, required this.prompt});

  @override
  State<PromptTabView> createState() => _PromptTabViewState();
}

class _PromptTabViewState extends State<PromptTabView> with AutomaticKeepAliveClientMixin {
  late CodeController _codeController;
  final Map<String, TextEditingController> _variableControllers = {};
  String _finalPrompt = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  void _initialize() {
    _codeController = CodeController(
      text: widget.prompt.template,
      language: markdown,
    );
    _extractVariables();
  }
  
   void _extractVariables() {
    final regex = RegExp(r'\{\{([a-zA-Z0-9_]+)\}\}', multiLine: true);
    final matches = regex.allMatches(widget.prompt.template);
    _variableControllers.clear();
    for (var match in matches) {
      final varName = match.group(1)!;
      if (!_variableControllers.containsKey(varName)) {
        _variableControllers[varName] = TextEditingController();
      }
    }
   }

  @override
  void didUpdateWidget(covariant PromptTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.prompt.id != oldWidget.prompt.id) {
        _initialize();
        _finalPrompt = '';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _variableControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.prompt.name, style: theme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(widget.prompt.description, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 24),

          _buildSectionHeader(context, "Variables", Icons.input),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _variableControllers.isEmpty
                  ? const Text("No variables found in the template.")
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _variableControllers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final key = _variableControllers.keys.elementAt(index);
                        return TextField(
                          controller: _variableControllers[key],
                          decoration: InputDecoration(
                            labelText: key,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader(context, "Template Editor", Icons.code),
          CodeTheme(
            data: CodeThemeData(styles: isDark ? monokaiSublimeTheme : atomOneLightTheme),
            child: CodeField(
                controller: _codeController,
                minLines: 5,
                maxLines: 15,
                expands: false,
                background: theme.colorScheme.surface,
                onChanged: (value) {
                    widget.prompt.template = value;
                    setState(() {
                      _extractVariables();
                    });
                },
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: FilledButton.tonal(
              onPressed: () {
                final variables = _variableControllers.map((key, value) => MapEntry(key, value.text));
                final provider = context.read<PromptProvider>();
                setState(() {
                  _finalPrompt = provider.generatePrompt(widget.prompt, variables);
                });
              },
              child: const Text('Generate Prompt'),
            ),
          ),
          const SizedBox(height: 24),

          if (_finalPrompt.isNotEmpty) ...[
            _buildSectionHeader(context, "Final Prompt", Icons.check_circle_outline),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(_finalPrompt),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text("Copy"),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _finalPrompt));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Prompt copied to clipboard!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
} 