// Image (image) — Ray Marching Experiment n°33bis by aiekick
// https://www.shadertoy.com/view/MljSRD

// Created by Stephane Cuillerdier - Aiekick/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
Space Body 
my goal was to introduce some sub-surface scattering with hot color but the result is not as expected
normaly less thikness is more cold than big thickness. here this is the inverse ^^ its not wanted
*/

#define BLOB

#define shape(p) length(p)-2.8

float dstepf = 0.0;
float df0, df1;
    
// by shane : https://www.shadertoy.com/view/4lSXzh
float Voronesque( in vec3 p )
{
    vec3 i  = floor(p + dot(p, vec3(0.333333)) );  p -= i - dot(i, vec3(0.166666)) ;
    vec3 i1 = step(0., p-p.yzx), i2 = max(i1, 1.0-i1.zxy); i1 = min(i1, 1.0-i1.zxy);    
    vec3 p1 = p - i1 + 0.166666, p2 = p - i2 + 0.333333, p3 = p - 0.5;
    vec3 rnd = vec3(7, 157, 113); // I use this combination to pay homage to Shadertoy.com. :)
    vec4 v = max(0.5 - vec4(dot(p, p), dot(p1, p1), dot(p2, p2), dot(p3, p3)), 0.);
    vec4 d = vec4( dot(i, rnd), dot(i + i1, rnd), dot(i + i2, rnd), dot(i + 1., rnd) ); 
    d = fract(sin(d)*262144.)*v*2.; 
    v.x = max(d.x, d.y), v.y = max(d.z, d.w), v.z = max(min(d.x, d.y), min(d.z, d.w)), v.w = min(v.x, v.y); 
#ifdef BLOB
    return  max(v.x, v.y) - max(v.z, v.w); // Maximum minus second order, for that beveled Voronoi look. Range [0, 1].
#else
    return max(v.x, v.y); // Maximum, or regular value for the regular Voronoi aesthetic.  Range [0, 1].
#endif
}

///////////////////////////////////

void commonMap(vec3 p, out float df0, out float df1)
{
	float voro = Voronesque(p);
 	float sp = shape(p);
    float spo = sp - voro;
    float spi = sp + voro * .5;
	float e = sin(iTime*.5)*.4 +.35;
    df0 = max(-spi, spo + e);
    df1 = sp + 1.;
}

float map(vec3 p)
{
    dstepf += 0.002;
    commonMap(p, df0, df1);          
	return min(df0, df1);
}

float mat(vec3 p)
{
    commonMap(p, df0, df1);      
	if (df0 < df1) 
		return 0.0;
    return 1.0;
}

vec3 nor( vec3 pos, float prec )
{
    vec2 e = vec2( prec, 0. );
    vec3 n = vec3(
    map(pos+e.xyy) - map(pos-e.xyy),
    map(pos+e.yxy) - map(pos-e.yxy),
    map(pos+e.yyx) - map(pos-e.yyx) );
    return normalize(n);
}

vec3 cam(vec2 uv, vec3 ro, vec3 cu, vec3 cv)
{
	vec3 rov = normalize(cv-ro);
    vec3 u =  normalize(cross(cu, rov));
    vec3 v =  normalize(cross(rov, u));
    vec3 rd = normalize(rov + u*uv.x + v*uv.y);
    return rd;
}

// return color from temperature 
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html
vec3 blackbody(float Temp)
{
	vec3 col = vec3(255.);
    col.x = 561e5 * pow(Temp,(-3. / 2.)) + 148.;
   	col.y = 100.04 * log(Temp) - 623.6;
   	if (Temp > 6500.) col.y = 352e5 * pow(Temp,(-3. / 2.)) + 184.;
   	col.z = 194.18 * log(Temp) - 1448.6;
   	col = clamp(col, 0., 255.)/255.;
    if (Temp < 1000.) col *= Temp/1000.;
   	return col;
}
        
void mainImage( out vec4 f, in vec2 g )
{
    f = vec4(0,0,0,1);
    
    vec2 si = iResolution.xy;
	float t = iTime;
    
    float ca = t*.2; // angle z
    float ce = 2.; // elevation
    float cd = 4.; // distance to origin axis
   	
    vec3 cu=vec3(0,1,0);//Change camere up vector here
    vec3 cv=vec3(0,0,0); //Change camere view here
    vec2 uv = (g+g-si)/min(si.x, si.y);
    vec3 ro = vec3(sin(ca)*cd, ce+1., cos(ca)*cd); //
    vec3 rd = cam(uv, ro, cu, cv);

    float md = 12.0;

    float d = 0.0;
	float s = 1.0;
    for(int i=0;i<200;++i)
    {      
		if(d*d/abs(s) > 1e6 || d>md) break;
        s = map(ro+rd*d);
		d += s * 0.25;
   	}

	if (d<md)
    {
        vec3 p = ro + rd * d;
		vec3 n = nor(p, .01);
        float m = mat(p);
		if ( m < 0.5) // icy color
        {
			rd = reflect(rd, n);
			p += rd * d;		
			d += map(p) * .001;
			f.rgb = exp(-d / vec3(.2,.4,.58) / 15.);
		}
		else if( m < 1.5) // kernel
		{
			float b = dot(n,normalize(ro-p))*0.9;
            f = (b*vec4(blackbody(2000.),0.9)+pow(b,0.2))*(1.0-d*.01);
		}	
   	}
    
    f = mix( f, vec4(0,.02,.15, 1.), 1.0 - exp( -d*dstepf) ); 
}

