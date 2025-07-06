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
            actions: [
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 20),
                onPressed: () => _showCreateFolderDialog(context),
                tooltip: 'Create New Folder',
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _showCreatePromptDialog(context),
                tooltip: 'Create New Prompt',
              ),
            ],
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
    return GestureDetector(
      onSecondaryTapDown: (details) => _showFolderContextMenu(context, details, folder),
      child: ExpansionTile(
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
      ),
    );
  }

  Widget _buildPromptTile(BuildContext context, Prompt prompt, int depth) {
    final provider = context.read<PromptProvider>();
    
    // Extract first line of template as headline
    String headline = prompt.template.split('\n').first.trim();
    if (headline.length > 50) {
      headline = '${headline.substring(0, 50)}...';
    }
    if (headline.isEmpty) {
      headline = 'No content';
    }
    
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * depth),
      child: ListTile(
        leading: Icon(Bootstrap.lightning_charge, size: 18, color: Theme.of(context).colorScheme.secondary),
        title: Text(prompt.name),
        subtitle: Text(headline, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          provider.openPromptInTab(prompt);
        },
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<PromptProvider>().createNewFolder(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreatePromptDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final provider = context.read<PromptProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Prompt Name',
                hintText: 'Enter prompt name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Folder',
                hintText: 'Select folder',
              ),
              items: provider.folders.map((folder) => DropdownMenuItem(
                value: folder.id,
                child: Text(folder.name),
              )).toList(),
              onChanged: (value) {
                // Store selected folder ID
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && 
                  descController.text.trim().isNotEmpty) {
                // Use first folder as default if no selection
                final folderId = provider.folders.isNotEmpty ? provider.folders.first.id : '';
                provider.createNewPrompt(
                  nameController.text.trim(),
                  descController.text.trim(),
                  folderId,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showFolderContextMenu(BuildContext context, TapDownDetails details, PromptFolder folder) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: const Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red.shade600)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'rename') {
        _showRenameFolderDialog(context, folder);
      } else if (value == 'delete') {
        // TODO: Implement delete folder functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete folder functionality coming soon!')),
        );
      }
    });
  }

  void _showRenameFolderDialog(BuildContext context, PromptFolder folder) {
    final TextEditingController controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter new folder name',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<PromptProvider>().renameFolder(folder.id, value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<PromptProvider>().renameFolder(folder.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
} 