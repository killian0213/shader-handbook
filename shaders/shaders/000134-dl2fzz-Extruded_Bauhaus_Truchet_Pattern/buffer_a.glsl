// Buffer A (buffer) — Extruded Bauhaus Truchet Pattern by Shane
// https://www.shadertoy.com/view/dl2fzz

/*

    Extruded Bauhaus Truchet Pattern
    --------------------------------
    
    This is an extruded Bauhaus Truchet pattern with a very simplistic 
    Cook-Torrance diffuse and specular lighting scheme applied to give 
    the vague appearance of hard ceramic and metal tiles.
    
    When not path tracing, I tend to get a bit lazy with material lighting 
    routines. Most of the time, I can make things look the way I want by
    tweaking the diffuse and specular powers. However, if you want a bit 
    more material realism, it's probably a good idea to drop in some kind 
    of BRDF (bidirectional reflectance distribution function) routine, 
    which is what I've done here.
    
    I hacked a very basic BRDF routine together pretty quickly some time 
    ago, and it works well enough for the purpose of this example, but I 
    wouldn't use it for anything other than a basic introduction. By the
    way, if you're an expert on the process, and I've made a mistake that
    can't be ignored, feel free to let me know.
    
    The Bauhaus pattern itself is nothing special. You can find them in
    abundance online, but I haven't seen them in variable heightmap form, 
    so I thought it'd be fun to do that. Technically speaking, the example
    is interesting in the sense that every cell is only rendered once, 
    which is made possible using a cell wall intersection trick that I've
    covered previously.
    
    I've included a heap of define options below, for anyone interested in
    playing around with different design settings.
    


    Other examples:

    // A much nicer implementation.
    Disney Principled BRDF - markusm
    https://www.shadertoy.com/view/XdyyDd


*/
 

// Paint on some edging.
#define EDGES

// Put some rivet holes on random objects.
#define HOLES

// Ratio of metallic tiles to dielectric (non-conducting) ones.
// Values range from zero (no metallic tiles) to one (all metallic).
#define METAL_AMOUNT .35 // Range: [0, 1].

// The color variety... I wasn't sure what to call this. Lower
// numbers mean fewer colors. Changing the variety of colors used
// changes the feel. I prefer fewer, but everyone's different.
//
// Greyscale 0, One color: 1, Two colors: 2, Four colors, 3
#define COLOR_VARIETY 2

// An override to display random material values and colors.
//#define RANDOM_MATERIALS

// Swizzle the palette from orange to purple based colors.
//#define SWIZZLE_PALETTE

// Relative amount of metallic tiles that are gold. For initial
// design reasons, the default is undefined.
//#define GOLD_AMOUNT .35 // Range: [0, 1].

// Subtle textured lines.
//#define LINES

 
// Object ID: Either the back plane, extruded object or beacons.
int objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
//float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){

    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

 
// Hacked together from IQ, Nimitz and Fabrice's hash functions.
vec3 hash23(in vec2 f){
     
    uvec2 p = floatBitsToUint(f);
    uint  n = 1103515245U*((p.x)^(p.y>>3U));
    // Converting a uint to a uvec3:
    // These numbers came from here:
    // Quality hashes collection WebGL2 - Nimitz.
    // https://www.shadertoy.com/view/Xt3cDn
    uvec3 u3 = uvec3(1, 16807U, 48271U);
    return vec3(((u3*n) >> 1) & uvec3(0x7fffffffU))/float(0x7fffffff);
    
    // Dave Hoskins's reliable hash function.
	//vec3 p3 = fract(f.xyx*vec3(.1031, .1030, .0973));
    //p3 += dot(p3, p3.yxz + 423.123);
    //return fract((p3.xxy+p3.yzz)*p3.zyx);
     
}
 
 

// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Ryan Geiss effectively multiplies the first line by 7. It took me a while to realize that 
    // it's largely redundant, due to the division process that follows. I'd never noticed on 
    // account of the fact that I'm not in the habit of questioning stuff written by Ryan Geiss. :)
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.yz).xyz;
    vec3 ty = texture(tex, p.zx).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture sample,
    // represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}


    
// Height map value, which is just the pixel's greyscale value.
//vec3 hm3(in vec2 p){ return texture(iChannel2, p*563.837, -100.).xyz; }
vec3 hm3(in vec2 p){ return hash23(p); }

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}
 

// Triangle scale: Smaller numbers mean smaller triangles, oddly enough. :)
float scale = 1./1.5;


// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
 
 
vec2 gIP;

// An extended square grid 2D Truchet routine: Split into square tiles
// as per usual, then produce the distance fields and ID for simple 
// shapes inside them. The kinds of shapes you render is up to you.
//
// This is 2D function called once per raymarching iteration, so it 
// needs to be reasonably quick, but not blindingly fast. I also wanted
// it to be a little bit readable, so I didn't go out of my way to 
// tweak it. If speed was the goal, then I'd be more inclined to render
// it to a backbuffer, rather than turn it into an unreadable mess, but
// to each their own.
void tr(inout vec2 oP, inout vec3 d, inout vec2[3] id, int oID){


    vec2 p = oP;
    
    // Row and column offset variable.
    vec2 offs = vec2(0);
    // Row and column ID.
    vec2 ii = floor(p/scale);
    /*
    // Offset columns.
    if(mod(ii.x, 2.)<.5){ 
        p.y -= scale/2.;
        offs.y += .5;
    } 
    */ 
    /*
    // Offset rows.
    if(mod(ii.y, 2.)<.5){ 
        p.x -= scale/2.;
        offs.x += .5;
    } */
    
    
    #ifndef RANDOM_MATERIALS
    // Animated offset columns.
    // Time, beginning at random intervals.
    float t = iTime/8. + hash21(vec2(2, ii.x));
    float iT = floor(t); // Integer time increments to keep track of position.
    float fT = t - iT; // Fractional time increment used for animation.
    
    // Smoothly slide the columns at random time intervals. 
    float dir = mod(ii.x, 2.)<.5? -1. : 1.;
    p.y += dir*(smoothstep(0., .0625, fT) + .25)*scale;
    offs.y = dir*(iT + .25); 
    #endif
   
    // Positional cell ID and local coordinates. If you didn't want to shift
    // rows and columns, you wouldn't need any of the code above, nor would you
    // need the three lines below.
    vec2 ip = floor(p/scale);
    p -= (ip + .5)*scale;
    
    
    ip += offs; // Update the positional cell ID with the sliding offset.
    gIP = ip; // Record the ID for usage elsewhere.
    oP = p; // Record the local position.
 

     
    // Random local coordinate rotation.
    float rnd = hash21(ip + .05);
    p *= rot2(floor(rnd*64.)*3.14159/2.);
   
     // A second random number that determines what kind of tile to draw.
    float rnd2 = hash21(ip + .1);

    
    // Three distances and IDs, to represent up to three shapes per cell.
    d = vec3(1e5);
    id = vec2[3](vec2(0), vec2(0), vec2(0));
    
    
    // Based on the random choice above, render one of three types of
    // tiles. I hacked this together to get the job done, so there'd no
    // doubt be more efficient ways to do this, but this seems fast 
    // enough on my machine, and it's readable enough, so it'll do.
    if(rnd2<.3){
    
        // Triangles.
         
        // Square boundary.
        vec2 q = abs(p);
        float sq = max(q.x, q.y) - .5*scale;
        
        // The diagonal center line.
        q = p;
        d.x = (p.x + p.y)*.7071;
        id[0] = ip - .25; // ID for this side of the line.

        // The other side of the diagonal line.
        d.y = max(sq, -d.x);
        id[1] = ip + .25; // ID for the other side.
        
        // Use the square boundary to render the other two lines.
        // This will leave you with two triangles... Probably not
        // real distance field values, but no one will notice.
        d = max(d, sq);
        
        oID = 0; // Record the overall square cell ID.
        
        
    }
    else if(rnd2<.5){
    
        // Square with central circle tile.
        
        // Circle.
        vec2 q = p;
        d.x = length(q) - 1./2.*.7071*scale + .05;
        id[0] = ip; // Center ID for the circle.

        // The remainder of the rectangle.
        q = abs(p);
        d.y = max(q.x - .5*scale, q.y - .5*scale);
        d.y = max(d.y, -d.x);
        id[1] = ip + vec2(-.25, 0); // Off to the side for the remainder.
        
        oID = 1; // Square cell ID.
    }
    else {
    
        // Three circular arcs.
    
        // Square boundary.
        vec2 q = abs(p);
        float sq = max(q.x, q.y) - .5*scale;
        
        float qrtr = length(p - .5*scale) - .5*scale; // Quarter.
        float semi = length(p - .5*scale) - 1.*scale; // Semi circle.
    
        d.x = qrtr; // Inner quarter.
        id[0] = ip - .25;
        
        d.y = max(semi, -qrtr); // Middle arc.
        id[1] = ip + vec2(0);
        
        
        
        d.z = max(sq, -semi); // Outer quarter.
        id[2] = ip + .25;
        
        // Using the square boundary to form the three bounded arcs.
        d = max(d, sq);
        
        oID = 2; // Square cell ID.
    
    }

    
    // Shape border line width.
    float lw = .015*scale;
    d += lw;
    
    
    // Rivet offset distance.
    float rvO = (1./2. - 1./4.*.7071)*scale;
    
    // Rivet nole distance.
    float rv;
   
    // Rivet holes.
    if(oID == 1){
        // Square corner holes.
        vec2 q = abs(p) - rvO;
        rv = length(q);
    }
    else {
        
        // Triangle holes and corner arc holes.
        vec2 q = p;
        rv = length(q - rvO);
        rv = min(rv, length(q + rvO));
        
        if(oID == 2){
           // Central arc rivet position.
           vec2 arcR = vec2(rvO, -(1.*scale - lw)/4.);
           rv = min(rv, min(length(p - arcR), length(p.yx - arcR)));
           
        }    
    } 
    
    // Smaller rivet holes when using edging.
    #ifdef EDGES
    float hw = .035;
    #else
    float hw = .045;
    #endif
 
    // Use CSG for some random rivet holes.
    #ifdef HOLES
    if(hash21(ip + .08)<.35){
       d = max(d, -(rv - hw*scale));
    }
    #endif
 
}

  
// The scene's distance function: There'd be faster ways to do this, but it's
// more readable this way. Plus, this  is a pretty simple scene, so it's 
// efficient enough.
float m(vec3 p){
    
    // Back plane.
    float fl = -p.z;
    
    // 2D Truchet distance, for the extrusion cross section.
    vec3 d; vec2[3] id; int oID;
    vec2 gP = p.xy;
    tr(gP, d, id, oID);
 
    // Extrude the 2D Truchet object along the Z-plane.
    //vec3 h3 = vec3(hm(id[0]), hm(id[1]), hm(id[2]))*.25 + .05;
    // A bit of face beveling to reflect the light a little more.
    vec3 bev = min(-d*6., .2)*.03; // 03;
    vec3 h3 = hm3(gIP)*.25 + .05;
    float obj = opExtrusion(d.x, p.z, h3.x, .015) - bev.x; 
    obj = min(obj, opExtrusion(d.y, p.z, h3.y, .015) - bev.y); 
    if(oID==0) obj = min(obj, opExtrusion(d.z, p.z, h3.z, .015) - bev.z); 
  
    // Directional ray collision with the square cell boundaries.
    vec2 rC = (gDir.xy*scale - gP)/gRd.xy; // For 2D, this will work too.
    
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... I'm not entirely sure it's
    // necessary here, but it stops artifacts from appearing with other 
    // non-rectangular grids.
    //gCD = max(min(min(rC.x, rC.y), rC.z), 0.) + .0015;
    gCD = max(min(rC.x, rC.y), 0.) + .0015; // Adding a touch to advance to the next cell.
 
     
    // Object ID.
    objID = fl<obj? 0 : 1;
    
    // Minimum distance for the scene.
    return min(fl, obj);
    
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not affordable for slower machines.
    const int iter = 32; 
    
    ro += n*.0015; // Bumping the shadow off the hit point.
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), 0.0001);
    rd /= end;
    
    //rd = normalize(rd + (hash33R(ro + n) - .5)*.03);
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = sign(rd)*.5;
    gRd = rd; 

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<iter; i++){

        float d = m(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(min(d*.7, gCD), .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = min(iFrame, 0); i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = m(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        
        // Deliberately redundant line that may or may not stop the 
        // compiler from unrolling.
        if(sca>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);
}
  
// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 nr(in vec3 p) {
	
    const vec2 e = vec2(.001, 0);
    
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(iFrame, 0); i<6; i++){
		mp[i] = m(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}


///////////////////////////
const float PI = 3.14159265;

// Microfaceted normal distribution function.
float D_GGX(float NoH, float roughness) {
    float alpha = pow(roughness, 4.);
    float b = (NoH*NoH*(alpha - 1.) + 1.);
    return alpha/(PI*b*b);
}

// Surface geometry function.
float G1_GGX_Schlick(float NoV, float roughness) {
    //float r = roughness; // original
    float r = .5 + .5*roughness; // Disney remapping.
    float k = (r*r)/2.;
    float denom = NoV*(1. - k) + k;
    return max(NoV, .001)/denom;
}

float G_Smith(float NoV, float NoL, float roughness) {
    float g1_l = G1_GGX_Schlick(NoL, roughness);
    float g1_v = G1_GGX_Schlick(NoV, roughness);
    return g1_l*g1_v;
}

// Bidirectional Reflectance Distribution Function (BRDF). 
//
// If you want a quick crash course in BRDF, see the following:
// Microfacet BRDF: Theory and Implementation of Basic PBR Materials
// https://www.youtube.com/watch?v=gya7x9H3mV0&t=730s
//
vec3 BRDF(vec3 col, vec3 n, vec3 l, vec3 v, 
          float type, float rough, float fresRef){
     
  vec3 h = normalize(v + l); // Half vector.

  // Standard BRDF dot product calculations.
  float nv = clamp(dot(n, v), 0., 1.);
  float nl = clamp(dot(n, l), 0., 1.);
  float nh = clamp(dot(n, h), 0., 1.);
  float vh = clamp(dot(v, h), 0., 1.);  

  
  // Specular microfacet (Cook- Torrance) BRDF.
  //
  // F0 for dielectics in range [0., .16] 
  // Default FO is (.16 * .5^2) = .04
  // Common Fresnel values, F(0), or F0 here.
  // Water: .02, Plastic: .05, Glass: .08, Diamond: .17
  // Copper: vec3(.95, .64, .54), Aluminium: vec3(.91, .92, .92), Gold: vec3(1, .71, .29),
  // Silver: vec3(.95, .93, .88), Iron: vec3(.56, .57, .58).
  vec3 f0 = vec3(.16*(fresRef*fresRef)); 
  // For metals, the base color is used for F0.
  f0 = mix(f0, col, type);
  vec3 F = f0 + (1. - f0)*pow(1. - vh, 5.);  // Fresnel-Schlick reflected light term.
  // Microfacet distribution... Most dominant term.
  float D = D_GGX(nh, rough); 
  // Geometry self shadowing term.
  float G = G_Smith(nv, nl, rough); 
  // Combining the terms above.
  vec3 spec = F*D*G/(4.*max(nv, .001));
  
  
  // Diffuse calculations.
  vec3 diff = vec3(nl);
  diff *= 1. - F; // If not specular, use as diffuse (optional).
  diff *= (1. - type); // No diffuse for metals.

  
  // Combining diffuse and specular.
  // You could specify a specular color, multiply it by the base
  // color, or multiply by a constant. It's up to you.
  return (col*diff + spec*PI);
  
}
////////////////////


void mainImage(out vec4 c, vec2 u){

    
    // Aspect correct coordinates. Only one line necessary.
    u = (u - iResolution.xy*.5)/iResolution.y;    
    
    // Unit direction vector, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), o = vec3(0, iTime/2., -3), l = o + vec3(.5, 1, 1.5);
    //vec3(-2.5, 2.5, -1.25);
    // Rotating the camera about the XY plane.
    r.yz = rot2(.15)*r.yz;
    r.xz = rot2(-cos(iTime*3.14159/32.)/8.)*r.xz;
    r.xy = rot2(sin(iTime*3.14159/32.)/8.)*r.xy; 
    
    // Mouse camera movement.
    if(iMouse.z>1.){
        r.yz *= rot2(-.5*(iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        r.xz *= rot2(-.25*(iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);
    } 
  
    
    // Standard raymarching setup.
    float d, t = hash21(r.xy*57. + fract(iTime))*.5;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = sign(r)*.5;
    gRd = r; 

    
    // Raymarch.
    for(int i = min(iFrame, 0); i<96; i++){ 
        
        vec3 p = o + r*t;
        d = m(p); // Surface distance.
        // Surface hit -- No far plane break, since it's just the floor.
        if(abs(d)<.001) break; 
        t += min(d*.9, gCD);  // Advance the overall distance closer to the surface.
         
    }
    
    // Object ID: Back plane (0), or the metaballs (1).
    int gObjID = objID;
    
 
 
    // Hit point and normal.
    vec3 p = o + r*t, n = nr(p); 
    
    
    
        // Basic point lighting.   
    vec3 ld = l - p;
    float lDist = length(ld);
    ld /= lDist; // Light direction vector.
    float at = 1./(1. + lDist*lDist*.05); // Attenuation.
    
    // Very, very cheap shadows -- Not used here.
    //float sh = min(min(m(p + ld*.08), m(p + ld*.16)), min(m(p + ld*.24), m(p + ld*.32)))/.08*1.5;
    //sh = clamp(sh, 0., 1.);
    float sh = softShadow(p, l, n, 8.); // Shadows.
    float ao = calcAO(p, n); // Ambient occlusion.
    
    /*
    // Old diffuse and specular calculations.
    float df = max(dot(n, ld), 0.); // Diffuse.
    float sp = pow(max(dot(reflect(r, n), ld), 0.), 32.); // Specular.
    float fr = pow(max(1. + dot(r, n), 0.), 2.); // Fresnel.
    
    // UV texture coordinate holder.
    vec2 uv = p.xy;
    */
    
    // 2D Truchet face distace -- Used to render borders, etc.
    //scale *= 3.;
    vec3 d3; vec2[3] vID; int oID;
    vec2 p2 = p.xy;
    tr(p2, d3, vID, oID);
    
    // Minimum tile object index.
    int index = (d3.x<d3.y && d3.x<d3.z)? 0 : d3.y<d3.z? 1 : 2;
    // 2D object face distance and ID.
    float obj2D = d3[index];
    vec2 id = vID[index]*scale;
    
    // Object heights.
    vec3 h3 = hm3(gIP)*.25 + .05;
    float h = h3[index];

 
    // Texture position.
    vec3 txP = vec3(p2, p.z);
    vec3 txN = n;
    vec3 tx = tex3D(iChannel1, txP/2., txN);//vec3(.25);//

    
    // Subtle lines for a bit of texture.
    #ifdef LINES
    float lSc = 24.;
    float pat = (abs(fract((p2.x - p2.y)*lSc - .5) - .5) - .125)/lSc;
    #endif  
    

  
    // Standard material properties: Roughness, matType and reflectance.
    //
    float roughness = .2; // Lower roughness reflects more light, as expected.
    float matType = 0.; // Dielectric (non conducting): 0, or metallic: 1.
    float reflectance = .5; // Reflective strength.
    
    
    // Object color.
    vec3 oCol = vec3(0);
    
    // Use whatever logic to color the individual scene components. I made it
    // all up as I went along, but things like edges, textured line patterns,
    // etc, seem to look OK.
    //
    if(gObjID == 0){
    
    
       // Floor -- Redundant here, but I've included it anyway.
       oCol = vec3(.125);
       matType = 1.; // Metallic material.
       roughness = .5;
       
       
    }
    else if(gObjID==1){
    
        // Extruded Truchet:

        // Noise texture, used for a hacky scratched surface look.
        // Usually, you'd tailor this to specific material needs.
        vec3 txR = txP;
        txR.xy *= rot2(-3.14159/6.);
        vec3 rTx = tex3D(iChannel2, txR*vec3(.5, 3, .5), txN);
        float rGr = dot(rTx, vec3(.299, .587, .114));
 
        
        // The tile base color.
         
        float sRnd = hash21(id + .01); // Random tile component value.
        
        //sRnd = id.x;
        vec3 sCol = .5 + .45*cos(6.2831*sRnd/8. + (vec3(0, 1, 2) + .05));//vec3(1, .15, .45);
        sCol = pow(sCol, vec3(1.5));
        
        #if COLOR_VARIETY >= 2
        if(hash21(id + .27)<.35) sCol = sCol.zyx; //yzx
        #endif
        
        #if COLOR_VARIETY >= 3
            #ifdef SWIZZLE_PALETTE
            if(hash21(id + .15)<.35) sCol = mix(sCol, sCol.yxz, .5);
            #else
            if(hash21(id + .15)<.35) sCol = mix(sCol, sCol.xzy, .5);
            #endif
        #endif
 
        // Face rim and face distance values for edge rendering. 
        float b = abs(obj2D) - .01;
        float pH = p.z + h - .04;
        b = max(b, (p.z + h - .02));
        
        float sf = .01; // Smoothing factor.
        float ew = .02; // Edge width.
        
        #ifdef RANDOM_MATERIALS
        float rRnd = hash21(gIP + .11);
        sCol = .5 + .45*cos(6.2831*rRnd + vec3(0, 1, 2)*hash21(gIP + .4)*1.5);
        #endif
        
        #ifdef EDGES
        
            float rW = .035; // Rim width.
            
            oCol = sCol;
            oCol = mix(oCol*.8, oCol*.15, (1. - smoothstep(0., sf, pH)));
            oCol = mix(oCol, mix(min(sCol*1.4, 1.), vec3(1), .2), (1. - smoothstep(0., sf, pH + ew)));
            oCol = mix(oCol, oCol*.15, (1. - smoothstep(0., sf, obj2D + rW)));

            #ifdef LINES
            // If applicable, apply lines to the inner face color.
            sCol = mix(sCol*1.15, sCol*.7, (1. - smoothstep(0., sf, pat)));
            #endif
            oCol = mix(oCol, sCol, (1. - smoothstep(0., sf, obj2D + rW + ew)));
        #else
        
            oCol.xyz = sCol;
            #ifdef LINES
            // If applicable, apply lines to the inner face color.
            pat = max(pat, pH + .02);
            oCol = mix(oCol, oCol*.15, (1. - smoothstep(0., sf, abs(pH + .02) - ew/2.)));
            oCol = mix(oCol*1.1, oCol.xyz*.7, (1. - smoothstep(0., sf, pat)));
            #endif
            
        #endif          
          
        
        // Greyscale value, calculated prior to gradient coloring.
        float gr = dot(oCol.xyz, vec3(.299, .587, .114));
        
        // Subtle face color gradient.
        oCol = mix(oCol, oCol.xzy, clamp(-p2.y - .125, 0., 1.));
        //oCol.xyz = mix(oCol.xyz, oCol.xzy, clamp(obj2D/scale*3. + .5, 0., 1.));

        #if COLOR_VARIETY == 0
        oCol.xyz = vec3(gr*sqrt(gr)*1.5);
        #endif
        
        #ifdef SWIZZLE_PALETTE
        oCol = oCol.yzx;
        #endif
   
      
        #ifndef RANDOM_MATERIALS   
        if(hash21(id + .2)<METAL_AMOUNT){
        //if(hash21(gIP + .2)<.25){ // gPI: Square cell ID.
        //if(mod(floor(gIP.x) + floor(gIP.y), 2.)>.5){ 
            
            
            // Metal material.
            
            // Mostly grey with tiny leftover color residue.
            oCol = mix(oCol, vec3(gr), .9);
             
            // Gold. Interesting, but a bit much for this example,
            // so the default is set to zero.
            #ifdef GOLD_AMOUNT
            if(hash21(id + .43)<GOLD_AMOUNT) oCol.xyz *= vec3(1, .75, .4)*2.5;
            #endif

            matType = 1.; // Metallic material.
            oCol.xyz *= tx*1. + .5;
            roughness = .6;
            //roughness *= gr*2.;
            roughness *= rGr*.6 + .4;
            
            // Metallic materials look dark when compared to their non-conducting 
            // dielectric equivalent, so for design sake, we're artificially 
            // inflating the brightness.
            //sCol *= 1.5;
        }
        else {
        
            // Dielectic material.
            
            roughness = .3;
            roughness *= (rGr*.4 + .6);
            oCol *= tx*.6 + .9;
             
        }
        #endif
        
        #ifdef RANDOM_MATERIALS
        roughness = hash21(gIP + .31)*(rGr*.5 + .5);
        matType = step(.5, hash21(gIP + .32));
        reflectance = hash21(gIP + .33);
        oCol *= tx*2.5 + .2;// + .5;
        #endif
        
        
        
    }

    /*
    // Requires "St Peter's Basillica" cube map loaded into "iChannel3".
    // Specular reflection.
    vec3 hv = normalize(-r + ld); // Half vector.
    vec3 ref = reflect(r, n); // Surface reflection.
    vec4 refTx = texture(iChannel3, -ref.yzx, 1.); refTx *= refTx; // Cube map.
    float spRef = pow(max(dot(hv, n), 0.), 8.); // Specular reflection.
    //spRef = mix(spRef/4., spRef, 1. - smoothstep(0., .01, d + .05));   
    float rf = (matType < .5)? .25 : 2.;//mix(.25, 4., 1. - smoothstep(0., .01, d + .05));
    oCol += oCol*reflectance*spRef*refTx.zyx*rf; //smoothstep(.03, 1., spRef) 
    */


    // I wanted to use a little more than a constant for ambient light this 
    // time around, but without having to resort to sophisticated methods, then I
    // remembered Blackle's example, here:
    // Quick Lighting Tech - blackle
    // https://www.shadertoy.com/view/ttGfz1
    float am = pow(length(sin(n*2.)*.5 + .5)/sqrt(3.), 2.)*1.5; // Studio.
    //float am = length(sin(n*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -n.z); // Outdoor.
 
    // Cook-Torrance based lighting.
    vec3 ct = BRDF(oCol, n, ld, -r, matType, roughness, reflectance);
        
    // Combining the ambient and microfaceted terms to form the final color:
    // None of it is technically correct, but it does the job. Note the hacky 
    // ambient shadow term. Shadows on the microfaceted metal doesn't look 
    // right without it... If an expert out there knows of simple ways to 
    // improve this, feel free to let me know. :)
    c.xyz = (oCol*am*(sh*.5 + .5) + ct*(sh))*ao*at;
     
 
    // Save the linear color to the backbuffer.
    c = vec4(max(c.xyz, 0.), t);  

}