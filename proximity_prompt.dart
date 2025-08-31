import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat.yMd('en_GB');
final timeFormatter = DateFormat.Hm();
final _uuid = Uuid();

class ProximityPrompt {
  ProximityPrompt({
    required this.promptID, 
    required this.promptInfo,
    required this.date, 
    required this.time,
    String? promptUniqueID, 
    }) : promptUniqueID = promptUniqueID ?? _uuid.v4();
  
  final String promptID;
  final String promptInfo;
  final DateTime date;
  final DateTime? time;
  final String promptUniqueID;

  String get formattedDate {
    return formatter.format(date);
  }
  String get formattedTime => time != null ? timeFormatter.format(time!) : "No time set";

  // these steps are so that it can be saved into memory when the app is closed
  String toStorageString() {
    final timeString = time?.toIso8601String() ?? '';
    return '$promptID|${date.toIso8601String()}|$timeString|$promptUniqueID|$promptInfo';
  }
  
  static ProximityPrompt fromStorageString(String stored) {
    final parts = stored.split('|');
    return ProximityPrompt(
      promptID: parts[0], 
      date: DateTime.parse(parts[1]),
      time: parts.length > 2 && parts[2].isNotEmpty ? DateTime.parse(parts[2]) : null,
      promptUniqueID: parts.length >3 ? parts [3] : null,
      promptInfo: parts.length >4 ? parts [4] : '',
    );
  }
}
