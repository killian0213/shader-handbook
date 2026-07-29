// Sound (sound) — [SIG15] The DeLorean by P_Malin
// https://www.shadertoy.com/view/MlsSzf

//#define DISABLE_SOUND 

#define N(T,N) t+=float(T); if(x>t) r=vec2(N,t);
#define L(T,N,X) t+=float(T); if((x>t) && (x<(t+float(X)))) r=vec2(N,t);

/* Start of main()
Header.id='MThd'
Header.size=6
Reading MThd Chunk
Type: 1, trackCount: 8, timeBase: 96
Header.id='MTrk'
Header.size=99
Reading MTrk Chunk
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
Header.id='MTrk'
Header.size=4158
Reading MTrk Chunk
Track Name:'Trumpet'
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
Header.id='MTrk'
Header.size=4318
Reading MTrk Chunk
Track Name:'Trombone'
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
Header.id='MTrk'
Header.size=10524
Reading MTrk Chunk
Track Name:'Treble Strings'
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
Header.id='MTrk'
Header.size=13845
Reading MTrk Chunk
Track Name:'Contrabass'
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
Header.id='MTrk'
Header.size=2291
Reading MTrk Chunk
Track Name:'Timpani'
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
Header.id='MTrk'
Header.size=2303
Reading MTrk Chunk
Track Name:'Tuba'
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
Header.id='MTrk'
Header.size=2280
Reading MTrk Chunk
Track Name:'Pizzicato strings'
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
Tempo
Time signature
Time signature
Time signature
Time signature
End of track
*/
vec2 GetTrack0Note(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    return r;
}

vec2 GetTrack1ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,67) N(48,72) N(48,67) N(48,74) N(48,79) N(48,72) N(192,65) N(192,71) N(336,72) N(24,74) N(24,72)
    N(64,69) N(64,65) N(64,71) N(144,72) N(24,74) N(24,72) N(96,67) N(96,72) N(96,79) N(96,79) N(192,78)
    N(144,76) N(24,78) N(24,79) N(768,74) N(128,76) N(32,74) N(32,72) N(64,74) N(64,72) N(64,74) N(288,79)
    N(96,77) N(128,76) N(32,74) N(32,76) N(64,74) N(64,72) N(64,74) N(192,62) N(64,69) N(64,71) N(64,72)
    N(128,76) N(64,79) N(128,81) N(64,82) N(64,74) N(64,77) N(64,77) N(64,72) N(64,77) N(64,74) N(128,72)
    N(32,70) N(32,70) N(576,72) N(128,70) N(32,68) N(32,68) N(576,58) N(128,56) N(32,54) N(32,54) N(192,70)
    return r;
}

vec2 GetTrack1BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(2928,77) N(192,76) N(1920,81) N(192,77) N(128,75) N(32,74) N(32,74) N(576,75) N(128,73) N(32,72)
    N(32,72) N(576,61) N(128,59) N(32,58) N(32,58) N(192,73)
    return r;
}

vec2 GetTrack2ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,55) N(48,60) N(48,55) N(48,62) N(48,67) N(48,60) N(192,57) N(192,59) N(384,60) N(64,57) N(64,53)
    N(64,55) N(192,60) N(96,55) N(96,57) N(96,57) N(96,69) N(192,62) N(192,62) N(768,62) N(192,60) N(192,67)
    N(128,67) N(32,67) N(32,67) N(192,58) N(192,55) N(192,62) N(128,62) N(32,62) N(32,62) N(64,69) N(64,71)
    N(64,72) N(128,71) N(32,69) N(32,71) N(64,67) N(64,74) N(64,74) N(64,74) N(64,72) N(32,70) N(32,72)
    N(64,72) N(64,77) N(64,74) N(128,72) N(32,70) N(32,70) N(576,72) N(128,70) N(32,68) N(32,68) N(576,61)
    N(128,59) N(32,58) N(32,58) N(192,70)
    return r;
}

vec2 GetTrack2BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(240,65) N(192,53) N(192,62) N(384,65) N(64,65) N(64,65) N(64,59) N(192,64) N(96,60) N(96,64) N(96,64)
    N(96,72) N(192,69) N(192,67) N(768,69) N(192,67) N(192,72) N(128,72) N(32,72) N(32,71) N(192,70) N(192,67)
    return r;
}

vec2 GetTrack2CNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(240,69) N(192,60) N(192,67) N(384,69) N(64,69) N(128,62) N(192,67) N(96,64) N(96,69) N(96,72) N(288,74)
    N(192,71) N(1536,74)
    return r;
}

vec2 GetTrack2DNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(1200,67) N(288,67) N(192,76)
    return r;
}

vec2 GetTrack3ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,79) N(48,84) N(48,79) N(48,86) N(48,91) N(48,77) N(192,65) N(192,71) N(336,84) N(24,86) N(24,84)
    N(64,81) N(64,77) N(64,83) N(144,84) N(24,86) N(24,76) N(96,72) N(96,67) N(96,76) N(96,72) N(192,69)
    N(144,76) N(24,78) N(24,67) N(768,69) N(128,76) N(32,74) N(32,67) N(64,67) N(64,67) N(64,60) N(192,59)
    N(192,74) N(128,76) N(32,74) N(32,64) N(64,62) N(64,60) N(64,62) N(192,74) N(192,72) N(192,71) N(192,82)
    N(192,81) N(192,62) N(384,68) N(384,60) N(384,66) N(384,58) N(384,73)
    return r;
}

vec2 GetTrack3BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(240,81) N(192,72) N(192,79) N(768,79) N(96,76) N(96,72) N(96,81) N(96,69) N(192,74) N(144,88) N(24,90)
    N(24,86) N(768,77) N(192,76) N(64,74) N(64,72) N(64,72) N(192,67) N(192,70) N(192,67) N(64,67) N(64,72)
    N(64,66) N(192,62) N(384,67) N(192,74) N(192,72) N(192,77) N(384,74) N(384,75) N(384,72) N(384,73)
    return r;
}

vec2 GetTrack3CNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(240,84) N(192,77) N(192,83) N(768,84) N(96,79) N(96,84) N(96,91) N(96,81) N(192,81) N(192,91) N(768,74)
    N(192,72) N(192,74) N(192,71) N(192,77) N(192,76) N(64,74)
    return r;
}

vec2 GetTrack3DNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(1776,91) N(192,90)
    return r;
}

vec2 GetTrack4ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(0,43) N(48,48) N(48,43) N(48,50) N(48,57) L(48,53,12) L(24,41,12) L(24,53,12) L(24,41,12) L(24,53,12)
    L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12)
    L(24,53,12) L(24,53,12) L(24,41,12) L(24,53,12) L(24,41,12) L(24,53,12) L(24,41,12) L(24,41,12) L(24,41,12)
    L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12)
    N(24,48) N(192,55) N(96,50) N(192,40) N(192,45) N(192,45) N(144,54) N(96,57) L(48,43,12) L(24,31,12)
    L(24,43,12) L(24,31,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,31,12) L(24,43,12) L(24,31,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) N(24,57) N(192,55) L(192,43,12) L(24,55,12) L(24,43,12) L(24,55,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,55,12) L(24,43,12) L(24,55,12) L(24,43,12) L(24,55,12) L(24,55,12)
    L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12)
    L(24,55,12) N(24,54) N(192,57) N(192,41) N(192,40) N(192,39) N(192,38) N(384,32) L(192,44,12) L(24,32,12)
    L(24,44,12) L(24,32,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12)
    L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) N(216,42) L(192,30,12) L(24,42,12) L(24,30,12)
    L(24,42,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12)
    L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) N(216,28) L(192,40,12) L(24,28,12) L(24,40,12)
    return r;
}

vec2 GetTrack4BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    L(240,41,12) L(24,53,12) L(24,41,12) L(24,53,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12)
    L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,53,12) L(24,41,12)
    L(24,53,12) L(24,41,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12)
    L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) N(24,41) N(192,41) N(96,41) N(576,38)
    N(144,38) N(96,38) L(48,31,12) L(24,43,12) L(24,31,12) L(24,43,12) L(24,31,12) L(24,31,12) L(24,31,12)
    L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12)
    L(24,31,12) L(24,43,12) L(24,31,12) L(24,43,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12)
    L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) N(24,38) N(192,40)
    L(192,55,12) L(24,43,12) L(24,55,12) L(24,43,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12)
    L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,43,12) L(24,55,12)
    L(24,43,12) L(24,55,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) N(24,50) N(192,52) N(192,53) N(192,52)
    N(192,51) N(192,50) N(384,44) L(192,32,12) L(24,44,12) L(24,32,12) L(24,44,12) L(24,32,12) L(24,32,12)
    L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12)
    L(24,32,12) N(216,30) L(192,42,12) L(24,30,12) L(24,42,12) L(24,30,12) L(24,42,12) L(24,42,12) L(24,42,12)
    L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12)
    N(216,40) L(192,28,12) L(24,40,12) L(24,28,12)
    return r;
}

vec2 GetTrack4CNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    L(252,41,12) L(24,41,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12)
    L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12)
    L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12)
    L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) N(204,50) L(972,31,12) L(24,31,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,31,12) L(24,31,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) N(24,43) N(204,52) L(204,55,12) L(24,55,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12)
    L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) N(24,55) L(1560,32,12)
    L(24,32,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12)
    L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) L(24,44,12) N(24,44) L(408,42,12) L(24,42,12) L(24,30,12)
    L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12) L(24,30,12)
    L(24,30,12) L(24,30,12) L(24,30,12) N(24,30) L(408,28,12) L(24,28,12)
    return r;
}

vec2 GetTrack4DNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    L(252,53,12) L(24,53,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12)
    L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12) L(24,41,12)
    L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12)
    L(24,53,12) L(24,53,12) L(24,53,12) L(24,53,12) N(24,53) L(1176,43,12) L(24,43,12) L(24,31,12) L(24,31,12)
    L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12)
    L(24,31,12) L(24,31,12) L(24,31,12) L(24,43,12) L(24,43,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12)
    L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12) L(24,31,12)
    N(24,31) L(408,43,12) L(24,43,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12)
    L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12) L(24,55,12)
    L(24,55,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12)
    L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) L(24,43,12) N(24,43) L(1560,44,12) L(24,44,12) L(24,32,12)
    L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12) L(24,32,12)
    L(24,32,12) L(24,32,12) L(24,32,12) N(24,32) L(408,30,12) L(24,30,12) L(24,42,12) L(24,42,12) L(24,42,12)
    L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12) L(24,42,12)
    L(24,42,12) N(24,42) L(408,40,12) L(24,40,12)
    return r;
}

vec2 GetTrack4ENote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(2928,50)
    return r;
}

vec2 GetTrack5ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(1008,36) N(288,41) N(192,40) N(192,45) N(192,38) N(144,38) N(96,38) N(48,43) N(24,43) N(24,43) N(24,43)
    N(24,43) N(24,43) N(24,43) N(24,43) N(24,43) N(24,43) N(24,43) N(24,43) N(24,43) N(24,43) N(24,43)
    N(24,43) N(24,43) N(96,43) N(96,43) N(96,43) N(96,50) N(192,52) N(192,55) N(384,46) N(192,48) N(192,38)
    return r;
}

vec2 GetTrack5BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(1008,41) N(288,50) N(876,38) N(24,38) N(24,38) N(24,38) N(24,38) N(24,38) N(24,38) N(24,38) N(24,38)
    N(24,38) N(24,38) N(24,38) N(24,38) N(24,38) N(24,38) N(24,38) N(396,38) N(192,40) N(192,43) N(768,50)
    return r;
}

vec2 GetTrack6ANote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(240,53) N(384,59) N(384,48) N(288,50) N(192,40) N(192,45) N(192,50) N(144,50) N(96,50) N(48,55)
    N(768,38) N(192,40) N(192,55) N(384,34) N(192,36) N(192,50) N(192,40) N(192,41) N(192,40) N(192,39)
    N(192,38) N(384,32) N(768,30) N(768,28)
    return r;
}

vec2 GetTrack6BNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(240,41) N(384,41) N(384,41) N(288,41) N(576,38) N(144,38) N(96,38) N(48,43) N(1152,43) N(384,53)
    N(192,48) N(192,38) N(192,52) N(192,53) N(192,52) N(192,51) N(192,50) N(384,44) N(768,42) N(768,40)
    return r;
}

vec2 GetTrack6CNote(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
    N(3696,46)
    return r;
}

vec2 GetTrack7Note(float x)
{
    vec2 r = vec2(-1.0);
    float t = 0.0;
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

float Sin( float t )
{
	return sin( t * radians(360.0) );
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
    float f = vFreqTime.x;
    float t = vFreqTime.y;
    
    if( t < 0.0 )
        return 0.0;
    float x = 0.0;
    float a = 0.5;
    float h = 1.0;
    float p = 0.0;
    for(int i=0; i<8; i++)
    {
        x += Sin( f * t * h + p ) * exp2( t * -a );
        x += Sin( f * (t+0.005) * h * 0.5 + p ) * exp2( t * -a * 2.0 ) ;
        //x += Sin( f * t * h + p ) * exp2( t * -a );
        //x += Sin( f * (t+0.005) * h * 0.5 + p ) * exp2( t * -a * 2.0 ) ;
        h = h + 1.01;
        a = a * 2.0;
        p += 0.1;
    }
    
    return x;
}

float Instr( const in vec2 vFreqTime )
{
    float f = vFreqTime.x;
    float t = vFreqTime.y;
    
    float d = f * t + Sin(f * t * 0.5) * exp2(t * -5.0) * 2.0;
    float x = Sin(d);
    
    return x * exp2(t * -1.0) * 2.0;
}


float Track1Instrument( const in vec2 vFreqTime )
{
    return Instr( vFreqTime );
}

float Track2Instrument( const in vec2 vFreqTime )
{
    return Instrument( vFreqTime ) * 0.5;
}

float Track3Instrument( const in vec2 vFreqTime )
{
    return 2.0 * (Tri(vFreqTime.x * vFreqTime.y) + Saw(vFreqTime.x * vFreqTime.y * 0.5 + 0.01) * 0.5) * Envelope(vFreqTime.y, 4.0);
}

float Track4Instrument( const in vec2 vFreqTime )
{
     return Instrument( vFreqTime ) * 0.2;
}


const float kMidiTimebase = 240.0;
const float kInvMidiTimebase = 1.0 / kMidiTimebase;

vec2 GetNoteData( const in vec2 vMidiResult, const in float fMidiTime )
{
    return vec2( NoteToHz(vMidiResult.x), abs(fMidiTime - vMidiResult.y) * kInvMidiTimebase );
}

float PlayMidi( const in float time )
{
#ifdef DISABLE_SOUND
	return 0.0;
#else
    if(time < 0.0)
		return 0.0;
    
    float fMidiTime = time * kMidiTimebase;
    
    float fResult = 0.0;
    
    fResult += Track1Instrument( GetNoteData( GetTrack1ANote(fMidiTime), fMidiTime ) );
    fResult += Track1Instrument( GetNoteData( GetTrack1BNote(fMidiTime), fMidiTime ) );
    //fResult += Track1Instrument( GetNoteData( GetTrack1CNote(fMidiTime), fMidiTime ) );

    fResult += Track2Instrument( GetNoteData( GetTrack2ANote(fMidiTime), fMidiTime ) );
    fResult += Track2Instrument( GetNoteData( GetTrack2BNote(fMidiTime), fMidiTime ) );
    fResult += Track2Instrument( GetNoteData( GetTrack2CNote(fMidiTime), fMidiTime ) );
    fResult += Track2Instrument( GetNoteData( GetTrack2DNote(fMidiTime), fMidiTime ) );

    fResult += Track3Instrument( GetNoteData( GetTrack3ANote(fMidiTime), fMidiTime ) );
    fResult += Track3Instrument( GetNoteData( GetTrack3BNote(fMidiTime), fMidiTime ) );
    fResult += Track3Instrument( GetNoteData( GetTrack3CNote(fMidiTime), fMidiTime ) );
    fResult += Track3Instrument( GetNoteData( GetTrack3DNote(fMidiTime), fMidiTime ) );

    fResult += Track4Instrument( GetNoteData( GetTrack4ANote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4BNote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4CNote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack4DNote(fMidiTime), fMidiTime ) );

    fResult += Track2Instrument( GetNoteData( GetTrack5ANote(fMidiTime), fMidiTime ) );
    fResult += Track2Instrument( GetNoteData( GetTrack5BNote(fMidiTime), fMidiTime ) );
    //fResult += Track2Instrument( GetNoteData( GetTrack5CNote(fMidiTime), fMidiTime ) );
    //fResult += Track2Instrument( GetNoteData( GetTrack5DNote(fMidiTime), fMidiTime ) );

    fResult += Track4Instrument( GetNoteData( GetTrack6ANote(fMidiTime), fMidiTime ) );
    fResult += Track4Instrument( GetNoteData( GetTrack6BNote(fMidiTime), fMidiTime ) );
    
    fResult = clamp(fResult * 0.05, -1.0, 1.0);
    /*
    float fFadeEnd = 20.0 * 240.0 / kMidiTimebase;
    float fFadeTime = 5.0;
    float fFade = (time - (fFadeEnd - fFadeTime)) / fFadeTime;    
    fResult *= clamp(1.0 - fFade, 0.0, 1.0);
    */
    return fResult;
#endif
}

vec2 mainSound( in int samp,float time)
{
    return vec2( PlayMidi(time ) );
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
