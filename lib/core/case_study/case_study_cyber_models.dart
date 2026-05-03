/// Case-study «kiber-detektiv»: tizim ogohlantirishi va taassurof tanlovlari.
library;

// Suhbat qatori (chat bubble uchun). JSON: role + text.
class CaseDialogueLine {
  const CaseDialogueLine({
    required this.role,
    required this.text,
  });

  /// `admin` · `system` · `client` · `user` (boshqa bo‘lsa, `user` sifatida ko‘rsatiladi).
  final String role;
  final String text;

  static CaseDialogueLine? tryParse(dynamic e) {
    if (e is! Map) return null;
    final m = Map<String, dynamic>.from(e);
    final role = '${m['role'] ?? m['speaker'] ?? 'user'}'.trim().toLowerCase();
    final text = '${m['text'] ?? m['message'] ?? ''}'.trim();
    if (text.isEmpty) return null;
    return CaseDialogueLine(role: role.isEmpty ? 'user' : role, text: text);
  }
}

class CaseCyberOption {
  const CaseCyberOption({
    required this.label,
    required this.isCorrect,
    required this.reaction,
  });

  final String label;
  final bool isCorrect;

  /// Tanlanganidan keyin ko‘rsatiladigan oqibat yoki tasdiq (yechimni bevosita bermaydi).
  final String reaction;

  Map<String, dynamic> toLogJson() => {
        'label': label,
        'correct': isCorrect,
        'reaction': reaction,
      };

  static CaseCyberOption? fromJson(dynamic e) {
    if (e is! Map) return null;
    final m = Map<String, dynamic>.from(e);
    final label = '${m['label'] ?? m['text'] ?? ''}'.trim();
    if (label.isEmpty) return null;
    final correct = m['correct'] == true;
    final reaction =
        '${m['reaction'] ?? m['consequence'] ?? m['feedback'] ?? ''}'.trim();
    return CaseCyberOption(
      label: label,
      isCorrect: correct,
      reaction:
          reaction.isNotEmpty ? reaction : (correct ? 'Qadam qabul qilindi.' : 'Bu tanlov xavfli natijalarga olib kelishi mumkin.'),
    );
  }
}

class CaseCyberTask {
  const CaseCyberTask({
    required this.alertTitle,
    required this.scenario,
    required this.options,
    this.dialogue,
  });

  final String alertTitle;
  final String scenario;
  final List<CaseCyberOption> options;

  /// Ixtiyoriy ovozli hikoya. Bo‘lmasa, interfeys matndan avtomatik bubble quradi.
  final List<CaseDialogueLine>? dialogue;

  bool get hasInteractive => options.length >= 2;

  static CaseCyberTask fromStructuredJson(Map<String, dynamic> m) {
    final alert =
        '${m['alert'] ?? m['alert_title'] ?? '⚠ Tizim ogohlantirishi'}'.trim();
    final scenario =
        '${m['scenario'] ?? m['text'] ?? m['body'] ?? ''}'.trim();
    final rawDlg = m['dialogue'] ?? m['messages'] ?? m['story'];
    List<CaseDialogueLine>? dialogue;
    if (rawDlg is List) {
      final lines = <CaseDialogueLine>[];
      for (final e in rawDlg) {
        final line = CaseDialogueLine.tryParse(e);
        if (line != null) lines.add(line);
      }
      if (lines.isNotEmpty) dialogue = lines;
    }
    final rawOpts = m['options'] ?? m['choices'];
    final opts = <CaseCyberOption>[];
    if (rawOpts is List) {
      for (final e in rawOpts) {
        final o = CaseCyberOption.fromJson(e);
        if (o != null) opts.add(o);
      }
    }
    if (opts.isEmpty) {
      return fromLegacyScenario(
        scenario.isNotEmpty ? scenario : 'Vaziyat matni',
        dialogue: dialogue,
        alertTitle: alert.isNotEmpty ? alert : null,
      );
    }
    return CaseCyberTask(
      alertTitle: alert.isNotEmpty ? alert : '⚠ Tizim ogohlantirishi',
      scenario: scenario,
      options: opts,
      dialogue: dialogue,
    );
  }

  /// JSONda struktura bo‘lmaganda: har bir vaziyat uchun umumiy IT/xavfsizlik tahlil tanlovlari.
  static CaseCyberTask fromLegacyScenario(
    String scenario, {
    List<CaseDialogueLine>? dialogue,
    String? alertTitle,
  }) {
    final s = scenario.trim();
    final alert = (alertTitle ?? '⚠ Tizim ogohlantirishi').trim();
    return CaseCyberTask(
      alertTitle: alert.isEmpty ? '⚠ Tizim ogohlantirishi' : alert,
      scenario: s.isEmpty ? 'Muammoli vaziyat yuklanmadi.' : s,
      dialogue: dialogue,
      options: const [
        CaseCyberOption(
          label: 'Muammoni qadama-baqadam tahlil qilib, ishonchli manba va xavfsizlik qoidalariga amal qilaman',
          isCorrect: true,
          reaction:
              'Yaxshi: tahlillar xatolarni kamaytiradi va keyingi qarorlaringizni mustahkamlaydi.',
        ),
        CaseCyberOption(
          label: 'Shoshilinch qaror qilaman, qoidalarni keyin o‘ylayman',
          isCorrect: false,
          reaction:
              'Oqibat: xato choralar zararni kattalashtirishi va ma’lumotlaringizni yo‘qotish xavfini oshirishi mumkin.',
        ),
        CaseCyberOption(
          label: 'Birinchi uchragan havola yoki manbaga ishonaman',
          isCorrect: false,
          reaction:
              'Oqibat: firibgarlar yoki zararli kontent orqali hisobingiz va fayllaringiz xavf ostida qolishi mumkin.',
        ),
        CaseCyberOption(
          label: 'Muammoni yashirib, hech kimga aytmayman',
          isCorrect: false,
          reaction:
              'Oqibat: yashirilgan hodisalar yoyiladi; tiklash qiyinlashadi va javobgarlik kuchayadi.',
        ),
      ],
    );
  }

  /// Chat / typewriter uchun tartiblangan qatorlar.
  List<CaseDialogueLine> resolvedDialogue() {
    if (dialogue != null && dialogue!.isNotEmpty) {
      return List<CaseDialogueLine>.from(dialogue!);
    }
    final lines = <CaseDialogueLine>[
      CaseDialogueLine(role: 'admin', text: alertTitle),
    ];
    final body = scenario.trim();
    if (body.isNotEmpty) {
      final chunks = _splitStoryChunks(body, maxChunks: 4);
      final roles = ['system', 'client', 'user', 'client'];
      for (var i = 0; i < chunks.length; i++) {
        lines.add(CaseDialogueLine(role: roles[i % roles.length], text: chunks[i]));
      }
    }
    return lines;
  }

  static List<String> _splitStoryChunks(String body, {required int maxChunks}) {
    var parts = body
        .split(RegExp(r'(?<=[.!?…])\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty && body.trim().isNotEmpty) {
      parts = [body.trim()];
    }
    if (parts.length <= maxChunks) return parts;
    final out = <String>[];
    final per = (parts.length / maxChunks).ceil();
    for (var i = 0; i < maxChunks; i++) {
      final start = i * per;
      if (start >= parts.length) break;
      final end = start + per > parts.length ? parts.length : start + per;
      out.add(parts.sublist(start, end).join(' '));
    }
    return out;
  }
}
