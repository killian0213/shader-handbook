// Buffer A (buffer) — After... by Dave_Hoskins
// https://www.shadertoy.com/view/3sBGRt

// After...
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//----------------------------------------------------------------------------------------

//#define OFF_LINE

float time;
vec3 sun_Dir;
mat3 m = mat3(.5, .6, -.02,
              -1., 0.7, .02,
	          .02, .01, 1.0)*2.0;	// ...3D spinner matrix includes doubling
float specAmount = .4;
#define HIGH 11					 	// ...Do high fractal.
#define LOW  5						// ...Do low fractal.
#define BLUR						// ...Do a cheapo blur.

//----------------------------------------------------------------------------------------
vec3 getSky(vec3 ro, vec3 rd)
{
    // Wrapped horizon colour...
    vec3 col = vec3(.4, .25, .2) *pow(abs(1.0-rd.y), 2.0);
    col += vec3(.01, .01, .01);
    return col;
}

//----------------------------------------------------------------------------------------
// The landscape is just added sine waves which is then subtracted from a plane...
float landscape(vec3 p, const int frac)
{
    p *= 0.003;				// ...Make it smaller and more manageable.
    
    float a = 800.;			// ...Init amplitude.
    float r = 0.0;			
    for (int i = 0; i< frac; i++)	// ...Changeable levels number (LOW & HIGH).
    {
        float h = dot(sin(p.xy*.183),(cos(p.xz*.211)));	// ...Use out of phase sine and cosine waves.
        h =1.0-abs(h);		// ...Make it peaky.
        r += pow(h, 2.)*a;	// ...More peaky!
        
        p = m * p;			// ...Rotate & double.
        a *= 0.525;			// ...Lower amplitude & repeat.
    }
    
  	return r;
}
float redMistMulti(vec3 p)
{
    p.y -= time*.65;
   
    return texture(iChannel1, p*0.0003).x+.5;
    
}

//----------------------------------------------------------------------------------------
mat2 rotate(const float a)
{
	float si = sin(a);
	float co = cos(a);
	return mat2(co, si, -si, co);
}

//----------------------------------------------------------------------------------------
float cylinder(const vec3 p, const vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//----------------------------------------------------------------------------------------
float roundBox( vec3 p, vec3 b, float r )
{

	return length(max(abs(p)-b,0.0))-r;
}

//----------------------------------------------------------------------------------------
float trees(vec3 p)
{
    float d;
    vec3 b = p;
    b.xz = floor(p.xz / 2000.0)*2000.0+1000.;

    vec2 ro = (noise2D(b.xz*.003224)-.5) * .4;
    
    mat2 mx2 = rotate(ro.x);
    
	b.y  = 0.0+ro.y*800.0;
    
    p.xz = mod(p.xz, 2000.0)-1000.0;
    p.xy = mx2 * p.xy;
    p.y -= b.y;
    p.xz += noise(b.xy+p.xy*.008+ro.xy)*70.;
    d = cylinder(p, vec2(40.+abs(ro.y)*200.0-p.y*.03,1200.+abs(ro.x)*1000.0) ); 
 
    return d;
}
//----------------------------------------------------------------------------------------
float bricks(vec3 p)
{
	p.x -= 1400.0;
    float d;
    vec3 b = p;
    b.xz = floor(p.xz / 4100.0)*4100.0+2050.;
  	vec2 ro = (hash22(b.xz)-.5);
	mat2 mx2 = rotate(ro.x);

    b.y  = 800.-landscape(vec3(b.xz, 00.0), LOW);
	p.y -= b.y;
    
    p.xz = mx2 * mod(p.xz, 4100.0)-2050.0;
    p.z += noise(b.xy-p.xy*.005+ro.xy)*50.;
    
    d = roundBox(p, vec3(50.0, 800.0, 100. + ro.y*450.), ro.y*30.0);
    return d;
}

//----------------------------------------------------------------------------------------
// Map the entire scene...
vec2 map(vec3 p, int depth)
{ 
    float h = p.y-landscape(p, depth);

    float tunnel = (330.0-length(p.xy - cameraPath(p.z).xy+ vec2(50,100)));
	h = sMax(h, tunnel, 1000.);
    float id = 0.0;
    
    //h = trees(p);
    float g = trees(p);
    if (g < h)
    {h = g; id = 1.0;}
    
    g = bricks(p);
    
    if (g < h)
    {h = g; id = 2.0;}
    return vec2(h, id);
}

//----------------------------------------------------------------------------------------
// Split ray either side of object then home in on it by halving furthest side length...
float BinarySubdivision(in vec3 ro, in vec3 rd, vec2 t)
{
    float halfwayT;
  
    for (int i = 0; i < 6; i++)
    {
        halfwayT = dot(t, vec2(.5));
        float d = map(ro + halfwayT*rd, LOW).x; 
        t = mix(vec2(t.x, halfwayT), vec2(halfwayT, t.y), step(0.0, d));
    }

	return halfwayT;
}

//----------------------------------------------------------------------------------------
vec2 rayMarch(vec3 ro, vec3 rd, vec2 co, inout float fg)
{
    
    float t = 70.*hash12(co);
    float oldT = 0.;
	vec2 dist = vec2(FAR);
	vec3 p;
    fg = 0.0;
    bool hit = false;
    float id = 0.;

    for( int j=0; j < 150; j++ )
	{
		if (t >= FAR) break;
		p = ro + t*rd;

		vec2 h = map(p, LOW);
 		if (h.x < 0.0)
		{
            dist = vec2(oldT, t);
            id = h.y;
            break;
	     }
        oldT = t;
        fg+= max(smoothstep(1200., 0., p.y),0.0) * redMistMulti(p);

        t += h.x * .5 + t*0.001+4.0;
	}
    if (dist.x < FAR) 
    {
       t = BinarySubdivision(ro, rd, dist);
    }
    fg = min(fg*.02, .5);
    return vec2(t, id);
}

//----------------------------------------------------------------------------------------
float shadow(in vec3 ro, in vec3 rd)
{
	float res = 1.0;
    float t = .1;
    for( int i = 0; i < 20; i++ )
    {
		float h = map(ro + rd*t, LOW).x;

        res = min( res, 3.*h/t );
        t += h + t*.01;
        //if (res < .1) break;
    }
    return clamp( res, 0.1, 1.0 );
}

//----------------------------------------------------------------------------------------
vec3 getNormal(vec3 p, float e)
{
    e = e * .5 / iResolution.y;
    
    return normalize( vec3( map(p+vec3(e,0.0,0.0), HIGH).x - map(p-vec3(e,0.0,0.0), HIGH).x,
                            map(p+vec3(0.0,e,0.0), HIGH).x - map(p-vec3(0.0,e,0.0), HIGH).x,
                            map(p+vec3(0.0,0.0,e), HIGH).x - map(p-vec3(0.0,0.0,e), HIGH).x) );
}

//----------------------------------------------------------------------------------------
vec3 texCube(sampler2D sam, in vec3 p, in vec3 n )
{
	vec3 x = texture(sam, p.yz).xyz;
	vec3 y = texture(sam, p.zx).xyz;
	vec3 z = texture(sam, p.xy).xyz;
	return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))/(abs(n.x)+abs(n.y)+abs(n.z));
}


//----------------------------------------------------------------------------------------
vec3 diffuseMat(vec3 p, vec3 nor, float id)
{
    vec3 mat;
    // All materials are quite simple...
    if (id  > 1.5)	// Ground....
    {
		mat = texCube(iChannel0, p*.001,nor);
        mat= mat*mat*mat;
    }else
    if (id  > 0.5)	// Trees.
    {
        mat = (texCube(iChannel2, p*.001,nor) + vec3(.4,.2,.2))*.25;
        mat= mat*mat;
        specAmount = .1;
    }else			// Wall remains...
    {
	   	vec3 fir = texture(iChannel0, p.xz*.000207).xyz;
    	mat = fir*texture(iChannel0, p.xz*.001131).xyz;
	    mat = mat*mat*mat*6.0;
    	mat = min(mat, 1.0);
    }

    return mat;
}

//----------------------------------------------------------------------------------------
void getLighting(inout vec3 col, vec3 pos, vec3 dir, vec2 d, vec3 nor, vec3 sky)
{
    float sh = shadow(pos+nor*8.0, sun_Dir);
    col = diffuseMat(pos, nor, d.y) * SUN_COLOUR*(max(dot(sun_Dir,nor), 0.0)) * sh;

    vec3 ref = reflect(dir, nor);
    float fre = clamp(1.+dot(nor,dir), 0.0, 1.0 ) * specAmount;
    col += pow((max(dot(ref,sun_Dir), 0.0)), 10.0)*fre  * sh * SUN_COLOUR;
}
	
//----------------------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -1 to 1 with aspect ratio changing x)
    vec2 uv = (-iResolution.xy + 2.0 * fragCoord ) / iResolution.y;
    if (abs(uv.y) > .75)
	{
		// Top and bottom cine-crop - what a waste! :)
		fragColor=vec4(0,0,0,1);
		return;
	}
 
    time = iTime*200.0+1500.;
    #ifndef OFF_LINE
    time+= iMouse.x*4000.0/iResolution.x;
    #endif
    sun_Dir = normalize(vec3(6., 5., -3.));

    vec3 col;
    
    vec3 ro = cameraPath(time);
    vec3 ta = cameraPath(time+20.0);
    float roll = (ro.x-ta.x)*.01;
    float t = mod(time+4400.,12000.0);
    ta.x+= (smoothstep(0.0,1000.0, t) * smoothstep(2000.0,1200.0, t)) * 100.0;
    ta.x-= (smoothstep(3000.0,4000.0, t) * smoothstep(5000.0,4200.0, t)) * 100.0;
    ta.y+= (smoothstep(5000.0,6000.0, t) * smoothstep(7000.0,6000.0, t)) * 20.0;
    ta.y-= (smoothstep(10000.0,11000.0, t) * smoothstep(12000.0,11000.0, t)) * 20.0;

    mat3 camM = setCamMat(ro, ta, roll);
    vec3 dir  =  camM * normalize( vec3(uv, cos((length(uv*.5)))));
    float fog;
    vec2 r = rayMarch(ro, dir, fragCoord, fog);
    float d = r.x;
    float id = r.y;
    vec3 sky = getSky(ro,dir);
    float sunDot = max(dot(sun_Dir,dir), 0.0);
    if (d < FAR)
    {
        vec3 pos = ro + dir * d;
        vec3 nor = getNormal(pos, d);
        // Do some standard lighting...
     	getLighting(col, pos, dir, r, nor, sky);
        
        // Fog...
        d = d*0.00011;
        float f = exp(-d*d);
        
        col = mix(sky, col,  min(f, 1.0));
       	col = mix(col, vec3(.2,.0,.0),  min(fog, 1.0)); // ..Accumulated red floor fog.
    }else
    {
        
		float sun = pow(sunDot, 80.)*.5 ;   
        sky += SUN_COLOUR  * sun;
        col = mix(sky, vec3(.2,.01,.0),  min(fog, 1.0));
	}
    
  	col += SUN_COLOUR * .2 *pow( sunDot, 5.0 );
    col = clamp(col, 0.0, 1.0);

    // Output to screen
    
    // Running average for a cheap blur....
    #ifdef BLUR
    float blur = (iTimeDelta/.06);
#ifdef OFF_LINE
    blur = .6;
#else
    blur = clamp(blur, 0.1, .9);
#endif
    fragColor = texelFetch(iChannel3,ivec2(fragCoord), 0)*(1.0-blur);
    fragColor += vec4(col,1.0)*blur;
    #else
    fragColor += vec4(col,1.0);
    #endif
}
