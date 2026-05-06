// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/part.dart';
import '../services/database_service.dart';
import '../services/csv_service.dart';
import '../theme.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final CsvService _csv = CsvService();
  final DateFormat _fmt = DateFormat('dd/MM/yy HH:mm');

  Map<String, int> _stats = {'total': 0, 'post1Done': 0, 'post2Done': 0, 'notProcessed': 0};
  List<Part> _parts = [];
  bool _loading = true;
  bool _importing = false;
  String _searchQuery = '';
  PartStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final stats = await _db.getStats();
    final parts = await _db.getAllParts();
    if (mounted) {
      setState(() {
        _stats = stats;
        _parts = parts;
        _loading = false;
      });
    }
  }

  Future<void> _importCsv() async {
    setState(() => _importing = true);
    final result = await _csv.importPartsFromCsv();
    setState(() => _importing = false);

    if (!mounted) return;

    if (!result.success) {
      if (result.error == 'No file selected') return;
      _showSnack(result.error!, Colors.red);
      return;
    }

    _showSnack(
      '✓ Imported ${result.imported} parts  •  ${result.skipped} already existed',
      AppTheme.post2Done,
    );
    await _loadData();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  List<Part> get _filteredParts {
    var list = _parts;
    if (_filterStatus != null) {
      list = list.where((p) => p.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) => p.partId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            tooltip: 'Import CSV',
            onPressed: _importing ? null : _importCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildStatsGrid(),
                        _buildProgressBar(),
                        _buildSearchAndFilter(),
                      ],
                    ),
                  ),
                  _filteredParts.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildPartTile(_filteredParts[i]),
                            childCount: _filteredParts.length,
                          ),
                        ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Parts',
                  value: _stats['total']!,
                  color: AppTheme.primary,
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Not Processed',
                  value: _stats['notProcessed']!,
                  color: AppTheme.notProcessed,
                  icon: Icons.hourglass_empty_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Control 1 Done',
                  value: _stats['post1Done']!,
                  color: AppTheme.post1Done,
                  icon: Icons.looks_one_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Fully Done',
                  value: _stats['post2Done']!,
                  color: AppTheme.post2Done,
                  icon: Icons.verified_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final total = _stats['total']!;
    if (total == 0) return const SizedBox.shrink();

    final post2 = _stats['post2Done']!;
    final post1Only = _stats['post1Done']! - post2;
    final notProc = _stats['notProcessed']!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${((post2 / total) * 100).toStringAsFixed(1)}% complete',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  if (post2 > 0)
                    Expanded(
                      flex: post2,
                      child: Container(height: 16, color: AppTheme.post2Done),
                    ),
                  if (post1Only > 0)
                    Expanded(
                      flex: post1Only,
                      child: Container(height: 16, color: AppTheme.post1Done),
                    ),
                  if (notProc > 0)
                    Expanded(
                      flex: notProc,
                      child: Container(height: 16, color: AppTheme.notProcessed.withOpacity(0.3)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTheme.post2Done, label: 'Done ($post2)'),
                const SizedBox(width: 16),
                _LegendDot(color: AppTheme.post1Done, label: 'Post 1 ($post1Only)'),
                const SizedBox(width: 16),
                _LegendDot(color: AppTheme.notProcessed.withOpacity(0.5), label: 'Pending ($notProc)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search part ID...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Not Processed',
                  selected: _filterStatus == PartStatus.notProcessed,
                  onTap: () => setState(() => _filterStatus = PartStatus.notProcessed),
                  color: AppTheme.notProcessed,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Post 1 Done',
                  selected: _filterStatus == PartStatus.post1Done,
                  onTap: () => setState(() => _filterStatus = PartStatus.post1Done),
                  color: AppTheme.post1Done,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Fully Done',
                  selected: _filterStatus == PartStatus.post2Done,
                  onTap: () => setState(() => _filterStatus = PartStatus.post2Done),
                  color: AppTheme.post2Done,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartTile(Part part) {
    final color = AppTheme.statusColorFromEnum(part.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 6,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(
          part.partId,
          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (part.post1Timestamp != null)
              Text(
                'Post 1: ${_fmt.format(part.post1Timestamp!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            if (part.post2Timestamp != null)
              Text(
                'Post 2: ${_fmt.format(part.post2Timestamp!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            if (part.delayBetweenPosts != null)
              Text(
                'Delay: ${_formatDuration(part.delayBetweenPosts!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: StatusBadge(status: part.status, fontSize: 11),
        isThreeLine: part.post1Timestamp != null || part.post2Timestamp != null,
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasAny = _stats['total']! > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAny ? Icons.filter_list_off : Icons.upload_file_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasAny ? 'No parts match filter' : 'No parts imported yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              hasAny
                  ? 'Try clearing filters or searching differently.'
                  : 'Tap the upload icon (↑) in the top right\nto import your parts CSV file.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
            ),
            if (!hasAny) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _importing ? null : _importCsv,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import CSV'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
              ),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
