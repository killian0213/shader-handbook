// Image (image) — Fractal Explorer Multi-res. by Dave_Hoskins
// https://www.shadertoy.com/view/MdV3Wz

// Fractal Explorer Multi-res. January 2016
// by David Hoskins
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://www.shadertoy.com/view/MdV3Wz

// Mandalay fractal. Thanks to 'rebb' for the fractal fomula reference in Fractal city_242.
// Here:- https://www.shadertoy.com/view/MsK3DR

// Enable antialiasing...
//w#define ANTIALIAS

// * * CONTROLS * *
// WASD or CURSOR keys
// Mouse drag to turn.
// SHIFT or SPACE for 2X speed

//--------------------------------------------------------------------------
#define SUN_COLOUR vec3(1., .95, .9)
#define FOG_COLOUR vec3(.12, 0.13, 0.14)
#define HASHSCALE .1031
#define TAU 6.28318530718

vec2 fcoord;

vec2 camStore = vec2(4.0,  0.0);
vec2 rotationStore	= vec2(1.,  0.);
vec3 sunLight  = normalize(vec3(  0.4, 0.7,  0.4 ));


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
// From https://www.shadertoy.com/view/4djSRW

//----------------------------------------------------------------------------------------
float Noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = texture( iChannel2, (uv+ 0.5)/256.0).yx;
	return mix( rg.x, rg.y, f.z );
}
vec3 GetSky(vec3 pos)
{
    pos *= 2.;
    pos -= iTime*.08;
	float t = Noise(pos);
    t += Noise(pos * 2.1) * .5;
    t += Noise(pos * 4.3) * .25;
    t += Noise(pos * 7.9) * .125;
	return (t * 0.7+.6) *FOG_COLOUR *.6;
}
//----------------------------------------------------------------------------------------
//--------------------------------------------------------------------------
float Shadow( in vec3 ro, in vec3 rd)
{
	float res = 1.0;
    float t = 0.06;
	float h;
	
    for (int i = 0; i < 5; i++)
	{
		h = Map( ro + rd*t );
		res = min(4.5*h / t, res);
		t += h+.2;
	}
    return max(res, 0.0);
}

//--------------------------------------------------------------------------
vec3 DoLighting(in vec3 mat, in vec3 pos, in vec3 normal, in vec3 eyeDir, in float d, in float sh)
{
    vec3 sunLight  = normalize( vec3(  0.4, 0.4,  0.3 ) );
//	sh = Shadow(pos,  sunLight);
    // Light surface with 'sun'...
	vec3 col = mat * SUN_COLOUR*(max(dot(sunLight,normal), 0.0)) *sh;
    col += mat *(max(dot(-sunLight,normal), 0.0))*.5;
    
    normal = reflect(eyeDir, normal); // Specular...
    col += pow(max(dot(sunLight, normal), 0.0), 10.0)  * SUN_COLOUR * .4 *sh;
    // Abmient..
    col += mat * .2 * max(normal.y, 0.3)+.011;
    
    
	return col;
}

//--------------------------------------------------------------------------
vec3 GetNormal(vec3 p, float sphereR)
{
	vec2 eps = vec2(sphereR, 0.0);
	return normalize( vec3(
           Map(p+eps.xyy) - Map(p-eps.xyy),
           Map(p+eps.yxy) - Map(p-eps.yxy),
           Map(p+eps.yyx) - Map(p-eps.yyx) ) );
}


//--------------------------------------------------------------------------
float binarySubdivision(in vec3 rO, in vec3 rD, vec2 t)
{
	// Home in on the surface by dividing by two and split...
    float halfwayT;
	for (int n = 0; n < 4; n++)
	{
		halfwayT = (t.x + t.y) * .5;
        (Map(rO + halfwayT*rD) < 0.002) ? t.x = halfwayT:t.y = halfwayT;
	}
	return halfwayT;
}

//--------------------------------------------------------------------------
float Scene(in vec3 rO, in vec3 rD, in float t)
{
	
	vec3 p = vec3(0.0);
    //t -= hash13(rO+rD+t)*.1;
    float oldT = t;

	for( int j=0; j < 100; j++ )
	{
		if (t > 7.0) break;
		p = rO + t*rD;
		float de = Map(p);
		if(abs(de) < 0.002) break;
        oldT = t;
		t +=  de*.8;
	}
    if (t < 7.0) t = binarySubdivision(rO, rD, vec2(t, oldT));
	return t;
}

float calcOcc( in vec3 pos, in vec3 nor)
{
	float occ = 0.0;
    float sca = 1.0;
    for(float h= 0.02; h < .05; h+= .01)
    {
		vec3 opos = pos + h*nor;
        float d = Map(opos);
        occ += (h-d)*sca;
        //sca *= 0.5;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}


//--------------------------------------------------------------------------
vec3 PostEffects(vec3 rgb, vec2 xy)
{
	// Gamma first...


    rgb = rgb*rgb * (3.0-2.0*rgb);
   	rgb = pow(rgb, vec3(0.45));
    rgb  = rgb * 2.;

	// Vignette...
    rgb *= .7+0.5*pow(250.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.3);	


	return clamp(rgb, 0.0, 1.0);
}

//--------------------------------------------------------------------------
vec3 TexCube( sampler2D sam, in vec3 p, in vec3 n )
{
	vec3 x = texture( sam, p.yz ).xzy;
	vec3 y = texture( sam, p.zx ).xyz;
	vec3 z = texture( sam, p.xy ).yzx;
	return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))/(abs(n.x)+abs(n.y)+abs(n.z));
}

//----------------------------------------------------------------------------------------
vec2 rot2D(inout vec2 p, float a)
{
    return cos(a)*p - sin(a) * vec2(p.y, -p.x);
}

//--------------------------------------------------------------------------
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{

	float m = (iMouse.x/iResolution.x)*20.0;
	float gTime = ((iTime+26.)*.2+m);
    vec2 xy = fragCoord.xy / iResolution.xy;
	vec2 uv = (-1. + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
    
    vec3 cameraPos = texture( iChannel0, vec2(.5,.5)/iResolution.xy, -100.0 ).xyz;
    vec2 camRot = texture( iChannel0, vec2(1.5,.5)/iResolution.xy, -100.0 ).xy;
    camRot*= TAU;
   
	// Recorded distance so far..
    float recDis = texture( iChannel1, xy*.5, -100.0 ).x;

    vec3 col = vec3(.0);
    vec3 sky = vec3(-1);
    
    
#ifdef ANTIALIAS
    for (int y = 0; y < 2; y++)
    {
    	for (int x = 0; x < 2; x++)
        {
            vec3 dir = normalize( vec3(uv+vec2(x,y)/iResolution.xy, sqrt(max(1.2 - dot(uv.xy, uv.xy)*.1, 0.))));
#else
			vec3 dir = normalize( vec3(uv, sqrt(max(1.2 - dot(uv.xy, uv.xy)*.1, 0.))));
                                       

#endif
            dir =  normalize(dir);

            float roll = .05 * sin(iTime*.3);
            dir.xy = dir.xy*cos(roll) + sin(roll)*vec2(1,-1)*dir.yx;
            dir.zy = dir.zy*cos(camRot.x) + sin(camRot.x)*vec2(1,-1)*dir.yz;
            dir.xz = dir.xz*cos(camRot.y) + sin(camRot.y)*vec2(1,-1)*dir.zx;

            float dis = Scene(cameraPos, dir, recDis);
            if (sky.x < 0.0)  sky = GetSky(dir);
            if (dis < 7.0)
            {
                vec3 pos = cameraPos + dir * dis;
                
                vec3 normal = GetNormal(pos, 0.002);

                float sha = Shadow(pos, sunLight);
                float occ = calcOcc(pos, sunLight);

                vec3 alb =	X.xyz*X.w*orbitTrap.x +
							Y.xyz*Y.w*orbitTrap.y +
							Z.xyz*Z.w*orbitTrap.z +
							R.xyz*R.w*orbitTrap.w;
				//alb *= occ;
                vec3 mat = DoLighting(alb*.2, pos, normal, dir, dis, sha)*occ;
                mat = mix(sky,mat, clamp(exp(-dis*dis*.05)+.03,0.0, 1.0));
                col += mat;
            }else
            {
                col += sky+pow(max(dot(sunLight, dir), 0.0), 20.0)  * SUN_COLOUR * .07;

            }
            col += pow(max(dot(sunLight, dir), 0.0), 2.0)  * SUN_COLOUR * .08;
#ifdef ANTIALIAS
        }
    }
        col/=4.;
#endif
    
	   
	col = PostEffects(col, xy) * smoothstep(.0, 2.0, iTime);	
	
    //fragColour=vec4(col+vec3(recDis/16., 0, 0), 1.);
    //fragColour=vec4(dis/16.);
	fragColour=vec4(col, 1.);
}

//--------------------------------------------------------------------------