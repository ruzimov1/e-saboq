import 'dart:convert';

/// O‘qituvchi ekranida: yuborilgan `answer` (Map) dan inson tushunadigan matn.
String formatSubmissionAnswerForTeacher(dynamic answer) {
  if (answer == null) {
    return '—';
  }
  if (answer is! Map) {
    return answer.toString();
  }
  final m = Map<String, dynamic>.from(answer);
  final kind = m['kind'] as String? ?? 'text';
  switch (kind) {
    case 'text':
      final t = m['text'] as String? ?? '';
      return t.trim().isEmpty ? '—' : t.trim();
    case 'quiz':
      final c = m['choices'];
      if (c is List) {
        final parts = <String>[];
        for (var i = 0; i < c.length; i++) {
          final v = c[i];
          if (v == null) {
            parts.add('${i + 1}. —');
          } else {
            parts.add('${i + 1}. variant: ${v is num ? v.toInt() : v}');
          }
        }
        return parts.isEmpty ? 'Test javobi bo‘sh' : parts.join('\n');
      }
      return const JsonEncoder.withIndent('  ').convert(m);
    case 'poll':
      return 'Tanlangan variant: ${m['choice'] ?? '—'}';
    case 'brainstorm':
      final ideas = m['ideas'] ?? m['Ideas'];
      if (ideas is List && ideas.isNotEmpty) {
        final parts = <String>[];
        for (var i = 0; i < ideas.length; i++) {
          final line = ideas[i] == null ? '—' : '${ideas[i]}'.trim();
          if (line.isNotEmpty) {
            parts.add('${i + 1}. $line');
          }
        }
        if (parts.isNotEmpty) {
          return parts.join('\n');
        }
      }
      final tBrain = m['text'] as String? ?? '';
      return tBrain.trim().isEmpty ? '—' : tBrain.trim();
    case 'case':
      final probes = m['caseProbes'];
      final tools = m['caseToolDrops'];
      final ref = '${m['caseReflection'] ?? m['text'] ?? ''}'.trim();
      final buf = StringBuffer();
      if (probes is List && probes.isNotEmpty) {
        buf.writeln('Taassurof tanlovlari:');
        for (final p in probes) {
          if (p is Map) {
            buf.writeln('• ${p['label'] ?? ''} → ${p['reaction'] ?? ''}');
          }
        }
        buf.writeln();
      }
      if (tools is List && tools.isNotEmpty) {
        buf.writeln('Tanlangan asboblar:');
        for (final t in tools) {
          if (t is Map) {
            buf.writeln('• ${t['tool'] ?? t}');
          } else {
            buf.writeln('• $t');
          }
        }
        buf.writeln();
      }
      if (ref.isNotEmpty) {
        buf.writeln('Yozma javob:');
        buf.write(ref);
      }
      final aiCoach = m['caseAiReflectionCoach'];
      if (aiCoach is String && aiCoach.trim().isNotEmpty) {
        buf.writeln();
        buf.writeln('AI maslahat (yozma tahlil):');
        buf.write(aiCoach.trim());
      }
      final branches = m['caseAiStoryBranches'];
      if (branches is List && branches.isNotEmpty) {
        buf.writeln();
        buf.writeln('AI ssenarist (qo‘shimcha voqealar):');
        for (final b in branches) {
          buf.writeln('• $b');
        }
      }
      final s = buf.toString().trim();
      return s.isEmpty ? '—' : s;
    case 'fishbone':
      final ts = m['tSchema'];
      if (ts is Map) {
        final buf = StringBuffer();
        final left = ts['left'];
        final right = ts['right'];
        final ua = ts['userAddedItems'];
        if (left is List && left.isNotEmpty) {
          buf.writeln('Chap:');
          for (final e in left) {
            if (e is Map) {
              buf.writeln('• ${e['text'] ?? e}');
            }
          }
        }
        if (right is List && right.isNotEmpty) {
          buf.writeln('O‘ng:');
          for (final e in right) {
            if (e is Map) {
              buf.writeln('• ${e['text'] ?? e}');
            }
          }
        }
        if (ua is List && ua.isNotEmpty) {
          buf.writeln('O‘quvchi qo‘shgan:');
          for (final e in ua) {
            if (e is Map) {
              buf.writeln(
                '• (${e['side'] ?? '—'}) ${e['text'] ?? ''}',
              );
            }
          }
        }
        if (buf.isNotEmpty) {
          return buf.toString().trim();
        }
      }
      final fb = m['text'] as String? ?? '';
      return fb.trim().isEmpty ? '—' : fb.trim();
    default:
      final t = m['text'] as String?;
      if (t != null && t.trim().isNotEmpty) {
        return t.trim();
      }
      return const JsonEncoder.withIndent('  ').convert(m);
  }
}

/// AI / qisqacha ko‘rinish uchun bitta matn.
String formatSubmissionAnswerPlain(dynamic answer) {
  return formatSubmissionAnswerForTeacher(answer).replaceAll('\n', ' · ');
}
