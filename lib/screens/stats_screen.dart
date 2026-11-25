import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/reports_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  String _avg(double? h) {
    if (h == null) return '—';
    if (h < 1) return '${(h * 60).round()} دقيقة';
    if (h < 48) return '${h.toStringAsFixed(1)} ساعة';
    return '${(h / 24).toStringAsFixed(1)} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportsProvider>();
    final byCat = rp.byCategory;
    final open = rp.reports.where((r) => r.status != ReportStatus.resolved).toList();

    String? topCat;
    if (byCat.isNotEmpty) {
      final top = byCat.entries.reduce((a, b) => a.value >= b.value ? a : b);
      topCat = Categories.byId(top.key).label;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات المدينة')),
      body: rp.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Wrap(spacing: 10, runSpacing: 10, children: [
                _StatCard('إجمالي البلاغات', '${rp.total}', Icons.report, Colors.blue),
                _StatCard('تم حلها', '${rp.countStatus(ReportStatus.resolved)}',
                    Icons.check_circle, Colors.green),
                _StatCard('نسبة الحل', '${rp.resolutionRate.toStringAsFixed(0)}%',
                    Icons.percent, Colors.teal),
                _StatCard('متوسط وقت الحل', _avg(rp.avgResolutionHours),
                    Icons.timer, Colors.deepPurple),
              ]),
              if (topCat != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.insights),
                    title: Text('أكثر مشكلة انتشارًا: $topCat'),
                    subtitle: const Text('البيانات دي بتساعد في توجيه الميزانية للأماكن الأكثر احتياجًا'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('البلاغات حسب النوع',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (byCat.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('لا توجد بيانات بعد')))
              else
                Row(children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: PieChart(PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        for (final c in Categories.all)
                          if ((byCat[c.id] ?? 0) > 0)
                            PieChartSectionData(
                              value: byCat[c.id]!.toDouble(),
                              color: c.color,
                              title: '${byCat[c.id]}',
                              radius: 48,
                              titleStyle: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                      ],
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final c in Categories.all)
                          if ((byCat[c.id] ?? 0) > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(children: [
                                Icon(Icons.circle, size: 12, color: c.color),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(c.label,
                                        style: const TextStyle(fontSize: 13))),
                              ]),
                            ),
                      ],
                    ),
                  ),
                ]),
              const SizedBox(height: 20),
              Text('البلاغات حسب الحالة',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(ReportStatus.values[v.toInt()].label,
                              style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (final s in ReportStatus.values)
                      BarChartGroupData(x: s.index, barRods: [
                        BarChartRodData(
                          toY: rp.countStatus(s).toDouble(),
                          color: s.color,
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ]),
                  ],
                )),
              ),
              const SizedBox(height: 20),
              Text('الخريطة الحرارية للمشاكل غير المحلولة',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('كل ما اللون يغمق، المنطقة فيها مشاكل أكتر',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          open.isNotEmpty ? open.first.position : AppConfig.defaultCenter,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConfig.osmTiles,
                        userAgentPackageName: AppConfig.packageName,
                      ),
                      CircleLayer(circles: [
                        for (final r in open)
                          CircleMarker(
                            point: r.position,
                            radius: 140,
                            useRadiusInMeter: true,
                            color: Colors.red.withValues(alpha: .22),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 42) / 2;
    return SizedBox(
      width: w,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ]),
        ),
      ),
    );
  }
}
