import 'package:flutter/foundation.dart';

import 'informatika_json_presets.dart';
import 'cluster_template.dart';

/// JSONda alohida chalg'ituvchilar bo‘lmasa — boshqa mavzulardan va statik
/// ro‘yxatdan 2–3 ta noto‘g‘ri, lekin darsga o‘xshash variant.
List<String> suggestClusterDistractorsHeuristic({
  required ClusterTemplate current,
  required List<ClusterTemplate> allTopicsInFile,
  int count = 3,
}) {
  final own = {
    for (final k in current.kalitSozlar) InformatikaJsonPresets.normForClusterCompare(k),
  }..removeWhere((e) => e.isEmpty);

  final out = <String>[];
  final usedNorms = <String>{...own};

  for (final t in allTopicsInFile) {
    if (out.length >= count) {
      break;
    }
    if (t.id != null && current.id != null && t.id == current.id) {
      continue;
    }
    if (t.id == null &&
        current.id == null &&
        t.centerForEditor == current.centerForEditor &&
        listEquals(t.kalitSozlar, current.kalitSozlar)) {
      continue;
    }
    for (final k in t.kalitSozlar) {
      if (out.length >= count) {
        break;
      }
      final n = InformatikaJsonPresets.normForClusterCompare(k);
      if (n.isEmpty) {
        continue;
      }
      if (own.contains(n)) {
        continue;
      }
      if (usedNorms.add(n)) {
        out.add(k.trim());
      }
    }
  }

  const pool = <String>[
    "Bog'liqsiz dastur funksiyasi",
    'Boshqa bobdan keltirilgan atama',
    "Bo'sh hujjat",
    "To'g'ri javob nusxasi (test)" ,
  ];
  for (final p in pool) {
    if (out.length >= count) {
      break;
    }
    final n = InformatikaJsonPresets.normForClusterCompare(p);
    if (usedNorms.add(n)) {
      out.add(p);
    }
  }
  return out.take(count).toList();
}
