import 'package:flutter/material.dart';
import 'package:uni_project/models/proximity_prompt.dart';
import 'package:uni_project/prompt_form.dart';

class PromptItem extends StatelessWidget {
  const PromptItem({
    super.key, 
    required this.prompt, 
    required this.onEdit, 
    this.isDissmissed=false,
    });
  
  final ProximityPrompt prompt;
  final void Function(ProximityPrompt updatePrompt) onEdit;
  final bool isDissmissed;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = isDissmissed ? Colors.grey.shade300 : theme.colorScheme.primaryContainer;
    final textColor = isDissmissed ? Colors.grey.shade700 : theme.colorScheme.onSecondaryContainer;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => PromptForm(
              existingPrompt: prompt,
              onSubmit: onEdit, 
            ),
          ),
        );
      },
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Row(
            children: [
              Text(prompt.promptID),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.alarm, color: textColor),
                  const SizedBox(width: 8,),
                  Text(
                    prompt.formattedDate,
                    style: TextStyle(color: textColor
                    ),
                  ),
                ]
              )
            ],
          ),
        )
      ),
    );
  }
}

