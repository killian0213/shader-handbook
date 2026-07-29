// Image (image) — Hexagon Polyhedron Pattern by Shane
// https://www.shadertoy.com/view/3ctXz8

/*

	Hexagon Polyhedron Pattern
	--------------------------
    
    Creating a hexagon grid, then using another resized hexagon grid to 
    partition the cells into something reminiscent of stacked isometric 
    polyhedrons.
    
    I doubt this would fool anyone into thinking it's a genuine 3D rendering 
    of packed polyhedra, but I think it's still a pretty cool and interesting 
    looking pattern. I also wanted to show that it's pretty easy to use a 
    hexagon grid to create packed isometric patterns other than cubes.
    
    As mentioned, this is two different sized grids (one is twice the scale 
    of the other) of hexagons overlayed to form a stacked polyhedral pattern. 
    Individual polygons (or faces) can easily be identified, then shaded to 
    give the impression that the cell is a diffusely lit surface.
    
    It's possible to make these things look much more realistic, but I feel 
    that would kind of defeat the purpose of putting together a faux 3D 
    pattern in the first place.

	
    
    Related eamples:
    
    // A classic hexagon grid based cube stacking, but
    // rendered in a really cool way.
    Rusty metal cubes  -- bitless
    https://www.shadertoy.com/view/stVGzG

  
    // A 3D packing featuring truncated octahedrons. I'm yet to post 
    // a truncated octahedron traversal, but I intend to at some stage.
    truncated octahedral honeycomb -- jt
    https://www.shadertoy.com/view/MXfBRl
 
    

*/


// Show the hexagon grid that the pattern is based on...
// Probably a little redundant in this case, but it's there.
//#define SHOW_GRID

// Edge shade -- Dark: 0, Light: 1.
#define EDGE_TYPE 1

/////////////////////
// 2 PI.
#define TAU 6.2831853

 
// One of Ford Perfect/s experimental hashes, which is a variation
// of Dave Hoskins's based on hash and number theory.
float hash21(vec2 f){

    vec4 v = f.xyxy;
    v = fract(v*sqrt(vec4(2, 3, 5, 7)));
    v += dot(v, v.wyxz + sqrt(2357.));
    return fract((v.x + v.y)*v.z);
}
 
/*
// A slight variation on one of Dave Hoskins's hash functions,
// which you can find here:
//
// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...

float hash21(vec2 p){
    
	vec3 p3  = fract(vec3(p.xyx)*.1031);
    p3 += dot(p3, p3.yzx + 42.123);
    return fract((p3.x + p3.y)*p3.z);
}
*/

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
 

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21B(vec2 f){

    // The first line relates to ensuring that icosahedron vertex identification
    // points snap to the exact same position in order to avoid hash inaccuracies.
    uvec2 p = floatBitsToUint(f + 16384.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}


// Signed distance to a hexagon -- IQ.
//
// List of other 2D distances:
// https://iquilezles.org/articles/distfunctions2d
// and https://www.shadertoy.com/playlist/MXdSRf

float hexagon(vec2 p, float r){ 

    // Modified to render a pointed top hexagon.
    const vec3 k = vec3(.5, -.866025404, .577350269);
    p = abs(p);
    p -= 2.*min(dot(k.xy, p),0.)*k.xy;
    p -= vec2(r, clamp(p.y, -k.z*r, k.z*r));
    return length(p)*sign(p.x);
 
    /* 
    // Flat top hexagon.
    const vec3 k = vec3(-.866025404, .5, .577350269);
    p = abs(p);
    p -= 2.*min(dot(k.xy, p),0.)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
    */
}

// Hexagon grid scale.
const float gSc = 1./4.;
vec2 s = vec2(1, 1.732)*gSc;

// Hexagonal grid coordinates. This returns the local coordinates and the cell's center.
// The process is explained in more detail here:
//
// Minimal Hexagon Grid - Shane
// https://www.shadertoy.com/view/Xljczw
//
vec4 getGrid(vec2 p){
    
    vec4 ip = floor(vec4(p/s, p/s - .5));
    vec4 q = p.xyxy - vec4(ip.xy + .5, ip.zw + 1.)*s.xyxy;
    // The ID is multiplied by 12 to account for the inflated neighbor IDs above.
    return dot(q.xy, q.xy)<dot(q.zw, q.zw)? vec4(q.xy, ip.xy*12.) : 
                                            vec4(q.zw, ip.zw*12. + 6.);
 
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Aspect correct screen coordinates.
    float iRes = min(iResolution.y, 800.);
    vec2 uv = (fragCoord.xy - iResolution.xy*.5)/iRes;

    // Smoothing factor.
    float sf = 1./iRes;
    
    // Scene rotation, scaling and translation.
    mat2 sRot = mat2(1, 0, 0, 1);//rot2(3.14159/12.); // Scene rotation.
    vec2 camDir = sRot*normalize(s); // Camera movement direction.
    vec2 p = sRot*uv + camDir*iTime/16.;
    
      
    // Hexagonal grid coordinates.
    vec4 p4 = getGrid(p);
    // Large hexagon polygon to map out the polyhedron boundaries..
    float polyL = hexagon(p4.xy, gSc*.5);//getHexF(p4.xy);
     
    // Smaller hexagons.
    s /= 2.;
    vec4 p4Sm = getGrid(p + vec2(0, -s.y*2./3.));
    float poly = hexagon(p4Sm.xy, gSc/4.);
    
    // Combining the large hexagon with the smaller ones to form the face
    // polygons -- Three center hexagons and three surrounding quads.
    poly = max(poly, polyL);
    
    
    // Larger outer hexagon ID.
    vec2 idL = floor(p4.zw/6.);
    // Small hexagon ID.
    vec2 id = floor(p4Sm.zw/6.);
 
    // It'd be very easy to asign normals to the faces: The top would be vec3(0, 1, 0), 
    // the one's below would involve rotating the top by factors of 45 degrees, etc. 
    // However, to keep things simple, we'll just assign some shade factors.
    int pID = 6;
    // The three large hexagons -- There'd be more elegant ways to identify these, 
    // but I was in a hurry. It works, so it'll do.
    float shd = .8; // Top left.
    if(mod(id.y, 2.) == 0. && mod(id.x + id.y, 4.)==2.) shd = 1.; // Top right.
    if(mod(id.y, 2.) == 1. && mod(id.x + id.y, 4.)==0.) shd = .7; // Bottom.
    // The three quadrilaterals.
    if(idL.y<id.y/2.){ shd = .95; pID = 4; }// Top quadrilateral.
    if(idL.y>id.y/2. && idL.x>id.x/2.){ shd = .6; pID = 4; }  // Bottom left.
    if(idL.y>id.y/2. && idL.x<id.x/2. - .5){ shd = .9; pID = 4; } // Bottom right
    
    
    // Random polyhedron coloring, with some extra refined face coloring.
    float rnd = hash21(idL + .1);
    float rnd2 = 1. - shd;
    vec3 pCol = .5 + .45*cos(TAU*(rnd/10. + rnd2/2.) + vec3(0, 2, 3) - .7);
  
    // Pinkish hue for a sunset environment effect... It needs work. :)
    pCol = mix(pCol, pCol.xzy, smoothstep(.2, .7, (-uv.y*1. - uv.x + 1.)/4.));
      
    // Adding some metallic shades. Always worth a try, but not today. :)
    //if(hash21(idL + .07)<.7) 
    //   pCol = mix(pCol.zyx, vec3(.75)*dot(pCol, vec3(.299, .587, .114)), .85);
    
    pCol *= shd*sqrt(shd); // Applying diffuse tone to the colored faces.
    
    float ew = .004; // Edge width.
    
    // Face pattern.
    float cir = poly + gSc/4. - .01;
    if(pID==4)  cir = poly + gSc/8. - .01/sqrt(2.);
    // Alternate face pattern.
    //float cir = abs(poly + .02) - ew/2.;


    // Applying the pattern to the polygon face.
    #if EDGE_TYPE == 0
    float lnSh = .35;
    #else
    float lnSh = 1.5; // Edge shade.
    #endif
    vec3 svPCol = pCol;
    pCol = mix(pCol, pCol*lnSh, 1. - smoothstep(0., sf, cir - ew));
    pCol = mix(pCol, svPCol*.5, 1. - smoothstep(0., sf, cir));
  
   
    // Polygon edge and inner colors.
    vec3 col = pCol*lnSh;
    col = mix(col, pCol, 1. - smoothstep(0., sf, poly + ew));
    // Enhancing the outer edges a bit more.
    //col = mix(col, pCol*lnSh, 1. - smoothstep(0., sf, abs(polyL) - ew));
  
    
    
     
    // Hexagon edge, offset spotlight and spotlight shading
    col *= smoothstep(0., .2, -polyL/gSc)*.3 + .85;
    col *= max(1. - length(p4.xy - vec2(.25, .125)*gSc)/gSc, 0.)*.3 + .85;
    //col *= max(1.35 - length(p4.xy)/gSc, 0.);
   
    // Enhancing the fake AO with sharp lines on the large cell edges.
    col = mix(col, col*.5, 1. - smoothstep(0., sf, abs(polyL)  - ew/2.));
  
    
    // Running a light fine grain texture over the top. The texturing 
    // isn't accurate, but 
    vec2 tUV = p4.zw/12. + vec2(hash21(p4.zw + .17), hash21(p4.zw + .31)) - .5;
    tUV += p4.xy*(1. + dot(p4.xy, p4.xy)/(gSc*gSc));
    vec3 tx = texture(iChannel0, tUV).xyz; tx *= tx;
    tx = smoothstep(-.2, .4, tx);
    col *= tx*1.33;//tx*3. + .25;

    
    #ifdef SHOW_GRID
    // Display the construction grid.
    col = mix(col, col*.1, 1. - smoothstep(0., sf, abs(polyL) - .003));
    #endif
   
    // Adding false sky based lighting.
    uv = fragCoord/iResolution.xy - .5;
    col *= 1.35 - length(uv - vec2(.25, 0))*1.;
      
     
    // Vignette.
    //uv = fragCoord/iResolution.xy;
    //col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);;
}