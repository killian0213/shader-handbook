// Sound (sound) — Mostly Harmless by P_Malin
// https://www.shadertoy.com/view/MdsGzr

#define N(T,N) t+=float(T); if(x>t) r=vec2(N,t);
#define L(T,N,X) t+=float(T); if((x>t) && (x<(t+float(X)))) r=vec2(N,t);

vec2 GetTrack0ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(288,62) N(96,66) N(96,69) N(96,50) N(96,62) N(96,62) N(96,50) N(96,66) N(96,62) N(96,50) N(96,62)
    N(96,54) N(96,50) N(96,62) N(96,66) N(96,52) N(96,61) N(96,67) N(96,52) N(96,61) N(96,61) N(96,52)
    N(96,61) N(96,57) N(96,52) N(96,61) N(96,61) N(96,45) N(96,61) N(96,67) N(96,45) N(96,61) N(96,61)
    N(96,45) N(96,61) N(96,55) N(96,45) N(96,61) N(96,61) N(96,50) N(96,66) N(96,66) N(96,50) N(96,66)
    N(96,66) N(96,50) N(96,62) N(96,57) N(96,50) N(96,62) N(96,66) N(96,54) N(96,66) N(96,66) N(96,54)
    N(96,66) N(96,66) N(96,42) N(96,50) N(96,50) N(96,42) N(96,45) N(96,45) N(96,43) N(96,50) N(96,52)
    N(96,43) N(96,47) N(96,52) N(96,52) N(192,52) N(96,52) N(96,55) N(96,59) N(96,52) N(96,61) N(96,67)
    N(96,45) N(96,61) N(96,61) N(96,50) N(96,66) N(96,66) N(96,54) N(96,66) N(96,66) N(96,52) N(192,76)
    N(96,55) N(192,81) N(96,54) N(144,66) N(48,66) N(96,54) N(96,78) N(96,85) N(96,52) N(96,56) N(96,56)
    N(96,52) N(96,56) N(96,61) N(96,52) N(96,56) N(96,56) N(96,52) N(96,56) N(96,56) N(91,52) N(101,61)
    N(96,61) N(93,54) N(99,61) N(96,61) N(91,55) N(101,57) N(96,61) N(93,54) N(99,64) N(96,61) L(89,52,7)
    N(103,56) N(96,56) N(96,52) N(96,56) N(96,61) N(96,52) N(96,56) N(96,62) N(96,52) N(96,59) N(96,62)
    N(96,61) N(192,57) N(96,54) N(144,78) N(48,74) N(48,71) N(48,52) N(48,78) N(48,56) N(96,52) N(96,57)
    N(281,81)
    return r;
}

vec2 GetTrack0BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(576,69) N(96,66) N(96,66) N(96,81) N(96,62) N(96,66) N(96,78) N(96,54) N(96,57) N(96,62) N(96,57)
    N(96,62) N(96,67) N(96,67) N(96,61) N(96,81) N(96,67) N(96,67) N(96,79) N(96,57) N(96,55) N(96,61)
    N(96,57) N(96,57) N(96,71) N(96,67) N(96,61) N(96,79) N(96,67) N(96,67) N(96,73) N(96,57) N(96,57)
    N(96,61) N(96,57) N(96,57) N(96,71) N(96,62) N(96,57) N(96,78) N(96,62) N(96,57) N(96,78) N(96,57)
    N(96,54) N(96,62) N(96,57) N(96,62) N(96,74) N(96,62) N(96,62) N(96,86) N(96,62) N(96,62) N(96,81)
    N(96,45) N(96,45) N(96,62) N(96,54) N(96,54) N(96,74) N(96,52) N(96,47) N(96,86) N(96,50) N(96,50)
    N(96,50) N(192,64) N(96,64) N(96,67) N(96,71) N(96,71) N(96,67) N(96,61) N(192,67) N(96,67) N(96,78)
    N(96,57) N(96,62) N(192,57) N(96,62) N(96,47) N(288,45) N(288,50) N(144,69) N(48,69) N(96,50) N(96,86)
    N(192,85) N(96,62) N(96,62) N(192,62) N(96,64) N(96,82) N(96,62) N(96,62) N(192,62) N(96,62) N(96,45)
    N(96,57) N(96,64) N(96,45) N(96,57) N(96,57) N(96,45) N(96,61) N(96,64) N(96,45) N(96,57) N(96,64)
    N(96,52) N(96,62) N(96,64) N(192,62) N(96,64) N(96,76) N(96,64) N(96,56) N(192,64) N(96,59) N(96,54)
    N(192,81) N(96,59) N(288,40) N(48,71) N(48,44) N(96,40) N(96,45) N(288,67)
    return r;
}

vec2 GetTrack0CNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(672,57) N(96,57) N(96,78) N(96,57) N(96,57) N(96,74) N(96,57) N(96,62) N(192,66) N(96,57) N(96,69)
    N(96,57) N(96,57) N(96,79) N(96,57) N(96,79) N(96,73) N(96,55) N(96,61) N(192,55) N(96,55) N(288,57)
    N(96,83) N(192,57) N(96,79) N(96,55) N(96,61) N(192,55) N(96,55) N(192,57) N(96,62) N(96,74) N(96,57)
    N(96,62) N(96,74) N(96,54) N(96,62) N(192,66) N(96,57) N(192,57) N(96,57) N(96,81) N(96,57) N(96,57)
    N(96,78) N(96,54) N(96,54) N(192,50) N(96,50) N(192,47) N(96,50) N(96,83) N(96,52) N(96,47) N(96,47)
    N(192,76) N(96,76) N(96,79) N(96,83) N(96,83) N(96,57) N(96,57) N(192,57) N(96,57) N(96,90) N(96,62)
    N(96,57) N(192,62) N(96,57) N(96,50) N(288,52) N(288,74) N(144,74) N(48,74) N(96,66) N(288,76) N(96,64)
    N(96,64) N(192,64) N(96,55) N(96,73) N(96,64) N(96,64) N(192,64) N(96,64) N(96,78) N(96,64) N(96,57)
    N(192,64) N(96,64) N(96,83) N(96,64) N(96,57) N(192,61) N(96,57) N(96,85) N(96,64) N(96,62) N(192,64)
    N(96,55) N(96,85) N(96,62) N(96,64) N(192,62) N(96,83) N(96,59) N(288,50) N(288,78) N(48,74) N(48,78)
    N(96,76) N(96,69) N(288,64)
    return r;
}

vec2 GetTrack0DNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(768,81) N(288,78) N(576,69) N(288,79) N(288,73) N(480,64) N(96,71) N(288,79) N(288,73) N(480,64)
    N(96,71) N(288,83) N(96,83) N(192,78) N(576,69) N(288,86) N(288,78) N(288,62) N(192,66) N(96,69) N(288,83)
    N(288,83) N(96,43) N(960,68) N(96,69) N(480,74) N(96,78) N(96,43) N(288,73) N(576,69) N(384,83) N(96,83)
    N(192,83) N(96,82) N(192,83) N(96,83) N(192,76) N(96,76) N(288,76) N(192,76) N(96,76) N(96,71) N(192,81)
    N(192,78) N(96,85) N(96,76) N(96,83) N(96,83) N(192,83) N(96,82) N(96,88) N(96,86) N(96,86) N(192,80)
    N(192,83) N(288,80) N(288,71) N(48,68) N(48,74) N(96,74) N(96,61)
    return r;
}

vec2 GetTrack0ENote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(768,78) N(288,74) N(864,81) N(1152,83) N(288,79) N(864,78) N(288,74) N(864,81) N(288,81) N(864,86)
    N(288,76) N(96,83) N(960,80) N(96,81) N(480,86) N(192,71) N(288,83) N(576,74) N(384,74) N(96,74) N(192,74)
    N(96,73) N(192,74) N(96,74) N(1152,69) N(192,86) N(96,76) N(192,74) N(96,74) N(192,74) N(96,85) N(192,83)
    N(96,83) N(384,71) N(288,68) N(288,74) N(96,71) N(96,71) N(96,64)
    return r;
}

vec2 GetTrack0FNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(4224,74) N(2688,76) N(1728,78) N(4128,74) N(96,74) N(960,68) N(96,68) N(96,68)
    return r;
}

// ------------------- 8< ------------------- 8< ------------------- 8< -------------------

float NoteToHz(float n)
{  	
	return 440.0*pow( 2.0, (n-69.0)/12.0 );
}

float Sin(float x)
{
    return sin(x * 3.1415 * 2.0);
}

#if 1

float Instrument( const in vec2 vFreqTime )
{
    float f = vFreqTime.x;
    float t = vFreqTime.y;
    
    if( t < 0.0 )
        return 0.0;
    float x = 0.0;
    float a = 1.0;
    float h = 1.0;
    for(int i=0; i<8; i++)
    {
        x += Sin( f * t * h ) * exp2( t * -a );
        x += Sin( f * (t+0.005) * h * 0.5 ) * exp2( t * -a * 2.0 ) ;
        h = h + 1.01;
        a = a * 2.0;
    }
    
    return x;
}

#else

float Function(float t, float f)
{
    float t2 = t * f * radians(180.0);
    float y = 0.0;
    
    float h = 1.0;
    float a = 1.0;
    for( int i=0; i<8; i++)
    {
        float inharmonicity = 0.001;
        float f2 = h * sqrt( 1.0 + h * h *  inharmonicity);
        float r = sin( t2 * f2 );

        //r = r * a;
        r = r * exp2(t * -2.0 / a);
        
        y += r;

        h = h + 1.0;
        a = a * 0.6;
    }
    
    //y *= exp2(t * -4.0);
    return y;
}

float Main( float t, float f )
{
    return Function(t, f) + Function(t + 0.01, f * 0.51);
}

float Instrument( const in vec2 vFreqTime )
{
    return Main(vFreqTime.y, vFreqTime.x);
}
#endif

const float kMidiTimebase = 240.0;
const float kInvMidiTimebase = 1.0 / kMidiTimebase;
const float kTranspose = 12.0 * 0.0;

vec2 GetNoteData( const in vec2 vMidiResult, const in float fMidiTime )
{
    return vec2( NoteToHz(vMidiResult.x + kTranspose), abs(fMidiTime - vMidiResult.y) * kInvMidiTimebase );
}

float PlayMidi( const in float time )
{
    if(time < 0.0)
		return 0.0;
    
    float fMidiTime = time * kMidiTimebase;
    
    float fResult = 0.0;
    
    fResult += Instrument( GetNoteData( GetTrack0ANote(fMidiTime), fMidiTime ) );
    fResult += Instrument( GetNoteData( GetTrack0BNote(fMidiTime), fMidiTime ) );
    fResult += Instrument( GetNoteData( GetTrack0CNote(fMidiTime), fMidiTime ) );
    fResult += Instrument( GetNoteData( GetTrack0DNote(fMidiTime), fMidiTime ) );
    fResult += Instrument( GetNoteData( GetTrack0ENote(fMidiTime), fMidiTime ) );
    fResult += Instrument( GetNoteData( GetTrack0FNote(fMidiTime), fMidiTime ) );
    
    fResult = clamp(fResult * 0.05, -1.0, 1.0);
    
    float fFadeEnd = 60.0;
    float fFadeTime = 5.0;
    float fFade = (time - (fFadeEnd - fFadeTime)) / fFadeTime;    
    fResult *= clamp(1.0 - fFade, 0.0, 1.0);
    
    return fResult;
}

vec2 mainSound( in int samp,float time)
{
    return vec2( PlayMidi(time) );
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
