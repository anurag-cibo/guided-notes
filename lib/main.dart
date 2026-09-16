import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'features/goals/application/goals_controller.dart';
import 'features/goals/data/goals_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = GoalsController(GoalsRepository(AppDatabase.local()));
  runApp(GuideApp(controller: controller));
  controller.load();
}
