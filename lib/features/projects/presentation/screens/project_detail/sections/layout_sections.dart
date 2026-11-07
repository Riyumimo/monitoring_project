part of '../../project_detail_screen.dart';

extension _ProjectDetailLayoutSections on _ProjectDetailScreenState {
  Widget _wideLayout(Project project, Offering? offering) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: SizedBox(
                height: 340,
                child: _overviewCard(project, offering),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: SizedBox(height: 340, child: _mapCard(project)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 260,
                child: _organizationContactCard(project),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(height: 260, child: _accountExecutiveCard()),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 260,
                child: _statusCard(project, offering),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _teamCard(project)),
            const SizedBox(width: 24),
            Expanded(flex: 7, child: _notesCard()),
          ],
        ),
      ],
    );
  }

  Widget _narrowLayout(Project project, Offering? offering) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overviewCard(project, offering),
        const SizedBox(height: 20),
        SizedBox(height: 260, child: _mapCard(project)),
        const SizedBox(height: 20),
        _organizationContactCard(project),
        const SizedBox(height: 20),
        _accountExecutiveCard(),
        const SizedBox(height: 20),
        SizedBox(height: 260, child: _statusCard(project, offering)),
        const SizedBox(height: 20),
        _teamCard(project),
        const SizedBox(height: 20),
        _notesCard(),
      ],
    );
  }
}
