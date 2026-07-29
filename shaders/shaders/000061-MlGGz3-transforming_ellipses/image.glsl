// Image (image) — transforming ellipses by mattz
// https://www.shadertoy.com/view/MlGGz3

/* transforming ellipses, by mattz.
   License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

   Demonstrates how to map an ellipse through a homography (2D perspective transform).
   Implements math from https://en.wikipedia.org/wiki/Ellipse

*/




// Construct a 3x3 matrix for a 2D rotation 
mat3 rot(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(c, s, 0.0,
                -s, c, 0.0,
                0.0, 0.0, 1.0);
}

// Construct a 3x3 matrix for a 2D axis-aligned scale
mat3 scale(vec2 s) {
    return mat3(s.x, 0.0, 0.0,
                0.0, s.y, 0.0,
                0.0, 0.0, 1.0);
}

// Construct a 3x3 matrix for a 2D perspective distortion
mat3 distort(vec2 k) {
    return mat3(1.0, 0.0, k.x,
                0.0, 1.0, k.y,
                0.0, 0.0, 1.0);
                
}

// Construct a 3x3 matrix for a 2D translation
mat3 translate(vec2 t) {
    return mat3(1.0, 0.0, 0.0,
                0.0, 1.0, 0.0,
                t.x, t.y, 1.0);
}

// Warp a point thru a homography 
vec2 warp(mat3 H, vec2 p) {
    vec3 Hp = H * vec3(p, 1.0);
    return Hp.xy / Hp.z;
}


// Convert matrix form of implicit conic parameters to canonical parameters:
// center, semimajor/semiminor axis lengths, and principal axis direction.
void gparams_from_conic(in mat3 M,
                        out vec2 ctr,
                       	out vec2 ab, 
                       	out vec2 axis) {
    
    float A = M[0][0];
    float B = M[0][1]*2.0;
    float C = M[1][1];
    float D = M[0][2]*2.0;
    float E = M[1][2]*2.0;
    float F = M[2][2];
    
    float T = B*B - 4.0*A*C;
    float S = A*E*E + B*B*F + C*D*D - B*D*E - 4.0*A*C*F;
    float U = sqrt((A-C)*(A-C) + B*B);
    
    ab = sqrt(vec2(2.0*S*(A+C+U), 2.0*S*(A+C-U)))/T;
    ctr = vec2(2.0*C*D - B*E, 2.0*A*E - B*D)/T;
    axis = normalize(vec2(B, C-A-U));
       
}

// Convert the other way from above function.
mat3 conic_from_gparams(vec2 ctr,
                        vec2 ab,
                        vec2 axis) {
    
    float a = ab.x;
    float b = ab.y;
    float c = axis.x;
    float s = axis.y;
    float xc = ctr.x;
    float yc = ctr.y;
    
    float A = a*a*s*s + b*b*c*c;
    float B = 2.0*(b*b - a*a) * s * c;
    float C = a*a*c*c + b*b*s*s;
    float D = -2.0*A*xc - B*yc;
    float E = -B*xc - 2.0*C*yc;
    float F = A*xc*xc + B*xc*yc + C*yc*yc - a*a*b*b;
    
    return mat3(A, 0.5*B, 0.5*D,
                0.5*B, C, 0.5*E,
                0.5*D, 0.5*E, F);
    
}

// Return distance of point uv from ellipse in implicit form.
float ellipse_dist(vec2 uv, mat3 M) {
    
    vec3 uv1 = vec3(uv, 1.0);
    
    float k = dot(uv1, M * uv1);
    
    float dist = k / length(vec2(dFdx(k), dFdy(k)));
    
    return abs(dist)-0.5;
    
}

// Return distance to line segment
float seg_dist(vec2 ba, vec2 pa) {
    float u = clamp(dot(ba,pa)/dot(ba,ba), 0.0, 1.0);
    return length(pa-u*ba);
}


// Return distances to points in quadrilateral.
float quad_dist(vec2 uv, vec2 p[5], float scl) {
    
    float d_quad = 1e5;
    
    for (int i=0; i<4; ++i) {
        d_quad = min(d_quad, length(uv-p[i])/scl-3.0);
        d_quad = min(d_quad, seg_dist(p[i+1]-p[i], uv-p[i])/scl-0.5);
    }
    
    return d_quad;
    
}

// Return grid distances
vec2 grid_fract(vec2 x, vec2 i) {
    return (fract(x/i+0.5)-0.5)*i;
}

// For mixing colors
vec3 color_dist_mix(vec3 bg, vec3 fg, float dist, float alpha) {
    float d = smoothstep(0.0, 0.75, dist); 
    return mix(bg, fg, alpha*(1.0-d));
}


// Do the things now.
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    // Set up coordinate frame (4 units tall window, square pixels).
	vec2 uv = (fragCoord.xy + 0.5 - 0.5*iResolution.xy);
    float scl = 4.0 / iResolution.y;
    uv *= scl;
    
    // Construct a continuously changing homography.
    float u = iTime;
    
    vec2 t = vec2(2.0*cos(0.17*u+0.32), sin(0.13*u+0.45));
    vec2 k = vec2(0.4*cos(0.19*u+0.57), 0.3*sin(0.21*u+0.92));
    vec2 s = 1.0 + vec2(0.5*cos(0.27*u+0.34), 0.3*sin(0.23*u+0.12));
	float a = 0.75*sin(0.07*u);
    
    mat3 H = translate(t) * distort(k) * rot(a) * scale(s);
        
    // Invert it
    mat3 Hinv = inverse(H);
    
    // Construct a quadrilateral 
    vec2 p[5], Hp[5];
    
    p[0] = vec2(1.0, 0.5);
    p[1] = vec2(-1.0, 0.5);
    p[2] = vec2(-1.0, -0.5);
    p[3] = vec2(1.0, -0.5);
    p[4] = p[0];
    
    // Map it through the homography.
    for (int i=0; i<5; ++i) {
        Hp[i] = warp(H, p[i]);
    }

    // Set up our original ellipse
    vec2 ctr = vec2(0), ab = p[0], axis = vec2(1.0, 0.0);
    mat3 M = conic_from_gparams(ctr, ab, axis);
    
    // Warp ellipse through homography
    mat3 M2 = transpose(Hinv) * M * Hinv;

    // Get canonical params of warped ellipse
    vec2 ctr2, ab2, axis2;
    gparams_from_conic(M2, ctr2, ab2, axis2);
    
    //////////////////////////////////////////////////
    // The rest is just drawing...

    // Get distances to quadrilaterals.
    float d_quad = quad_dist(uv, p, scl);
    float d_quad2 = quad_dist(uv, Hp, scl);

    // Sample points along both quadrilaterals
    float d_stretch = 1e5;
    
    for (int i=0; i<32; ++i) {
        float theta = float(i)*6.283185307179586/32.0;
        vec2 v = vec2(cos(theta), sin(theta));
        vec2 p0 = v * ab;
        vec2 p1 = warp(H, p0);
        d_stretch = min(d_stretch, seg_dist(p1-p0, uv-p0)/scl-0.5);
    }
    
    // Green stuff
    vec2 pcw = warp(H, ctr);
    float d_pcw = length(uv-pcw)/scl-3.0;
    d_pcw = min(d_pcw, seg_dist(Hp[0]-Hp[2], uv-Hp[2])/scl-0.5);
    d_pcw = min(d_pcw, seg_dist(Hp[1]-Hp[3], uv-Hp[3])/scl-0.5);
   
    // Original ellipse & center
    float d_ell = ellipse_dist(uv, M);
    d_ell = min(d_ell, length(uv-ctr)/scl-3.0);
    
    // New ellipse & center
    float d_ell2 = ellipse_dist(uv, M2);
    d_ell2 = min(d_ell2, length(uv-ctr2)/scl-3.0);
    
    // Grid
    vec2 grid = abs(grid_fract(uv, vec2(0.5)))/scl;
    float d_grid = min(grid.x, grid.y);

    vec3 color = vec3(1.0);
    
    color = color_dist_mix(color, vec3(0.8), d_grid, 1.0);
    color = color_dist_mix(color, vec3(1.0, 0.7, 1.0), d_stretch, 0.2);
    color = color_dist_mix(color, vec3(0.7, 0.7, 1.0), d_quad, 1.0);
    color = color_dist_mix(color, vec3(1.0, 0.7, 0.7), d_ell, 1.0);
    color = color_dist_mix(color, vec3(0, 0.7, 0), d_pcw, 0.5);
    color = color_dist_mix(color, vec3(0, 0, 0.7), d_quad2, 1.0);
    color = color_dist_mix(color, vec3(0.7, 0, 0), d_ell2, 1.0);
    
    fragColor = vec4(color, 1.0);
    
}