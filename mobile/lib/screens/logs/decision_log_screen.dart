import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/simulation/simulation.dart';
import '../../theme/app_theme.dart';

/// Screen 9/Audit — Layar Log Riwayat Keputusan Handover (Monokrom Modern & Dark Mode)
class DecisionLogScreen extends StatefulWidget {
  const DecisionLogScreen({super.key});

  @override
  State<DecisionLogScreen> createState() => _DecisionLogScreenState();
}

class _DecisionLogScreenState extends State<DecisionLogScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final records = context.select<SimulationController, List<DecisionRecord>>(
      (c) => c.history,
    );
    final isDark = context.isDark;

    final filteredRecords = records.where((r) {
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
        title: Text('Log Keputusan', style: TextStyle(color: context.textPrimaryColor)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.borderColor),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: context.cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Semua', 'Handover', 'Stay', 'Insufficient'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final chipSelectedBg = isDark ? Colors.white : AppTheme.darkNavy;
                  final chipSelectedText = isDark ? AppTheme.pureBlack : Colors.white;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? chipSelectedText : context.textPrimaryColor,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: chipSelectedBg,
                      backgroundColor: context.cardColor,
                      side: BorderSide(
                        color: isSelected ? chipSelectedBg : context.borderColor,
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
          Divider(height: 1, color: context.borderColor),

          // Log List
          Expanded(
            child: filteredRecords.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada catatan log untuk filter ini.',
                      style: TextStyle(color: context.textSecondaryColor),
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
    final isDark = context.isDark;

    final badgeColor = isFallback
        ? AppTheme.errorRed
        : (isHandover
            ? (isDark ? Colors.white : AppTheme.darkNavy)
            : (isStay ? (isDark ? const Color(0xFF262626) : AppTheme.surfaceBackground) : AppTheme.warningOrange));

    final badgeTextColor = isFallback
        ? Colors.white
        : (isHandover
            ? (isDark ? AppTheme.pureBlack : Colors.white)
            : (isStay ? context.textPrimaryColor : Colors.white));

    final badgeText = isFallback
        ? 'FALLBACK HO'
        : (isHandover
            ? 'HANDOVER'
            : (isStay ? 'STAY' : record.stabilizedAction.name.toUpperCase()));

    final targetId = record.effectiveTargetId;
    final titleText = isHandover && targetId != null
        ? '${formatNetworkLabel(record.activeNetworkId)} → ${formatNetworkLabel(targetId)}'
        : 'Tetap pada ${formatNetworkLabel(record.activeNetworkId)}';

    final hfText = record.handoverFactor != null
        ? 'HF: ${record.handoverFactor!.toStringAsFixed(2)} (Ambang: ${record.threshold?.toStringAsFixed(2) ?? '-'})'
        : 'Sinyal terputus (Link Failure)';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        side: BorderSide(color: context.borderColor, width: 1.0),
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
                            color: isStay ? context.borderColor : Colors.transparent,
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
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  record.trafficClass.name,
                  style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              titleText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'QoS: ${record.qosFactor?.toStringAsFixed(2) ?? '-'} · $hfText · Alasan: ${record.stabilizedReason.name}',
              style: TextStyle(fontSize: 10.5, color: context.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
