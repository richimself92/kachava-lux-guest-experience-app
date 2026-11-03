import 'package:flutter/material.dart';
import '../../domain/entities/stay_entities.dart';

/// Opens a date picker bounded to the stay and returns `yyyy-MM-dd`.
///
/// Returns `null` when cancelled or when the stay has no dates: no date range
/// is ever invented.
Future<String?> pickStayDate(BuildContext context, StaySummary stay) async {
  final bounds = stay.stayDateBounds;
  if (bounds == null) return null;
  final picked = await showDatePicker(
    context: context,
    initialDate: bounds.$1,
    firstDate: bounds.$1,
    lastDate: bounds.$2,
  );
  if (picked == null) return null;
  final m = picked.month.toString().padLeft(2, '0');
  final d = picked.day.toString().padLeft(2, '0');
  return '${picked.year}-$m-$d';
}
