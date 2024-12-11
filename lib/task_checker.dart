class TaskChecker {
  static final TaskChecker _singleton = TaskChecker._internal();

  factory TaskChecker() {
    return _singleton;
  }

  TaskChecker._internal();

  bool needCancel = false;
}
