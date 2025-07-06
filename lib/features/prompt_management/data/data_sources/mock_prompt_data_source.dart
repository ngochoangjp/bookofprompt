import 'package:prompt_manager/features/prompt_management/data/models/prompt_model.dart';

class MockPromptDataSource {
  Future<List<PromptFolder>> getPromptFolders() async {
    // Simulate network/db delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      PromptFolder(
        id: 'f1',
        name: 'Marketing',
        prompts: [
          Prompt(
            id: 'p1',
            name: 'Blog Post Idea Generator',
            description: 'Generates 5 blog post ideas for a given topic.',
            template: 'Generate 5 creative and engaging blog post titles about the topic: "{{topic}}". The target audience is {{audience}}.',
          ),
          Prompt(
            id: 'p2',
            name: 'Social Media Ad Copy',
            description: 'Writes ad copy for Facebook.',
            template: 'Write a compelling Facebook ad copy for a product named "{{product_name}}". The key benefit is {{key_benefit}}. Include a clear call to action.',
          ),
        ],
        subFolders: [
           PromptFolder(
             id: 'f1-sub1',
             name: 'Email Campaigns',
             prompts: [
                Prompt(
                  id: 'p3',
                  name: 'Welcome Email Series',
                  description: 'Draft for a new subscriber.',
                  template: 'Draft a friendly and informative welcome email for a new subscriber to our "{{newsletter_name}}" newsletter. Mention our top feature: {{top_feature}}.',
                )
             ],
           )
        ],
      ),
      PromptFolder(
        id: 'f2',
        name: 'Development',
        prompts: [
          Prompt(
            id: 'p4',
            name: 'Code Refactoring Helper',
            description: 'Suggests improvements for a code snippet.',
            template: 'Analyze the following {{language}} code and suggest three ways to refactor it for better readability and performance. \n\n```\n{{code_snippet}}\n```',
          ),
        ],
      ),
    ];
  }
} 