// Buffer B (buffer) — Arcane Lands by Dave_Hoskins
// https://www.shadertoy.com/view/XdcfR7

// Render the lanscape and sky...
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.



//========================================================================
// Utilities...

//----------------------------------------------------------------------------------------
// Grab value of variable, indexed 'num' from buffer_ A...
// Useful because each pixel doesn't need to do a whole bunch of math/code over and over again.
// Like camera positions and animations...
vec4 getStore(int num)
{
	return  texelFetch(iChannel0, ivec2(num, 0), 0);
}

mat3 getStoreMat33(int num)
{
    vec3 m0 = texelFetch(iChannel0, ivec2(num, 0),   0).xyz;
    vec3 m1 = texelFetch(iChannel0, ivec2(num+1, 0), 0).xyz;
    vec3 m2 = texelFetch(iChannel0, ivec2(num+2, 0), 0).xyz;
    return mat3(m0, m1, m2);
}

//----------------------------------------------------------------------------------------
float  sphere( vec3 p, float s )
{
    return length(p)-s;
}
 
//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
float noise( in vec3 p )
{
    vec3 f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel3, (uv+ 0.5)/256.0, 0.0).yx;
	return mix( rg.x, rg.y, f.z );
}
#define VOR_SCALE .01
float voronoi( vec3 p)
{
    p*= VOR_SCALE;
    vec2 f = fract(p.xz);
    p.xz = floor(p.xz);
    float d = 1000.7, d2;
    float ret = 0.;
    vec2 tp;
    
	for (int xo = -1; xo <= 1; xo++)
	{
		for (int yo = -1; yo <= 1; yo++)
		{
            vec2 g = vec2(xo, yo);
            vec2 q = g + p.xz;
 
            vec2 n = textureLod(iChannel3,(q)/256.0, -100.0).xy;
            tp = g + n  - f + sin(p.y-n.y*37.)*.2;
            d2 = dot(tp, tp);
            
            if (d2 < d)
            {
                d = d2;
                ret = sqrt(d) / VOR_SCALE;
                ret-= 10.;
            }
		}
	}
 
    return ret;
}


//--------------------------------------------------------------------------
// This uses mipmapping with the incoming ray distance.
// I think it also helps with the texture cache, but I don't know that for sure...
float map( in vec3 p, float di)
{
  
    // Grab texture based on 3D coordinate mixing...
 	float te = textureLod(iChannel1, p.xz*.0017 + p.xy * 0.0019-p.zy*.0017, di).y*80.0;
    // Make a wibbly wobbly sin/cos dot product..
    float h = dot(sin(p*.019),(cos(p.zxy*.017)))*100.;
    
    // Rock Plateaus...
    float g = p.y*.33 + textureLod(iChannel1, p.xz*.0003, 4.).x*40.0;
    float c = 60.0;
    g /= c;
    float s = fract(g);
    g = floor(g)*c+pow(s, 20.)*c;
    // Add them all together...
    float d =  h+te + g;
    
    //d = min(d, voronoi(p));
    //...Then subtract the camera tunnel...
    vec2 o = cameraPath(p.z).xy;
    p.xy -= o;
    float tunnel = 40. - length(p.xy); 
     
    d = sMax(d, tunnel, 140.);


    return d;
}

//--------------------------------------------------------------------------

vec3 getSky(vec3 dir, vec2 uv, vec3 pos)
{
    vec3 col;
	col = mix(vec3(FOG_COLOUR), vec3(0.05, 0.14,.5),abs(dir.y));
 
    return col;
}


//--------------------------------------------------------------------------

vec3 getNormal(vec3 p, float e)
{
    return normalize( vec3( map(p+vec3(e,0.0,0.0), e) - map(p-vec3(e,0.0,0.0), e),
                            map(p+vec3(0.0,e,0.0), e) - map(p-vec3(0.0,e,0.0), e),
                            map(p+vec3(0.0,0.0,e), e) - map(p-vec3(0.0,0.0,e), e) ) );
}

//--------------------------------------------------------------------------

float BinarySubdivision(in vec3 rO, in vec3 rD, vec2 t)
{
    float halfwayT;
  
    for (int i = 0; i < 8; i++)
    {

        halfwayT = dot(t, vec2(.5));
        float d = map(rO + halfwayT*rD, halfwayT*.002); 
        t = mix(vec2(t.x, halfwayT), vec2(halfwayT, t.y), step(0.01, d));
    }

	return halfwayT;
}

//--------------------------------------------------------------------------
float marchScene(in vec3 rO, in vec3 rD, vec2 co)
{
	float t = 5.+10.*hash12(co);
    float oldT = 0.;
	vec2 dist = vec2(1000);
	vec3 p;
    bool hit = false;
    
    #ifdef MOVIE

    for( int j=0; j < 1000; j++ )
    #else
    for( int j=0; j < 200; j++ )
    #endif
	{
		if (t >= FAR) break;
		p = rO + t*rD;

		float h = map(p, t*0.002);
 		if(h < 0.01)
		{
            dist = vec2(oldT, t);
            break;
	     }
        oldT = t;
        #ifdef MOVIE
        t += h * .2;
        #else
        t += h * .35 + t*.001;
        #endif
	}
    if (t < FAR) 
    {
       t = BinarySubdivision(rO, rD, dist);
    }
    return t;
}

//--------------------------------------------------------------------------
float noise2d(vec2 p)
{
    vec2 f = fract(p);
    p = floor(p);
    f = f*f*(3.0-2.0*f);
    
    float res = mix(mix( hash12(p),  		    hash12(p + vec2(1,0)),f.x),
                    mix( hash12(p + vec2(0,1)), hash12(p + vec2(1,1)),f.x),f.y);
    return res;
}

//--------------------------------------------------------------------------
float findClouds2D(in vec2 p)
{
	float a = 1.0, r = 0.0;
    p*= .0015;
    for (int i = 0; i < 5; i++)
    {
        r+= noise2d(p*=2.2)*a;
        a*=.5;
    }
	return max(r-1., 0.0);
}

//--------------------------------------------------------------------------
// Use the difference between two cloud densities to light clouds in the direction of the sun.
vec4 getClouds(vec3 pos, vec3 dir)
{
    if (dir.y < 0.0) return vec4(0.0);
    float d = (1600. / dir.y);
    vec2 p = pos.xz+dir.xz*d;
    float r = findClouds2D(p);
    float t = findClouds2D(p+normalize(sunLight.xz)*15.);    
    t = sqrt(max((r-t)*20., .2))*.8;
    vec3 col = vec3(t) * SUN_COLOUR;
    // returns colour and alpha...
    return vec4(col, r);
}

//--------------------------------------------------------------------------
// Turn a 2D texture into a six sided one...
vec3 texCube(in sampler2D tex, in vec3 p, in vec3 n )
{
	vec3 x = textureLod(tex, p.yz, 0.0).xyz;
	vec3 y = textureLod(tex, p.zx, 0.0).xyz;
	vec3 z = textureLod(tex, p.xy, 0.0).xyz;
	return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))/(1e-20+abs(n.x)+abs(n.y)+abs(n.z));
}

//--------------------------------------------------------------------------
// Grab the colour...
vec3 albedo(vec3 pos, vec3 nor)
{
    specular  = .8;
    vec3 alb  = texCube(iChannel2, pos*.017, nor).yxz;

    // Brown the texture in places for warmth...
    float f = noise(pos*.01);
    alb *= vec3(.75+f, 1., .9);
    
	// Do grass on flat areas..
    float grass = smoothstep(0.1, .8, nor.y)* (noise(pos*.07)+.1);
	
    float v = (noise(pos*.05) + noise(pos*.1)*.5)*.5;
    
    vec3 col = texture(iChannel2,pos.xz*.01).xyz;
    col += texture(iChannel3,pos.xz*.01).x-.3;
    alb = mix(alb, col* vec3(.1+v, 0.8,.1), grass); 
    alb = clamp(alb, 0.0, 1.0);
    specular= max(specular-grass, 0.0);
    
    return pow(alb, vec3(1.3));
}


//--------------------------------------------------------------------------
float shadow(in vec3 ro, in vec3 rd)
{
	float res = 1.0;
    
    float t = .1;
    for( int i = 0; i < 10; i++ )
    {
		float h = map(ro + rd*t, 1.);

        res = min( res, 4.*h/t );
        t += h + t*.01;
        if (res < .3) break;
    }
    return clamp( res, 0.3, 1.0 );
}

float calcOcc( in vec3 pos, in vec3 nor)
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = .1 + 1.*float(i);
        float d = map( pos+h*nor, 0.);
        occ += (h-d)*sca;
        sca *= 0.5;
    }
    return clamp( 1.0-1.0*occ, 0.0, 1.0 );
}


//--------------------------------------------------------------------------
vec3 lighting(in vec3 mat, in vec3 pos, in vec3 normal, in vec3 eyeDir, in float d)
{
  
	float sh = shadow(pos+normal*.2,  sunLight);
    vec3 col = mat * SUN_COLOUR*(max(dot(sunLight,normal), 0.0))*sh;
    float occ = calcOcc(pos, normal);

    
    // Ambient...
	col += mat * SUN_COLOUR  * abs(-(normal.y*.14)) * occ;
    
    normal = reflect(eyeDir, normal); // Specular...
    col += pow(max(dot(sunLight, normal), 0.0), 12.0)  * SUN_COLOUR * sh * specular* occ;
    

	return min(col, 1.0);
}


//--------------------------------------------------------------------------
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    vec2 uv = (-iResolution.xy + 2.0 * fragCoord ) / iResolution.y;
    specular = 0.0;
  	vec3 col;

    sunLight 	= getStore(SUN_DIRECTION).xyz;
    camPos = getStore(CAMERA_POS).xyz;
    camMat = getStoreMat33(CAMERA_MAT0);

    vec3 dir = camMat * normalize( vec3(uv, projectZ(uv)));

    vec3 sky = getSky(dir, uv, camPos);
    //March it...
    float dhit = marchScene(camPos, dir, fragCoord);
    // Render at distance value...
    if (dhit < FAR)
    {
	   	vec3  p = camPos+dhit*dir;
        float pixel = iResolution.y;
       	vec3 nor =  getNormal(p, dhit/pixel);
       	vec3 mat = albedo(p, nor);
		vec3  temp = lighting(mat, p, nor, dir, dhit);
		// Distance fog...
       	//temp = mix(sky, temp , exp(-dhit*.0006));
       	col = temp;
    }else
	{
 
        // Clouds and Sun...
        col = sky;
        vec4 cc = getClouds(camPos, dir);
       
        col = mix(col, cc.xyz, cc.w);

        col+= pow(max(dot(sunLight, dir), 0.0), 200.0)*SUN_COLOUR;
        col = min(col, 1.0);
    }
    col = clamp(col, 0.0, 1.0);
	//col = mix( col, vec3(dot(col,vec3(0.333))), 0.4 );
    col = col*.6+col*col*(3.0-2.0*col);
    
	fragColour = vec4(col, dhit);
    //fragColor = vec4(poo);
    
}



