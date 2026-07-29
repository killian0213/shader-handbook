// Sound (sound) — Rubik's Ball by tdhooper
// https://www.shadertoy.com/view/tslfWs


vec2 rand(vec2 n) {
    return fract(sin(n) * 43758.5453123) * 2. - 1.;
}

vec2 srand(vec2 n, float hard) {
	vec2 nf = floor(n);
    vec2 nc = ceil(n);
    return mix(rand(nf), rand(nc), smoothstep(.5 * hard, 1. - .5 * hard, fract(n)));
}

vec2 mainSound( in int samp, float time )
{
    time += TIME_OFFSET;
    // shift time to stop clipping at start of move
    float index = floor((time + .05) / LOOP_DURATION * MOVE_COUNT);
    float moveIndex = mod(index - 1., MOVE_COUNT);
    float turns = abs(moves[int(moveIndex)].w);
    float volume = pow(turns / 3., 1.5);
    
    float t = mod(time, LOOP_DURATION);
    t = mod(t, LOOP_DURATION / MOVE_COUNT);
    vec2 s = srand(vec2(t * 2.5, t * 2. + .02) * 1000., .0) * exp(-100. * t);
    s += sin(vec2(t * 5000.) / mix(1.1, 1., rand(vec2(index+.2)).x) / (1. + t * .5)) * exp(-30. * t) * .1;

    return s * volume;
}