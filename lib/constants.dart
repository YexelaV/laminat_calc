const MIN_ROOM_MM = 500;
// The smallest corner worth cutting out of a room. The geometry only needs a
// millimetre — below that two corners of the outline land on each other — but
// a cut narrower than a hand is a mistyped digit, not a riser.
//
// It is also the floor under the expansion gap: a cut is inset from both of
// its own walls, so a cut of 100 against the widest gap the form takes closes
// to nothing, and anything narrower turns the inset outline inside out.
const MIN_NOTCH_MM = 100;
// How big a room the calculator will take. Not a statement about rooms — it is
// the paired half of the plank minimums below. Planks per layout is roughly
// (length / plank length) × (width / plank width), and the search walks that
// list four times over and once more per row; the product is what has to stay
// in hand, not either side of it.
const MAX_LENGTH_MM = 24000;
const MAX_WIDTH_MM = 16000;
// A plank, at its smallest, is a herringbone block or a tile rather than a
// board: 200 × 50 takes in both. Below 50 across, every row the engine lays is
// a sliver by its own [minRowWidthMm] rule, and at 200 along the exact joint
// offset has no range left to be typed into — half the plank is the ceiling on
// it, and the floor is 50.
const MIN_PLANK_LENGTH = 200; //mm
const MAX_PLANK_LENGTH = 3000; //mm
const MIN_PLANK_WIDTH = 50; //mm;
const MAX_PLANK_WIDTH = 1000; //mm;
// The widest expansion gap. Held under half of [MIN_ROOM_MM] because the rows
// are laid inside the gap on both sides, and a room the gap eats whole leaves
// no rows to lay.
const MAX_INDENT_FROM_WALL = 50; //mm
// How many planks come in a pack. The count is divided into the total once and
// read nowhere else, so the ceiling is only here to catch a slipped keyboard:
// packs of 24, 36 and 48 are ordinary for tiles and were refused by the old
// ceiling of 20.
const MIN_ITEMS_IN_PACK = 1;
const MAX_ITEMS_IN_PACK = 1000;
// The smallest joint offset and the shortest offcut worth laying.
//
// Both were 100, which asked more of a typed number than the app asks of its
// own: the 1/2, 1/3 and 1/4 buttons work the offset out from the plank without
// checking any range, and a 300 mm plank in quarters already offers 75. 50 is
// the floor the engine actually needs — the offset is divided into, so it has
// to clear zero, and a minimum of nothing would file every offcut, down to a
// plank of no length at all, as a piece worth keeping.
const MIN_ROW_OFFSET = 50;
const MIN_MIN_LENGTH = 50;
const MIN_ROOM_FT = 1;
const MAX_INCHES_IN_FOOT = 11.9375; // 11 15/16''
