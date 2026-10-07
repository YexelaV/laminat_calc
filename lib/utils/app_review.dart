// Asking for a rating, at the one moment there is anything to rate.
//
// The app has no account, no server and nothing to measure itself by, so the
// only thing that says whether it is any good is the Play rating — which is
// also what decides whether anybody finds it. Nothing asked for one until now.
//
// The ask is Google's own dialog, drawn by Play Services over the app. We do
// not get to know whether it appeared: Play has a quota of its own and stays
// silent about it, which is deliberate — an app that could tell would start
// retrying until it worked.
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many times the user has looked at a finished floor and come back.
///
/// On disk rather than in [CalculateCubit], which is built fresh on every
/// launch: what matters here is that somebody came back a second time, and a
/// counter that forgets overnight cannot tell.
const SCHEMES_SEEN_PREF_KEY = 'schemes_seen';

/// Which of those times to ask on.
///
/// The second, not the first: a user who went back for another room has
/// already decided the app works, and a user who has not is being asked to
/// judge something they have barely seen.
///
/// And once more much later, because Play may have swallowed the first ask
/// without telling us. Two is where it stops — Google's own guidance is not to
/// keep at it, and a third attempt would be us arguing with a quota.
const _askAfter = [2, 10];

/// What the ask is made with.
///
/// An interface for the sake of the tests: a widget test has no Play Services
/// behind it, and what has to be proved here is the counting, not Google's
/// dialog. [PlayReviewPrompt] is the real one and the default everywhere else.
abstract class ReviewPrompt {
  Future<bool> isAvailable();

  Future<void> request();
}

class PlayReviewPrompt implements ReviewPrompt {
  const PlayReviewPrompt();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> request() => InAppReview.instance.requestReview();
}

/// Counts one finished calculation the user has looked at, and asks for a
/// rating if this is one of the times to ask.
///
/// Never throws and never reports. A rating is worth nothing to the user, so
/// nothing it can do is worth a message, a delay or a crash — on a phone with
/// no Play Services at all, [ReviewPrompt.isAvailable] simply says no and the
/// whole thing is a counter incrementing.
///
/// The count is written before the asking, so a swallowed ask does not shift
/// the numbering: the user who was asked at two gets asked again at ten
/// whatever Play did with the first one.
Future<void> countSchemeSeen({ReviewPrompt prompt = const PlayReviewPrompt()}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getInt(SCHEMES_SEEN_PREF_KEY) ?? 0) + 1;
    await prefs.setInt(SCHEMES_SEEN_PREF_KEY, seen);
    if (!_askAfter.contains(seen)) return;
    if (!await prompt.isAvailable()) return;
    await prompt.request();
  } catch (_) {
    // Including the counter's own write. There is no outcome here that the
    // user would want to hear about, and none that is worth a second of the
    // floor they came to lay.
  }
}
