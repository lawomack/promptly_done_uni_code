import 'package:flutter/material.dart';
import 'package:uni_project/models/proximity_prompt.dart';
import 'package:uni_project/prompt_item.dart';

class PromptsList extends StatelessWidget {
  const PromptsList({
    super.key, 
    required this.enteredPrompts,
    required this.dismissedPrompts, 
    required this.onRemovePrompt, 
    required this.onEditPrompt});

  final List<ProximityPrompt> enteredPrompts;
  final List<ProximityPrompt> dismissedPrompts;
  final void Function(ProximityPrompt prompt) onRemovePrompt;
  final void Function(ProximityPrompt updatedPrompt) onEditPrompt;

  @override
  Widget build(BuildContext context) {
    final allPrompts = [...enteredPrompts,...dismissedPrompts];

    return ListView.builder(
      itemCount: allPrompts.length, 
      itemBuilder: (ctx, index) {
        final prompt = allPrompts[index];
        final isDissmissed = dismissedPrompts.any((p) => p.promptUniqueID == prompt.promptUniqueID);

        return Dismissible(
          key: ValueKey(prompt.promptUniqueID), 
          background: Container(
            color: Theme.of(context).colorScheme.error,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onDismissed: (direction) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onRemovePrompt(prompt);
            });
          },
          child: PromptItem(
            prompt: prompt, 
            onEdit: onEditPrompt,
            isDissmissed: isDissmissed,
          ),
        );
      }
    );
  }
}
      
    