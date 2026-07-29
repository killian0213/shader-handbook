// Sound (sound) — [SH16C] Stubble Bobble by stubbe
// https://www.shadertoy.com/view/Mlt3Wn

const float BPM = 125.0;
const float SPEED = 6.0;
const float ROWS_PER_SEC = BPM * 24.0 / (60.0 * SPEED);
const float SEC_PER_ROW = 1.0 / ROWS_PER_SEC;

const int	PATTERN0_LENGTH = 153;
const int	PATTERN_LENGTH = 64;
const int 	NUM_PATTERNS = 7;

const float PI = 3.1415926535;

const int C  = 0;
const int Cs = 1;
const int D  = 2;
const int Ds = 3;
const int E  = 4;
const int F  = 5;
const int Fs = 6;
const int G  = 7;
const int Gs = 8;
const int A  = 9;
const int As = 10;
const int B  = 11;
const int X  = -1;

#define N(_pos, _note, _octave) if(row >= (_pos)) { note = ((_octave)*12 + (_note)); hitRow = baseRow + (_pos); }

int imod(int x, int m)
{
    return x - x / m * m;
}

int Data(float time, int track, out float envTime)
{
    int globalRow = int(time * ROWS_PER_SEC);
    
    int baseRow = 0;
    int pattern = 0;
    int row = globalRow;
    
    if(globalRow >= PATTERN0_LENGTH)
    {
        int m = NUM_PATTERNS - 1;
        
        int tmp = globalRow - PATTERN0_LENGTH;
        
        row = imod(tmp, PATTERN_LENGTH);
        
        pattern = tmp / PATTERN_LENGTH;
        int numRepeats = pattern / m;
        pattern = imod(pattern, m);
        
        baseRow = PATTERN0_LENGTH + (numRepeats*m+pattern) * PATTERN_LENGTH;
        pattern++;
    }
    
    int hitRow = -10;
    int note = 0;
    if(track == 0)
    {
        if(pattern == 0)
        {
            N( 0,  B, 0) N( 1,  C, 1) N( 2,  D, 1) N( 3,  E, 1) N( 4,  F, 1) N( 5,  G, 1) N( 6,  A, 1) N( 7,  B, 1) N( 8,  C, 2) 
            N( 9,  D, 2) N(10,  E, 2) N(11,  F, 2) N(12,  G, 2) N(13,  A, 2) N(14,  C, 3) N(20,  X, 0)         
            //break between splash and intro. Currently 60 beats.
            N(80,  C, 2) N(86,  C, 2) N(90,  B, 1) N(92,  A, 1)
            N(96,  B, 1) N(98,  C, 2) N(100, D, 2) N(102, G, 1) N(108,  B, 1)
            N(112, A, 1) N(118, E, 1) N(124, B, 1)
            N(128, C, 2) N(132, D, 2) N(139, E, 2) N(146, Fs, 2)
        }
        else if(pattern == 1)
        {
            N( 0,  G, 2) N( 2, Fs, 2) N( 4,  E, 2) N( 7,  D, 2) N( 8, Fs, 2) N(10,  E, 2) N(12,  D, 2) N(15,  C, 2)
            N(16,  E, 2) N(18,  D, 2) N(20,  C, 2) N(21,  B, 1) N(24,  D, 2) N(30,  B, 1) N(31,  A, 1) 
            N(32,  G, 1) N(34,  A, 1) N(36,  B, 1) N(38,  C, 2) N(40,  A, 1) N(42,  B, 1) N(43,  C, 2) N(46,  D, 2)
            N(48,  D, 2) N(50,  E, 2) N(52, Fs, 2) N(53,  E, 2) N(56,  D, 2) N(58,  D, 2) N(60,  E, 2) N(62, Fs, 2) 
        }
        else if(pattern == 2)
        {
            N( 0,  G, 2) N( 2, Fs, 2) N( 4,  E, 2) N( 7,  D, 2) N( 8, Fs, 2) N(10,  E, 2) N(12,  D, 2) N(15,  C, 2)
            N(16,  E, 2) N(18,  D, 2) N(20,  C, 2) N(21,  B, 1) N(24,  D, 2) N(30,  B, 1) N(31,  A, 1) 
            N(32,  G, 1) N(34,  A, 1) N(36,  B, 1) N(38,  C, 2) N(40,  A, 1) N(42,  B, 1) N(43,  C, 2) N(46,  D, 2)
            N(48,  D, 2) N(50,  E, 2) N(52, Fs, 2) N(53,  D, 2) N(56,  G, 2) N(58,  D, 2) N(60,  E, 2) N(62, Fs, 2) 
        }
        else if(pattern == 3)
        {
            N( 0, Fs, 2) N(10,  D, 2) N(12,  E, 2) N(14, Fs, 2)
            N(16,  G, 2) N(26,  D, 2) N(28,  E, 2) N(30, Fs, 2)
            N(32,  A, 2) N(42,  D, 2) N(44,  E, 2) N(46, Fs, 2)
            N(48,  B, 2) N(58,  G, 2) N(60,  A, 2) N(62,  B, 2)
        }
        else if(pattern == 4)
        {
            N( 0,  C, 3) N( 2,  C, 3) N( 6,  C, 3) N(10,  B, 2) N(12,  A, 2)
            N(16,  B, 2) N(28,  B, 2)
            N(32,  A, 2) N(38,  E, 2) N(44,  B, 2) N(48,  A, 2) 
            N(58,  D, 2) N(60,  E, 2) N(62,  Fs, 2) 
        }
        else if(pattern == 5)
        {
            N( 0, Fs, 2) N(10,  D, 2) N(12,  E, 2) N(14, Fs, 2)
            N(16,  G, 2) N(26,  D, 2) N(28,  E, 2) N(30, Fs, 2)
            N(32,  A, 2) N(42,  D, 2) N(44,  E, 2) N(46, Fs, 2)
            N(48,  B, 2) N(58,  G, 2) N(60,  A, 2) N(62,  B, 2)
        }
        else if(pattern == 6)
        {
            N( 0,  C, 3) N( 2,  C, 3) N( 6,  C, 3) N(10,  B, 2) N(12,  A, 2)
            N(16,  B, 2) N(28,  B, 2)
            N(32,  A, 2) N(38,  D, 2) N(42,  B, 2) N(44,  D, 2) N(46,  B, 2)
            N(48,  G, 2) N(56,  X, 0) N(58,  D, 2) N(60,  E, 2) N(62, Fs, 2) 
        }
    }
    else if(track == 1)
    {
        if(pattern == 0)
            
        {
            N(50, C, 1) 
            N(66,  G, 1)
            N(82,  A, 1)
            N(98,  D, 1) N(102,  D, 1) N(109,  E, 1) N(116, Fs, 1)

        }
        else if(pattern == 1)
        {
            N( 0,  G, 1) N( 2,  G, 2) N( 4,  G, 1) N( 6,  G, 2) N( 8,  G, 1) N(10,  G, 2) N(12,  G, 1) N(14,  G, 2)
            N(16,  G, 1) N(18,  G, 2) N(20,  G, 1) N(22,  G, 2) N(24,  G, 1) N(26,  G, 2) N(28,  G, 1) N(30,  G, 2)
            N(32,  E, 0) N(34,  E, 1) N(36,  E, 0) N(38,  E, 1) N(40,  E, 0) N(42,  E, 1) N(44,  E, 0) N(46,  E, 1)
            N(48,  E, 0) N(50,  E, 1) N(52,  E, 0) N(54,  E, 1) N(56,  E, 0) N(58,  E, 1) N(60,  E, 0) N(62,  E, 1)
        }
        else if(pattern == 2)
        {
            N( 0,  G, 1) N( 2,  G, 2) N( 4,  G, 1) N( 6,  G, 2) N( 8,  G, 1) N(10,  G, 2) N(12,  G, 1) N(14,  G, 2)
            N(16,  G, 1) N(18,  G, 2) N(20,  G, 1) N(22,  G, 2) N(24,  G, 1) N(26,  G, 2) N(28,  G, 1) N(30,  G, 2)
            N(32,  E, 0) N(34,  E, 1) N(36,  E, 0) N(38,  E, 1) N(40,  E, 0) N(42,  E, 1) N(44,  E, 0) N(46,  E, 1)
            N(48,  E, 0) N(50,  E, 1) N(52,  E, 0) N(54,  E, 1) N(56,  G, 0) N(58,  D, 0) N(60,  E, 0) N(62,  F, 0)
        }
        else if(pattern == 3 || pattern == 5)
        {
            N( 0, Fs, 0) N( 2, Fs, 1) N( 4, Fs, 0) N( 6, Fs, 1) N( 8, Fs, 0) N(10,  D, 0) N(12,  E, 0) N(14, Fs, 0)
            N(16,  G, 0) N(18,  G, 1) N(20,  G, 0) N(22,  G, 1) N(24,  G, 0) N(26,  D, 0) N(28,  E, 0) N(30,  F, 0)
            N(32, Fs, 0) N(34, Fs, 1) N(36, Fs, 0) N(38, Fs, 1) N(40, Fs, 0) N(42,  D, 0) N(44,  E, 0) N(46, Fs, 0)
            N(48,  G, 0) N(50,  G, 1) N(52,  G, 0) N(54,  G, 1) N(56,  G, 0) N(58,  G, 0) N(60,  A, 1) N(62,  B, 1)
        }
        else if(pattern == 4)
        {
            N( 0,  C, 1) N( 2,  C, 2) N( 4,  C, 1) N( 6,  C, 2) N( 8,  C, 1) N(10,  C, 2) N(12,  C, 1) N(14,  C, 2)
            N(16,  B, 0) N(18,  B, 1) N(20,  B, 0) N(22,  B, 1) N(24,  B, 0) N(26,  B, 1) N(28,  B, 0) N(30,  B, 1)
            N(32,  A, 0) N(34,  A, 1) N(36,  A, 0) N(38,  A, 1) N(40,  E, 0) N(42,  E, 1) N(44,  E, 0) N(46,  E, 1)
            N(48,  A, 0) N(50,  A, 1) N(52,  A, 0) N(54,  A, 1) N(56,  A, 0) 
        }
        else if(pattern == 6)
        {
            N( 0,  C, 1) N( 2,  C, 2) N( 4,  C, 1) N( 6,  C, 2) N( 8,  C, 1) N(10,  C, 2) N(12,  C, 1) N(14,  C, 2)
            N(16,  B, 0) N(18,  B, 1) N(20,  B, 0) N(22,  B, 1) N(24,  B, 0) N(26,  B, 1) N(28,  B, 0) N(30,  B, 1)
            N(32,  A, 0) N(34,  A, 1) N(36,  A, 0) N(38,  A, 1) N(40,  D, 0) N(42,  A, 0) N(44,  D, 0) N(46,  A, 0)
            N(48,  G, 0) N(56,  X, 0) N(58,  D, 0) N(60,  E, 1) N(62, Fs, 1) 
        }
    }
    else if(track == 2)
    {
        if(pattern == 3 || pattern == 5)
        {
            N( 2,  D, 3) N( 4,  E, 3) N( 6,  F, 3) N( 8, Fs, 3)
            N(18,  D, 3) N(20,  E, 3) N(22, Fs, 3) N(24,  G, 3)
            N(34,  D, 3) N(36,  E, 3) N(38, Fs, 3) N(40,  A, 3)
            N(50,  D, 3) N(52,  E, 3) N(54, Fs, 3) N(56,  B, 3)
        }
    }
    
    envTime = time - float(hitRow)*SEC_PER_ROW;
    
    return note;
}

float Square(float x, float threshold)
{
    return fract(x) > threshold ? 1.0 : -1.0;
}

float Square2(float x, float threshold, float detune)
{
    return (Square(x-detune, threshold) + Square(x+detune, threshold))*.5;
}
    
vec2 mainSound( in int samp, float time )
{
    float threshold = sin(time*5.)*.1+.5;
    
    float envTime0;
    float envTime1;
    float envTime2;
    float envTime3;
    
    int note0 = Data(time, 0, envTime0);
    int note1 = Data(time, 1, envTime1);
    int note2 = Data(time, 2, envTime2);
    int note3 = Data(time - SEC_PER_ROW, 0, envTime3);
    
    float freq0 = 440.0*pow(2.0, float(note0)/12.0)*.5*.5;
    float freq1 = 440.0*pow(2.0, float(note1)/12.0)*.5*.5;
    float freq2 = 440.0*pow(2.0, float(note2)/12.0)*.5*.5;
    float freq3 = 440.0*pow(2.0, float(note3)/12.0)*.5*.5;
    
    float v = 0.0;
    v += Square(envTime0*freq0, .5) * exp(-envTime0*.1) * float(note0 >= 0);
    v += Square(envTime3*freq3, .5) * exp(-envTime3*.1) * float(note0 >= 0) * .2;
    v += Square2(envTime1*freq1*.5*.5, threshold, 0.03) * float(note0 >= 0);
    v += Square(envTime2*freq2, .5) * exp(-envTime2*2.) * float(note0 >= 0);
    
    return vec2(v*.1);
}