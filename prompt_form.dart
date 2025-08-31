import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uni_project/models/proximity_prompt.dart';

// This is a screen for inputting all the required prompt information in. 

final formatter = DateFormat.yMd('en_GB');
final timeFormatter = DateFormat.Hm();

class PromptForm extends StatefulWidget {
  const PromptForm({super.key, this.existingPrompt, required this.onSubmit});

  final ProximityPrompt? existingPrompt;
  final void Function(ProximityPrompt prompt) onSubmit;

  @override
  State<PromptForm> createState() => _PromptFromState();
}

class _PromptFromState extends State<PromptForm> {
  late TextEditingController _titleController;
  final _optionalController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingPrompt?.promptID ?? '',
    );
    _optionalController.text = widget.existingPrompt?.promptInfo ?? '';
    _selectedDate = widget.existingPrompt?.date;
    _selectedTime = widget.existingPrompt?.time;
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year, now.month + 2, now.day);
    final pickedDate = await showDatePicker(
      context: context, 
      initialDate: now, 
      firstDate: firstDate, 
      lastDate: lastDate,
    );
    if (pickedDate != null) {
      
      print("Picked date: $pickedDate");

      _updateCombinedDateTime(newDate: pickedDate);
    }
  } 


  void _presentTimePicker() async {
    final now = TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context, 
      initialTime: now, 
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), 
          child: child!);
      },
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime != null){
      print("Picked time: ${pickedTime.format(context)}");
      _updateCombinedDateTime(newTime: pickedTime);
    }
  } 

  void _updateCombinedDateTime({DateTime? newDate, TimeOfDay? newTime}) {
    print("Updated combined datetime: $_selectedTime");
    final date = newDate ?? _selectedDate;
    final time = newTime ?? (_selectedTime != null
      ? TimeOfDay.fromDateTime(_selectedTime!)
      : null);

    if (date != null && time != null) {
      setState(() {
        _selectedDate = date;
        _selectedTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    } else {
      if (newDate != null) {
        setState(() {
          _selectedDate = newDate;
        });
      }
      if (newTime != null) {
        final now = DateTime.now();
        setState(() {
          _selectedTime = DateTime(
            now.year,
            now.month,
            now.day,
            newTime.hour,
            newTime.minute,
          );
        });
      }
    }
  }

  void _submitPromptData() {
    if (_titleController.text.trim().isEmpty || _selectedDate == null || _selectedTime == null) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text('Invalid input'),
        content: const Text('Please make sure you have set a location title, date and time'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            }, 
          child: const Text('Okay'))
        ],
      ));
      return;
    }

    final updatedPrompt = ProximityPrompt(
      promptID: _titleController.text, 
      date: _selectedDate!, 
      time: _selectedTime!,
      promptUniqueID: widget.existingPrompt?.promptUniqueID,
      promptInfo: _optionalController.text,
    );

    widget.onSubmit(updatedPrompt);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _optionalController.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPrompt ==null ? 'New Prompt' : 'Edit Prompt'),),
        body: Padding(
          padding: EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Column(
            //mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Reminder Location'),
                ),
              ),
              TextField(
                controller: _optionalController,
                maxLength: 100,
                decoration: const InputDecoration(
                  label: Text('Optional Information'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _selectedDate == null ? 'No date selected' : 
                      formatter.format(_selectedDate!),
                    ),
                    IconButton(
                      onPressed: _presentDatePicker, 
                      icon: const Icon(
                        Icons.calendar_month,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _selectedTime == null ? 'No time selected' : 
                      DateFormat.Hm().format(_selectedTime!),
                    ),
                    IconButton(
                      onPressed: _presentTimePicker, 
                      icon: const Icon(
                        Icons.access_time,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    }, 
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: 
                      _submitPromptData,
                    child: Text('Save Prompt'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
}
