# Laminate Calculator

A Flutter app that calculates how much laminate flooring you need for a room and generates an optimal laying scheme.

[Google Play](https://play.google.com/store/apps/details?id=com.floor_calculator.host)

## Features

- Calculates the number of planks and packs required for a room
- Rooms that are not square: each of the four walls is measured on its own, and the diagonal closes the outline exactly, so the rows come out at the lengths they will actually be cut to
- Rooms with corners taken off them, picked as a shape rather than described: a corner run across at 45°, both ends of one wall run across, a Г with one corner out square, a Т with both ends of a wall out, and a Z with two corners out diagonally across from each other. The overall size is the rectangle the room is cut from, each cut is measured the way a tape reaches it — a 45° cut by the wall it leaves, a square one by its two sides — and which corners are gone is set by tapping the sketch. Each cut is its own size, so the riser and the cupboard on one wall need not be the same depth. The three square-cut shapes are laid along the room or across it; 45° is not offered in them, because a diagonal strip crosses such an outline twice and a row would be two rows
- A П with a notch in the middle of one wall: the boxed-in riser on a kitchen wall, a chimney breast, a column standing against the plaster. Measured as the two pieces of wall left at the ends and the depth between them, with the wall picked by tapping the sketch. The one room laid in a single direction — across the notched wall and never along it, because a row running along it is parted in two by the notch and a row in two is not something the engine can lay. The other direction is out of reach on the laying screen and says why
- Builds several laying layout options, minimizing waste by reusing offcuts
- Respects laying constraints: expansion gap from walls, exact joint offset between rows, minimum plank length
- Plank offset level selection: 1/2, 1/3, 1/4 of the plank length or an exact value
- Laying direction selection: along the room length, along its width, or at 45°
- Metric and imperial measurement systems (millimeters, or feet and inches down to 1/16")
- Visual laying scheme with every plank numbered and every row numbered beside it — the same numbers the cut list uses, so "row 7, plank 12" is found on the drawing without counting down from the top — drawn large enough to read and panned rather than shrunk onto the screen; every wall carries its own measured length, so a room that is out of square says so even where the slant is too small to see; rows always run left to right, so laying across the room turns the room instead; a button holds the phone in landscape while the scheme is read
- Text cut list: every row plank by plank, reusable leftovers, waste and its share of the material bought
- Export to PDF: the scheme on a sheet turned to match it, then the cut list; the cut list also shares as plain text
- Language and measurement system are asked once at first launch, persisted, and changed later from the gear on the form; switching the system rewrites the values already typed
- Twelve languages: English, Russian, German, Spanish, French, Italian, Polish, Portuguese, Turkish, Czech, Swedish, Bulgarian
- Runs entirely on the device: the manifest declares no permissions, and there is no network, ad or analytics dependency

## How the calculation works

Given the room size, plank dimensions, and laying parameters, the algorithm (`lib/calculate.dart`) lays out the floor row by row:

1. Rows follow an exact staircase pattern: each row's first plank is exactly the configured offset (1/2, 1/3, 1/4 of the plank length or a custom value) shorter than the previous one; when the next step would drop below the minimum plank length, the pattern restarts from the first row's length.
2. The pattern start is chosen so that in every row both the first and the last plank stay at or above the minimum plank length.
3. Offcuts with an intact lock are kept and reused at the start or end of later rows.
4. Several strategies are tried (with/without cutting offcuts, with/without offcut optimization); invalid layouts are filtered out and the remaining options are sorted by total plank count.

Laying at 45° changes only the shape of the rows (`lib/row_plan.dart`): they grow, hold and shrink across the diagonal of the room instead of all being one length, they start a plank width apart in a staircase that turns once at a corner, and every row ends in a wedge, which costs half a plank width of reach and cannot be reused as a square end. The strip left against the far corner is dropped when it comes to less than 50 mm, being narrower than a plank a fitter can cut and click into place.

A room whose walls differ is the same idea taken one step further. Four wall lengths are one measurement short of a shape — a quadrilateral has five degrees of freedom, and four sides leave the outline hinged — so the form asks for the diagonal too, which cuts the room into two triangles and fixes it without assuming anything about right angles (`lib/room_shape.dart`). The rows are then found by turning the outline until they run along one axis and cutting it into strips a plank wide (`scanPlan`): where a strip's centreline crosses the floor is the row, and how the walls lean at those two crossings is the slant of its ends, never steeper than 45°. A true rectangle keeps the closed forms it has always used, so nothing about it moves; `test/scan_plan_test.dart` holds the strip walk to what they produce.

A room with corners cut away is the other direction: square throughout, but no longer convex (`CutCornersRoomShape`). That costs it the diagonal and buys back something worth more — the outline is one unbroken run of floor across every row, however many corners are gone, because a piece pressed into a *corner* eats into one end of a row and never into its middle. So the engine needs nothing new. What it does need is three things of its own (`rectilinearPlan`). The rows keep a rectangle's width rule, because the outer walls are still parallel both ways and a rectangle that grows a small notch must not have every row re-ripped. Each row is measured across the whole of its strip rather than along one line through it, and laid to the furthest the floor reaches anywhere in that strip: laid to any less, a ribbon of real floor is left bare along a step, and laid to the furthest the board is notched round the inside corner, which is what a fitter does anyway. In a Z whose two inside corners fall in one strip that row is longer than the floor is at any single height in it — notched at both ends, and still the only row that covers the strip. And the drawing stops cutting planks against one wall's line at a time — against a floor that bends back on itself that leaves only the little rectangle where the two arms overlap — and takes each inside corner away as a corner instead (`clipToFloor`). A plank there comes back as one piece: what is removed is a quarter-plane and what it is removed from is convex. Two cuts may not reach each other, which would make the outline cross itself; that is the one arrangement of corners the form refuses (`RoomProblem.cutsOverlap`).

A notch in the middle of a wall (`WallNotchRoomShape`) is where that argument runs out, and where it pays to see exactly how far. The sentence above turns on the missing piece being pressed into a *corner*: that is what makes it eat into one end of a row rather than the middle. Put it in the middle of a wall and the rows running along that wall come back in two pieces with a hole between them — and a row in two is a thing nothing downstream can say, since `RowPlan` holds one start and one length apiece. But only those rows: the rows running *across* the notched wall meet it from one side and stay whole, starting a notch's depth further along or running that much shorter, which is the same thing a corner cut already does to the rows beside it. So the room is offered in one direction and not the other (`RoomOutline.takesAlongLength`), and in that direction the engine needs nothing new — not the row plan, not the joint rule, not a line of `calculate.dart`.

The drawing does need something. `clipToFloor` takes each inside corner away as a quarter-plane, and a notch has two of them facing each other: one takes everything to the left of the notch and below it, the other everything to the right and below, and between them that is the whole band the notch is cut into, floor and all. So two inside corners that are neighbours in the ring — which is a notch, and which no arrangement of cut corners produces — are taken away together as a slot, three walls at once (`_withoutNotch`). A plank there can come back with a bay in its edge rather than a corner off its end, which is still one ring; it would come back in two pieces only if the slot passed clean through it, and laying across the notched wall is what rules that out.

## Project structure

```
lib/
  calculate.dart      # Core laying/count algorithm
  room_shape.dart     # The floor as an outline: four walls and a diagonal, or a rectangle less a corner
  row_plan.dart       # The shape of the rows: the only file the laying directions differ in
  models.dart         # Plank, Line, Bevel, Result models
  scheme_geometry.dart # Result to polygons and label anchors in millimetres of room
  scheme_pdf.dart     # The same geometry on an A4 page, and the cut list after it
  cubit/              # One cubit per part of the form, and one for the settings
  pages/              # Screens: language, unit system, the room, the plank and the laying, result, laying scheme
  router/             # auto_route navigation
  l10n/               # Localization (ru template, plus en, de, es, fr, it, pl, pt, tr, cs, sv, bg)
  utils/, widgets/    # Unit conversion, form validators, shared widgets
test/
  stress_test.dart       # Randomized stress test of algorithm invariants
  diagonal_stress_test.dart # The same, for 45° laying: row lengths, bevels, material balance
  uneven_stress_test.dart # The same, for rooms measured wall by wall, in all three directions
  l_shape_stress_test.dart # The same, for rooms with a corner cut away, both ways round
  row_geometry_test.dart # The geometry the validators derive must match what the algorithm lays out
  row_plan_test.dart     # Row lengths and starts at 45°, against a numeric oracle
  room_shape_test.dart   # Measuring the outline built from five numbers gives the five numbers back
  scan_plan_test.dart    # The strip walk against the closed forms it has to subsume on a rectangle
  rectilinear_plan_test.dart # Rows round a cut-away corner: the rectangle oracle and the coverage bounds
  scheme_geometry_test.dart # The drawn planks cover the floor, stay inside the walls and are labelled
  scheme_pdf_test.dart   # The pages save, the sheet turns with the drawing, and every alphabet prints
  l10n_test.dart         # .arb key parity, CLDR plural categories, unit-label collisions
  cut_list_test.dart     # Grouping and waste arithmetic, plus the lines the cut list renders
  units_test.dart        # Inch fractions: formatting, parsing and the round trip through millimetres
  inch_field_test.dart   # The whole-inch field and its fraction picker stay one value
  imperial_form_test.dart # What the imperial form accepts, and the millimetres it stores
  uneven_form_test.dart  # Measuring wall by wall from the form's side, and what it refuses
  l_shape_form_test.dart # Picking the shape, the cut and the corner, and the 45° the room cannot have
  measurement_system_test.dart # The system picked at launch reaches the calculation and the disk
  settings_test.dart     # The gear sheet: relocalising in place, and switching units under typed values
  golden_test.dart       # Rendered result and scheme screens, plural forms, language picker
  goldens/               # Reference images for the golden tests
  store_screenshots_test.dart # Walks the app to shoot the Play listing images
assets/
  *.svg               # Flags for the language picker
  fonts/              # Roboto, for the PDF only: the pdf package cannot reach the app's fonts
store/                # Play listing per locale: feature graphic, screenshots, listing.txt, whatsnew.txt
```

The PDF is set in Roboto (Apache 2.0, `assets/fonts/LICENSE.txt`), which covers Latin and Cyrillic —
between them every alphabet the app ships in. `PdfFonts.canPrint` is the guard for the day one
arrives that it does not: the cut list is left off the page rather than printed as empty boxes, and
is still read on screen and shared as text. A language in a third alphabet means shipping a face for
it (Noto, OFL, about 200 KB a weight) and picking a face per string.

## State

Four cubits, and all four live above the router in `main.dart` rather than belonging to a screen.

One per part of the form — the room, the laminate, the laying — plus one for the two settings that
are not about this floor at all, the language and the unit system. One cubit per part and not per
screen: the plank and the laying share a screen and keep their answers apart all the same, because
what the form is made of has nothing to do with how many pages it is printed on.

A screen can reach what it collects and the settings, and nothing else; all the laying section wants
of the room is its outline, which it reads by name and gathers with the plank into one read-only
snapshot per frame (`LayingInputs`). The direction the rows run is read *through* the room: a 45°
strip crosses an outline that turns back on itself twice, so a room with a corner notched out of it
is laid along or across whatever the user picked earlier, without the room screen reaching forward
to rewrite an answer given on the screen after it.

Above the router and not inside the screens because the screens are pushed on top of each other: a
step back destroys the route, its `State` and the text controllers in it, and the boxes are filled
again from the cubits when the screen comes round a second time. Cubits that lived and died with
their screens would turn every step back into a form to retype — which is the one thing a step back
exists to avoid.

## Tech stack

Flutter, flutter_bloc, auto_route, pdf, share_plus, shared_preferences, flutter_svg, intl.

## Development

```bash
flutter pub get
flutter run

# Regenerate code (routes)
flutter pub run build_runner build --delete-conflicting-outputs

# Regenerate localizations (settings come from l10n.yaml, so pass no arguments)
flutter gen-l10n

# Run every test
flutter test

# Update the reference images after an intentional visual change
flutter test --update-goldens test/golden_test.dart

# Reshoot the Play listing screenshots into store/<locale>/ (1242x2208, 9:16)
flutter test --update-goldens test/store_screenshots_test.dart

# The stress test also runs standalone, without the Flutter test harness
dart test/stress_test.dart
```

## Releasing

The Play listing is written in `store/<locale>/listing.txt` and
`store/<locale>/whatsnew.txt` and shot into `store/<locale>/*.png`;
`tool/build_store_metadata.dart` lays all of it out as
`fastlane/metadata/android/` under the locale codes Play uses, checks it
against Play's limits, and `fastlane supply` sends it. The feature graphic and
the icon are never uploaded — supply overwrites only the fields it finds a file
for, so those stay as they are on Play. The title works the same way: write
`store/<locale>/title.txt` (30 characters) only to change one, or to give a
locale Play does not carry yet a title at all, because a listing Play has never
seen starts out empty and it will not take an empty title.

Portuguese is filed as `pt-PT`, the text being European. Play still carries the
older `pt-BR` listing, and supply cannot delete a listing — until that one is
removed by hand in the Play Console, Brazil goes on seeing it.

Publishing needs a service account key at `~/.config/laminat_calc/play-api.json`
(override with `PLAY_JSON_KEY`), and `android/key.properties` for the signing.
Neither is in the repository.

```bash
# One-off: install the pinned fastlane
bundle install

# Lay out fastlane/metadata/ from store/ and check the lengths. Run it on its
# own after editing any listing text — it reports every problem at once.
dart run tool/build_store_metadata.dart

# Texts and screenshots for all twelve locales, nothing else.
# dry_run:true validates the whole edit against Play and discards it.
bundle exec fastlane android listing dry_run:true
bundle exec fastlane android listing

# A whole release: metadata, a signed bundle, and the release notes.
bundle exec fastlane android release track:internal draft:true
bundle exec fastlane android release track:production

# Read the live listing into fastlane/play_current/ to see what Play holds now
bundle exec fastlane android pull
```

The order for a release: bump `version` in `pubspec.yaml` (the build number is
Play's versionCode and must go up), rewrite the twelve `whatsnew.txt` — their
first line carries the version and the generator refuses a stale one — reshoot
the screenshots, then `fastlane android release`.
