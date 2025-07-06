class Prompt {
  final String id;
  final String name;
  final String description;
  String template; // Can be modified

  Prompt({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
  });
}

class PromptFolder {
  final String id;
  final String name;
  final List<Prompt> prompts;
  final List<PromptFolder> subFolders;

  PromptFolder({
    required this.id,
    required this.name,
    List<Prompt>? prompts,
    List<PromptFolder>? subFolders,
  }) : prompts = prompts ?? [],
       subFolders = subFolders ?? [];
}

class GeneratedPromptHistory {
    final String id;
    final String sourcePromptId;
    final String generatedText;
    final DateTime timestamp;

    GeneratedPromptHistory({
        required this.id,
        required this.sourcePromptId,
        required this.generatedText,
        required this.timestamp,
    });
} 