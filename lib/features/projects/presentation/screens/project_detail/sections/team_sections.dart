part of '../../project_detail_screen.dart';

extension _ProjectTeamSections on _ProjectDetailScreenState {
  Widget _teamCard(Project project) {
    final names = project.assignedWorkerNames;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Eyebrow('Project Team')),
              Text(
                names.isEmpty
                    ? 'No team assigned'
                    : '${names.length} Active ${names.length == 1 ? 'Member' : 'Members'}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          if (names.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Assign workers to this project to see them here.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            for (var i = 0; i < names.length; i++)
              _teamRow(names[i], i, isLast: i == names.length - 1),
        ],
      ),
    );
  }

  Widget _teamRow(String name, int index, {required bool isLast}) {
    const roles = [
      'Field Surveyor',
      'GIS Specialist',
      'CAD Specialist',
      'Survey Technician',
    ];
    const colors = [
      AppColors.primary,
      AppColors.inProgress,
      AppColors.accepted,
      AppColors.pending,
    ];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _initialsAvatar(name, color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roles[index % roles.length],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _iconAction(
            icon: Icons.mail_outline,
            tooltip: 'Message $name',
            onTap: () => _showPlaceholder('Messaging $name…'),
          ),
        ],
      ),
    );
  }
}
