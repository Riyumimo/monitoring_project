import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../providers/project_provider.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class WorkersView extends StatelessWidget {
  const WorkersView({super.key});

  @override
  Widget build(BuildContext context) {
    final workers = MockData.workers();
    final projects = context.watch<ProjectProvider>().projects;
    final active = projects.where((p) => p.status == ProjectStatus.inProgress);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${workers.length}',
                  label: 'Team Members',
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${active.length}',
                  label: 'Active Assignments',
                  icon: Icons.assignment_turned_in_outlined,
                  color: AppColors.inProgress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Field Team',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...workers.map((worker) => _workerCard(worker, projects)),
        ],
      ),
    );
  }

  Widget _workerCard(User worker, List<Project> projects) {
    final assigned = projects
        .where((p) => p.assignedWorkerId == worker.id)
        .toList();
    final inProgress =
        assigned.where((p) => p.status == ProjectStatus.inProgress).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _avatar(worker.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      worker.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          '${assigned.length} assigned',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (inProgress > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.autorenew,
                              size: 14, color: AppColors.inProgress),
                          const SizedBox(width: 5),
                          Text(
                            '$inProgress in progress',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inProgress,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.completed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.completed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? (parts.first[0] + parts.last[0]).toUpperCase()
        : parts.first[0].toUpperCase();
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
