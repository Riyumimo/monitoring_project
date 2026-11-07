part of '../../offerings_page.dart';

extension _ClientsSection on _OfferingsPageState {
  Widget _clientsView() {
    final clients = [
      for (final client in ClientDirectory.all())
        _ClientRecord.fromClient(client),
    ];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? clients
        : clients.where((client) => client.matches(q)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _clientsHeader(clients, filtered),
          const SizedBox(height: 16),
          _clientSummary(clients),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _clientsEmptyState()
          else
            _clientResults(filtered),
        ],
      ),
    );
  }

  Widget _clientResults(List<_ClientRecord> clients) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return _clientTable(clients);
        }

        const gap = 12.0;
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final client in clients) _clientCard(client, width)],
        );
      },
    );
  }

  Widget _clientTable(List<_ClientRecord> clients) {
    const widths = <double>[220, 110, 150, 210, 140, 190, 95];
    const headers = [
      'Client',
      'Type',
      'Contact',
      'Email',
      'Phone',
      'Location',
      'Updated',
    ];
    final total = widths.fold<double>(0, (sum, width) => sum + width);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fill = total <= constraints.maxWidth;
          final scale = fill ? constraints.maxWidth / total : 1.0;
          final scaled = [for (final width in widths) width * scale];

          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: fill ? constraints.maxWidth : total,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < headers.length; i++)
                            _gridCell(
                              width: scaled[i],
                              header: true,
                              last: i == headers.length - 1,
                              child: _headerText(headers[i]),
                            ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < clients.length; i++)
                      _clientTableRow(
                        clients[i],
                        scaled,
                        i,
                        i == clients.length - 1,
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

  Widget _clientTableRow(
    _ClientRecord client,
    List<double> widths,
    int index,
    bool isLast,
  ) {
    final stripe = index.isEven
        ? AppColors.surface
        : AppColors.background.withValues(alpha: 0.5);

    return Material(
      color: stripe,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _gridCell(
              width: widths[0],
              bottom: !isLast,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: client.typeColor.withValues(alpha: 0.12),
                    child: Text(
                      client.initials,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: client.typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          client.name,
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
                          client.number,
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
                ],
              ),
            ),
            _gridCell(
              width: widths[1],
              bottom: !isLast,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _pill(client.typeLabel, client.typeColor),
              ),
            ),
            _gridCell(
              width: widths[2],
              bottom: !isLast,
              child: _plainText(client.contact.isEmpty ? '—' : client.contact),
            ),
            _gridCell(
              width: widths[3],
              bottom: !isLast,
              child: _plainText(client.email.isEmpty ? '—' : client.email),
            ),
            _gridCell(
              width: widths[4],
              bottom: !isLast,
              child: _plainText(client.phone.isEmpty ? '—' : client.phone),
            ),
            _gridCell(
              width: widths[5],
              bottom: !isLast,
              child: _plainText(client.fullAddress),
            ),
            _gridCell(
              width: widths[6],
              last: true,
              bottom: !isLast,
              child: _plainText(client.updatedLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientsHeader(
    List<_ClientRecord> clients,
    List<_ClientRecord> filtered,
  ) {
    final q = _query.trim();
    final cities = {
      for (final client in clients)
        if (client.city.isNotEmpty) client.city,
    }.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.people_outline, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                q.isEmpty
                    ? '${clients.length} clients across $cities ${cities == 1 ? 'city' : 'cities'}'
                    : '${filtered.length} of ${clients.length} clients match "$q"',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _addClient,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          label: const Text('Add Client'),
        ),
        if (q.isNotEmpty) _pill('${filtered.length} found', AppColors.primary),
      ],
    );
  }
}
