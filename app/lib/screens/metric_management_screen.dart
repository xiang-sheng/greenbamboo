import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/record_provider.dart';
import '../ui/widgets/record_input_dialog.dart';

/// 指标管理页面
/// 用户可以：
/// 1. 查看已创建的指标
/// 2. 创建新指标
/// 3. 删除指标
class MetricManagementScreen extends StatefulWidget {
  const MetricManagementScreen({super.key});

  @override
  State<MetricManagementScreen> createState() => _MetricManagementScreenState();
}

class _MetricManagementScreenState extends State<MetricManagementScreen> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  String _selectedType = '数值';

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _showCreateMetricDialog() async {
    _nameController.clear();
    _unitController.clear();
    _selectedType = '数值';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('创建新指标'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '指标名称',
                    hintText: '例如：体重、睡眠、心情',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: '单位（可选）',
                    hintText: '例如：kg, h, 分',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: '类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '数值', child: Text('数值')),
                    DropdownMenuItem(value: '文本', child: Text('文本')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _nameController.text.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context, {
                        'name': _nameController.text,
                        'unit': _unitController.text,
                        'type': _selectedType,
                      });
                    },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final recordProvider = context.read<RecordProvider>();
      final now = DateTime.now();
      final metricId = '${now.millisecondsSinceEpoch}_${DateTime.now().microsecond}';

      // 保存到本地数据库
      await recordProvider.createMetric(
        id: metricId,
        name: result['name']!,
        type: result['type']!,
        unit: result['unit'] ?? '',
      );

      // 重新加载指标
      await recordProvider.loadMetrics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已创建指标：${result['name']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指标管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateMetricDialog,
            tooltip: '创建新指标',
          ),
        ],
      ),
      body: Consumer<RecordProvider>(
        builder: (context, recordProvider, child) {
          final metrics = recordProvider.metrics;

          if (metrics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无指标',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 创建第一个指标',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              final isPreset = metric['is_preset'] == 1;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPreset ? Colors.green[100] : Colors.blue[100],
                    child: Icon(
                      isPreset ? Icons.eco : Icons.category,
                      color: isPreset ? Colors.green : Colors.blue,
                    ),
                  ),
                  title: Text(
                    metric['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${metric['type']}${metric['unit'] != null && metric['unit']!.isNotEmpty ? ' · ${metric['unit']}' : ''}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: isPreset
                      ? const Icon(Icons.lock_outline, color: Colors.grey)
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDeleteMetric(context, metric),
                        ),
                  onTap: () {
                    // 点击指标直接添加记录
                    _showRecordDialog(context, metric);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRecordDialog(BuildContext context, Map<String, dynamic> metric) {
    final recordProvider = context.read<RecordProvider>();

    // 显示日期选择器
    showDialog(
      context: context,
      builder: (context) {
        DateTime selectedDate = DateTime.now();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择日期'),
              content: SizedBox(
                width: 300,
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRecordInputDialog(
                      context,
                      metric,
                      selectedDate,
                    );
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRecordInputDialog(
    BuildContext context,
    Map<String, dynamic> metric,
    DateTime recordedDate,
  ) {
    final recordProvider = context.read<RecordProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return RecordInputDialog(
          metricId: metric['id'],
          metricName: metric['name'],
          metricUnit: metric['unit'] ?? '',
          recordedAt: recordedDate,
          onSave: (value, note, recordedAt) async {
            final success = await recordProvider.createRecord(
              metricId: metric['id'],
              value: value,
              note: note,
              recordedAt: recordedAt,
            );

            if (context.mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已记录 ${metric['name']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('记录失败'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  void _confirmDeleteMetric(BuildContext context, Map<String, dynamic> metric) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除指标 "${metric['name']}' 吗？这将同时删除所有相关记录。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final recordProvider = context.read<RecordProvider>();
                await recordProvider.deleteMetric(metric['id']);
                await recordProvider.loadMetrics();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已删除指标：${metric['name']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
