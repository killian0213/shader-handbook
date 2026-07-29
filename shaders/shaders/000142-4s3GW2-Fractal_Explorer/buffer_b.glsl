// Buffer B (buffer) — Fractal Explorer by Dave_Hoskins
// https://www.shadertoy.com/view/4s3GW2

// Flying camera code...
// by David Hoskins
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define TAU 6.28318530718


const float KEY_W		= 87.5/256.0;
const float KEY_A		= 65.5/256.0;
const float KEY_S		= 83.5/256.0;
const float KEY_D		= 68.5/256.0;
const float KEY_LEFT  = 37.5/256.0;
const float KEY_UP    = 38.5/256.0;
const float KEY_RIGHT = 39.5/256.0;
const float KEY_DOWN  = 40.5/256.0;

const float KEY_SPACE	= 32.5/256.0;
const float KEY_SHIFT	= 16.5/256.0;


vec2 clickStoreA = vec2(4.0,  0.0);
vec2 camStore = vec2(0.0,  0.0);
vec2 rotationStore	= vec2(1.,  0.);
vec2 mouseStore = vec2(2.,  0.);
vec2 startStore		= vec2(3.,  0.);
vec2 timeStore = vec2(6.0,  0.0);


bool isKeyPressed(float key)
{
	return texture( iChannel2, vec2(key, 0.25) ).x > .0;
}
float isInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }
vec4 loadValue4( in vec2 re )
{
    return texture( iChannel1, (0.5+re) / iChannelResolution[1].xy, -100.0 );
}
vec3 loadValue3( in vec2 re )
{
    return texture( iChannel1, (0.5+re) / iChannelResolution[1].xy, -100.0 ).xyz;
}
vec2 loadValue2( in vec2 re )
{
    return texture( iChannel1, (0.5+re) / iChannelResolution[1].xy, -100.0 ).xy;
}
float loadValue1( in vec2 re )
{
    return texture( iChannel1, (0.5+re) / iChannelResolution[0].xy, -100.0 ).x;
}
float loadValueA1( in vec2 re )
{
    return texture( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 ).x;
}

void storeValue4( in vec2 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord, re) > 0.0 ) ? va : fragColor;
}
void storeValue3( in vec2 re, in vec3 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord, re) > 0.0 ) ? vec4(va, 0.0) : fragColor;
}

void storeValue2( in vec2 re, in vec2 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord, re) > 0.0 ) ? vec4(va, .0, .0) : fragColor;
}
void storeValue1( in vec2 re, in float va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord, re) > 0.0 ) ? vec4(va, .0, .0, .0) : fragColor;
}
vec2 rot2D(inout vec2 p, float a)
{
    return cos(a)*p - sin(a) * vec2(p.y, -p.x);
}

mat3 RotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
   	fragColour = vec4(0);
    
    
	vec2 tempStart 	= loadValue2(startStore);
	float click 	= loadValueA1(clickStoreA);
    float time 		= loadValue1(timeStore);
    
    vec3 camPos;
    vec2 rot;
    if (iFrame == 0)
    {
        camPos = vec3(-13.0,-1.2,2.5);
        rot = vec2(.2, 0.);
    }else
    {
        camPos = loadValue3(camStore);
        rot 		= loadValue2(rotationStore);
    }


    vec4 mouse = iMouse /iResolution.xyxy;
    
    if (click > 0.0)
    {
    	tempStart = mouse.xy;// First clicked
    }
    if (mouse.z > 0.0)
    	rot += mouse.xy - tempStart;
    
    
	storeValue2(startStore, tempStart,  fragColour, fragCoord);
	storeValue2(rotationStore, rot,  fragColour, fragCoord);
    
    rot*= TAU;
    mat3 mX = RotationMatrix(vec3(1.0, .0, .0), rot.y);
    mat3 mY = RotationMatrix(vec3(.0, 1.0, 0.0), -rot.x);
    mX = mY * mX;
    
       
    
 
	
    time = iTime - time;
    float speed = time*.4;
    if (isKeyPressed(KEY_SPACE) || isKeyPressed(KEY_SHIFT)) speed*=2.0;
    if (isKeyPressed(KEY_W) || isKeyPressed(KEY_UP))
	{
		camPos += mX * vec3(0,0,1)* speed;
	}
    if (isKeyPressed(KEY_S) || isKeyPressed(KEY_DOWN))
	{
		camPos += mX * vec3(0,0,-1)* speed;
    }
  	if (isKeyPressed(KEY_D) || isKeyPressed(KEY_RIGHT))
	{
		camPos += mX * vec3(1,0,0)* speed;
	}
	if (isKeyPressed(KEY_A) || isKeyPressed(KEY_LEFT))
	{
		camPos += mX * vec3(-1,0,0) * speed;
	}
    storeValue3(camStore, camPos,  fragColour, fragCoord);
    storeValue1(timeStore, iTime,  fragColour, fragCoord);
            
}