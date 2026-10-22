import 'package:flutter/material.dart';

import '../models/offering.dart';
import '../theme/app_theme.dart';
import 'offering_map.dart';

class OfferingMapSplit extends StatefulWidget {
  final Widget leftPanel;
  final List<Offering> offerings;
  final String? selectedId;
  final ValueChanged<Offering> onSelect;
  final double breakpoint;

  const OfferingMapSplit({
    super.key,
    required this.leftPanel,
    required this.offerings,
    required this.selectedId,
    required this.onSelect,
    this.breakpoint = 900,
  });

  @override
  State<OfferingMapSplit> createState() => _OfferingMapSplitState();
}

class _OfferingMapSplitState extends State<OfferingMapSplit> {
  bool _showMap = false;

  @override
  void didUpdateWidget(covariant OfferingMapSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != null && widget.selectedId != oldWidget.selectedId) {
      _showMap = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= widget.breakpoint;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: (constraints.maxWidth * 0.4).clamp(340.0, 460.0),
                child: widget.leftPanel,
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: _mapPanel()),
            ],
          );
        }

        return Column(
          children: [
            _viewToggle(),
            Expanded(
              child: IndexedStack(
                index: _showMap ? 1 : 0,
                children: [
                  widget.leftPanel,
                  _mapPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mapPanel() {
    return OfferingMap(
      offerings: widget.offerings,
      selectedId: widget.selectedId,
      onOfferingTap: widget.onSelect,
    );
  }

  Widget _viewToggle() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('Offerings'),
            icon: Icon(Icons.list_alt, size: 18),
          ),
          ButtonSegment(
            value: true,
            label: Text('Map'),
            icon: Icon(Icons.map_outlined, size: 18),
          ),
        ],
        selected: {_showMap},
        onSelectionChanged: (selection) =>
            setState(() => _showMap = selection.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
