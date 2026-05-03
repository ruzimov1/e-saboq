import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Topshiriq muddatini sana + soat/daqiqa bilan tanlash.
Future<DateTime?> pickAssignmentDeadline(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  var base = initial;
  if (base.isBefore(firstDate)) {
    base = firstDate;
  }
  if (base.isAfter(lastDate)) {
    base = lastDate;
  }
  final date = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (!context.mounted) {
    return null;
  }
  if (date == null) {
    return null;
  }
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
  );
  if (!context.mounted) {
    return null;
  }
  if (time == null) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      base.hour,
      base.minute,
    );
  }
  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

/// Sana, oy, yil + soat:daqiqa (24 soat).
String formatAssignmentDeadlineDateTime(DateTime d) {
  return DateFormat('dd.MM.yyyy, HH:mm').format(d);
}
