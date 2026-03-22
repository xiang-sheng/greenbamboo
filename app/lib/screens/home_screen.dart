import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/record_provider.dart';
import '../ui/widgets/record_input_dialog.dart';
import 'metric_management_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const MetricManagementScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: '指标',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化时加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordProvider = context.read<RecordProvider>();
      if (recordProvider.metrics.isEmpty) {
        recordProvider.loadMetrics();
      }
      if (recordProvider.records.isEmpty) {
        recordProvider.loadRecords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎋 青竹'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecordDialog(context),
            tooltip: '添加记录',
          ),
        ],
      ),
      body: Consumer<RecordProvider>(
        builder: (context, recordProvider, child) {
          final metrics = recordProvider.metrics;

          return RefreshIndicator(
            onRefresh: () async {
              await recordProvider.loadMetrics();
              await recordProvider.loadRecords();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 欢迎语
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),

                  // 指标列表
                  if (metrics.isEmpty)
                    _buildEmptyMetricsPrompt(context)
                  else ...[
                    const Text(
                      '我的指标',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricsGrid(context, metrics),
                    const SizedBox(height: 24),

                    // 今日概览
                    const Text(
                      '今日概览',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTodaySummary(context),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green[100],
              child: const Icon(Icons.eco, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '健康如竹，节节高',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '坚持记录，遇见更好的自己',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMetricsPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
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
            '点击下方"指标"标签创建第一个指标',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, List<dynamic> metrics) {
    return Consumer<RecordProvider>(
      builder: (context, recordProvider, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            final isPreset = metric['is_preset'] == 1;
            
            // 查找该指标的最新记录
            final metricRecords = recordProvider.records
                .where((r) => r['metric_id'] == metric['id'])
                .toList();
            final latestRecord = metricRecords.isNotEmpty ? metricRecords.first : null;
            final latestValue = latestRecord?['value'];

            IconData icon;
            Color color;

            switch (metric['name']) {
              case '体重':
                icon = Icons.monitor_weight;
                color = Colors.blue;
                break;
              case '睡眠':
                icon = Icons.bedtime;
                color = Colors.purple;
                break;
              case '运动':
                icon = Icons.fitness_center;
                color = Colors.orange;
                break;
              case '心情':
                icon = Icons.sentiment_satisfied;
                color = Colors.green;
                break;
              default:
                icon = isPreset ? Icons.eco : Icons.category;
                color = isPreset ? Colors.green : Colors.blue;
            }

            return InkWell(
              onTap: () => _showRecordDialog(context, metric),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: color),
                    const SizedBox(height: 8),
                    Text(
                      metric['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (latestValue != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            latestValue.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (metric['unit'] != null && metric['unit']!.isNotEmpty)
                            Text(
                              metric['unit'],
                              style: TextStyle(
                                fontSize: 12,
                                color: color.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ] else if (metric['unit'] != null && metric['unit']!.isNotEmpty)
                      Text(
                        metric['unit'],
                        style: TextStyle(
                          fontSize: 11,
                          color: color.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTodaySummary(BuildContext context) {
    return Consumer<RecordProvider>(
      builder: (context, recordProvider, child) {
        final todayRecords = recordProvider.records.where((r) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(
            r['recorded_at'] is int ? r['recorded_at'] : DateTime.parse(r['recorded_at']).millisecondsSinceEpoch,
          );
          final today = DateTime.now();
          return recordDate.year == today.year &&
              recordDate.month == today.month &&
              recordDate.day == today.day;
        }).toList();

        if (todayRecords.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '今日暂无记录',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: todayRecords.map((record) {
                final metricName = record['metric_name'] ?? '未知';
                final value = record['value'];
                // 从指标中获取单位
                final metric = recordProvider.metrics.cast<Map<String, dynamic>>().firstWhere(
                  (m) => m['id'] == record['metric_id'],
                  orElse: () => {'unit': ''},
                );
                final unit = metric['unit'] ?? '';

                return _buildSummaryItem(metricName, value?.toString() ?? '', unit);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: [
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    final recordProvider = context.read<RecordProvider>();
    final metrics = recordProvider.metrics;

    if (metrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建指标')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String? selectedMetricId;
        String selectedMetricName = '';
        String selectedMetricUnit = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择指标'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: metrics.length,
                  itemBuilder: (context, index) {
                    final metric = metrics[index];
                    return ListTile(
                      leading: Icon(
                        metric['is_preset'] == 1 ? Icons.eco : Icons.category,
                        color: Colors.green,
                      ),
                      title: Text(metric['name']),
                      subtitle: Text(metric['unit'] ?? ''),
                      onTap: () {
                        setState(() {
                          selectedMetricId = metric['id'];
                          selectedMetricName = metric['name'];
                          selectedMetricUnit = metric['unit'] ?? '';
                        });
                      },
                      selected: selectedMetricId == metric['id'],
                      selectedTileColor: Colors.green[100],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: selectedMetricId == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showRecordInputDialog(
                            context,
                            selectedMetricId!,
                            selectedMetricName,
                            selectedMetricUnit,
                          );
                        },
                  child: const Text('下一步'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRecordDialog(BuildContext context, Map<String, dynamic> metric) {
    final recordProvider = context.read<RecordProvider>();
    
    // 直接显示记录输入对话框（已包含日期选择）
    showDialog(
      context: context,
      builder: (context) {
        return RecordInputDialog(
          metricId: metric['id'],
          metricName: metric['name'],
          metricUnit: metric['unit'] ?? '',
          recordedAt: DateTime.now(),
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

  void _showRecordInputDialog(
    BuildContext context,
    String metricId,
    String metricName,
    String metricUnit, {
    DateTime? recordedAt,
  }) {
    final recordProvider = context.read<RecordProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return RecordInputDialog(
          metricId: metricId,
          metricName: metricName,
          metricUnit: metricUnit,
          recordedAt: recordedAt ?? DateTime.now(),
          onSave: (value, note, recordedAt) async {
            final success = await recordProvider.createRecord(
              metricId: metricId,
              value: value,
              note: note,
              recordedAt: recordedAt,
            );

            if (context.mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已记录 $metricName'),
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
}
