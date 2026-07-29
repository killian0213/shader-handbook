// Sound (sound) — E1M1 - Hangar by P_Malin
// https://www.shadertoy.com/view/lsSXzD

#define N(T,N) t+=float(T); if(x>t) r=vec2(N,t);
#define L(T,N,X) t+=float(T); if((x>t) && (x<(t+float(X)))) r=vec2(N,t);

vec2 GetTrack1Note(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    L(1628,40,8)N(24,40)N(28,52)L(24,40,8)N(26,40)N(26,50)L(24,40,8)N(26,40)N(26,48)L(24,40,8)N(26,40)N(26,46)L(24,40,12)N(28,40)N(24,47)N(26,48)L(26,40,4)N(24,40)N(26,52)L(26,40,8)N(24,40)N(26,50)L(26,40,8)N(24,40)N(28,48)L(24,40,10)N(26,40)N(26,46)L(126,40,10)N(26,40)N(24,52)L(28,40,8)N(24,40)N(26,50)L(26,40,10)N(24,40)N(26,48)L(26,40,8)N(24,40)N(26,46)L(26,40,8)N(24,40)N(28,47)N(24,48)L(26,40,8)N(26,40)N(24,52)L(26,40,10)N(26,40)N(24,50)L(26,40,8)N(26,40)L(24,63,14)L(14,60,14)L(14,59,12)L(12,63,12)L(12,66,12)L(12,64,14)L(14,63,12)L(12,59,14)L(14,63,12)L(12,64,12)L(12,66,12)L(12,67,14)L(14,66,14)L(14,64,12)L(12,63,12)L(12,59,12)L(12,40,8)N(26,40)N(26,52)L(24,40,8)N(28,40)N(24,50)L(26,40,8)N(26,40)N(24,48)L(26,40,8)N(26,40)N(24,46)L(26,40,10)N(26,40)N(24,47)N(28,48)L(24,40,4)N(26,40)N(26,52)L(24,40,8)N(26,40)N(26,50)L(24,40,8)N(26,40)N(26,48)L(24,40,10)N(28,40)N(24,46)L(128,40,8)N(24,40)N(26,52)L(26,40,8)N(24,40)N(28,50)L(24,40,10)N(26,40)N(26,48)L(24,40,8)N(26,40)N(26,46)L(24,40,8)N(26,40)N(26,47)N(24,48)L(28,40,8)N(24,40)N(26,52)L(26,40,8)N(24,40)N(26,50)L(26,40,8)N(24,40)L(26,67,14)L(14,64,12)L(12,59,12)L(12,64,12)L(12,67,14)L(14,64,14)L(14,67,12)L(12,71,12)L(12,67,12)L(12,64,14)
    return r;
}

vec2 GetTrack2Note(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    L(0,40,8)N(24,40)N(26,52)L(26,40,8)N(26,40)N(26,50)L(24,40,8)N(26,40)N(26,48)L(24,40,8)N(26,40)N(26,46)L(24,40,12)N(26,40)N(26,47)N(26,48)L(26,40,4)N(24,40)N(26,52)L(26,40,8)N(24,40)N(26,50)L(26,40,8)N(24,40)N(26,48)L(26,40,10)N(26,40)N(26,46)L(126,40,10)N(26,40)N(24,52)L(26,40,10)N(26,40)N(26,50)L(26,40,10)N(24,40)N(26,48)L(26,40,8)N(24,40)N(26,46)L(26,40,8)N(24,40)N(26,47)N(26,48)L(26,40,8)N(26,40)N(24,52)L(26,40,10)N(26,40)N(24,50)L(26,40,8)N(26,40)N(24,48)L(26,40,10)N(26,40)N(26,46)L(126,40,8)N(26,40)N(26,52)L(24,40,8)N(26,40)N(26,50)L(26,40,8)N(26,40)N(24,48)L(26,40,8)N(26,40)N(24,46)L(26,40,10)N(26,40)N(24,47)N(26,48)L(26,40,4)N(26,40)N(26,52)L(24,40,8)N(26,40)N(26,50)L(24,40,8)N(26,40)N(26,48)L(24,40,10)N(26,40)N(26,46)L(128,40,8)N(24,40)N(26,52)L(26,40,8)N(24,40)N(26,50)L(26,40,10)N(26,40)N(26,48)L(24,40,8)N(26,40)N(26,46)L(24,40,8)N(26,40)N(26,47)N(24,48)L(26,40,10)N(26,40)N(26,52)L(26,40,8)N(24,40)N(26,50)L(26,40,8)N(24,40)L(26,66,14)L(14,64,12)L(12,63,12)L(12,66,12)L(12,69,14)L(14,67,12)L(12,66,14)L(14,63,12)L(12,66,12)L(12,67,14)L(14,69,12)L(12,71,14)L(14,69,12)L(12,67,12)L(12,66,12)L(12,63,14)L(14,40,6)N(26,40)N(24,52)L(26,40,8)N(26,40)N(24,50)L(26,40,10)N(26,40)N(26,48)L(26,40,8)N(24,40)N(26,46)L(26,40,10)N(24,40)N(26,47)N(26,48)L(24,40,6)N(26,40)N(26,52)L(26,40,8)N(26,40)N(24,50)L(26,40,8)N(26,40)N(24,48)L(26,40,10)N(26,40)N(24,46)L(128,40,8)N(26,40)N(26,52)L(24,40,8)N(26,40)N(26,50)L(24,40,12)N(26,40)N(26,48)L(26,40,8)N(26,40)N(24,46)L(26,40,8)N(26,40)N(24,47)N(26,48)L(26,40,8)N(24,40)N(26,52)L(26,40,8)N(26,40)N(26,50)L(24,40,8)L(26,40,14)L(26,71,12)L(12,67,12)L(12,64,14)L(14,67,12)L(12,71,14)L(14,67,12)L(12,71,12)L(12,76,12)L(12,71,14)L(14,67,12)
    return r;
}

vec2 GetTrack3Note(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,40)N(406,40)N(406,40)N(408,40)N(408,40)N(408,40)N(406,40)N(408,40)N(406,40)N(52,40)N(52,40)N(50,40)N(50,40)N(52,40)N(50,40)N(50,40)N(52,40)N(52,40)N(50,40)N(50,40)N(52,40)N(52,40)N(50,40)N(50,40)N(52,40)N(50,40)N(50,40)N(52,40)N(52,40)N(50,40)N(50,40)N(52,40)N(52,40)N(50,40)N(50,40)N(52,40)N(50,40)N(50,40)N(52,40)
    return r;
}

vec2 GetTrack4ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,36)N(406,36)N(406,36)N(408,36)N(408,36)L(38,49,8)N(370,36)L(36,49,10)N(370,36)L(38,49,8)N(370,36)L(38,49,8)L(164,36,12)L(28,36,10)L(24,36,12)L(26,36,14)L(26,36,10)L(24,36,12)L(26,36,10)L(26,36,12)N(24,36)N(2,46)N(50,40)N(2,46)L(50,36,12)N(2,46)N(22,36)N(26,40)N(2,46)N(48,36)N(2,46)N(50,40)N(4,46)L(46,36,14)N(2,46)N(24,36)N(24,40)N(4,46)N(48,36)N(2,46)N(50,40)N(2,46)L(48,36,14)N(6,46)N(20,36)N(24,40)N(4,46)N(48,36)N(52,40)N(48,46)L(2,36,14)N(26,36)N(24,40)N(2,46)N(48,46)N(2,36)N(50,46)N(50,46)L(28,36,14)N(24,46)N(52,36)N(50,40)N(2,46)N(48,36)N(52,40)N(2,46)N(50,36)N(48,46)N(2,40)N(50,46)N(26,36)N(26,40)L(50,36,6)L(2,50,8)L(24,36,8)L(24,36,8)L(4,40,6)L(24,36,8)L(24,36,8)L(4,45,8)L(2,40,6)
    return r;
}

vec2 GetTrack4BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,40)N(406,40)N(406,40)N(408,40)N(408,40)L(38,57,8)N(370,40)L(36,57,10)N(370,40)L(38,57,8)N(370,40)L(38,57,8)L(164,40,12)L(28,40,8)L(24,40,14)L(26,40,12)L(26,40,12)L(24,40,12)L(26,40,14)L(26,40,12)N(636,46)N(52,46)N(202,40)N(50,36)N(52,40)N(52,46)N(100,46)N(104,46)L(100,36,14)N(52,46)L(52,40,8)L(52,47,8)
    return r;
}

vec2 GetTrack4CNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,41)N(406,41)N(406,41)N(408,41)N(408,41)N(408,41)N(406,41)N(408,41)L(202,41,12)L(28,41,8)L(24,41,12)L(26,41,10)L(26,41,12)L(24,41,12)L(26,41,12)L(26,41,12)
    return r;
}

vec2 GetTrack4DNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(1628,49)N(408,49)N(406,49)N(408,49)
    return r;
}

vec2 GetTrack4ENote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(1628,57)N(408,57)L(406,57,14)L(408,57,14)
    return r;
}


// ------------------- 8< ------------------- 8< ------------------- 8< -------------------

#define PI radians(180.0)
#define TWO_PI radians(360.0)

float NoteToHz(float n)
{  	
	return 440.0*pow( 2.0, (n-69.0)/12.0 );
}

float Tri( float t )
{
	return abs(fract( t ) * 4.0 - 2.0) - 1.0;
}

float Saw( float t )
{
	return fract( t ) * 2.0 - 1.0;
}

vec4 Saw4( vec4 x )
{
	return fract( x ) * 2.0 - 1.0;
}

float Cos( float t )
{
	return cos( t * radians(360.0) );
}

vec4 Cos4( vec4 x )
{
	x = abs(fract(x) * 2.0 - 1.0);
	vec4 x2 = x*x;
	return x2 * 6.0 - x2*x * 4.0  - 1.0;
}

float Square( float t )
{
	return step( fract(t), 0.5 ) * 2.0 - 1.0;
}

// Thanks to Dave_Hoskins for the hash
float Hash(float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

float Noise( float x )
{
	return Hash( floor(x * 32.0) ) * 2.0 - 1.0;
}

float SmoothNoise( float t )
{
	float noiset = t * 32.0;
	float tfloor = floor(noiset);
	float ffract = fract(noiset);
	
	float n0 = Hash(tfloor);
	float n1 = Hash(tfloor + 1.0);
	float blend = ffract*ffract*(3.0 - 2.0*ffract);
	return mix(n0, n1, blend) * 2.0 - 1.0;
}

float FBM( float t, float persistence )
{
    float result = 0.0;
    
    float a = 1.0;
    float tot = 0.0;
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence;
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence; 
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence; 
    result += SmoothNoise(t) * a; tot += a; t *= 2.02; a *= persistence; 
    tot += a; 
    return result / tot;
}


float StepNoise( float t, float freq )
{
	float noiset = t * freq;
	float tfloor = floor(noiset);
	
	float n = Hash(tfloor);
	return n * 2.0 - 1.0;
}

float Cos4(float x, vec4 phase, vec4 freq, vec4 amp)
{
	return dot(Cos4((x+phase) * freq), amp);
}

float Saw4(float x, vec4 phase, vec4 freq, vec4 amp)
{
	return dot(Saw4((x+phase) * freq), amp);
}


float Test( float t )
{
	return Saw4(t, vec4(0.0, 0.5, 0.1, 0.4), vec4(1.0, 1.50, 2.00, -3.00), vec4(1.0, 0.5, 0.25, 0.125));
}

float Envelope( float time, float decay )
{	
	return exp2( -time * (5.0 / decay) );
}

float Envelope( float time, float attack, float decay )
{
	if( time < attack )
	{
		return time/attack;
	}

	time -= attack;

	return Envelope( time, decay );
}

float Test2(float f)
{
    return Test(f) + Test(f - 0.0454) * 0.4 + Test(f - 0.1123) * 0.3 + Test(f - 0.1523) * 0.1;
}
float Instrument( const in vec2 vFreqTime )
{
    return Test2( vFreqTime.x * vFreqTime.y ) * Envelope( vFreqTime.y, 0.01, 1.0 );    
}

float Track1Instrument( const in vec2 vFreqTime )
{
    return Instrument( vFreqTime * vec2(2.0, 1.0) ) * 0.75;
}

float Track2Instrument( const in vec2 vFreqTime )
{
    return Instrument( vFreqTime );
}

float Track3Basic(float x)
{
    return FBM(x, 0.5);
}

float Track3Instrument( const in vec2 vFreqTime )
{
    return Track3Basic(vFreqTime.y * vFreqTime.x) * Envelope(vFreqTime.y, 0.4) * 2.0;
}

float kick(float freq, float fNoteTime){
    float a = clamp(1.0-fNoteTime,0.0,1.0);
    float osc = sin(pow(a,5.0)*freq);
    return osc * pow(a, 2.0);
}

float Track4Instrument( const in vec2 vFreqTime )
{
    return FBM(vFreqTime.y * vFreqTime.x * 8.0, 2.0) * Envelope(vFreqTime.y, 0.5);
}


const float kMidiTimebase = 200.0;
const float kInvMidiTimebase = 1.0 / kMidiTimebase;

vec2 GetNoteData( const in vec2 vMidiResult, const in float fMidiTime )
{
    return vec2( NoteToHz(vMidiResult.x), abs(fMidiTime - vMidiResult.y) * kInvMidiTimebase );
}

float PlayMidi( const in float time )
{
    if(time < 0.0)
		return 0.0;
    
    float fMidiTime = time * kMidiTimebase;
    
    float fResult = 0.0;
    
    fResult += Track1Instrument( GetNoteData( GetTrack1Note(fMidiTime), fMidiTime ) );
    fResult += Track2Instrument( GetNoteData( GetTrack2Note(fMidiTime), fMidiTime ) );
    fResult += Track3Instrument( GetNoteData( GetTrack3Note(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4ANote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4BNote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4CNote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4DNote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4ENote(fMidiTime), fMidiTime ) );
    
    fResult = clamp(fResult * 0.1, -1.0, 1.0);
    
    float fFadeEnd = 20.0 * 240.0 / kMidiTimebase;
    float fFadeTime = 5.0;
    float fFade = (time - (fFadeEnd - fFadeTime)) / fFadeTime;    
    fResult *= clamp(1.0 - fFade, 0.0, 1.0);
    
    return fResult;
}

vec2 mainSound( in int samp,float time)
{
    return vec2( PlayMidi(time - 3.0) );
}

//#define IMAGE_SHADER

#ifdef IMAGE_SHADER

float Function( float x )
{
	return mainSound( in int samp, iTime + x / (44100.0 / 60.0) ).x * 0.5 + 0.5;
}

float Plot( vec2 uv )
{
	float y = Function(uv.x);
	
	return abs(y - uv.y) * iResolution.y;	
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	
	vec2 uv = fragCoord.xy / iResolution.xy;
	
	vec3 vResult = vec3(0.0);
	
	vResult += Plot(uv);
	
	fragColor = vec4((vResult),1.0);
}
#endif

