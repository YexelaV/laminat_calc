// When the app asks for a rating, and when it keeps quiet.
//
// Play draws the dialog and never says whether it did, so there is nothing to
// check on that side. What is checkable is everything before it: that the ask
// comes on the second finished floor and not the first, that it comes once
// more much later and then never, and that none of it can cost the user
// anything — a phone with no Play Services behind it must count just the same
// and say nothing at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floor_calculator/utils/app_review.dart';

/// Stands in for Play. Counts what it was asked to do, and can be told to be
/// unavailable or to fail outright.
class FakePrompt implements ReviewPrompt {
  final bool available;
  final bool throws;
  int availabilityChecks = 0;
  int requests = 0;

  FakePrompt({this.available = true, this.throws = false});

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    if (throws) throw StateError('no Play Services');
    return available;
  }

  @override
  Future<void> request() async {
    requests++;
    if (throws) throw StateError('the dialog blew up');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<int> seen() async =>
      (await SharedPreferences.getInstance()).getInt(SCHEMES_SEEN_PREF_KEY) ?? 0;

  test('the first finished floor is counted and not asked about', () async {
    final prompt = FakePrompt();
    await countSchemeSeen(prompt: prompt);
    expect(await seen(), 1);
    expect(prompt.requests, 0);
    expect(prompt.availabilityChecks, 0, reason: 'Play is not even woken up');
  });

  test('the second is the one that asks', () async {
    final prompt = FakePrompt();
    await countSchemeSeen(prompt: prompt);
    await countSchemeSeen(prompt: prompt);
    expect(await seen(), 2);
    expect(prompt.requests, 1);
  });

  test('and then it stops until the tenth', () async {
    final prompt = FakePrompt();
    for (var i = 0; i < 12; i++) {
      await countSchemeSeen(prompt: prompt);
    }
    expect(await seen(), 12);
    expect(prompt.requests, 2, reason: 'the second and the tenth, and no more');
  });

  test('the count survives a launch, because it is on disk', () async {
    SharedPreferences.setMockInitialValues({SCHEMES_SEEN_PREF_KEY: 1});
    final prompt = FakePrompt();
    await countSchemeSeen(prompt: prompt);
    expect(await seen(), 2);
    expect(prompt.requests, 1, reason: 'the second floor, counted across two runs');
  });

  test('a phone without Play Services counts all the same', () async {
    final prompt = FakePrompt(available: false);
    await countSchemeSeen(prompt: prompt);
    await countSchemeSeen(prompt: prompt);
    expect(await seen(), 2);
    expect(prompt.availabilityChecks, 1);
    expect(prompt.requests, 0, reason: 'asked whether it could, told no, left it');
  });

  test('a swallowed ask does not shift the numbering', () async {
    // Play keeps a quota of its own and does not say when it has been spent,
    // so the ask at two may have shown nothing. The tenth has to come round
    // regardless, which it only does if the count went on counting.
    final prompt = FakePrompt(available: false);
    for (var i = 0; i < 10; i++) {
      await countSchemeSeen(prompt: prompt);
    }
    expect(await seen(), 10);
    expect(prompt.availabilityChecks, 2);
  });

  test('nothing it can do reaches the user', () async {
    final prompt = FakePrompt(throws: true);
    await countSchemeSeen(prompt: prompt);
    // The throw is in isAvailable, and the count still got there first.
    await expectLater(countSchemeSeen(prompt: prompt), completes);
    expect(await seen(), 2);
  });
}
