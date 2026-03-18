import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/record_provider.dart';
import '../ui/widgets/record_input_dialog.dart';
import 'record_list_screen.dart';
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
    const RecordListScreen(),
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
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: '记录',
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎋 青竹'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddRecordDialog(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: 刷新数据
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

              // 快速指标
              const Text(
                '快速记录',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickMetrics(context),
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
              _buildTodaySummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Text(
                        '健康如竹，节节高',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetrics(BuildContext context) {
    final metrics = [
      {'name': '体重', 'icon': Icons.monitor_weight, 'color': Colors.blue},
      {'name': '睡眠', 'icon': Icons.bedtime, 'color': Colors.purple},
      {'name': '运动', 'icon': Icons.fitness_center, 'color': Colors.orange},
      {'name': '心情', 'icon': Icons.sentiment_satisfied, 'color': Colors.green},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return InkWell(
          onTap: () {
            _showQuickRecordDialog(context, metric['name'] as String);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: (metric['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  metric['icon'] as IconData,
                  size: 32,
                  color: metric['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  metric['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: metric['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('体重', '65.5', 'kg'),
            _buildSummaryItem('睡眠', '7.5', 'h'),
            _buildSummaryItem('步数', '8,520', '步'),
            _buildSummaryItem('心情', '4', '/5'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: [
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 14,
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
        const SnackBar(content: Text('请先加载指标')),
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
                      leading: const Icon(Icons.eco, color: Colors.green),
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
                          _showRecordInput(
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

  void _showQuickRecordDialog(BuildContext context, String metricName) {
    final recordProvider = context.read<RecordProvider>();
    final metrics = recordProvider.metrics;

    final metric = metrics.firstWhere(
      (m) => m['name'] == metricName,
      orElse: () => null,
    );

    if (metric == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('指标不存在')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => QuickRecordDialog(
        metricName: metricName,
        metricUnit: metric['unit'] ?? '',
        onSave: (value) async {
          final success = await recordProvider.createRecord(
            metricId: metric['id'],
            value: value,
            recordedAt: DateTime.now(),
          );

          if (context.mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('记录成功'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('记录失败'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showRecordInput(
    BuildContext context,
    String metricId,
    String metricName,
    String metricUnit,
  ) {
    final recordProvider = context.read<RecordProvider>();

    showDialog(
      context: context,
      builder: (context) => RecordInputDialog(
        metricId: metricId,
        metricName: metricName,
        metricUnit: metricUnit,
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
                const SnackBar(
                  content: Text('记录成功'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('记录失败'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
