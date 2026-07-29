// Buffer C (buffer) — post: bokeh blur, hexagon 5pass by hornet
// https://www.shadertoy.com/view/Xd33Ds

#define USE_RANDOM

const vec2 blurdir = vec2( -1.0, -0.577350269189626 );

// ====

const float blurdist_px = 32.0;
const int NUM_SAMPLES = 16;




//#define GAMMA_SRGB
#if defined( GAMMA_SRGB )
// see http://www.opengl.org/registry/specs/ARB/framebuffer_sRGB.txt
vec3 srgb2lin( vec3 cs )
{
	vec3 c_lo = cs / 12.92;
	vec3 c_hi = pow( (cs + 0.055) / 1.055, vec3(2.4) );
	vec3 s = step(vec3(0.04045), cs);
	return mix( c_lo, c_hi, s );
}
vec3 lin2srgb( vec3 cl )
{
	//cl = clamp( cl, 0.0, 1.0 );
	vec3 c_lo = 12.92 * cl;
	vec3 c_hi = 1.055 * pow(cl,vec3(0.41666)) - 0.055;
	vec3 s = step( vec3(0.0031308), cl);
	return mix( c_lo, c_hi, s );
}
#else
vec3 srgb2lin(vec3 c) { return c*c; }
vec3 lin2srgb(vec3 c) { return sqrt(c); }
#endif //GAMMA_SRGB

//note: uniform pdf rand [0;1[
float hash12n(vec2 p)
{
	p  = fract(p * vec2(5.3987, 5.4421));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
	return fract(p.x * p.y * 95.4307);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 blurvec = normalize(blurdir) / iResolution.xy;
    vec2 uv = fragCoord / iResolution.xy;
    vec2 suv = (fragCoord + 25.0 * vec2( cos(iTime), sin(iTime ) )) / iResolution.xy;
    float sinblur = ( 0.55 + 0.45 * sin( 5.0 * uv.x + iTime ) );
    float blurdist = (iMouse.z>0.5) ? 100.0 * iMouse.x/iResolution.x : blurdist_px * sinblur;
    
    vec2 p0 = uv;
    vec2 p1 = uv + blurdist * blurvec;
    vec2 stepvec = (p1-p0) / float(NUM_SAMPLES);
    vec2 p = p0;
    #if defined(USE_RANDOM)
    p += (hash12n(uv+fract(iTime)+0.3)) * stepvec;
    #endif
    
    vec3 sumcol = vec3(0.0);
    for (int i=0;i<NUM_SAMPLES;++i)
    {
     	sumcol += srgb2lin( texture( iChannel0, p, -10.0 ).rgb);
        p += stepvec;
    }
    sumcol /= float(NUM_SAMPLES);
    
    fragColor = vec4( lin2srgb(sumcol), 1.0 );
}
