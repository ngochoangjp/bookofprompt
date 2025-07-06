import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prompt_manager/features/prompt_management/presentation/providers/prompt_provider.dart';
import 'package:prompt_manager/features/prompt_management/presentation/widgets/prompt_tab_view.dart';

class MainContentPanel extends StatelessWidget {
  const MainContentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromptProvider>();
    final theme = Theme.of(context);

    if (provider.openPrompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 60, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'Select a prompt from the left panel to start working',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    
    return DefaultTabController(
      key: ValueKey(provider.activeTabIndex), // Important to rebuild on index change
      length: provider.openPrompts.length,
      initialIndex: provider.activeTabIndex,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              provider.setActiveTabIndex(tabController.index);
            }
          });
          
          return Scaffold(
             backgroundColor: theme.scaffoldBackgroundColor,
             appBar: AppBar(
                backgroundColor: theme.colorScheme.surface,
                toolbarHeight: 48,
                elevation: 0,
                flexibleSpace: TabBar(
                  controller: tabController,
                  isScrollable: true,
                  tabs: provider.openPrompts.map((prompt) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(prompt.name),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            final index = provider.openPrompts.indexOf(prompt);
                            provider.closePromptTab(index);
                          },
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              body: TabBarView(
                controller: tabController,
                children: provider.openPrompts.map((prompt) => PromptTabView(prompt: prompt)).toList(),
              ),
          );
        }
      ),
    );
  }
} 