/// بيحول وقت مخزن بصيغة 24 ساعة "HH:mm" لصيغة 12 ساعة مع AM/PM
/// مثال: "14:30" -> "2:30 PM"
String formatTime12h(String time24) {
  final parts = time24.split(':');
  if (parts.length != 2) return time24;

  int hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1].padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';

  hour = hour % 12;
  if (hour == 0) hour = 12;

  return '$hour:$minute $period';
}
