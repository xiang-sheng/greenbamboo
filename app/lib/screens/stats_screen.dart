import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/providers/record_provider.dart';

/// 统计图表页面
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedMetricId = '';
  String _selectedMetricName = '体重';
  String _selectedMetricUnit = 'kg';
  int _timeRangeDays = 7;

  @override
  void initState() {
    super.initState();
    // 确保数据已加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordProvider = context.read<RecordProvider>();
      if (recordProvider.records.isEmpty || recordProvider.metrics.isEmpty) {
        recordProvider.loadMetrics();
        recordProvider.loadRecords();
      }
    });
  }

  void _initializeMetric(RecordProvider recordProvider) {
    // 只在首次初始化时设置，避免重复设置
    if (_selectedMetricId.isEmpty && recordProvider.metrics.isNotEmpty) {
      final weightMetric = recordProvider.metrics.firstWhere(
        (m) => m['name'] == '体重',
        orElse: () => recordProvider.metrics.first,
      );
      // 直接设置，不使用 setState（因为 Consumer 会自动重建）
      _selectedMetricId = weightMetric['id'];
      _selectedMetricName = weightMetric['name'];
      _selectedMetricUnit = weightMetric['unit'] ?? '';
      debugPrint('StatsScreen: Initialized metric - id=$_selectedMetricId, name=$_selectedMetricName');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 统计图表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('StatsScreen: Manual refresh triggered');
              final recordProvider = context.read<RecordProvider>();
              recordProvider.loadMetrics();
              recordProvider.loadRecords();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在刷新数据...'), duration: Duration(seconds: 1)),
              );
            },
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: Consumer<RecordProvider>(
        builder: (context, recordProvider, child) {
          debugPrint('=== StatsScreen build ===');
          debugPrint('isLoading: ${recordProvider.isLoading}');
          debugPrint('metrics count: ${recordProvider.metrics.length}');
          debugPrint('records count: ${recordProvider.records.length}');

          // 确保数据已加载
          if (recordProvider.isLoading) {
            debugPrint('StatsScreen: Still loading...');
            return const Center(child: CircularProgressIndicator());
          }

          debugPrint('StatsScreen: metrics count = ${recordProvider.metrics.length}, records count = ${recordProvider.records.length}');

          // 如果没有指标，提示用户创建
          if (recordProvider.metrics.isEmpty) {
            debugPrint('StatsScreen: No metrics found');
            return _buildNoMetricsState();
          }

          // 初始化选中的指标
          _initializeMetric(recordProvider);

          if (_selectedMetricId.isEmpty) {
            debugPrint('StatsScreen: Selected metric ID is empty after init');
            return const Center(child: CircularProgressIndicator());
          }

          debugPrint('StatsScreen: Selected metric ID = $_selectedMetricId, name = $_selectedMetricName');

          // 过滤记录
          final filteredRecords = _getFilteredRecords(recordProvider.records);
          debugPrint('StatsScreen: Filtered records count = ${filteredRecords.length}');

          // 输出所有记录信息
          debugPrint('=== 所有记录 ===');
          for (var r in recordProvider.records) {
            debugPrint('Record: metric_id=${r['metric_id']}, value=${r['value']}, recorded_at=${r['recorded_at']}');
          }

          debugPrint('=== 构建内容 ===');
          return _buildContent(recordProvider);
        },
      ),
    );
  }

  Widget _buildNoMetricsState() {
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
            '请先在"指标"页面创建指标',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '先添加一些健康记录吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RecordProvider recordProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 指标选择
          _buildMetricSelector(recordProvider),
          const SizedBox(height: 16),

          // 时间范围选择
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),

          // 趋势图表
          _buildTrendChart(recordProvider),
          const SizedBox(height: 16),

          // 汇总统计
          _buildSummaryStats(recordProvider),
          const SizedBox(height: 16),

          // 最近记录
          _buildRecentRecords(recordProvider),
        ],
      ),
    );
  }

  Widget _buildMetricSelector(RecordProvider recordProvider) {
    final metrics = recordProvider.metrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '选择指标',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics.map((metric) {
                final isSelected = metric['id'] == _selectedMetricId;
                return FilterChip(
                  label: Text(metric['name']),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMetricId = metric['id'];
                      _selectedMetricName = metric['name'];
                      _selectedMetricUnit = metric['unit'] ?? '';
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              '时间范围：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            ...[7, 30, 90].map((days) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text('$days 天'),
                selected: _timeRangeDays == days,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _timeRangeDays = days;
                    });
                  }
                },
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(RecordProvider recordProvider) {
    final records = _getFilteredRecords(recordProvider.records);

    if (records.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  '所选时间段内无数据',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final spots = _buildLineSpots(records);
    final minY = _getMinY(records);
    final maxY = _getMaxY(records);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '$_selectedMetricName 趋势图',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxY - minY) / 4,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 4,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: spots.length > 6 ? (spots.length / 6).toDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= spots.length) return const SizedBox();
                          final record = records[value.toInt()];
                          final recordedAt = record['recorded_at'];
                          final recordedAtMs = recordedAt is int
                              ? (recordedAt > 10000000000 ? recordedAt : recordedAt * 1000)
                              : DateTime.parse(recordedAt.toString()).millisecondsSinceEpoch;
                          final date = DateTime.fromMillisecondsSinceEpoch(recordedAtMs);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  minX: 0,
                  maxX: spots.length - 1.0,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.green,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 趋势指示
            _buildTrendIndicator(records),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildLineSpots(List<dynamic> records) {
    List<FlSpot> spots = [];
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final value = (record['value'] ?? 0.0).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  double _getMinY(List<dynamic> records) {
    if (records.isEmpty) return 0;
    double min = records.map((r) => r['value'] ?? 0.0).reduce((a, b) => a < b ? a : b).toDouble();
    return (min - 1).floorToDouble();
  }

  double _getMaxY(List<dynamic> records) {
    if (records.isEmpty) return 100;
    double max = records.map((r) => r['value'] ?? 0.0).reduce((a, b) => a > b ? a : b).toDouble();
    return (max + 1).ceilToDouble();
  }

  Widget _buildTrendIndicator(List<dynamic> records) {
    if (records.length < 2) {
      return const SizedBox();
    }

    final firstValue = records.first['value'] ?? 0.0;
    final lastValue = records.last['value'] ?? 0.0;
    final change = lastValue - firstValue;
    final changePercent = (change / firstValue * 100).abs();

    final isUp = change >= 0;
    final trendColor = isUp ? Colors.red : Colors.green;
    final trendIcon = isUp ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(trendIcon, color: trendColor, size: 20),
          Text(
            isUp ? '上升趋势' : '下降趋势',
            style: TextStyle(
              color: trendColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} $_selectedMetricUnit',
            style: TextStyle(
              color: trendColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${changePercent.toStringAsFixed(1)}%',
            style: TextStyle(
              color: trendColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(RecordProvider recordProvider) {
    final records = _getFilteredRecords(recordProvider.records);

    if (records.isEmpty) {
      return const SizedBox();
    }

    final values = records.map((r) => r['value'] ?? 0.0).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '汇总统计',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('平均值', avg.toStringAsFixed(1), _selectedMetricUnit, Colors.blue),
                _buildStatItem('最低值', min.toStringAsFixed(1), _selectedMetricUnit, Colors.green),
                _buildStatItem('最高值', max.toStringAsFixed(1), _selectedMetricUnit, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('记录数', '${values.length}', '次', Colors.purple),
                _buildStatItem('时间段', '$_timeRangeDays', '天', Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            children: [
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRecords(RecordProvider recordProvider) {
    final records = _getFilteredRecords(recordProvider.records).take(5).toList();

    if (records.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '最近记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...records.map((record) {
              final recordedAt = record['recorded_at'];
              final recordedAtMs = recordedAt is int
                  ? (recordedAt > 10000000000 ? recordedAt : recordedAt * 1000)
                  : DateTime.parse(recordedAt.toString()).millisecondsSinceEpoch;
              final date = DateTime.fromMillisecondsSinceEpoch(recordedAtMs);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(date),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Text(
                      '${(record['value'] ?? 0.0).toStringAsFixed(1)} $_selectedMetricUnit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<dynamic> _getFilteredRecords(List<dynamic> allRecords) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: _timeRangeDays));

    return allRecords
        .where((record) {
          // 处理时间戳（可能是秒或毫秒）
          final recordedAt = record['recorded_at'];
          final recordedAtMs = recordedAt is int
              ? (recordedAt > 10000000000 ? recordedAt : recordedAt * 1000)
              : DateTime.parse(recordedAt.toString()).millisecondsSinceEpoch;
          final recordDate = DateTime.fromMillisecondsSinceEpoch(recordedAtMs);
          return recordDate.isAfter(cutoff);
        })
        .where((record) => record['metric_id'] == _selectedMetricId)
        .toList()
      ..sort((a, b) => b['recorded_at'].compareTo(a['recorded_at']));
  }

  void _refreshData() {
    final recordProvider = context.read<RecordProvider>();
    recordProvider.loadRecords();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('数据已刷新'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
