// Image (image) — TrueType Glyph Outline by glk7
// https://www.shadertoy.com/view/4tGBRV

// Created by genis sole 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International.

float segment(vec2 uv, float e, vec2 a, vec2 b)
{         
    b -= a;
    uv -= a;
    return smoothstep(0.0, e, 
                      length( uv - b * clamp(dot(b, uv) / dot(b, b), 0.0, 1.0)));
}

float segment_line(vec2 uv, float e, vec2 a, vec2 b) 
{
    b -= a;
    uv -= a;
    vec2 d = normalize(b);
    
    float sd1 = smoothstep(e*0.1, 2.0*e, abs(dot(vec2(-d.y, d.x), uv)));
    float sd2 = smoothstep(e*0.1, e, abs(dot(vec2(-d.y, d.x), uv)));
    float t = min(step(0.0, dot(d, uv)), step(0.0, dot(d, b - uv)));
    
    float fo = clamp(pow(length(uv - b*0.5)/(length(b)*4.0), 4.0), 0.0, 1.0);
    
 	return mix(mix(0.8 + 0.2*sd2,1.0, fo) , sd1, t); 
}

float point(vec2 uv, float e, vec2 p) 
{
	return 1.0 - ((1.0 - smoothstep(1.5*e, 3.0*e, length(uv - p))) * 0.8); 
}

float cpoint(vec2 uv, float e, vec2 p)
{
    const float s = 1.5;
	float d = segment(uv, 1.5*e, p + e*vec2(s), p - e*vec2(s)) *
              segment(uv, 1.5*e, p + e*vec2(s, -s), p - e*vec2(s, -s));
    return 1.0 - (1.0 - d) * 0.7;
}

float bezier(vec2 uv, float e, vec2 b0, vec2 b1, vec2 b2)
{   
    // Nehab and Hoppe quadratic bezier distance aproximation.
    // http://hhoppe.com/ravg.pdf
    b0 -= uv;
    b1 -= uv;
    b2 -= uv;
    
    float a = determinant(mat2(b0, b2));
    float b = 2.0 * determinant(mat2(b1, b0));
    float d = 2.0 * determinant(mat2(b2, b1));
    
    float f = b*d - a*a;
    vec2 d21 = b2 - b1;
    vec2 d10 = b1 - b0;
    vec2 d20 = b2 - b0;  
    
    vec2 gf = 2.0 * (b*d21 + d*d10 + a*d20);  
    gf = vec2(gf.y, -gf.x);
    
    vec2 pp = -f*gf / dot(gf, gf);
    vec2 d0p = b0 - pp;  
    float ap = determinant(mat2(d0p, d20));
    float bp = 2.0 * determinant(mat2(d10, d0p)); 
    float t = clamp((ap + bp) / (2.0*a + b + d), 0.0, 1.0);
    
    vec2 dist = vec2(length(mix(mix(b0, b1, t), mix(b1, b2, t), t)), length(pp));

    float fo = clamp(0.0, 1.0, pow(length(b1)/(length(d20)*4.0), 4.0));
    
    return min(smoothstep(e*0.1, 2.0*e, dist.x), 
               			  mix(0.8 + 0.2*smoothstep(e*0.1, e, dist.y), 1.0, fo));
}

float move_to(inout vec2 p, vec2 to, vec2 uv, float e)
{
	p = to;
    return point(uv, e, to);
}

float line_to(inout vec2 p, vec2 to, vec2 uv, float e)
{
	float d = min(segment_line(uv, e, p, to), point(uv, e, to));
    p = to;
    return d;
}

float conic_to(inout vec2 p, vec2 c, vec2 to, vec2 uv, float e)
{
	float d = min(min(bezier(uv, e, p, c, to), cpoint(uv, e, c)), point(uv, e, to));
    p = to;
    return d;
}

float glyph(vec2 uv, float e) 
{
    vec2 p = vec2(0.0);

    float r = 1.0;
    r = min(r, move_to(p, vec2(57, -162), uv, e) );
    r = min(r, conic_to(p, vec2(57, -96), vec2(107, -39), uv, e) );
    r = min(r, conic_to(p, vec2(158, 18), vec2(246, 43), uv, e) );
    r = min(r, conic_to(p, vec2(156, 100), vec2(156, 225), uv, e) );
    r = min(r, conic_to(p, vec2(156, 321), vec2(219, 395), uv, e) );
    r = min(r, conic_to(p, vec2(123, 475), vec2(123, 606), uv, e) );
    r = min(r, conic_to(p, vec2(123, 727), vec2(219, 816), uv, e) );
    r = min(r, conic_to(p, vec2(315, 905), vec2(455, 905), uv, e) );
    r = min(r, conic_to(p, vec2(578, 905), vec2(672, 831), uv, e) );
    r = min(r, conic_to(p, vec2(770, 927), vec2(889, 928), uv, e) );
    r = min(r, conic_to(p, vec2(942, 928), vec2(967, 895), uv, e) );
    r = min(r, conic_to(p, vec2(993, 862), vec2(993, 827), uv, e) );
    r = min(r, conic_to(p, vec2(993, 796), vec2(973, 781), uv, e) );
    r = min(r, conic_to(p, vec2(954, 766), vec2(934, 766), uv, e) );
    r = min(r, conic_to(p, vec2(909, 766), vec2(891, 782), uv, e) );
    r = min(r, conic_to(p, vec2(874, 799), vec2(874, 825), uv, e) );
    r = min(r, conic_to(p, vec2(874, 868), vec2(907, 881), uv, e) );
    r = min(r, conic_to(p, vec2(901, 883), vec2(887, 883), uv, e) );
    r = min(r, conic_to(p, vec2(787, 883), vec2(702, 803), uv, e) );
    r = min(r, conic_to(p, vec2(786, 725), vec2(786, 604), uv, e) );
    r = min(r, conic_to(p, vec2(786, 483), vec2(690, 394), uv, e) );
    r = min(r, conic_to(p, vec2(594, 305), vec2(455, 305), uv, e) );
    r = min(r, conic_to(p, vec2(340, 305), vec2(252, 369), uv, e) );
    r = min(r, conic_to(p, vec2(217, 328), vec2(217, 272), uv, e) );
    r = min(r, conic_to(p, vec2(217, 221), vec2(248, 181), uv, e) );
    r = min(r, conic_to(p, vec2(279, 141), vec2(326, 135), uv, e) );
    r = min(r, line_to(p, /*vec2(340, 133),*/ vec2(479, 133), uv, e) );
    r = min(r, line_to(p, /*vec2(561, 133),*/ vec2(606, 131), uv, e) );
    r = min(r, conic_to(p, vec2(651, 129), vec2(715, 115), uv, e) );
    r = min(r, conic_to(p, vec2(780, 102), vec2(831, 76), uv, e) );
    r = min(r, conic_to(p, vec2(964, 2), vec2(965, -158), uv, e) );
    r = min(r, conic_to(p, vec2(965, -275), vec2(830, -348), uv, e) );
    r = min(r, conic_to(p, vec2(696, -422), vec2(510, -422), uv, e) );
    r = min(r, conic_to(p, vec2(322, -422), vec2(189, -347), uv, e) );
    r = min(r, conic_to(p, vec2(57, -273), vec2(57, -162), uv, e) );
    r = min(r, move_to(p, vec2(164, -162), uv, e) );
    r = min(r, conic_to(p, vec2(164, -246), vec2(263, -310), uv, e) );
    r = min(r, conic_to(p, vec2(362, -375), vec2(512, -375), uv, e) );
    r = min(r, conic_to(p, vec2(659, -375), vec2(758, -311), uv, e) );
    r = min(r, conic_to(p, vec2(858, -248), vec2(858, -162), uv, e) );
    r = min(r, conic_to(p, vec2(858, -101), vec2(823, -62), uv, e) );
    r = min(r, conic_to(p, vec2(788, -23), vec2(716, -7), uv, e) );
    r = min(r, conic_to(p, vec2(645, 8), vec2(595, 11), uv, e) );
    r = min(r, line_to(p, /*vec2(545, 14),*/ vec2(453, 14), uv, e) );
    r = min(r, line_to(p, vec2(332, 14), uv, e) );
    r = min(r, conic_to(p, vec2(262, 10), vec2(213, -41), uv, e) );
    r = min(r, conic_to(p, vec2(164, -92), vec2(164, -162), uv, e) );
    r = min(r, move_to(p, vec2(276, 604), uv, e) );
    r = min(r, conic_to(p, vec2(276, 352), vec2(455, 352), uv, e) );
    r = min(r, conic_to(p, vec2(545, 352), vec2(600, 434), uv, e) );
    r = min(r, conic_to(p, vec2(633, 489), vec2(633, 606), uv, e) );
    r = min(r, conic_to(p, vec2(633, 858), vec2(455, 858), uv, e) );
    r = min(r, conic_to(p, vec2(365, 858), vec2(309, 776), uv, e) );
    r = min(r, conic_to(p, vec2(276, 721), vec2(276, 604), uv, e) );
    
	return r;    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   	float s = 50.*64.;
    float e = s/iResolution.x;
    vec2 uv = fragCoord * e;
	uv -= vec2(0.34, 0.20)*s;
    fragColor = vec4(vec3(pow(glyph(uv, e)*0.8, 0.4545)),1.0);
}