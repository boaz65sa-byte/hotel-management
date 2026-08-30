// Regression cover for the "Requests tab spins forever" bug.
//
// myDeptRequestsProvider used to `return const Stream.empty()` when it could
// not resolve a department for the signed-in role. An empty stream closes
// without ever emitting, and a StreamProvider fed such a stream stays in
// AsyncLoading indefinitely — the screen shows a spinner with no data, no
// empty state and no error, and nothing ever rebuilds it. These tests pin
// that behaviour down so the workaround isn't quietly reintroduced.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a StreamProvider fed Stream.empty() stays loading forever', () async {
    final provider = StreamProvider<List<String>>((_) => const Stream.empty());
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.listen(provider, (_, __) {});
    expect(container.read(provider), isA<AsyncLoading<List<String>>>());

    // Let the stream close. Closing is not emitting, so nothing resolves.
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(provider),
      isA<AsyncLoading<List<String>>>(),
      reason: 'an empty stream never emits, so the UI can never leave its '
          'loading state — this is the infinite-spinner bug',
    );
  });

  test('Stream.error surfaces as AsyncError so the screen can react', () async {
    final provider = StreamProvider<List<String>>(
      (_) => Stream<List<String>>.error(StateError('unknown role')),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.listen(provider, (_, __) {});
    await Future<void>.delayed(Duration.zero);

    final value = container.read(provider);
    expect(value, isA<AsyncError<List<String>>>());
    expect(value.error, isA<StateError>());
  });

  test('emitting an empty list resolves to data, not loading', () async {
    final provider =
        StreamProvider<List<String>>((_) => Stream.value(const <String>[]));
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.listen(provider, (_, __) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(provider), isA<AsyncData<List<String>>>());
    expect(container.read(provider).value, isEmpty);
  });
}
