import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../auth/data/auth_username.dart';
import '../../assignments/data/teacher_assignment_item.dart';
import '../../../../core/utils/code_generator.dart';

/// Guruhlar (`groups`), kirish kodlari (`groupCodes`), o'quvchi inbox (`studentGroupTasks`).
class GroupsRepository {
  GroupsRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    return _override ?? FirebaseFirestore.instance;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchTeacherGroups(String teacherId) {
    if (!_ready || teacherId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('groups')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGroup(String groupId) {
    if (!_ready) {
      return const Stream.empty();
    }
    return _db.collection('groups').doc(groupId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudentGroupInbox(
    String studentId,
  ) {
    if (!_ready || studentId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('studentGroupTasks')
        .doc(studentId)
        .collection('items')
        .snapshots();
  }

  /// Login (usernames kolleksiyasi) bo'yicha UID.
  Future<String?> resolveUsernameToUid(String rawUsername) async {
    if (!_ready) return null;
    final doc = await _db
        .collection('usernames')
        .doc(normalizeUsername(rawUsername))
        .get();
    return doc.data()?['uid'] as String?;
  }

  Future<({String groupId, String joinCode})> createGroup({
    required String teacherId,
    required String name,
  }) async {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('Guruh nomi bo\'sh');
    }
    for (var attempt = 0; attempt < 12; attempt++) {
      final code = generateAssignmentCode(length: 6);
      final codeRef = _db.collection('groupCodes').doc(code);
      final existing = await codeRef.get();
      if (existing.exists) continue;

      final groupRef = _db.collection('groups').doc();
      final batch = _db.batch();
      batch.set(groupRef, {
        'teacherId': teacherId,
        'name': trimmed,
        'memberIds': <String>[],
        'joinCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(codeRef, {
        'groupId': groupRef.id,
        'teacherId': teacherId,
      });
      try {
        await batch.commit();
        return (groupId: groupRef.id, joinCode: code);
      } catch (_) {
        continue;
      }
    }
    throw StateError('Boshqa urinib ko\'ring: kod to\'qnashuvi');
  }

  Future<void> addMemberByUid({
    required String teacherId,
    required String groupId,
    required String studentUid,
  }) async {
    if (!_ready) return;
    final ref = _db.collection('groups').doc(groupId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('Guruh topilmadi');
    if (snap.data()?['teacherId'] != teacherId) {
      throw StateError('Ruxsat yo\'q');
    }
    await ref.update({
      'memberIds': FieldValue.arrayUnion([studentUid]),
    });
  }

  Future<void> removeMember({
    required String teacherId,
    required String groupId,
    required String studentUid,
  }) async {
    if (!_ready) return;
    final ref = _db.collection('groups').doc(groupId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('Guruh topilmadi');
    if (snap.data()?['teacherId'] != teacherId) {
      throw StateError('Ruxsat yo\'q');
    }
    await ref.update({
      'memberIds': FieldValue.arrayRemove([studentUid]),
    });
  }

  /// O'quvchi: kirish kodi orqali o'zini a'zo qiladi.
  Future<void> joinGroupWithCode({
    required String studentId,
    required String rawCode,
  }) async {
    if (!_ready) return;
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) throw StateError('Kod kiriting');
    final codeDoc = await _db.collection('groupCodes').doc(code).get();
    if (!codeDoc.exists) throw StateError('Guruh kodi topilmadi');
    final groupId = codeDoc.data()?['groupId'] as String?;
    if (groupId == null || groupId.isEmpty) {
      throw StateError('Noto\'g\'ri kod yozuvi');
    }
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([studentId]),
    });
  }

  /// Guruh a'zolariga topshiriqni inbox ga yozadi (bitta topshiriq — bir nechta o'quvchi).
  Future<void> assignTeacherItemToGroup({
    required String teacherId,
    required String groupId,
    required TeacherAssignmentItem item,
  }) async {
    if (!_ready) return;
    final g = await _db.collection('groups').doc(groupId).get();
    if (!g.exists) throw StateError('Guruh topilmadi');
    final d = g.data()!;
    if (d['teacherId'] != teacherId) throw StateError('Ruxsat yo\'q');
    final members = List<String>.from(d['memberIds'] ?? const []);
    if (members.isEmpty) {
      throw StateError('Avval guruhga o\'quvchi qo\'shing');
    }
    final groupName = '${d['name'] ?? 'Guruh'}';
    final itemId = '${groupId}_${item.assignmentId}';

    var batch = _db.batch();
    var n = 0;
    for (final sid in members) {
      final ref = _db
          .collection('studentGroupTasks')
          .doc(sid)
          .collection('items')
          .doc(itemId);
      batch.set(
        ref,
        {
          'groupId': groupId,
          'groupName': groupName,
          'subjectId': item.subjectId,
          'classId': item.classId,
          'topicId': item.topicId,
          'methodId': item.methodId,
          'assignmentId': item.assignmentId,
          'title': item.title,
          'code': item.code,
          'assignedAt': FieldValue.serverTimestamp(),
        },
      );
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) {
      await batch.commit();
    }
  }

  Future<void> deleteGroupInboxItemForMembers({
    required String teacherId,
    required String groupId,
    required List<String> memberIds,
    required String itemId,
  }) async {
    if (!_ready) return;
    final g = await _db.collection('groups').doc(groupId).get();
    if (!g.exists || g.data()?['teacherId'] != teacherId) {
      throw StateError('Ruxsat yo\'q');
    }
    var batch = _db.batch();
    var n = 0;
    for (final sid in memberIds) {
      final ref = _db
          .collection('studentGroupTasks')
          .doc(sid)
          .collection('items')
          .doc(itemId);
      batch.delete(ref);
      n++;
      if (n >= 400) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) {
      await batch.commit();
    }
  }

  /// O'quvchi: o'z inboxidagi (`studentGroupTasks/.../items/...`) yozuvni o'chirish.
  Future<void> deleteStudentInboxItem(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    if (!_ready) return;
    await ref.delete();
  }
}
