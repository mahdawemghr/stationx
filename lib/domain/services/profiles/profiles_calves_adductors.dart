part of '../profile_dsl.dart';

// Muscle profiles: calves_adductors. Add new entries at the END of the map (keys unique across ALL parts).
// Helpers (_p, _pr, _s, _sr, _x, _stab, region aliases) live in profile_dsl.dart.
final Map<String, ExerciseMuscleProfile> profilesCalvesAdductors = {
  'calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'single_leg_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'seated_calf_raise': _x(
    [_p(Muscle.soleus, 'Knee bent shifts load to soleus')],
    [_s(Muscle.gastrocnemius)],
  ),
  'donkey_calf_raise': _x(
    [_p(Muscle.gastrocnemius, 'Stretch under load')],
    [_s(Muscle.soleus)],
  ),
  'leg_press_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'smith_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'db_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'tibialis_raise': _x([_pr(_calf, 'Front of the shin')]),
  'cable_hip_adduction': _x([_pr(_glu, 'Inner thigh (adductors)')]),
  'band_hip_adduction': _x([_pr(_glu, 'Inner thigh (adductors)')]),
  'side_lying_hip_adduction': _x([_pr(_glu, 'Inner thigh (adductors)')]),
  'db_sumo_squat': _x(
    [_pr(_quad), _pr(_glu, 'Inner thigh (adductors)')],
    [_s(Muscle.gluteusMaximus)],
  ),
  'kb_sumo_squat': _x(
    [_pr(_quad), _pr(_glu, 'Inner thigh (adductors)')],
    [_s(Muscle.gluteusMaximus)],
  ),
  'kb_cossack_squat': _x(
    [_pr(_quad), _pr(_glu, 'Inner thigh (adductors)')],
    [_s(Muscle.gluteusMaximus)],
  ),
  'standing_barbell_calf_raise': _x(
    [_p(Muscle.gastrocnemius)],
    [_s(Muscle.soleus)],
  ),
  'seated_barbell_calf_raise': _x(
    [_p(Muscle.soleus, 'Knee bent shifts load to soleus')],
    [_s(Muscle.gastrocnemius)],
  ),
  'single_leg_db_calf_raise': _x(
    [_p(Muscle.gastrocnemius)],
    [_s(Muscle.soleus)],
  ),
  'seated_db_calf_raise': _x(
    [_p(Muscle.soleus, 'Knee bent shifts load to soleus')],
    [_s(Muscle.gastrocnemius)],
  ),
  'cable_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'bodyweight_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'bent_knee_calf_raise': _x(
    [_p(Muscle.soleus, 'Knee bent shifts load to soleus')],
    [_s(Muscle.gastrocnemius)],
  ),
  'stair_calf_raise': _x(
    [_p(Muscle.gastrocnemius, 'Full stretch off a step')],
    [_s(Muscle.soleus)],
  ),
  'band_calf_raise': _x([_p(Muscle.gastrocnemius)], [_s(Muscle.soleus)]),
  'band_tibialis_raise': _x([_pr(_calf, 'Front of the shin')]),
  'weighted_tibialis_raise': _x([_pr(_calf, 'Front of the shin')]),
};
