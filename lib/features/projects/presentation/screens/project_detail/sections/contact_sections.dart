part of '../../project_detail_screen.dart';

extension _ProjectContactSections on _ProjectDetailScreenState {
  Widget _organizationContactCard(Project project) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Eyebrow('Organization Contact'),
          Row(
            children: [
              _initialsAvatar(
                'Michael Petersen',
                AppColors.inProgress,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Michael Petersen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Primary Contact',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (project.owner.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.owner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: () => _showPlaceholder('Calling Michael Petersen…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => _showPlaceholder('Emailing Michael Petersen…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountExecutiveCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Eyebrow('Account Executive'),
          Row(
            children: [
              _initialsAvatar('Cynthia Lopez', AppColors.primary, size: 56),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cynthia Lopez',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Account Lead',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'GeoTerra Monitoring',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: () => _showPlaceholder('Calling Cynthia Lopez…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () => _showPlaceholder('Emailing Cynthia Lopez…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(String name, Color color, {required double size}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.inProgress.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.inProgress),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inProgress,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
