import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';
import 'add_report_screen.dart';
import 'map_screen.dart';
import 'report_detail_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<AppProvider>().loadReports());
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'البلاغات' : 'الخريطة'),
        actions: [
          Center(
              child: Text(app.userName ?? '',
                  style: const TextStyle(fontSize: 13))),
          IconButton(
            tooltip: 'خروج',
            icon: const Icon(Icons.logout),
            onPressed: app.logout,
          ),
        ],
      ),
      body: _tab == 0 ? const _ReportsList() : const MapScreen(),
      floatingActionButton: app.isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddReportScreen())),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('بلاغ جديد'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'البلاغات'),
          NavigationDestination(icon: Icon(Icons.map), label: 'الخريطة'),
        ],
      ),
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final list = app.visible;
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              for (final f in ['all', ...statuses])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f == 'all' ? 'الكل' : statusLabels[f]!),
                    selected: app.filter == f,
                    onSelected: (_) => app.setFilter(f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: app.loading
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? const Center(child: Text('مفيش بلاغات'))
                  : RefreshIndicator(
                      onRefresh: app.loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _ReportTile(report: list[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Report report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final img = report.imagePath;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ReportDetailScreen(reportId: report.id!))),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: (img != null && File(img).existsSync())
                ? Image.file(File(img), fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.report_problem)),
          ),
        ),
        title: Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
              '${report.category} • ${DateFormat('y/MM/dd HH:mm').format(report.createdAt)}'),
        ),
        trailing: StatusChip(
            status: report.status, label: statusLabels[report.status]!),
      ),
    );
  }
}
