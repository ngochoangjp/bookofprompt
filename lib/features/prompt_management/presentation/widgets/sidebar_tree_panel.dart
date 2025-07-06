import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';
import '../providers/prompt_provider.dart';
import '../../data/models/prompt_model.dart';

class SidebarTreePanel extends StatefulWidget {
  const SidebarTreePanel({super.key});

  @override
  State<SidebarTreePanel> createState() => _SidebarTreePanelState();
}

class _SidebarTreePanelState extends State<SidebarTreePanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
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
          _buildHeader(),
          _buildSearchBar(),
          const SizedBox(height: 8),
          Expanded(
            child: _buildTreeView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Row(
        children: [
          Icon(
            Bootstrap.folder_fill,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Prompt Library',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Create New Folder',
          child: IconButton(
            icon: const Icon(Bootstrap.folder_plus, size: 18),
            onPressed: () => _showCreateFolderDialog(),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Create New Prompt',
          child: IconButton(
            icon: const Icon(Bootstrap.plus_circle, size: 18),
            onPressed: () => _showCreatePromptDialog(),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search prompts...',
          prefixIcon: const Icon(Bootstrap.search, size: 16),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Bootstrap.x, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    context.read<PromptProvider>().clearSearch();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          context.read<PromptProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildTreeView() {
    return Consumer<PromptProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.searchQuery.isNotEmpty) {
          return _buildSearchResults(provider);
        }

        return _buildFolderTree(provider);
      },
    );
  }

  Widget _buildSearchResults(PromptProvider provider) {
    final filteredPrompts = provider.filteredPrompts;

    if (filteredPrompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Bootstrap.search,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No prompts found',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: filteredPrompts.length,
      itemBuilder: (context, index) {
        final prompt = filteredPrompts[index];
        return _buildPromptTile(prompt, provider);
      },
    );
  }

  Widget _buildFolderTree(PromptProvider provider) {
    return ReorderableListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final folders = List<PromptFolder>.from(provider.folders);
        final folder = folders.removeAt(oldIndex);
        folders.insert(newIndex, folder);
        provider.reorderFolders(folders);
      },
      children: provider.folders.map((folder) {
        return _buildFolderTile(folder, provider);
      }).toList(),
    );
  }

  Widget _buildFolderTile(PromptFolder folder, PromptProvider provider) {
    final isSelected = provider.selectedFolder?.id == folder.id;
    final promptCount = provider.getPromptsInFolder(folder.id).length;

    return Card(
      key: ValueKey(folder.id),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(
            folder.isExpanded ? Bootstrap.folder : Bootstrap.folder_fill,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  folder.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (promptCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    promptCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          onExpansionChanged: (expanded) {
            // Update folder expansion state
            final updatedFolder = folder.copyWith(isExpanded: expanded);
            // Note: You might want to save this to storage
          },
          children: [
            ...provider.getPromptsInFolder(folder.id).map((prompt) {
              return _buildPromptTile(prompt, provider, isInFolder: true);
            }),
            if (promptCount == 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No prompts in this folder',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptTile(PromptModel prompt, PromptProvider provider, {bool isInFolder = false}) {
    final isSelected = provider.selectedPrompt?.id == prompt.id;

    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showPromptContextMenu(context, details.globalPosition, prompt, provider);
      },
      child: Card(
        key: ValueKey(prompt.id),
        margin: EdgeInsets.symmetric(
          vertical: 1,
          horizontal: isInFolder ? 16 : 0,
        ),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        child: ListTile(
          leading: Icon(
            prompt.isFavorite ? Bootstrap.star_fill : Bootstrap.file_text,
            color: prompt.isFavorite
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 16,
          ),
          title: Text(
            prompt.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            prompt.headline, // Show headline instead of description
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: prompt.isFavorite
              ? Icon(
                  Bootstrap.star_fill,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 14,
                )
              : null,
          onTap: () {
            provider.selectPrompt(prompt);
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  void _showPromptContextMenu(BuildContext context, Offset position, PromptModel prompt, PromptProvider provider) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Bootstrap.pencil, size: 16),
              const SizedBox(width: 8),
              const Text('Rename'),
            ],
          ),
          onTap: () => _showRenamePromptDialog(prompt, provider),
        ),
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
              Icon(
                prompt.isFavorite ? Bootstrap.star : Bootstrap.star_fill,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(prompt.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
            ],
          ),
          onTap: () => provider.togglePromptFavorite(prompt.id),
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
    );
  }

  void _showFolderContextMenu(BuildContext context, Offset position, PromptFolder folder, PromptProvider provider) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Bootstrap.pencil, size: 16),
              const SizedBox(width: 8),
              const Text('Rename'),
            ],
          ),
          onTap: () => _showRenameFolderDialog(folder, provider),
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
          onTap: () => _showDeleteFolderDialog(folder, provider),
        ),
      ],
    );
  }

  // Dialog methods
  void _showCreateFolderDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: nameController,
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
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<PromptProvider>().createNewFolder(
                  name: nameController.text.trim(),
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

  void _showCreatePromptDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedFolderId;

    showDialog(
      context: context,
      builder: (context) => Consumer<PromptProvider>(
        builder: (context, provider, child) => AlertDialog(
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
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter description',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFolderId,
                decoration: const InputDecoration(
                  labelText: 'Folder',
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  provider.createNewPrompt(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    folderId: selectedFolderId,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(PromptFolder folder, PromptProvider provider) {
    final nameController = TextEditingController(text: folder.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                provider.renameFolder(folder.id, nameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showRenamePromptDialog(PromptModel prompt, PromptProvider provider) {
    final nameController = TextEditingController(text: prompt.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Prompt'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Prompt Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedPrompt = prompt.copyWith(name: nameController.text.trim());
                provider.updatePrompt(updatedPrompt);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
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

  void _showDeleteFolderDialog(PromptFolder folder, PromptProvider provider) {
    final promptCount = provider.getPromptsInFolder(folder.id).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${folder.name}"?'),
            if (promptCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$promptCount prompt(s) will be moved to the General folder.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteFolder(folder.id);
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
} 