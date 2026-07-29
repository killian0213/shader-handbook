// Sound (sound) — R Tape loading error, 0:1 by P_Malin
// https://www.shadertoy.com/view/lsl3Rn

// Border phases

const float kPhaseBlank = 0.0;
const float kPhaseSilent = 1.0;
const float kPhaseHeader = 2.0;
const float kPhaseData = 3.0;
const float kPhaseRunning = 4.0;
 
// Loading phases

const vec3 vTimeSilent1  = vec3(1.0,	5.0,                       kPhaseSilent);
const vec3 vTimeHeader1  = vec3(2.0,  vTimeSilent1.y + 2.0,      kPhaseHeader);
const vec3 vTimeData1    = vec3(3.0,  vTimeHeader1.y + 0.125,    kPhaseData);
 
const vec3 vTimeBlank2   = vec3(4.0,  vTimeData1.y + 1.0,        kPhaseBlank);
const vec3 vTimeSilent2  = vec3(5.0,  vTimeBlank2.y + 2.0,       kPhaseSilent);
const vec3 vTimeHeader2  = vec3(6.0,  vTimeSilent2.y + 2.0,      kPhaseHeader);
const vec3 vTimeData2    = vec3(7.0,  vTimeHeader2.y + 1.0,      kPhaseData);
 
const vec3 vTimeSilent3  = vec3(8.0,  vTimeData2.y + 2.0,        kPhaseSilent);
const vec3 vTimeHeader3  = vec3(9.0,  vTimeSilent3.y + 2.0,      kPhaseHeader);
const vec3 vTimeData3    = vec3(10.0, vTimeHeader3.y + 0.125,    kPhaseData);
 
const vec3 vTimeSilent4  = vec3(11.0, vTimeData3.y + 2.0,        kPhaseSilent);
const vec3 vTimeHeader4  = vec3(12.0, vTimeSilent4.y + 2.0,      kPhaseHeader);
const vec3 vTimeData4    = vec3(13.0, vTimeHeader4.y + 38.0,     kPhaseData);
 
const vec3 vTimeRunning  = vec3(14.0, vTimeData4.y + 10.0,       kPhaseRunning);
 
const vec3 vTimeTotal    = vec3(15.0, vTimeRunning.y,            kPhaseBlank);
       
vec4 GetPhase(float fTime)
{             
    vec3 vResult = vTimeRunning;

    vResult = mix( vResult, vTimeData4, step(fTime, vTimeData4.y ) );
    vResult = mix( vResult, vTimeHeader4, step(fTime, vTimeHeader4.y ) );
    vResult = mix( vResult, vTimeSilent4, step(fTime, vTimeSilent4.y ) );

    vResult = mix( vResult, vTimeData3, step(fTime, vTimeData3.y ) );
    vResult = mix( vResult, vTimeHeader3, step(fTime, vTimeHeader3.y ) );
    vResult = mix( vResult, vTimeSilent3, step(fTime, vTimeSilent3.y ) );

    vResult = mix( vResult, vTimeData2, step(fTime, vTimeData2.y ) );
    vResult = mix( vResult, vTimeHeader2, step(fTime, vTimeHeader2.y ) );
    vResult = mix( vResult, vTimeSilent2, step(fTime, vTimeSilent2.y ) );
    vResult = mix( vResult, vTimeBlank2, step(fTime, vTimeBlank2.y ) );

    vResult = mix( vResult, vTimeData1, step(fTime, vTimeData1.y ) );
    vResult = mix( vResult, vTimeHeader1, step(fTime, vTimeHeader1.y ) );
    vResult = mix( vResult, vTimeSilent1, step(fTime, vTimeSilent1.y ) );

    return vec4(vResult.z, vResult.x, fTime - vResult.y, vResult.y);
}

// Thanks Dave_Hoskins for the hash - https://www.shadertoy.com/view/4djSRW
float hash(const in float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

float GetAudio(float fTime)
{
    float fPhase = GetPhase(fTime).x;
	
    float fLoadScreenTime = fTime - vTimeHeader4.y;
    
    float fSignal = 0.0;
	
	if(fPhase == kPhaseBlank)
	{                       
		fSignal = 0.0;           
	}
	else  
	if(fPhase == kPhaseSilent)
	{
		fSignal = 0.0;          
	}
	else
	if(fPhase == kPhaseHeader)
	{
		float fFreq = 3500000.0 / 2168.0;
        fFreq *= 0.5;
		float fBlend = step(fract(fTime * fFreq), 0.5);
		fSignal = fBlend;           
	}
	else
	if(fPhase == kPhaseData)
	{
		float fFreq = 3500000.0 / 1710.0;
        float fWaveTime = fTime * fFreq;

        float fDataHashPos = floor(fWaveTime);
        
        // Attribute loading sounds
        float kAttributeStart = 256.0 * 192.0 / 8.0;    
        float kAttributeEnd = kAttributeStart + (32.0 * 24.0);    
        float fAddressLoaded = fLoadScreenTime * 192.0;
		if( (fAddressLoaded > kAttributeStart) && (fAddressLoaded < kAttributeEnd) )
        {
            fDataHashPos = mod(fDataHashPos, 8.0);
        }

        
        float fValue = hash(fDataHashPos);
        
        
        float fr = fract(fWaveTime);
        if(fValue > 0.5)
        {
            fr = fract(fr * 2.0);
        }
        float fBlend = step(fr, 0.5);

		fSignal = fBlend;                   
	}
	
	return fSignal;
}
 

vec2 mainSound( in int samp,float time)
{
    return vec2( GetAudio(time) * 2.0 - 1.0 ) * 0.2;
}