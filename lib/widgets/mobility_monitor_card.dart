import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/mobility/mobility.dart';

/// Widget ringkas untuk menampilkan status mobilitas pengguna
/// pada Live Monitor atau Dashboard Simulasi WMC.
class MobilityMonitorCard extends StatelessWidget {
  const MobilityMonitorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MobilityController>(
      builder: (context, controller, child) {
        final state = controller.mobilityState;
        final isMoving = state.isMoving;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header & Mode Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_walk, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'Mobilitas Pengguna',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    DropdownButton<MobilitySpeedMode>(
                      value: controller.mode,
                      isDense: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: MobilitySpeedMode.manualStatic,
                          child: Text('Manual (Statis)'),
                        ),
                        DropdownMenuItem(
                          value: MobilitySpeedMode.randomWaypoint,
                          child: Text('Simulasi (RWP)'),
                        ),
                      ],
                      onChanged: (newMode) {
                        if (newMode != null) {
                          controller.setMode(newMode);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Indikator Status & Kecepatan Efektif
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Kecepatan Efektif',
                        value: '${controller.effectiveSpeed.toStringAsFixed(2)} m/s',
                        subtitle: controller.isRandomWaypointActive
                            ? 'Sumber: Random Waypoint'
                            : 'Sumber: Manual Input',
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Status Gerak',
                        value: isMoving ? 'MOVING' : 'PAUSED',
                        subtitle: isMoving
                            ? 'Menuju target'
                            : 'Jeda: ${state.remainingPauseTime.toStringAsFixed(1)}s',
                        color: isMoving ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Koordinat Posisi & Target Waypoint
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Posisi Pengguna (X, Y)',
                        value: '(${state.position.x.toStringAsFixed(1)}, ${state.position.y.toStringAsFixed(1)}) m',
                        subtitle: 'Area [0, ${controller.generator.config.areaWidth.toInt()}] m',
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Target Waypoint (X, Y)',
                        value: '(${state.currentWaypoint.x.toStringAsFixed(1)}, ${state.currentWaypoint.y.toStringAsFixed(1)}) m',
                        subtitle: 'Jarak: ${state.position.distanceTo(state.currentWaypoint).toStringAsFixed(1)} m',
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),

                // Tombol Kontrol Simulasi RWP
                if (controller.isRandomWaypointActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reset'),
                        onPressed: () => controller.resetSimulation(),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('Step (+1s)'),
                        onPressed: () => controller.stepSimulation(1.0),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(
                          controller.isRunning ? Icons.pause : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(controller.isRunning ? 'Pause' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              controller.isRunning ? Colors.amber[800] : Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (controller.isRunning) {
                            controller.stopSimulation();
                          } else {
                            controller.startSimulation();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
