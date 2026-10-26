import 'package:aviation_logbook/core/layout/responsive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('window size classes follow the 600 and 1024 breakpoints', () {
    expect(WindowSize.forWidth(390), WindowSize.compact);
    expect(WindowSize.forWidth(599.9), WindowSize.compact);
    expect(WindowSize.forWidth(600), WindowSize.medium);
    expect(WindowSize.forWidth(820), WindowSize.medium);
    expect(WindowSize.forWidth(1024), WindowSize.expanded);
    expect(WindowSize.forWidth(1440), WindowSize.expanded);
  });
}
