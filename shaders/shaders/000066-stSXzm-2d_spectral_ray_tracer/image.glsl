// Image (image) — 2d spectral ray tracer by riouxld
// https://www.shadertoy.com/view/stSXzm

// ------------------------------------------------------------------------------ //
// 2D spectral ray tracer: Vaguely inspired by an afternoon listening to dark     //
// side of the moon. Some other inspirations:                                     //
// https://benedikt-bitterli.me/tantalum/                                         //
// https://www.shadertoy.com/view/NtXSR4                                          //
// https://www.shadertoy.com/view/llVSDz                                          //
// https://www.shadertoy.com/view/wlSXz3                                          //
// https://pbr-book.org/3ed-2018/Light_Transport_I_Surface_Reflection/Sampling_Reflection_Functions#sec:mc-specular-deltas //
// Could be more efficient and simpler but I wanted to do it fast and have some   //
// fun. For the same reason, there might be some mistakes such has forgotten      //
// or duplicated cosines                                                          //
// ------------------------------------------------------------------------------ // 


// XYZ to sRGB conversion 
// ---------------------
// https://www.shadertoy.com/view/llVSDz     

float cross2(vec2 a, vec2 b) { return a.x*b.y - a.y*b.x; } 

// Returns 1 if the lines intersect, otherwise 0. In addition, if the lines 
// intersect the intersection point may be stored in the floats i_x and i_y.

vec2 intersectSegment(vec2 p0, vec2 p1, vec2 p2, vec2 p3)
{
    vec2 s1 = p1-p0, s2 = p3-p2;

    float d = cross2(s1,s2),
          s = cross2(s1, p0-p2) / d,
          t = cross2(s2, p0-p2) / d;

    return s >= 0. && s <= 1. && t >= 0. && t <= 1.
         ? p0 + t*s1    // Collision detected
         : p0;
}

vec3 constrainXYZToSRGBGamut(vec3 col)
{
    vec2 xy = col.xy / (col.x + col.y + col.z);
    
    vec2 red   = vec2(0.64,   0.33  ),
         green = vec2(0.3,    0.6   ),
         blue  = vec2(0.15,   0.06  ),
         white = vec2(0.3127, 0.3290);
    
    const float desaturationAmount = 0.1;
    xy = mix(xy, white, desaturationAmount);
    
    xy = intersectSegment(xy, white, red,   green);
    xy = intersectSegment(xy, white, green, blue );
    xy = intersectSegment(xy, white, blue,  red  );
    
    return col.y * vec3( xy, 1. - xy.x - xy.y ) / xy.y;
}

vec3 xyzToRgb(vec3 XYZ)
{
	return XYZ * mat3( 3.240479, -1.537150, -0.498535,
	                  -0.969256 , 1.875991,  0.041556,
	                   0.055648, -0.204043,  1.057311 );
}

// gamma correction
vec3 gamma_correction(vec3 RGB) {
    float gamma = 2.2;
    return pow(RGB, vec3(1./gamma));
}

vec3 final_color(vec3 XYZ) {
    return gamma_correction(xyzToRgb(constrainXYZToSRGBGamut(XYZ)));
}

// main
// ----
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    // uv texture coordinate (0,1)x(0,1)
    vec2 uv = (fragCoord)/iResolution.xy;


    // accumulated color 
    vec3 col_xyz = texture(iChannel1, uv).xyz;
    
    // longer exposition, for brighter results
    col_xyz *= 2.5;
    
    // correct and show
    fragColor = vec4(final_color(col_xyz), 1.);
}
