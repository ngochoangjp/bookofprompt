import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prompt_manager/features/prompt_management/presentation/providers/prompt_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromptProvider>();
    final history = provider.currentPromptHistory;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: Text("History", style: theme.textTheme.headlineSmall),
        toolbarHeight: 48,
        actions: [
            IconButton(onPressed: (){}, icon: Icon(Icons.search, size: 20)),
            IconButton(onPressed: (){}, icon: Icon(Icons.filter_list, size: 20)),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                provider.activePrompt == null
                    ? "Select a prompt to see its history"
                    : "No history for this prompt yet. \nGenerate one to get started!",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      item.generatedText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jms().format(item.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.generatedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('History item copied!')),
                          );
                        },
                    ),
                  ),
                );
              },
            ),
    );
  }
} 