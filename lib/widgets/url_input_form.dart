import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/create_task_dialog.dart';

class UrlInputForm extends StatefulWidget {
  const UrlInputForm({super.key});

  @override
  State<UrlInputForm> createState() => _UrlInputFormState();
}

class _UrlInputFormState extends State<UrlInputForm> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateTaskDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('创建新任务'),
      ),
    );
  }
}
