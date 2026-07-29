// Image (image) — Extruded Hilbert Curve by Shane
// https://www.shadertoy.com/view/7lKfWW

/*

    Extruded Truchet Pattern
    ------------------------
    
    This is an extruded version of the parameterized Hilbert curve I posted
    earlier. I was expecting it to be a little trickier to code than it was,
    but most of the work was performed in the 2D version.

    The best way to do this would be to precalculate the required 2D information
    and store it on the backbuffer. However, I wanted to avoid multiple tabs
    and passes, resolution headaches, etc, so generated it on the fly. The code
    was slightly rushed, but it seems to run well enough on medium range machines.    
    
    I kept the curve design and background simple. The background originally had 
    more detail, but I felt it took away from the pattern itself, so I scaled it 
    back. The spheres aren't perfectly round, but I thought that gave the scene 
    some character.
    
    I have a more interesting version that I'll post at some stage. I also plan 
    to post a proper 3 dimensional version. If you'd like to see what one of 
    those looks like, I've posted links to Dr2 and MLA's examples below. 
    


    References:
    

    // Efficient and concise, as always.
    Hilbert 3D - dr2
	https://www.shadertoy.com/view/lltfRj
    
    // Hilbert curves in 3D using the Skilling algorithm.
    Hilbert Curves 3D - MLA
    https://www.shadertoy.com/view/flX3W8
    
    // A simpler flat 2D plane version.
	Hilbert Curve Animation - Shane
    https://www.shadertoy.com/view/NlKfzV


*/
 
// Maximum ray distance.
#define FAR 20.

// The number of Hilbert curve iterations. I designed everything to work with the
// number 4. However, values 3 to 6 will look OK. Numbers outside that range 
// haven't been accounted for.
const int iters = 4;

// Subtle textured lines.
//#define LINES


// Object ID: Either the back plane, extruded object or beacons.
int objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

// IQ's vec2 to float hash.
//float hash31(vec3 p){  return fract(sin(dot(p, vec3(27.619, 57.583, 19.257)))*43758.5453); }

// Global time, to keep track for the rolling spheres.
float gTime;

// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){ 
    
    n = max(abs(n) - .0, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n);
    
    // Texure samples. One for each plane.
    vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture sample,
    // represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}

 
/*
// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}
*/


// IQ's unsigned line distance formula.
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// Arc distance formula.
float dist(vec2 p){

   
    // Circular.
    return length(p);
    
    // Hard square edge. The sphere's get distorted, but some fine
    // tuning could fix that.
    //p = abs(p);
    //return max(p.x, p.y);
    
    // Rounded square.
    //p = abs(p) - .015;
    //return min(max(p.x, p.y), 0.) + length(max(p, 0.)) + .015;
    
    // Diamond and octagon.
    //p = abs(p);
    //return abs(p.x + p.y)*.7; // Requires readjusting in the Hilbert arc logic.
    //return max(max(p.x, p.y), abs(p.x + p.y)*.7);
}

void swap(inout vec2 a, inout vec2 b){ vec2 t = a; a = b; b = t; }


vec2 gDir; // Cell direction flag.
float squashF; // Squashing factor hack, based on straight of arc curved cells.

//
// A standard Hilbert curve routine with some extra parameterization hacked
// in at the end. It needs some tidying up, but it works pretty fast, all 
// things considered. I've taken an approach that's very similar to Fabrice's
// example, here: 
//
// Hilbert curve 5 - FabriceNeyret2
// https://www.shadertoy.com/view/XtjXW3

// Fabrice's started with a different orientation, which has led to slightly
// neater logic, which I might try to incorporate later.
vec4 hilbert(vec2 p){ 

    // Hacking in some scaling.
    float hSc = 1./4.;
    // If you scale the coordinates, you normally have to scale things back
    // after you've finished calculations.
    p *= hSc; 
    
    // Saving the global coordinates prior to subdivision. I'm not experiencing
    // alignment glitches, but I'm using Fabrice's hack, just to be on the safe side. :)
    vec2 op = p + 1e-4; 
    
    // Initial scale set to one.
    float sc = 1.;
    
    // Cell ordering vector -- Clockwise from the bottom left. If the new partitioned
    // frame is flipped, then this will be also.
    ivec4 valC = ivec4(0, 1, 2, 3);
    
    // Initate to top left quadrant cell.
    int val = 1;
    
    p = op; // Initialize.
    
    // Splitting the curve block into two. There's no real reason for doing this,
    // but I thought it filled the canvas dimensions a little better... Plus, I
    // like to complicate things for myself. :)
    if(p.x<0.) p.x = abs(p.x) - .5; // Left half -- Moved to the left.
    else { p.x = .5 - abs(p.x); p = -p.yx;  } // Right half -- Moved right and rotated CCW.
    
    p = fract(p + .5); // Needs to begin in the zero to one range.
    p *= vec2(-1, 1); // Not absolutely necessary, but we're forcing the top left quadrant split.
    
    // The horizontal and vertical vectors. I've adopted Fabrice's naming
    // convention (i and j), but have stored them in one vector.
    vec4 ij = vec4(1, 0, 0, 1), d12 = ij; //vec4(ij.xy, -ij.zw);
 
    int rn = 0; // Cell number.
   
    float dirX = 1.; // Hacked in to keep track of the left or right of the curve.
    
    for(int i = min(0, iFrame); i<iters; i++){
       
       
        // The quadrant splitting logic:
        // Bottom left: Rotate clockwise. Leave the first direction alone. The second points up.
        // Top left: Leave the space untouched. First direction points down. Second points right.
        // Top right: Flip across the X-axis. First direction points left. Second points down.
        // Bottom right: Rotate clockwise then flip across the X-axis. First points up. Second left alone.
        
        if(p.x>0.){
            // You need to reverse the rendering order of the two right cells.
            // In other words, swap(dir1, dir2);
            if(p.y>0.){ d12 = -ij; p.x = -p.x;  d12.xz = -d12.xz; val = 2; } // Top right.
            else { d12.xy = ij.zw;  /*d12.xy = ij.zw;*/ 
                 p = p.yx*vec2(1, -1); d12 = d12.yxwz*vec4(1, -1, 1, -1); 
                 dirX *= -1.; val = 3; // Bottom right  (Exit).
            } 

            // Flip vector directions on the right -- You could incorporate this into the
            // lines above, if you wanted to.
            d12 = d12.zwxy; 
          
            valC = valC.wzyx; // Reverse rendering order direction in the right quadrants.

        }
        else {
        
            if(p.y>0.){ d12 = vec4(-ij.zw, ij.xy); val = 1; } // Top left.
            else { /*d12.xy = -ij.zw;*/ d12.zw = ij.zw; p = p.yx; d12 = d12.yxwz; 
                 dirX *= -1.; val = 0; // Bottom left (Entry).
            }  
          
        }
        
        // Ordering the cells from start to finish -- There's probably a smarter way,
        // but this is what I came up with at the time. It works, so it has that 
        // going for it. :)
        //
        // The new quadrant value, after splitting, rotating, flipping, etc, above.
        int valN = p.x<0.? p.y<0.? 0 : 1 : p.y<0.? 3 : 2; 
        // Number of squares per side for this iteration.
        int sL = 1<<(iters - i - 1); // 1, 2, 4, 8, etc.
        // Position number multiplied by total number of squares for each iteration.
        rn += valC[valN]*sL*sL;
       
        // Subdivide and center.
        p = mod(p, sc) - sc/2.;
        sc /= 2.;
        

   
    }

    
    // Square block number.
    float sL = float(1<<(iters - 1));
 
   
    // The distance field value.
    float d = 1e5;
    
    // If a swap occurred, swap the rendering order of dir1 and dir2.
    //if(valC[val] != val) d12 = d12.zwxy;
 
   
    // If a swap has occurred, reverse direction.
    float dir = valC[val] != val? -1. : 1.;
    
    
    float crvLR = 4./3.14159265; //Curve length ratio.
    
    // The two direction vectors in this cell are perpendicular. 
    // Therefore, calculate the arc distance function and coordinates.  
    // Otherwise, the direction vectors are aligned, so calculate
    // the line portion.
    //
    // By the way, for those who don't know, curvy line coordinates are
    // similar to 2D Euclidean plane coordinates. However, the X value runs 
    // along the curve and the Y value is perpendicular to the curve.
    //
    if(dot(d12.xy, d12.zw) == 0.){
        
        // Arc distance field and the conversion of 2D plane coordinates
        // to curve coordinates.
        
        // Using the perpendicular direction vectors to center the arc.
        p -= (d12.xy + d12.zw)*sc;
        
        // Pixel angle.  
        float a = atan(p.x, p.y); 
       
        p.y = dist(p) - sc; // The Y coordinate (centered arc distance).
        
        d = abs(p.y); // Distance field value.
        
        p.x = fract(dir*a/6.2831853*4.); // The X coordinate (angle). Order counts.
        
        // Hacky distortion factor at the border of the line and arcs.
        //crvLR = mix(1.,  crvLR, 1. - p.x);
    }
    else { 
     
        // Line distance field and curve coordinates. 
        
        d = distLine(p, d12.xy*sc*1., d12.zw*sc); // Line distance.
        p.x = fract(dir*p.x*sL - .5); // Straight line coordinate.
        // p.y remains the same as the Euclidean Y value.
        
        // Hacky distortion factor at the border of the line and arcs.
        crvLR = mix(1., crvLR, smoothstep(0., 1., abs(p.x - .5)*2.));
        //crvLR = 1.;
    }
   
   
    // Using the current ordered cell value, the total number of cells and
    // the fractional curve cell value to calculate the overall ordered position
    // of the current pixel along the curve.
    float hPos = (float(rn) + p.x)/(sL*sL);
    
    // Getting rid of curves, etc, outside the rectangle domain.
    if(abs(op.x)>1. || abs(op.y)>.5){ d = 1e5; p = vec2(1e5); }
    
    // Handling (hacking) the entry and exit channels separately.
    if(op.y>.5){ 
        d = min(d, distLine(op - vec2(.5/sL, 0), vec2(0), ij.zw*4.)); 
        hPos = 1. + (op.y - .5)/(sL); 
        p.x = fract(op.y*sL); // Angle for this channel.
        crvLR = mix(1., crvLR, smoothstep(0., 1., abs(p.x - .5)*2.));
        p.y = (op.x - sc)*dirX;
        
    }
    if(op.y<-.5){ 
        d = min(d, distLine(op - vec2(-1. + .5/sL, 0), vec2(0), -ij.zw*4.)); 
        hPos = (op.y + .5)/(sL); 
        p.x = fract(op.y*sL); // Angle for this channel.
        crvLR = mix(1., crvLR, smoothstep(0., 1., abs(p.x - .5)*2.));
        p.y = -(op.x + (1. - sc))*dirX;
        
    }
    
    squashF = crvLR; 
   
    p.x = fract(p.x + gTime);
    // The curve coordinates -- Scaled back to the zero to one range.
    p = vec2((p.x - .5)/sL/crvLR, p.y*dirX);
    
    
 
    // Line thickness.
    d -= .3/sL;

    // Accounting for the left and right Hilbert curve blocks.
    if(op.x<0.){ hPos = 1. - fract(-hPos); p.y *= -1.; }
    
    gDir = vec2(dirX, dir);
    
    // Return the distance field, curve position, and curve coordinates.
    return vec4(d/hSc, hPos, p/hSc);

}

// // Emulating sin and cos waves with a triangle function.
//vec2 sinT(in vec2 x){ return 1. - abs(fract(x/6.2831 + .25) - .5)*4.; }
//vec2 cosT(in vec2 x){ return 1. - abs(fract(x/6.2831 + .5) - .5)*4.; }

// Very basic terrain function consisting of some rotated transcendental layers.
vec2 terrain(vec3 p){

    // Simple, but cheap, background hills.
    vec2 q = p.yx*1.8;
    float terr = 1. - (dot((sin(q - cos(q.yx)*1.57)), vec2(.25)) + .5);
    q *= rot2(3.14159/2.75);
    float terr2 = 1. - (dot((sin(q*3.25 - cos(q.yx*3.25)*1.57 + 1.)), vec2(.25)) + .5);
    //terr = mix(terr, 1. - abs(terr2 - .5)*2., .15);
    //q *= rot2(3.14159/1.5);
    //float terr3 = (dot((sin(q*6.5 - cos(q.yx*6.5)*1.57 + 2.)), vec2(.25)) + .5);
    //terr2 = mix(terr2, terr3, .333);
     //terr = mix(terr, abs(terr - .5)*2., .333);
     
    // Carving out the entry and exit road passes.
    float sL = float(1<<(iters - 1));
    terr = smin(terr, max(abs(p.x - 4.*.5/sL) - 2./sL, -p.y + 2.), .25); 
    terr = smin(terr, max(abs(p.x + 4.*(1. - .5/sL)) - 2./sL, p.y + 2.), .25);
    
    return vec2(terr, terr2);

}
 
// The scene's distance function. There'd be faster ways to do this.
float m(vec3 p){
    
        // Square block number.
    float sL = float(1<<(iters - 1));
    // Rectangular bound.
    float bound = sBoxS(p.xy, vec2(4, 2), 0.);//max(abs(p.x) - 4., abs(p.y) - 2.);

    // Back plane.
    float fl = -p.z;//abs(p.z - 2.) - 2.;
    // Terrain function.
    vec2 terr = terrain(p);
    // Adding the terrain to the flat plain.
    fl -= smoothstep(0., 1., bound)*terr.x*.6 + terr.y*.1  - .1;
    //fl -= clamp(bound, 0., 1.)*terr.x*.6 + terr.y*.1  - .1;

    
    
    // 2D Hilbert distance, for the extrusion cross section.
    vec4 hilb = hilbert(p.xy);
    float obj = hilb.x;
    
    // Variable extrusion height along the length of the curve.
    const float hN = 3.;
    float hgt = cos(6.2831*hilb.y*hN - 3.14159265)*.5 + .5;
    

    // Extruded curve height factor.
    const float hf = .2; 
    // Extrude the 2D Hilbert curve object along the Z-plane. Note that this is a cheap
    // hack. However, in this case, it doesn't make much of a visual difference.
    obj = max(obj, abs(p.z - .25*7./4. + (hgt*hf + .25)) - (hgt*hf + .25)) + smoothstep(.03, .2, -obj)*.05;
    // Proper extrusion formula for comparisson.
    //obj = opExtrusion(obj, p.zz - .25*7./4. + (hgt*hf + .25), hgt*hf + .25, .01) 
    //      + smoothstep(.03, .2, -obj)*.05;
    

    // The rolling spheres.
    float ballSz = .9/sL; //
    // Patitioning the curve's X position.
    vec3 bp = vec3(hilb.zw, p.z - .25*7./4. + (hgt*hf + .25)*2.) + vec3(0, 0, ballSz - .01);
    
    //const float N = 4.;
    //bp.x = (mod(hilb.y + (gTime + .5)/(sL*sL), 1./N) - .5/N)*sL/squashF*4.;
    float rollSp = (hilb.y + gTime)/(ballSz*1.57);
    bp.xz *= rot2(rollSp);
    
    // Spheres.
    float ball = (length(bp) - ballSz);
    //float ball = sBoxS(bp, vec3(ballSz), ballSz*.25);
 
     // Only show four spheres per curve -- There are two curves joined on either side
     // of the zero X line, so eight spheres altogether.
     float crv = fract(hilb.y + gTime/(sL*sL));
     if(mod(floor(crv*(sL*sL)), sL*sL/4.)>.5) ball = 1e5;
   
    // Object ID.
    objID = fl<obj && fl<ball? 0 : obj<ball? 1 : 2;
    
    // Minimum distance for the scene.
    return min(min(fl, obj), ball);
    
}

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float d, t = 0.;//hash21(ro.xy*57. + fract(iTime + ro.z))*.5;
    
    for(int i = min(iFrame, 0); i<72; i++){
    
        d = m(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.

        t += d*.7; 
    }

    return min(t, FAR);
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
    

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<iter; i++){

        float d = m(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // IQ's subtle refinement.
        t += clamp(d, .01, .1); 
        
        
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
	
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += m(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 texBump( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3(tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(.299, .587, .114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(.299, .587, .114)))/e.x; 
    
    // Adjusting the tangent vector so that it's perpendicular to the normal -- Thanks to
    // EvilRyu for reminding me why we perform this step. It's been a while, but I vaguely
    // recall that it's some kind of orthogonal space fix using the Gram-Schmidt process. 
    // However, all you need to know is that it works. :)
    g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
	
}


void mainImage(out vec4 c, vec2 u){

    
    // Aspect correct coordinates. Only one line necessary.
    u = (u - iResolution.xy*.5)/iResolution.y;    
    
    // Unit direction vector, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), o = vec3(0, -2.5, -3), l = o + vec3(-1, 3, 1.5);//vec3(0, -2.5, -3)//1.5
    
    // Distorting the camera.
    r = normalize(vec3(r.xy, r.z - length(r.xy)*.2 + (u.y + .5)*(u.y + .5)*.0));
    
    
    // Rotating the camera about the XY plane.
    r.yz = rot2(.6)*r.yz;
    r.xz = rot2(-cos(iTime*3.14159/16.)/6.)*r.xz;
    r.xy = rot2(sin(iTime*3.14159/16.)/8.)*r.xy; 
    
    // Global animated sphere timing.
    gTime = iTime*1.5;
  
    
    // Raymarch to the scene.
    float t = trace(o, r);
    
    // Cell direction debug.
    vec2 svDir = gDir;
    
    // Object ID: Back plane (0), or the metaballs (1).
    int gObjID = objID;
    
    
    // Very basic lighting.
    // Hit point and normal.
    vec3 p = o + r*t, n = nr(p); 
    
    // Integrating bump mapping -- Not used here. It's possible
    // to bump map on a pass by pass basis to save cycles.
    vec3 smN = n;
    float bf =  gObjID == 0? .1 : .01; 
    if(gObjID<2) n = texBump(iChannel1, p, n, bf);///(1. + t/FAR)
    

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
    
    
    // spr: sample spread, amp: amplitude, offs: offset.
	float spr = 4., amp = 4., offs = -.0;
    //float crv = curve(p, spr, amp, offs)*.95 + .05;
    
    
    float df = max(dot(n, ld), 0.); // Diffuse.
    float sp = pow(max(dot(reflect(r, n), ld), 0.), 32.); // Specular.
    
    
    // UV texture coordinate holder.
    vec2 uv = p.xy;
    // Cell ID and local cell coordinates for the texture we'll generate.
    float sc = 1./float(1<<(iters - 3)); // Scale: .5 to about .2 seems to look OK.
    vec2 iuv = floor(uv/sc) + .5; // Cell ID.
    uv -= iuv*sc; // Local cell coordinates.
    
    // Smooth borders.
    float bord = max(abs(uv.x), abs(uv.y)) - .5*sc;
    bord = abs(bord) - .002;
    
    // 2D Hilbert face distace -- Used to render borders, etc.
    vec4 hilb = hilbert(p.xy);
    float d = hilb.x;
    
    
    // Subtle lines for a bit of texture.
    #ifdef LINES
    float lSc = 20.;
    float pat = (abs(fract((uv.x - uv.y)*lSc - .5) - .5)*2. - .5)/lSc;
    float pat2 = (abs(fract((uv.x + uv.y)*lSc + .5) - .5)*2. - .5)/lSc;
    #else
    float pat = 1e5, pat2 = 1e5;
    #endif     
     
    // Colors for the floor and extruded face layer. Each were made up and 
    // involve subtle gradients, just to mix things up.
    float sf = dot(sin(p.xy - cos(p.yx*2.)), vec2(.5));
    vec4 col2 = mix(vec4(1., .75, .6, 0), vec4(1, .85, .65, 0), smoothstep(-.5, .5, sf));
    vec4 col1 = pow(col2, vec4(1.6));
    
    // Object color.
    vec4 oCol;
  
    
    // Use whatever logic to color the individual scene components. I made it
    // all up as I went along, but things like edges, textured line patterns,
    // etc, seem to look OK.
    //
    if(gObjID == 0){
    
       // The terrain.
        float sL = float(1<<(iters - 1));   

        vec2 vT = terrain(p);
        float terr = vT.x*.85 + vT.y*.15;
        
        // Redening the terrain crevices and making the slopes lighter.
        oCol = mix(col1, col1, smoothstep(.85, 1., abs(n.z)));
        // Fake terrain height-based occlusion.
        oCol *= terr*.5 + .5;

        // Using the Hilbert pattern for some bottom edging.
        oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, d - .02))*.7);

        vec3 tx = tex3D(iChannel0, p/2., n);
        oCol *= tx.xyzz*2. + .2;
        
        //vec3 tx2 = tex3D(iChannel1, p/2., n);
        //oCol = mix((oCol + .5)*tx2.xyzz, oCol, abs(n.z));
        //float gr = dot(tx2, vec3(.299, .587, .114));
        //oCol *= gr*1.5 + .65;
       
    }
    else if(gObjID==1){
    
        // Extruded Hilbert pattern:
 
        // Cream sides with a dark edge. 
        oCol = mix(vec4(1, .9, .8, 0), vec4(0), 1. - smoothstep(0., .01, d + .035));
        
        //if(svDir.y<0.) col1 *= vec4(1.2, 1.7, 1, 0); // Debug opposite direction cells
        
        // Hilbert pattern dimension -- Number of cells per side.
        float sL = float(1<<(iters - 1));
        
        // Four trails per curve to match each rolling sphere.
        const float N = 4.;
        float trailL = 1./3.; // Fraction of space between tolling spheres.
        // Trail and trail tip positions.
        float x = (mod(hilb.y - trailL/2./N - .5/N + (gTime - .5)/(sL*sL), 1./N) - .5/N);
        float x2 = (mod(hilb.y - .5/N - .03/sL + (gTime - .5)/(sL*sL), 1./N) - .5/N)*sL/squashF*4.;
        
        // Trail tip, trail and trail fade factor.
        float tip = length(vec2(x2, hilb.w)) - 1./sL;
        float trail = (abs(x) - trailL/2./N)*sL/squashF*4.;
        float trailFade = (1. - max(x/(trailL/2./N), 0.))*.5;

        // Applying the trails to the colored section of the pattern.
        col1 = mix(col1, vec4(1, .1, .4, 0), (1. - smoothstep(0., .01*4., min(trail, tip)))*trailFade);
       
        // Golden faces with some subtle lines.
        vec4 fCol = mix(col1, vec4(0), (1. - smoothstep(0., .01, pat))*.35);
        // Square borders: Omit the middle of edges where the Truchet passes through.
        fCol = mix(fCol, vec4(0), (1. - smoothstep(0., .01, bord))*.8);
        // Darken alternate checkers on the face only.
        if(mod(iuv.x + iuv.y, 2.)<.5) fCol *= .8;
        
        // Apply the golden face to the Hilbert pattern, but leave enough room for an edge.
        oCol = mix(oCol, fCol, 1. - smoothstep(0., .01, d + .065));
        
        // Applying some texture.
        vec3 tx = tex3D(iChannel0, p/2., n);
        oCol *= tx.xyzz*2. + .2;
        
        
    }
    else {
    
       // Hilbert pattern dimension -- Number of cells per side.
       float sL = float(1<<(iters - 1));
       
       // The rolling ball.
       float hf = .2; // Curve height factor.
       float ballSz = .9/sL; // Sphere size.
       // Curve height equation.
       const float hN = 3.;
       float hgt = cos(6.2831*hilb.y*hN - 3.14159265)*.5 + .5;
       
       // Sphere position along the curve.
       vec3 bp = vec3(hilb.zw, p.z - .25*7./4. + (hgt*hf + .25)*2.) + vec3(0, 0, ballSz - .01);
        
       
       
       // Rollong sphere angle: CurveXCoord/Sphere_Rad .
       float rollSp = fract((bp.x + gTime)/3.14159265)/(ballSz/2.);
       // Apply the rotation to the curve's X coordinate -- Not to be confused with the
       // global Euclidean X coordinate, which is just p.x.
       bp.xz *= rot2(rollSp); // ang = time/radius.
  
       // I always forget this, but the object's normal needs to rotated in the 
       // same manner to match.
       vec3 tn = n;
       tn.xz *= rot2(rollSp);
        
       // Sphere color. Roughly the same as the trail color.
       oCol = mix(col1, vec4(1, .1, .4, 0), .5);
       
       // Applying some texture.
       vec3 tx = tex3D(iChannel0, bp*4., tn).xxx;
       oCol *= tx.xyzz*2. + .2;
           
    
    } 
    
      
    // Apply the lighting and shading. 
    c = oCol*(df*sh + sp*sh + .5)*at*ao;
     

    // Rough gamma correction.
    c = sqrt(max(c, 0.));  

}