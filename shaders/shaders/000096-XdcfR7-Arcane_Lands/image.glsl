// Image (image) — Arcane Lands by Dave_Hoskins
// https://www.shadertoy.com/view/XdcfR7

// Render Sun Rays over landscape from 'B
// by David Hoskins. April 30th, 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec3 sunPos;

//----------------------------------------------------------------------------------------
vec4 getStore(int num)
{
	return  texelFetch(iChannel0, ivec2(num, 0), 0);
}

//----------------------------------------------------------------------------------------
mat3 getStoreMat33(int num)
{
    vec3 m0 = texelFetch(iChannel0, ivec2(num, 0),   0).xyz;
    vec3 m1 = texelFetch(iChannel0, ivec2(num+1, 0), 0).xyz;
    vec3 m2 = texelFetch(iChannel0, ivec2(num+2, 0), 0).xyz;
    return mat3(m0, m1, m2);
}
//----------------------------------------------------------------------------------------
float noise( in vec3 p )
{
    vec3 f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
	 
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel1, (uv+ 0.5)/256.0, 0.0).yx;
	return mix( rg.x, rg.y, f.z );
}

//----------------------------------------------------------------------------------------
float getMist(vec3 dir, vec2 uv, vec3 pos)
{
    vec3 clou = dir * 1.5 + pos*.02;
	float t = noise(clou);
    t += noise(clou * 2.1) * .4;
    t += noise(clou * 4.3) * .2;
    t += noise(clou * 7.9) * .1;
 
    return t;
}

float obscurePartsOfSun(vec2 p)
{
    float a = 0.0, z;
    float e = .08;

    vec2 asp = vec2(iResolution.y/iResolution.x,1.0);
   	vec2 texUV = .5+.5*p*asp;
   	z = texture(iChannel3, texUV).w;
    if (z >= FAR) a +=.5;
    
    texUV = .5+.5*(p+vec2(e, e))*asp;
   	z = texture(iChannel3, texUV).w;
    if (z > FAR) a +=.125;

    texUV = .5+.5*(p+vec2(e, -e))*asp;
   	z = texture(iChannel3, texUV).w;
    if (z > FAR) a +=.125;

    texUV = .5+.5*(p+vec2(-e, -e))*asp;
   	z = texture(iChannel3, texUV).w;
    if (z > FAR) a +=.125;
    
    texUV = .5+.5*(p+vec2(-e, e))*asp;
   	z = texture(iChannel3, texUV).w;
    if (z > FAR) a +=.125;

    return a;
}    


//----------------------------------------------------------------------------------------
float godRays(vec2 uv)
{
   	float ra =0.0;
	vec2 sunPos = vec2(dot( sunLight, camMat[0] ),dot( sunLight, camMat[1] ) )-vec2(0.05,-.15);
   	vec2 p = uv-sunPos;
    float add = hash12(uv*4000.)*.02;
    
    
 	for (float x = .1; x < 1.; x+=.02)
	{
		float z = max(textureLod(iChannel3,(sunPos+(p*(x+add))+1.)*.5, 0.).w, 300.0)-300.;
		ra+= z*x;
	}
   
    return ra*.00001;
}

//----------------------------------------------------------------------------------------
vec3 lenseFlare(vec2 uv,vec3 dir, mat3 camMat)
{

    vec3 col = vec3(0);
    
    mat3 inv = transpose(camMat);
    vec3 cp = inv * - sunPos;
    //
	if (cp.z < 0.0)
	{

        vec2 sun2d = zProj * cp.xy / cp.z;
        if (sun2d.x < -2.0 || sun2d.x > 2. || sun2d.y < -2.0 || sun2d.y > 2.) return col;

        float z = obscurePartsOfSun(sun2d);
    	
        if (z > 0.0)
        {
            float bri = max(dot(dir, sunLight)*.5, 0.0);
            bri = pow(bri, 3.)*5.*z;

            vec2 uvT = uv - sun2d;

            float glare1 = max(dot(dir,sunLight),0.0);

            uvT = mix (uvT, uv, -2.3);
            float glare2 = max(1.7-length(uvT+sun2d*3.)*4.0, 0.0);
            float glare3 = max(1.7-pow(length(uvT+sun2d*3.5)*14., 200.), 0.0)*.7;

            col += bri * vec3(1.0, .0, .0)  * pow(glare1, 10.5)*2.;
            col += bri * vec3(.5, .05, .0) * pow(glare2, 3.);
            col += bri * vec3(.1, .1, .6) * pow(glare3, 3.)*3.0;
        }
	}
    return col*.8;
}
 
//----------------------------------------------------------------------------------------
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    vec2 xy = (-iResolution.xy + 2.0 * fragCoord ) / iResolution.xy;
    vec2 uv = xy * vec2(iResolution.x / iResolution.y, 1.0);
    
    fragColour	= texelFetch(iChannel3, ivec2(fragCoord), 0);
    vec3 col 	= fragColour.xyz;
    sunLight 	= getStore(SUN_DIRECTION).xyz;
    camPos		= getStore(CAMERA_POS).xyz;
    camMat 		= getStoreMat33(CAMERA_MAT0);
    zProj = projectZ(uv);

    vec3 dir 	= camMat * normalize( vec3(uv, zProj));
    sunPos = sunLight * 20000.;
    
    float t = getMist(dir, uv, camPos);
    t = mix(1.0, t, exp(-0.00005*fragColour.w));
    float gr  = godRays(xy);
    //col = clamp(col, 0.0, 1.0);
    
   	col += gr*t * SUN_COLOUR;
    col += lenseFlare(uv, dir, camMat);

 
    float vig = smoothstep(4.2,.5, dot(uv,uv)); 
    col*= vig;
    col *= smoothstep(.0, 4.0, iTime);
    col = min(col*vec3(1.1,1.,.8), 1.0);
    
    fragColour = vec4(sqrt(col), 1.0);


    
}
    