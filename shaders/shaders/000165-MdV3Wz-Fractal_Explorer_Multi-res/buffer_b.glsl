// Buffer B (buffer) — Fractal Explorer Multi-res. by Dave_Hoskins
// https://www.shadertoy.com/view/MdV3Wz

// Fractal Explorer Multi-res. January 2016
// by David Hoskins
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://www.shadertoy.com/view/MdV3Wz

// Mandalay fractal. Thanks to 'rebb' for the fractal fomula reference in Fractal city_242.
// Here:- https://www.shadertoy.com/view/MsK3DR


//--------------------------------------------------------------------------
#define TAU 6.28318530718

//--------------------------------------------------------------------------
vec3 loadValue3( in vec2 re )
{
    return texture( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 ).xyz;
}
vec2 loadValue2( in vec2 re )
{
    return texture( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 ).xy;
}

//----------------------------------------------------------------------------------------

//--------------------------------------------------------------------------

float SphereRadius(in float t)
{
    t = t * .001*(500./iResolution.y);
    return (t*2.5);
}
//--------------------------------------------------------------------------
float binarySubdivision(in vec3 rO, in vec3 rD, vec2 t)
{
	// Home in on the surface by dividing by two and split...
    float halfwayT;
	for (int n = 0; n < 4; n++)
	{
		halfwayT = (t.x + t.y) * .5;
        (Map(rO + halfwayT*rD) < SphereRadius(t.x)) ? t.x = halfwayT:t.y = halfwayT;
	}
	return halfwayT;
}
//--------------------------------------------------------------------------
float Scene(in vec3 rO, in vec3 rD, vec2 uv)
{

	float t = hash12(uv)*.05;
    float oldT = t;

	
	vec3 p = vec3(0.0);

	for( int j=0; j < 80; j++ )
	{
		if (t > 7.0) break;
		p = rO + t*rD;
		
		float de = Map(p);
		if(abs(de) < .1) break;
        
       oldT = t;
		t +=  de;
	}
    //if (t < 7.0) t = binarySubdivision(rO, rD, vec2(t, oldT));

	return max(t, 0.01);
}

//--------------------------------------------------------------------------
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
	float m = (iMouse.x/iResolution.x)*20.0;
	float gTime = ((iTime+26.)*.2+m);
    
    // Only use a quarter of the screen for first pass...
    vec2 xy = fragCoord.xy / iResolution.xy;
    if(xy.x > .5 || xy.y > .5) discard;
    xy *= 2.0;
	vec2 uv = (-1. + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
    
   
    vec3 cameraPos = texture( iChannel0, vec2(.5,.5)/iResolution.xy, -100.0 ).xyz;
    vec2 camRot = texture( iChannel0, vec2(1.5,.5)/iResolution.xy, -100.0 ).xy;

    camRot*= TAU;

	vec3 dir = normalize( vec3(uv, sqrt(max(1.2 - dot(uv.xy, uv.xy)*.1, 0.))));
    dir =  normalize(dir);

    float roll = .05 * sin(iTime*.3);
    dir.xy = dir.xy*cos(roll) + sin(roll)*vec2(1,-1)*dir.yx;
    dir.zy = dir.zy*cos(camRot.x) + sin(camRot.x)*vec2(1,-1)*dir.yz;
    dir.xz = dir.xz*cos(camRot.y) + sin(camRot.y)*vec2(1,-1)*dir.zx;
  
    float dis = Scene(cameraPos, dir, fragCoord);
	
	fragColour = vec4(dis);
}

//--------------------------------------------------------------------------