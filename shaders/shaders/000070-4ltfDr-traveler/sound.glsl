// Sound (sound) — traveler. by kaneta
// https://www.shadertoy.com/view/4ltfDr

#define PI 3.141592654
#define TAU 6.283185307

#define BPM 120.0

#define C3  60
#define Cs3 61
#define D3  62
#define Ds3 63
#define E3  64
#define F3  65
#define Fs3 66
#define G3  67
#define Gs3 68
#define A3  69
#define As3 70
#define B3  71
#define UP + 12
#define DN - 12
#define CHO(a,b,c) ivec3(a,b,c)

#define INIT(t) float tmp = t, nTime = t, p = 0.0; int , num; ivec3 chord;
#define R(v) tmp -= 240.0 / BPM / float(v);
#define D(v)if (tmp >= 0.0 ) {nTime = tmp; p = 1.0;} R(v)
#define N(v, n) if (tmp >= 0.0) {nTime = tmp; num = n; p = 1.0;}  R(v)
#define C(v, c) if (tmp >= 0.0) {nTime = tmp; chord = c; p = 1.0;}  R(v)
#define S(v) if (tmp >= 0.0) {p = v;}
#define LOOP(b) if(tmp>0.0) tmp = mod(tmp, float(b) * 240.0 / BPM);
#define FOR(b, n) if(tmp>0.0) {float a = float(b) * 240.0 / BPM; for(int i = 0; i < n-1; i++){if (tmp> a) tmp -= a;}}

float sine( float phase ) {
    return sin( TAU * phase );
}

float saw( float phase ) {
    return 2.0 * fract( phase ) - 1.0;
}

float square( float phase ) {
    return fract( phase ) < 0.5 ? -1.0 : 1.0;
}

float n2f(in float t, in int n)
{
    return fract(440.0 * exp2((float(n)-69.0) / 12.0) * t);    
}

float kick(float t)
{
    INIT(t)
    LOOP(1)
        D(4)
        D(4)
        D(4)
        D(4)
        
    return sin( nTime * 250.0 - exp( -nTime * 100.0 ) * 30.0 ) * exp( -nTime * 5.0 ) * p;
}

vec2 hash( vec2 p ){
	p = vec2( dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3)));
	return fract(sin(p)*43758.5453);
}

vec2 hihat( float t ) {
    INIT(t)
    LOOP(16.0)
    FOR(0.25, 16)
    	R(4)
    FOR(0.5, 24)
        R(8)
        D(8)
        R(8)
        D(8)
  return sin(hash(vec2(nTime))) * exp( -nTime * 20.0 ) * 0.2 * p;
}


vec2 snare(float t) {
    INIT(t)
    LOOP(16.0)
    FOR(0.25, 32)
    	R(4)
    FOR(1.0, 8)
        R(4)
        D(4)
        R(4)
        D(4)
	return clamp(vec2(0.0), vec2(1.0), (
		hash( vec2(nTime) ).xy * 1.5 +
		sine( nTime * 300.0 - exp( -nTime * 400.0 ) * 30.0 ) * 0.1 +
		saw( nTime - exp( -nTime * 400.0 ) * 30.0 ) * 0.3
		) * 2.0 * exp( -nTime * 23.0 ) ) * 0.3 * p;
}

vec2 mainSound( in int samp, float time )
{
    // A 440 Hz wave that attenuates quickly overt time
    return  kick(time) + hihat(time) + snare(time);
}