import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rss_provider.dart';

class AddRssFeedDialog extends StatefulWidget {
  const AddRssFeedDialog({super.key});

  @override
  State<AddRssFeedDialog> createState() => _AddRssFeedDialogState();
}

class _AddRssFeedDialogState extends State<AddRssFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _initialEntriesController = TextEditingController(text: '1');
  final _updateEntriesController = TextEditingController(text: '1');
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _initialEntriesController.dispose();
    _updateEntriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加RSS订阅'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'RSS源URL *',
                  hintText: '请输入RSS源的URL',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入URL';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasAbsolutePath) {
                    return '请输入有效的URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _initialEntriesController,
                      decoration: const InputDecoration(
                        labelText: '首次抓取文章数',
                        hintText: '首次抓取的文章数量',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入数字';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return '请输入有效数字';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _updateEntriesController,
                      decoration: const InputDecoration(
                        labelText: '每次更新文章数',
                        hintText: '每次更新的最大文章数量',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入数字';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return '请输入有效数字';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> feedData = {
        'url': _urlController.text,
        'initial_entries_count': int.parse(_initialEntriesController.text),
        'update_entries_count': int.parse(_updateEntriesController.text),
      };

      await context.read<RssProvider>().addFeed(feedData);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
