import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/audio_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: context.read<SettingsProvider>().baseUrl,
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultUrl = context.read<SettingsProvider>().defaultBaseUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '服务器设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _baseUrlController,
                    decoration: InputDecoration(
                      labelText: '服务器地址',
                      hintText: defaultUrl,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: Wrap(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            tooltip: '测试连接',
                            onPressed: () async {
                              final url = _baseUrlController.text.trim();
                              if (url.isEmpty) return;
                              
                              try {
                                final (success, message) = await context
                                    .read<SettingsProvider>()
                                    .testConnection(url);
                                
                                if (!context.mounted) return;
                                
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('连接成功'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('连接失败：$message'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('连接失败：${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            tooltip: '保存设置',
                            onPressed: () async {
                              final url = _baseUrlController.text.trim();
                              if (url.isEmpty) return;
                              
                              try {
                                await context.read<SettingsProvider>().setBaseUrl(url);
                                await context.read<AudioProvider>().refreshPodcastList();
                                
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('保存成功'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('保存失败：${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '当前: ${context.watch<SettingsProvider>().baseUrl}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.restore),
                        label: const Text('重置'),
                        onPressed: () async {
                          await context.read<SettingsProvider>().resetToDefault();
                          if (!context.mounted) return;
                          
                          _baseUrlController.text = context.read<SettingsProvider>().defaultBaseUrl;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已重置为默认服务器地址'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 