// Common (common) — 2d spectral ray tracer by riouxld
// https://www.shadertoy.com/view/stSXzm

// debugging options
#define ACCUMULATE true
#define ONLY_INDIRECT false


// constants & parameters
// ----------------------

const float eps = 0.001;
const float infinity = 10000.0;
const float two_pi = 6.283185;
const float pi = 3.1415925;

const int n_samples = 16;
const int max_depth = 20;

const int nb_emiters = 1;
const int nb_objects = 3;

const int none = -1;
const int emiter = 0;
const int mirror = 1;
const int dielectric = 2;

const int spectrum_start = 380;
const int spectrum_end = 720;
const int spectrum_width = (spectrum_end - spectrum_start);

// Keyboard
// --------

//const int KEY_ONE  = 49;
//const int KEY_A  = 65;
const int KEY_SPACE  = 32;

// variable buffer locations
// ----------------------
const ivec2 reset_time_loc = ivec2(0,0);
const ivec2 light_pos_loc = ivec2(1,0);

