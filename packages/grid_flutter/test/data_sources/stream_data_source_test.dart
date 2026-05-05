import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_core/grid_core.dart';
import 'package:grid_flutter/src/data_sources/stream_data_source.dart';

void main() {
  test('StreamDataSource returns initial data in fetch() and watches correctly', () async {
    final streamController = StreamController<List<String>>();
    final dataSource = StreamDataSource<String>(
      streamBuilder: (query) => streamController.stream,
    );

    final query = GridQuery(pageIndex: 0, pageSize: 10, sorting: const [], columnFilters: const {});
    final watchStream = dataSource.watch(query);
    
    expect(watchStream, isNotNull);

    // Initial fetch should be empty since stream hasn't emitted
    final initialPage = await dataSource.fetch(query);
    expect(initialPage.data, isEmpty);

    // Emit data
    streamController.add(['Apple', 'Banana']);
    
    // Wait for the stream to process
    final emittedData = await watchStream!.first;
    expect(emittedData, ['Apple', 'Banana']);

    // Now fetch should return the cached data
    final secondPage = await dataSource.fetch(query);
    expect(secondPage.data, ['Apple', 'Banana']);
    expect(secondPage.totalItems, 2);

    await streamController.close();
  });
}
