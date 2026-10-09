part of '../seed_dsl.dart';

// Seed rows: other. Add new rows at the END of the list (ids must be unique across ALL parts).
// Shared helper `_e` and muscle aliases (_chest, _back, ...) live in seed_dsl.dart.
List<Exercise> seedOther() => [
  _e('sled_push', 'Sled Push', _legs, Equipment.other, 'Push', sec: [_core]),
  _e(
    'backward_sled_drag',
    'Backward Sled Drag',
    _legs,
    Equipment.other,
    'Pull',
  ),
  _e(
    'yoke_walk',
    'Yoke Walk',
    _legs,
    Equipment.other,
    'Carry',
    sec: [_back, _core],
  ),
  _e(
    'sandbag_carry',
    'Sandbag Carry',
    _legs,
    Equipment.other,
    'Carry',
    sec: [_back, _core],
  ),
];
