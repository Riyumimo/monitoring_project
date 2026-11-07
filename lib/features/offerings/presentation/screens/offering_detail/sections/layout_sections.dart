part of '../../offering_detail_screen.dart';

extension _LayoutSections on _OfferingDetailScreenState {
  Widget _wideLayout(Offering offering, ClientRecord? client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: SizedBox(height: 340, child: _overviewCard(offering)),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: SizedBox(height: 340, child: _mapCard(offering)),
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
                height: 300,
                child: _clientCard(offering, client),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(height: 300, child: _paymentCard(offering)),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: SizedBox(height: 300, child: _statusCard(offering)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _actionsCard(offering),
                  const SizedBox(height: 20),
                  _recentActivityCard(offering),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _descriptionCard(offering),
                  const SizedBox(height: 20),
                  _termsCard(offering),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _narrowLayout(Offering offering, ClientRecord? client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overviewCard(offering),
        const SizedBox(height: 20),
        SizedBox(height: 260, child: _mapCard(offering)),
        const SizedBox(height: 20),
        _clientCard(offering, client),
        const SizedBox(height: 20),
        _paymentCard(offering),
        const SizedBox(height: 20),
        SizedBox(height: 270, child: _statusCard(offering)),
        const SizedBox(height: 20),
        _actionsCard(offering),
        const SizedBox(height: 20),
        _recentActivityCard(offering),
        const SizedBox(height: 20),
        _descriptionCard(offering),
        const SizedBox(height: 20),
        _termsCard(offering),
      ],
    );
  }

  Widget _navButton() {
    return Tooltip(
      message: 'Show on map',
      child: Material(
        color: AppColors.inProgress.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: _showOnMap,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.navigation_outlined,
              size: 17,
              color: AppColors.inProgress,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBar({required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 11),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _infoNote(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _card({Key? key, required Widget child, Color? stripe}) {
    final content = stripe == null
        ? Padding(padding: const EdgeInsets.all(22), child: child)
        : Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: ColoredBox(color: stripe),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 22, 22),
                child: child,
              ),
            ],
          );

    return Container(
      key: key,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
    );
  }
}
