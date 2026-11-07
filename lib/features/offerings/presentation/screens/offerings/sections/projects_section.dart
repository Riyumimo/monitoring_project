part of '../../offerings_page.dart';

extension _ProjectsSection on _OfferingsPageState {
  Widget _projectsView(List<Project> projects) {
    if (projects.isEmpty) return _projectsEmptyState();
    final provider = context.read<ProjectProvider>();

    return RefreshIndicator(
      onRefresh: () => context.read<ProjectProvider>().fetchProjects(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final project = projects[index];
          final offering = provider.offeringById(project.offeringId);
          final team = project.assignedWorkerNames;

          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push(AppRouter.projectDetail(project.id)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pill(project.status.label, project.status.color),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _projectMeta(
                      Icons.tag,
                      project.number.isEmpty ? '—' : project.number,
                    ),
                    const SizedBox(height: 4),
                    _projectMeta(Icons.apartment_outlined, project.owner),
                    const SizedBox(height: 4),
                    _projectMeta(
                      Icons.description_outlined,
                      offering == null
                          ? 'No linked offering'
                          : '${offering.number} · ${offering.name}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${team.length} worker${team.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (team.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              team.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _projectMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _projectsEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'No projects yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Accept an offering and create its project to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
