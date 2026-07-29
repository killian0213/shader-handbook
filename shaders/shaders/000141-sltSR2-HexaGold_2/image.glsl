// Image (image) — HexaGold 2 by aiekick
// https://www.shadertoy.com/view/sltSR2

// Created by Stephane Cuillerdier - Aiekick/2021 (github:aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned with Noodlesplate (https://github.com/aiekick/NoodlesPlate)

mat3 rotz(float a)
{
    float c = cos(a), s = sin(a);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

// from IQ, https://www.shadertoy.com/view/Xds3zN
// sdf of heaxagon
float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
       length(p.xy - vec2(clamp(p.x, -k.z*h.x, k.z*h.x), h.x))*sign(p.y - h.x),
       p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// hexagons repeat placement
#define ox 1.3
#define oz 1.5

// variation between 0 and 1 along p.z
float var_z = 0.0;

// common part used by the map and mat functions
// return the two sdf's
void common_map(vec3 p, out float df0, out float df1)
{
	p *= rotz(p.z * 0.05);
	
	p.y = 5.0 + 5.0 * var_z - abs(p.y);
	
    // the horizontal wave
	float wave = sin(length(p.xz) * 0.25 - iTime * 1.5);
	df0 = abs(p.y + wave) - 1.0;
	
	vec2 hex_size = vec2(0.25 + p.y * 0.25, 10.0);
	
    // first hexagones row
	vec3 q0 = p;
	q0.x = mod(q0.x - ox, ox + ox) - ox;
	q0.z = mod(q0.z - oz * 0.5, oz) - oz * 0.5;
	float hex0 = sdHexPrism(q0.xzy, hex_size) - 0.2; 
	
    // second hexagones row
	vec3 q1 = p;
	q1.x = mod(q1.x, ox + ox) - ox;
	q1.z = mod(q1.z, oz) - oz * 0.5;
	float hex1 = sdHexPrism(q1.xzy, hex_size) - 0.2; 
	
    // the hexagones
	df1 = min(hex0, hex1);
}

// from IQ
float smin( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}

// return the final SDF
float map(vec3 p)
{
    float df0, df1;
    common_map(p, df0, df1);
    
    // final df
    return smax(df0, df1, 0.1);
    //return max(df0, df1);
}

// same code as map but with decomposition of the last max()
// for return the material id
float mat(vec3 p)
{
	float df0, df1;
    common_map(p, df0, df1);
    
    // max() decomposition for get df id
	if (df0 > df1)
		return 1.0;
	return 0.0;
}

// get normal for the surface point and a precision
vec3 getNormal(vec3 p)
{
	const vec3 e = vec3(0.1, 0, 0);
	return normalize(vec3(
		map(p+e)-map(p-e),
		map(p+e.yxz)-map(p-e.yxz),
		map(p+e.zyx)-map(p-e.zyx)));
}

// IQ Occ
float getAmbiantOcclusion(vec3 p, vec3 n, float k)
{
    const float aoStep = 0.1; 
	float occl = 0.;
    for(int i = min(iFrame,0); i < 6; ++i)
    {
        float diff = float(i)*aoStep;
        float d = map(p + n*diff);
        occl += (diff - d) * pow(2., float(-i));
    }
    return min(1., 1. - k*occl);
}

// IQ Shadow
float getShadow(vec3 ro, vec3 rd, float minD, float maxD, float k)
{
    float res = 1.0;
    float d = minD;
	float s = 0.;
    for(int i = min(iFrame,0); i < 20; ++i)
    {
        s = map(ro + rd * d);
        if( abs(s)<d*d*1e-5 ) return 0.0;
        res = min( res, k * s / d );
		d += s;
        if(d >= maxD) break;
    }
    return res;
}

// get the perpsective camera
vec3 cam(vec2 uv, vec3 ro, vec3 cv, float fov)
{
	vec3 cu = normalize(vec3(0,1,0));
  	vec3 z = normalize(cv-ro);
    vec3 x = normalize(cross(cu,z));
  	vec3 y = cross(z,x);
  	return normalize(z + fov*uv.x*x + fov*uv.y*y);
}

// from IQ https://www.shadertoy.com/view/MsS3Wc
// Smooth HSV to RGB conversion 
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	
	return c.z * mix( vec3(1.0), rgb, c.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 si = iResolution.xy;
    
    // central uv
    vec2 uvc = (2.*fragCoord.xy-si)/si.y;
    
    // classic path camera
	vec3 ro = vec3(0.0, 0.0, iTime * 20.0 + 5.0);
	vec3 cv = ro + vec3(0.0, 0.0, 4.0);
	vec3 rd = cam(uvc, ro, cv, 0.4);

    vec3 col = vec3(0);

    vec3 p = ro;
    float s = 1., d = 0.;
    const float md = 70.;
	for (int i = min(iFrame,0); i < 200; i++)
	{
		// log marching
        if (d*d/s > 1e6 || d > md) break;
        var_z = sin(p.z * 0.1) * 0.5 + 0.5;
		s = map(p);
		d += s * 0.5;
        p = ro + rd * d;
	}
	
	if (d < md)
	{
        // surface normal
        // internal precision of 0.1 for remove some aliasing
		vec3 n = getNormal(p);
		
		// light pos
		vec3 lp = vec3(0,5,0);
		
		// light dir
		vec3 ld = normalize(lp - p);
								
        // diffuse, ambiant occlusion, shadow, specular
		float diff = pow(dot(n, ld) * .5 + .5,2.0);
		float ao = getAmbiantOcclusion(p, n, 40.0);
		float sha = clamp(getShadow(p, ld, 0.01, 150.0, 5.0), 0. ,0.9);
		
		if (mat(p) > 0.5) // hexa face
        { 
            // variation between orange glod and white along z
            col = mix(
                vec3(1.5, 1.0, 0.0), 
                vec3(2.0, 2.0, 2.0), 
                var_z);
		} 
        else // hexa sides
        {
            // gold
            col = vec3(1.0, 0.85, 0.0) * 0.75;	
        }
        
        // apply reflection
        col *= texture(iChannel0, reflect(rd, n)).rgb;
		
        // final brdf
		col += diff * sha * 0.5;
	}
	
    // clamp for avoid overlight
	col = clamp(col, 0., 1.);
        
    // distance fog
	col *= exp(1.0-d*d*0.001);
	
    // final color
	fragColor = vec4(col,1);
}