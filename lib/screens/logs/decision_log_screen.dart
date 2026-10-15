import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';

/// Screen 7 — Log Keputusan (Decision Audit Log sesuai PRD v1.0/v2.0)
class DecisionLogScreen extends StatefulWidget {
  const DecisionLogScreen({super.key});

  @override
  State<DecisionLogScreen> createState() => _DecisionLogScreenState();
}

class _DecisionLogScreenState extends State<DecisionLogScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final history = context.select<SimulationController, List<DecisionRecord>>(
      (c) => c.history,
    );

    final filteredRecords = history.where((r) {
      if (_selectedFilter == 'Handover') {
        return r.isHandoverRecommended;
      }
      if (_selectedFilter == 'Stay') {
        return !r.isHandoverRecommended && r.stabilizedAction == DecisionAction.stay;
      }
      if (_selectedFilter == 'Insufficient') {
        return r.stabilizedAction == DecisionAction.insufficientData;
      }
      return true;
    }).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Keputusan'),
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Semua', 'Handover', 'Stay', 'Insufficient'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.darkNavy,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppTheme.darkNavy : AppTheme.dividerColor,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Log List
          Expanded(
            child: filteredRecords.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada catatan log untuk filter ini.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      return _DecisionRecordCard(
                        key: ValueKey(record.stepIndex),
                        record: record,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DecisionRecordCard extends StatelessWidget {
  final DecisionRecord record;

  const _DecisionRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final isHandover = record.isHandoverRecommended;
    final isStay = !isHandover && record.stabilizedAction == DecisionAction.stay;
    final isFallback = isHandover && record.stabilizedAction != DecisionAction.recommendSwitch;

    final badgeColor = isFallback
        ? AppTheme.errorRed
        : (isHandover
            ? AppTheme.darkNavy
            : (isStay ? AppTheme.surfaceBackground : AppTheme.warningOrange));

    final badgeTextColor = isFallback
        ? Colors.white
        : (isHandover
            ? Colors.white
            : (isStay ? AppTheme.textPrimary : Colors.white));

    final badgeText = isFallback
        ? 'FALLBACK HO'
        : (isHandover
            ? 'HANDOVER'
            : (isStay ? 'STAY' : record.stabilizedAction.name.toUpperCase()));

    final targetId = record.effectiveTargetId;
    final titleText = isHandover && targetId != null
        ? '${record.activeNetworkId} → $targetId'
        : 'Tetap pada ${record.activeNetworkId}';

    final hfText = record.handoverFactor != null
        ? 'HF: ${record.handoverFactor!.toStringAsFixed(2)} (Ambang: ${record.threshold?.toStringAsFixed(2) ?? '-'})'
        : 'Sinyal terputus (Link Failure)';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: const BorderSide(color: AppTheme.dividerColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isStay ? AppTheme.dividerColor : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Langkah #${record.stepIndex} (${record.elapsedSeconds.toStringAsFixed(1)}s)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  record.trafficClass.name,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              titleText,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'QoS: ${record.qosFactor?.toStringAsFixed(2) ?? '-'} · $hfText · Alasan: ${record.stabilizedReason.name}',
              style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
