/// `go_router` `extra` orqali metod ekranlariga uzatiladi.
class MethodRouteArgs {
  const MethodRouteArgs({
    required this.subjectId,
    required this.classId,
    required this.topicId,
    this.methodId,
  });

  final String subjectId;
  final String classId;
  final String topicId;
  final String? methodId;
}
