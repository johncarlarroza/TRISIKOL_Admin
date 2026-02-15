import 'package:flutter/material.dart';

class AdminDataTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String? emptyMessage;
  final int rowsPerPage;
  final bool isLoading;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'No data available',
    this.rowsPerPage = 10,
    this.isLoading = false,
  });

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  late int _rowsPerPage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading data...'),
          ],
        ),
      );
    }

    if (widget.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(widget.emptyMessage ?? 'No data available'),
      );
    }

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, widget.rows.length);
    final pageRows = widget.rows.sublist(startIndex, endIndex);
    final totalPages = (widget.rows.length / _rowsPerPage).ceil();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: widget.columns, rows: pageRows),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page ${_currentPage + 1} of $totalPages (${widget.rows.length} total)',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.navigate_before),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _currentPage < totalPages - 1
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.navigate_next),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
