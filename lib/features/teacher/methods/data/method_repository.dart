import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/firestore/firestore_subtree_delete.dart';
import 'method_model.dart';

/// Firestore: `subjects/{subjectId}/classes/{classId}/topics/{topicId}/methods/{methodId}`
class MethodRepository {
  MethodRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    return _override ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> methodsCollection({
    required String subjectId,
    required String classId,
    required String topicId,
  }) {
    return _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics')
        .doc(topicId)
        .collection('methods');
  }

  List<MethodModel> _mergeWithPresets({
    required List<MethodModel> fromDb,
    required String subjectId,
    required String classId,
    required String topicId,
  }) {
    final presets = CurriculumPresets.presetMethodsFor(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    );
    final byId = {for (final m in fromDb) m.id: m};
    final merged = <MethodModel>[];
    for (final p in presets) {
      merged.add(byId[p.id] ?? p);
    }
    for (final m in fromDb) {
      if (!presets.any((p) => p.id == m.id)) {
        if (CurriculumPresets.isPresetMethodId(m.id)) {
          continue;
        }
        merged.add(m);
      }
    }
    return merged;
  }

  Future<List<MethodModel>> fetchMethods({
    required String subjectId,
    required String classId,
    required String topicId,
  }) async {
    if (!_ready) {
      return CurriculumPresets.presetMethodsFor(
        subjectId: subjectId,
        classId: classId,
        topicId: topicId,
      );
    }
    final snap = await methodsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    ).get();
    final fromDb = snap.docs.map(_docToModel).toList();
    return _mergeWithPresets(
      fromDb: fromDb,
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    );
  }

  Stream<List<MethodModel>> watchMethods({
    required String subjectId,
    required String classId,
    required String topicId,
  }) {
    if (!_ready) {
      return Stream.value(
        CurriculumPresets.presetMethodsFor(
          subjectId: subjectId,
          classId: classId,
          topicId: topicId,
        ),
      );
    }
    return methodsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    ).snapshots().map(
          (snap) => _mergeWithPresets(
            fromDb: snap.docs.map(_docToModel).toList(),
            subjectId: subjectId,
            classId: classId,
            topicId: topicId,
          ),
        );
  }

  MethodModel _docToModel(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    return MethodModel.fromJson({
      ...d.data(),
      'id': d.id,
    });
  }

  Future<String> createMethod({
    required String subjectId,
    required String classId,
    required String topicId,
    required String type,
    Map<String, dynamic>? config,
  }) async {
    final ref = methodsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    ).doc();
    await ref.set({
      'type': type,
      'config': config ?? <String, dynamic>{},
    });
    return ref.id;
  }

  /// Maxsus fan uchun: mavzuda 5 ta `preset_*` metodini Firestore ga yozadi.
  Future<void> seedPresetMethodsForCustomTopic({
    required String subjectId,
    required String classId,
    required String topicId,
    required String topicDisplayName,
  }) async {
    if (!_ready) {
      return;
    }
    if (CurriculumCatalog.isCurriculumSubject(subjectId)) {
      return;
    }
    final presets = CurriculumPresets.presetMethodsFor(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      overrideTopicLabel: topicDisplayName,
    );
    final batch = _firestore.batch();
    for (final p in presets) {
      final ref = methodsCollection(
        subjectId: subjectId,
        classId: classId,
        topicId: topicId,
      ).doc(p.id);
      batch.set(ref, {
        'type': p.type,
        'config': p.config ?? <String, dynamic>{},
      });
    }
    await batch.commit();
  }

  Future<MethodModel?> fetchMethod({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
  }) async {
    if (!_ready) {
      return CurriculumPresets.presetMethodById(
        subjectId: subjectId,
        classId: classId,
        topicId: topicId,
        methodId: methodId,
      );
    }
    final doc = await methodsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    ).doc(methodId).get();
    if (doc.exists && doc.data() != null) {
      return MethodModel.fromJson({
        ...doc.data()!,
        'id': doc.id,
      });
    }
    return CurriculumPresets.presetMethodById(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
    );
  }

  Future<void> updateMethodConfig({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required Map<String, dynamic> config,
  }) async {
    if (!_ready) return;
    final ref = methodsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    ).doc(methodId);
    final snap = await ref.get();
    if (!snap.exists) {
      final preset = CurriculumPresets.presetMethodById(
        subjectId: subjectId,
        classId: classId,
        topicId: topicId,
        methodId: methodId,
      );
      if (preset == null) {
        throw StateError('Metod topilmadi: $methodId');
      }
      await ref.set({
        'type': preset.type,
        'config': config,
      });
    } else {
      await ref.update({'config': config});
    }
  }

  /// Faqat Firestore dagi qo'shimcha metodlar (tayyor shablonlar yo'q).
  Future<void> deleteMethod({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
  }) async {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    if (CurriculumPresets.isPresetMethodId(methodId)) {
      throw StateError('Tayyor metodni o\'chirib bo\'lmaydi');
    }
    await FirestoreSubtreeDelete.deleteMethodDocument(
      _firestore,
      subjectId,
      classId,
      topicId,
      methodId,
    );
  }
}
