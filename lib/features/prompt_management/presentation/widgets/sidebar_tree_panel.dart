import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prompt_manager/features/prompt_management/data/models/prompt_model.dart';
import 'package:prompt_manager/features/prompt_management/presentation/providers/prompt_provider.dart';
import 'package:icons_plus/icons_plus.dart';

class SidebarTreePanel extends StatelessWidget {
  const SidebarTreePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromptProvider>();
    final theme = Theme.of(context);

    return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            title: Text("Prompts", style: theme.textTheme.headlineSmall),
            toolbarHeight: 48,
        ),
        body: Column(
        children: [
            Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
                decoration: InputDecoration(
                hintText: 'Search prompts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
            ),
            ),
            const Divider(height: 1),
            if (provider.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
            else
            Expanded(
                child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: provider.folders.length,
                itemBuilder: (context, index) {
                    final folder = provider.folders[index];
                    return _buildFolderTile(context, folder, 0);
                },
                ),
            ),
        ],
        ),
    );
  }

  Widget _buildFolderTile(BuildContext context, PromptFolder folder, int depth) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: Icon(Icons.folder_open, color: Colors.orange.shade300),
      title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        for (var subFolder in folder.subFolders)
            Padding(
                padding: EdgeInsets.only(left: 16.0 * (depth + 1)),
                child: _buildFolderTile(context, subFolder, depth + 1),
            ),
        for (var prompt in folder.prompts)
            _buildPromptTile(context, prompt, depth + 1),
      ],
    );
  }

  Widget _buildPromptTile(BuildContext context, Prompt prompt, int depth) {
    final provider = context.read<PromptProvider>();
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * depth),
      child: ListTile(
        leading: Icon(Bootstrap.lightning_charge, size: 18, color: Theme.of(context).colorScheme.secondary),
        title: Text(prompt.name),
        subtitle: Text(prompt.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          provider.openPromptInTab(prompt);
        },
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
} 