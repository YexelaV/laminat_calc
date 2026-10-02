const MIN_ROOM_MM = 500;
// The smallest corner worth cutting out of a room. The geometry only needs a
// millimetre — below that two corners of the outline land on each other — but
// a cut narrower than a hand is a mistyped digit, not a riser.
const MIN_NOTCH_MM = 100;
const MAX_LENGTH_MM = 24000;
const MAX_WIDTH_MM = 16000;
const MIN_PLANK_LENGTH = 300; //mm
const MAX_PLANK_LENGTH = 3000; //mm
const MIN_PLANK_WIDTH = 90; //mm;
const MAX_PLANK_WIDTH = 1000; //mm;
const MAX_INDENT_FROM_WALL = 50; //mm
const MIN_ITEMS_IN_PACK = 1;
const MAX_ITEMS_IN_PACK = 20;
const MIN_ROW_OFFSET = 100;
const MIN_MIN_LENGTH = 100;
const MIN_ROOM_FT = 1;
const MAX_INCHES_IN_FOOT = 11.9375; // 11 15/16''
const KOEF_COMPRESS = 35;
