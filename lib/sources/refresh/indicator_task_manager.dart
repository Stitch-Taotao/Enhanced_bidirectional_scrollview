import 'package:flutter/material.dart';

import '../task/tasks.dart';

class MTProcessingManager {
  /// 任务
  Task Function() generateTask;

  // TaskStatus get loadingTask => taskStatus;
  VoidCallback? loadedCallback;
  VoidCallback? endCallback;

  MTProcessingManager({
    required this.generateTask,
    this.loadedCallback,
    this.endCallback,
  });
}
