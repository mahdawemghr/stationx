import 'package:flutter/material.dart';

import '../../domain/domain.dart';

/// The ONE presentation definition per [CardioKind]: icon, section and search aliases.
/// Exhaustive switches, so adding a kind fails to compile until it is described here.
/// `cardioKindIcon` / `cardioIcon` in the cardio screens are thin wrappers over [cardioKindGlyph].
IconData cardioKindGlyph(CardioKind k) => switch (k) {
      CardioKind.outdoorRun => Icons.directions_run,
      CardioKind.outdoorWalk => Icons.directions_walk,
      CardioKind.treadmill => Icons.speed,
      CardioKind.cycling => Icons.directions_bike,
      CardioKind.stationaryBike => Icons.pedal_bike,
      CardioKind.elliptical => Icons.accessibility_new,
      CardioKind.rowing => Icons.kayaking,
      CardioKind.stairClimber => Icons.stairs,
      CardioKind.jumpRope => Icons.bolt,
      CardioKind.trailRun => Icons.terrain,
      CardioKind.hiking => Icons.hiking,
      CardioKind.spinBike => Icons.directions_bike_outlined,
      CardioKind.airBike => Icons.air,
      CardioKind.skiErg => Icons.downhill_skiing,
      CardioKind.arcTrainer => Icons.sports_gymnastics,
      CardioKind.verticalClimber => Icons.north,
      CardioKind.swimming => Icons.pool,
      CardioKind.handCycle => Icons.back_hand_outlined,
      CardioKind.hiit => Icons.local_fire_department,
      CardioKind.boxing => Icons.sports_mma,
      CardioKind.indoorWalk => Icons.trending_up,
      CardioKind.nordicWalk => Icons.nordic_walking,
      CardioKind.rucking => Icons.backpack,
      CardioKind.recumbentBike => Icons.airline_seat_recline_normal,
      CardioKind.indoorTrainer => Icons.electric_bike,
      CardioKind.crossCountrySki => Icons.snowshoeing,
      CardioKind.openWaterSwim => Icons.waves,
      CardioKind.outdoorRowing => Icons.rowing,
      CardioKind.paddling => Icons.surfing,
      CardioKind.danceCardio => Icons.music_note,
      CardioKind.skating => Icons.roller_skating,
      CardioKind.climbing => Icons.landscape,
      CardioKind.martialArts => Icons.sports_martial_arts,
      CardioKind.custom => Icons.fitness_center,
    };

/// Section headers of the select-activity list, in display order. `Custom` is last.
const cardioSections = [
  'Walk & Run',
  'Cycling',
  'Machines',
  'Water',
  'Outdoor & Winter',
  'Classes & Conditioning',
  'Custom',
];

/// The single section [k] is listed under (each kind belongs to exactly one).
String cardioSection(CardioKind k) => switch (k) {
      CardioKind.outdoorRun ||
      CardioKind.trailRun ||
      CardioKind.outdoorWalk ||
      CardioKind.treadmill ||
      CardioKind.indoorWalk ||
      CardioKind.nordicWalk ||
      CardioKind.hiking ||
      CardioKind.rucking => 'Walk & Run',
      CardioKind.cycling ||
      CardioKind.stationaryBike ||
      CardioKind.spinBike ||
      CardioKind.recumbentBike ||
      CardioKind.indoorTrainer ||
      CardioKind.airBike ||
      CardioKind.handCycle => 'Cycling',
      CardioKind.elliptical ||
      CardioKind.rowing ||
      CardioKind.stairClimber ||
      CardioKind.skiErg ||
      CardioKind.arcTrainer ||
      CardioKind.verticalClimber => 'Machines',
      CardioKind.swimming ||
      CardioKind.openWaterSwim ||
      CardioKind.outdoorRowing ||
      CardioKind.paddling => 'Water',
      CardioKind.crossCountrySki || CardioKind.skating || CardioKind.climbing => 'Outdoor & Winter',
      CardioKind.jumpRope ||
      CardioKind.hiit ||
      CardioKind.boxing ||
      CardioKind.danceCardio ||
      CardioKind.martialArts => 'Classes & Conditioning',
      CardioKind.custom => 'Custom',
    };

/// Extra lower-case words the activity search matches besides the label and blurb.
List<String> cardioSearchTerms(CardioKind k) => switch (k) {
      CardioKind.outdoorRun => const ['run', 'running', 'jog', 'jogging', 'track', 'road', '5k', '10k', 'marathon'],
      CardioKind.outdoorWalk => const ['walk', 'walking', 'stroll', 'steps'],
      CardioKind.treadmill => const ['run', 'running', 'jog', 'treadmill', 'indoor run'],
      CardioKind.cycling => const ['bike', 'biking', 'road bike', 'mountain bike', 'mtb', 'ride', 'cycle'],
      CardioKind.stationaryBike => const ['exercise bike', 'stationary', 'upright', 'bike'],
      CardioKind.elliptical => const ['cross trainer', 'cross-trainer'],
      CardioKind.rowing => const ['rower', 'erg', 'concept2', 'concept 2', 'row machine', 'ergometer'],
      CardioKind.stairClimber => const ['stepper', 'stepmill', 'step mill', 'stairs', 'stairmaster', 'stair master', 'step'],
      CardioKind.jumpRope => const ['skipping', 'skip rope', 'jump rope', 'rope'],
      CardioKind.trailRun => const ['trail', 'off-road', 'offroad', 'run', 'running', 'ultra'],
      CardioKind.hiking => const ['hike', 'trek', 'trekking', 'trail walk'],
      CardioKind.spinBike => const ['spinning', 'spin class', 'peloton', 'indoor cycling', 'soulcycle'],
      CardioKind.airBike => const ['assault bike', 'fan bike', 'echo bike', 'airdyne'],
      CardioKind.skiErg => const ['skierg', 'ski erg', 'concept2', 'pull erg'],
      CardioKind.arcTrainer => const ['arc', 'cybex', 'low impact'],
      CardioKind.verticalClimber => const ['versaclimber', 'vertical', 'climber', 'ladder'],
      CardioKind.swimming => const ['swim', 'pool', 'laps', 'lap swim'],
      CardioKind.handCycle => const ['arm bike', 'arm ergometer', 'ergometer', 'ugh', 'upper body ergometer', 'ube', 'handcycle'],
      CardioKind.hiit => const [
          'circuit', 'conditioning', 'metcon', 'crossfit', 'wod', 'battle ropes', 'sled', 'tabata', 'interval', 'intervals', 'emom', 'amrap', 'bootcamp',
        ],
      CardioKind.boxing => const ['heavy bag', 'bag', 'pads', 'shadow boxing', 'punch'],
      CardioKind.indoorWalk => const [
          'walking pad', 'walk pad', 'under desk', 'desk treadmill', 'treadmill walk', '12-3-30', '12 3 30', 'incline walk', 'incline walking', 'indoor walk',
        ],
      CardioKind.nordicWalk => const ['nordic', 'pole walking', 'poles', 'trekking poles'],
      CardioKind.rucking => const ['ruck', 'rucksack', 'weighted walk', 'weighted vest', 'backpack', 'goruck', 'loaded carry walk'],
      CardioKind.recumbentBike => const ['recumbent', 'seated bike', 'bike'],
      CardioKind.indoorTrainer => const ['zwift', 'trainer', 'smart trainer', 'turbo trainer', 'peloton', 'rouvy', 'bike', 'cycling'],
      CardioKind.crossCountrySki => const ['xc ski', 'nordic ski', 'skiing', 'ski', 'skate ski', 'classic ski', 'snow'],
      CardioKind.openWaterSwim => const ['swim', 'lake', 'sea', 'ocean', 'river', 'triathlon', 'wild swim'],
      CardioKind.outdoorRowing => const ['row', 'sculling', 'scull', 'crew', 'river', 'boat', 'regatta'],
      CardioKind.paddling => const [
          'kayak', 'kayaking', 'canoe', 'canoeing', 'sup', 'stand up paddle', 'paddleboard', 'paddle board', 'paddle', 'dragon boat', 'surf ski',
        ],
      CardioKind.danceCardio => const ['zumba', 'aerobics', 'dance', 'dancing', 'step aerobics', 'jazzercise', 'cardio dance', 'bokwa', 'class'],
      CardioKind.skating => const ['skate', 'rollerblade', 'rollerblading', 'roller skate', 'inline', 'ice skating', 'roller derby', 'skateboard'],
      CardioKind.climbing => const ['bouldering', 'boulder', 'rock climbing', 'indoor climbing', 'wall', 'lead', 'sport climbing', 'via ferrata'],
      CardioKind.martialArts => const [
          'muay thai', 'kickboxing', 'karate', 'taekwondo', 'judo', 'bjj', 'jiu jitsu', 'mma', 'krav maga', 'sparring', 'wrestling', 'fight',
        ],
      CardioKind.custom => const ['custom', 'other', 'padel', 'tennis', 'football', 'soccer', 'basketball', 'squash', 'badminton'],
    };
