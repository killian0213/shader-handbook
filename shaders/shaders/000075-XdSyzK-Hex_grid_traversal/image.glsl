// Image (image) — Hex grid traversal by mattz
// https://www.shadertoy.com/view/XdSyzK

/* Hex grid marching, by mattz
   License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

   Click and drag to set ray direction.

*/

// square root of 3 over 2
const float hex_factor = 0.8660254037844386;

#define HEX_FROM_CART(p) vec2(p.x / hex_factor, p.y)
#define CART_FROM_HEX(g) vec2(g.x * hex_factor, g.y)

//////////////////////////////////////////////////////////////////////
// Given a 2D position, find integer coordinates of center of nearest
// hexagon in plane.

vec2 nearestHexCell(in vec2 pos) {
    
    // integer coords in hex center grid -- will need to be adjusted
    vec2 gpos = HEX_FROM_CART(pos);
    vec2 hex_int = floor(gpos);

    // adjust integer coords
    float sy = step(2.0, mod(hex_int.x+1.0, 4.0));
    hex_int += mod(vec2(hex_int.x, hex_int.y + sy), 2.0);

    // difference vector
    vec2 gdiff = gpos - hex_int;

    // figure out which side of line we are on and modify
    // hex center if necessary
    if (dot(abs(gdiff), vec2(hex_factor*hex_factor, 0.5)) > 1.0) {
        vec2 delta = sign(gdiff) * vec2(2.0, 1.0);
        hex_int += delta;
    }

    return hex_int;
    
}

//////////////////////////////////////////////////////////////////////
// Flip normal if necessary to have positive dot product with d

vec2 alignNormal(vec2 h, vec2 d) {
    return h*sign(dot(h, CART_FROM_HEX(d)));
}

//////////////////////////////////////////////////////////////////////
// Intersect a ray with a hexagon wall with normal n

vec3 rayHexIntersect(vec2 ro, vec2 rd, vec2 h) {

    vec2 n = CART_FROM_HEX(h);

    // solve for u such that dot(n, ro+u*rd) = 1.0
    float u = (1.0 - dot(n, ro)) / dot(n, rd);

    // return the 
    return vec3(h, u);

}

//////////////////////////////////////////////////////////////////////
// Choose the vector whose z coordinate is minimal

vec3 rayMin(vec3 a, vec3 b) {
    return a.z < b.z ? a : b;
}

//////////////////////////////////////////////////////////////////////
// Triangle wave - used only for visualization

float tri(float x) {
    return abs(0.5*x-floor(0.5*x)-0.5)*2.0;
}

//////////////////////////////////////////////////////////////////////
// Used only for visualization

float hexDist(vec2 p) {
    p = abs(p);
    return max(dot(p, vec2(hex_factor, 0.5)), p.y) - 1.0;
}

//////////////////////////////////////////////////////////////////////
// From Dave Hoskins' https://www.shadertoy.com/view/4djSRW

#define HASHSCALE1 .1031

float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//////////////////////////////////////////////////////////////////////
// Main function

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    float scl = 10.5 / iResolution.y;

    float ray_width = max(0.04, 0.5*scl);
    float dot_size = max(0.125, 4.0*scl);
    float gridline_width = max(0.01, 0.125*scl);
    float outline_dist = max(0.15, 3.0*scl);

    //////////////////////////////////////////////////
    // get fragment position
    vec2 pos = (fragCoord.xy + 0.5 - .5*iResolution.xy) * scl;

    //////////////////////////////////////////////////
    // get ray origin and direction
    
    float t = 0.2*iTime;
    vec2 ro = vec2(2.5*sin(1.732*t), -2.5*sin(1.0532*t));

    vec2 mouse = iMouse.xy;
    if (iMouse.x == 0.0) {
        mouse = 0.5*iResolution.xy;
    }

    vec2 rd = (mouse - 0.5*iResolution.xy) * scl - ro;

    //////////////////////////////////////////////////
    // start visualizing ray

    float u_vis = max(0.0, dot(pos-ro, rd) / dot(rd, rd));

    float ray_line_dist = length(pos - ro - u_vis*rd);
    float ray_dot_dist = length(pos - ro);
    
    //////////////////////////////////////////////////
    // set up ray hex grid traversal

    // find nearest hex center to ray origin
    vec2 ro_cell = nearestHexCell(ro);

    // get the three candidate wall directions for this ray.
    // (each one is related to a normal by scaling by
    // hex_factor in the x direction).
    vec2 h0 = alignNormal(vec2(0.0, 1.0), rd);
    vec2 h1 = alignNormal(vec2(1.0, 0.5), rd);
    vec2 h2 = alignNormal(vec2(1.0, -0.5), rd);

    // instead of moving the hexagon center as we traverse the hex
    // grid, we will translate the ray origin in the opposite
    // direction
    vec2 cur_cell = ro_cell;

    // march along ray, one iteration per cell
    for (int i=0; i<20; ++i) {

        // after three tests, nt.xy holds the normal, nt.z holds the
        // ray distance parameter
        vec2 rdelta = ro - CART_FROM_HEX(cur_cell);
        vec3 ht = rayHexIntersect(rdelta, rd, h0);
        ht = rayMin(ht, rayHexIntersect(rdelta, rd, h1));
        ht = rayMin(ht, rayHexIntersect(rdelta, rd, h2));

        // we will always move by twice the unit normal of the
        // intersection
        cur_cell += 2.0 * ht.xy;

        // get the ray intersection point for visualization
        vec2 p_intersect = ro + rd*ht.z;
        
        // visualization
        ray_dot_dist = min(ray_dot_dist, length(pos - p_intersect));

    }

    //////////////////////////////////////////////////
    // visualization

    vec2 pos_cell = nearestHexCell(pos);
    
    float d = abs(hexDist(pos - CART_FROM_HEX(pos_cell)));

    vec3 c;

    // hex color
    if (pos_cell == ro_cell) {
        float k = tri(7.0*d  - 2.0*iTime);
        c = mix(vec3(0.7, 0.2, 0.5), vec3(0.2), 0.3*k);
    } else {
        float k = tri(7.0*d + 1.0);
        c = mix(vec3(0.45, 0.55, 0.6), vec3(0.6), hash12(pos_cell + 14.0));
        c = mix(c, vec3(0.8), k*0.25);
    }

    // grid lines
    c *= smoothstep(0.0, scl, d-gridline_width);

    const vec3 ray_color = vec3(1.0, 0.85, 0);

    // line shadow
    c = mix(c, vec3(0),
            0.5*smoothstep(outline_dist, 0.0, ray_line_dist-ray_width));

    // line 
    c = mix(c, ray_color,
            smoothstep(scl, 0.0, ray_line_dist-ray_width));
    
    // dot shadow
    c = mix(c, vec3(0),
            0.5*smoothstep(outline_dist, 0.0, ray_dot_dist-dot_size));

    // dot
    c = mix(ray_color, c, smoothstep(0.0, scl, ray_dot_dist-dot_size));
    
    fragColor = vec4(c, 1.0);
            
}

