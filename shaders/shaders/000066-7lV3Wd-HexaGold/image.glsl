// Image (image) — HexaGold by aiekick
// https://www.shadertoy.com/view/7lV3Wd

// Created by Stephane Cuillerdier - Aiekick/2021 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned with Noodlesplate (https://github.com/aiekick/NoodlesPlate)

// turning table angle offset for the thumbnail at time 0
#define THUMBNAIL_ANGLE_OFFSET 0.35

// from IQ, https://www.shadertoy.com/view/Xds3zN
// sdf of heaxagong
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

// hexacone :-,)
// reduce hexagon size with height
#define hex_size vec2(0.5 - p.y * 0.1, 10)
	
// common part used by the map and mat functions
// return the two sdf's
void common_map(vec3 p, out float df0, out float df1)
{
    // the horizontal wave
	df0 = p.y - 1.0 + sin(length(p.xz) * 0.8 - iTime);
	
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
vec3 getNormal(vec3 p, float prec)
{
	vec3 e = vec3(prec, 0, 0);
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
    
    // classice turning table camera
	float a = iTime * 0.1 + THUMBNAIL_ANGLE_OFFSET;
	vec3 ro = vec3(cos(a), 0.0, sin(a)) * 20.0;
	ro.y = 20.0;
	vec3 rd = cam(uvc, ro, vec3(0), 0.4);

    vec3 col = vec3(0.1);

    // log raymarching
    float s = 1., d = 0., md = 100.;
	for (int i = min(iFrame,0); i < 200; i++)
	{
		if (d*d/s>1e8 || d > 70.) break;
		s = map(ro + rd * d);
		d += s * 0.5;
	}
	
	if (d < md)
	{
        // surface point
		vec3 p = ro + rd * d;
        
        // surface normal, precision of 0.1 for remove some aliasing
		vec3 n = getNormal(p, 0.1);
		
		// light pos
		vec3 lp = vec3(0,5,0);
		
		// light dir
		vec3 ld = normalize(lp - p);
								
        // diffuse, ambiant occlusion, shadow, specular
		float diff = pow(dot(n, ld) * .5 + .5,2.0);
		float ao = getAmbiantOcclusion(p, n, 40.0);
		float sha = clamp(getShadow(p, ld, 0.01, 150.0, 5.0), 0. ,0.9);
		float spe = pow(max(dot(-rd, reflect(-ld, n)), 0.0), 32.0);
		
		if (mat(p) < 0.5) // hexa sides
        { 
			// smooht hsv
            vec3 base = hsv2rgb_smooth(vec3(atan(p.x,p.z)/3.14159*0.5 - iTime * 0.1, 0.8, 0.8)); 
            
            // vary base color according to ao
			col = mix(base, vec3(1), ao) * 0.5;
		} 
        else // hexa face
        { 
            // reflected gold
            col = vec3(1.0, 0.85, 0.0) * texture(iChannel0, reflect(rd, n)).rgb;	
        }
		
        // final brdf
		col += diff * sha * 0.5 + spe;
        
        // clamp for avoid overlight
		col = clamp(col, 0., 1.);
	}
	
    // distance fog
	col *= exp(1.0-d*d*0.001);
	
    // final color
	fragColor = vec4(col,1);
}