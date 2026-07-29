// Common (common) — 20220405_Eucredian Rhythms by 0b5vr
// https://www.shadertoy.com/view/7ljczz

#define saturate(i) clamp(i,0.,1.)
#define clip(i) clamp(i,-1.,1.)
#define lofi(i,j) (floor((i)/(j))*(j))
#define tri(p) (1.-4.*abs(fract(p)-0.5))

// constants that you might want to tweak
const float BPM = 140.0;

const float KICK_PULSES = 4.0;
const float KICK_STEPS = 16.0;
const float KICK_OFFSET = 0.0;

const float HIHAT_PULSES = 13.0;
const float HIHAT_STEPS = 16.0;
const float HIHAT_OFFSET = 0.0;

const float SNARE_PULSES = 3.0;
const float SNARE_STEPS = 16.0;
const float SNARE_OFFSET = 4.0;

const float HITOM_PULSES = 3.0;
const float HITOM_STEPS = 10.0;
const float HITOM_OFFSET = 1.0;

const float LOTOM_PULSES = 5.0;
const float LOTOM_STEPS = 13.0;
const float LOTOM_OFFSET = 2.0;

const float RIM_PULSES = 3.0;
const float RIM_STEPS = 5.0;
const float RIM_OFFSET = 0.0;

// constants
const float PI = acos( -1.0 );
const float TAU = PI * 2.0;
const float SQRT2 = sqrt( 2.0 );

const float BPS = BPM / 60.0;
const float TIME2BEAT = BPS;
const float BEAT2TIME = 1.0 / BPS;

// common
mat2 rotate2D( float t ) {
    float c = cos( t );
    float s = sin( t );
    return mat2( c, s, -s, c );
}

// euclidean rhythms stuff
bool euclideanRhythms( float pulses, float steps, float i ) {
    float t = mod( i * pulses, steps );
    return t - pulses < 0.0;
}

float euclideanRhythmsInteg( float pulses, float steps, float time ) {
    float t = mod( floor( time ) * pulses, steps );
    return floor( ( t - pulses ) / pulses ) + 1.0 + fract( time );
}
