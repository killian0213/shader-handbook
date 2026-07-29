// Image (image) — Isometric Cube Pattern by Shane
// https://www.shadertoy.com/view/lXGcDD

/*

    Isometric Cube Pattern
    ----------------------
    
    Producing a common hexagonal design by constructing an isometric camera, 
    then rendering a simple block pattern onto the faces of a cube.
    
    I love making simple well-known geometric images. Most of the time, I
    find it more fun to figure out a way to use 2D methods to render them,
    but every now and again, it makes more sense to simply render the object
    in 3D, then give it a bit of a 2D look. This is one of the latter
    situations.
    
    This example was pretty simple and quick to make: Set up an isometric 
    camera, render block lines onto the faces of a cube, add in some basic 
    animation, then color things up a bit. The details are in the code.    
    

*/

// Use an isometric camera setup.
#define ISOMETRIC

// Surface bevel.
//#define BEVEL

// Face surface-line holes.
//#define HOLES

// Join the face lines together: I put this in after reading Flockaroo's 
// comment. Once you see it, you can't unsee it... 
// 
// Just for the record, it's pretty difficult to make cross related
// square spiral patterns without that symbol appearing in some kind 
// of disguised form, and the shadow you can see is the reversed version 
// anyway, which is a peace symbol that is present in many parts of Asia... 
// Either way, it's no longer the default pattern.
#define JOIN    

// Far plane, or maximum ray distance.
#define FAR 40.

#define PI 3.14159265


// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    //f = mod(f + 16384., 16384.); // Annoying GPU hash related hack.
    uvec2 p = floatBitsToUint(f);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Object rotation, with some optional mouse movement.
vec3 objMove(vec3 p){

    
    if(iMouse.z>1.){
        // Mouse override.
        vec2 ms = (iMouse.xy - iResolution.xy*.5)/iResolution.xy*PI;
        p.yz *= r2(-ms.y);  
        p.xz *= r2(-ms.x);   
    } 
    else {
    
        // Key frame animation. It's very common in software and the 
        // demoscene. It's kind of overkill here, but I figured it'd
        // be interesting to those who aren't familiar with the concept.
        
        // Time variable. Set so that each scene will last four seconds each,
        // but it can be more elaborate than that.
        float tm = iTime/4.;
        // Total scenes.
        float sceneTotal = 3.;
        // Current scene number.
        float sceneNum = mod(floor(fract(tm/sceneTotal)*sceneTotal), sceneTotal);
        
        // Fractional time per scene. Zero marks the beginning of the
        // scene and one means it's time to reset and move to the next scene.
        float fT = fract(tm); 
        
        // What you do with each fractional time component is up to you, but
        // here we're just performing some very basic easing.
        //
        // Easing: That's its own subject.
        fT = smoothstep(0., .25, fT);
        float ang = fT*PI;
        mat2 m2 = r2(ang);
        
        // Animate each individual scene block.
        //
        // The animation here is very simple. In each scene, rotate 
        // around a different axis. However, the animation can be
        // as elaborate as you'd like to make it.
        if(sceneNum==0.){
            p.xz *= m2; // Rotate around Y.
        }
        else if(sceneNum==1.){
            p.yz = m2*p.yz; // Rotate around X (opposite way).
        }  
        else p.xy *= m2; // Rotate around z. 
        
    }
    
    return p;

}

 // IQ's 2D box formula with smoothing.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}

// IQ's 3D box formula with smoothing.
float sBoxS(in vec3 p, in vec3 b, in float rf){
  
  vec3 d = abs(p) - b + rf;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - rf;
    
}


// Storage for four object distances.
vec4 objD;
  

float m(vec3 p){

    // Cube scale.
    vec3 sc = vec3(1)/2.;

    vec2 sc2 = sc.xy/7.; // 7x7 face block scale.
    
    // Extra thickness on the pixel blocks.
    float th = sc2.x/8. + .001; 
  
     
    // Floor.
    float fl = p.y;
 
    
    // Object positioning and movement.
    vec3 q = p - vec3(0, sc.y, 0);
    
    
    q = objMove(q);
  
    // In this case, the box faces are split into 7x7 equal squares.
    // The idea is to create a bit pattern on each face. How you do
    // that depends on the pattern design. This one is pretty simple.
    // which is 8 line strokes. 
    
    
    // The cube itself. Note the extra one. That's just a hack to 
    // ensure no cube roundness.
    float bx = sBoxS(q, sc/2. + 1., .0) + 1.;
    // Just the outer cube shell.
    bx = abs(bx + sc.x/7./2.) - sc.x/7./2. - th;
    
    // Cube face direction normals.
    vec3 fq = abs(q); 
    fq = step(fq.yzx, fq)*step(fq.zxy, fq)*sign(q); // Used for cube mapping also.

    // 2D face coordinates.
    vec2 p2 = abs(fq.x)>.5? q.yz : abs(fq.y)>.5? q.zx : q.xy;
    
    // Reorienting the face patterns for this particular example, to 
    // make them match up the way we'd like them to. This is unique to
    // this particular example and was determined by trial and error.
    if((fq.x)>.5) p2.x = -p2.x;
    if((fq.z)>.5) p2.x = -p2.x;
    if((fq.y)>.5) p2.x = -p2.x;
 
 
    // Box lines.
    //
    // Rendering the box lines on each face the easy, but more expensive, way.
    // Most machines can handle this. However, if you wanted to speed things
    // up, you could look for symmetry, and employ the usual tricks.
    //
    // There are six line-box renders per face, but we only need perform
    // of these per pass, so it's not too bad.

    float sf = .0;
    float bxLn = 1e5;
    
    
    
    
    vec2 dim = sc2*vec2(3, 1)/2. + th; // Box line dimensions.
   
    #ifdef JOIN
    // Longer joining line.
    vec2 dim2 = sc2*vec2(5, 1)/2. + th;
    bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(-1, 1), dim2, sf)); // X-line.
    bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(1, -1), dim2, sf)); // X-line.
    #else
    bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(-2, 1), dim, sf)); // X-line.
    bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(2, -1), dim, sf)); // X-line.
    #endif
     //bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(-3, -0), dim.yx, sf)); // Y-line.
    //bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(3, -0), dim.yx, sf)); // Y-line.
    vec2 p22 = p2; p22.x = abs(p22.x);
    bxLn = min(bxLn, sBoxS(p22 - sc2*vec2(3, -0), dim.yx, sf)); // Y-line.
 
    // Using symmetry. to render the other four lines. There's probably 
    // a way to use folding trickery to combine the lines above, but
    // I'm feeling lazy. :)
    p2 = p2.yx*vec2(1, -1);
    
    bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(-2, 1), dim, sf)); // X-line.
    bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(2, -1), dim, sf)); // X-line.
    //bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(-3, -0), dim.yx, sf)); // Y-line.
    //bxLn = min(bxLn, sBoxS(p2 - sc2*vec2(3, -0), dim.yx, sf)); // Y-line.
    p22 = p2; p22.x = abs(p22.x);
    bxLn = min(bxLn, sBoxS(p22 - sc2*vec2(3, -0), dim.yx, sf)); // Y-line.
 
 
    #ifdef HOLES
    // Face surface-line holes.
    bxLn = abs(bxLn + sc2.x/4.) - sc2.x/4.;
    #endif
    
    // Encapulating the 2D block lines within the cube face shell.
    float d = max(bx, bxLn);
    
    // Face line bevel.
    #ifdef BEVEL
    d += bxLn*.15; // Raised faces.
    //d -= min(-bxLn, .02)*.5; // Technically, more of a bevel.
    #endif
    
    // Object distances.
    objD = vec4(fl, d, 0, 0);
     
    // Minum object distance.
    return min(fl, d);
    
}

float rayMarch(vec3 ro, vec3 rd){
    
    float d, t = 0.;//hash31(ro + rd)*.25; // Glow jitter.
    vec2 dt = vec2(1e8, 0); // IQ's edge desparkle trick.


    const int iter = 128;
    int i = 0;
     
    for (i = 0; i<iter; i++) {
       
        d = m(ro + rd*t);
       
        // IQ's clever edge desparkle trick. :)
        if (d<dt.x) { dt = vec2(d, t); } 

        if (abs(d)<.001 || t>FAR){
            break;
        }
        
        // Advance the ray.
        t += d*.7;
    }
    
    if(i == iter - 1) { t = dt.y; }

    // Don't go further than the far plane.
    return min(t, FAR);
}


// Ambient occlusion. Based on IQ's original.
float cao(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<6; i++ ){
    
        float hr = .01 + float(i)*.25/6.;        
        float d = m(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        //if(occ>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}

// Standard normal function.
vec3 nr(in vec3 p) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), 
                          m(p + e.yxy) - m(p - e.yxy),	
                          m(p + e.yyx) - m(p - e.yyx)));
}


// Cubic curvature function.
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec3 p, in float spr, in float amp, in float offs){

    float d = m(p);
    
    spr /= 450.;

    // Cubic.
    vec2 e = vec2(spr, 0); 
	float d1 = m(p + e.xyy), d2 = m(p - e.xyy);
	float d3 = m(p + e.yxy), d4 = m(p - e.yxy);
	float d5 = m(p + e.yyx), d6 = m(p - e.yyx);
    return clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*6.)/e.x/2.*amp + offs + .5, 0., 1.);

}


void mainImage( out vec4 c, vec2 u ){

    
    // Screen coordinates.
    u = (u - iResolution.xy*.5)/iResolution.y;
      
    // Unit direction ray, origin vector and light vector.
    vec3 r, o, l = normalize(vec3(2, 4, 1));
        

    #ifdef ISOMETRIC

    // Orthographic camera.
	o = vec3(u, -4);
    // A unit direction ray, without the UV vanishing horizon component.
    r = vec3(0, 0, 1); 
    
    // Extra orientation to give the object a
    // flat top hexagon perspective.
    o.xy *= r2(PI/6.);
    //r.xy *= r2(PI/6.);
  
    // Isometric angle. 
    float isoA = atan(sqrt(.5));
    o.yz = r2(-isoA)*o.yz;
    r.yz = r2(-isoA)*r.yz;
    o.xz = r2(-PI/4.)*o.xz;
    r.xz = r2(-PI/4.)*r.xz;

    // Extra camera positioning.
    o = o + vec3(0, .5, .0);
    
    #else
    
    // More conventional camera setup.
    
    // Screen distortion.
    u *= 1. + dot(u, u)*.5;
    // Unit direction vector and origin.
    r = normalize(vec3(u, 1.2)); 
    o = vec3(.5, 1.15, -.9);
 
    // Rotating the unit direction ray.
    r.xy *= r2(.5);
    r.xz *= r2(.4);
    r.yz *= r2(.65);
    #endif
 
    
    
    // Raymarch the scene.
    float t = rayMarch(o, r); 

    
    // Object ID.
    int objID = objD.x<objD.y? 0 : 1;
    
    // Scene color, initialized to zero.
    c = vec4(0);
    
    // If we've hit an object, light it up.
    if(t<FAR){
    
        // Surface hit point and normal.
        vec3 p = o + r*t, n = nr(p);
        
        // Ambient occlusion.
        float ao = cao(p, n);
  
          
        // Diffuse and specular.
        float dif = max(dot(l, n), 0.);
        //float speR = pow(max(dot(normalize(l - r), n), 0.), 8.);
        //float spe = pow(max(dot(reflect(l, n), r), 0.), 8.);
        
        // Curvature.
        float spr = 2., amp = 1., offs = .0;
        float crv = curve(p, spr, amp, offs);
        
        
       
        if(objID==1){
         
            // Animated cube object.
            
            // Surface color.
            c = vec4(1, .3, .15, 0);

            /*
            // Normal-based coloring. Not used here.
            vec3 txN = n;
            txN = objMove(txN);
            c = vec4(.95, .175, .175, 0);
            if(abs(txN.x)>.5) c = vec4(1, .5, .5, 0);
            if(abs(txN.y)>.5) c = vec4(1, .75, .75, 0);
            */
        
        }
        else{
        
        
           // Floor.
        
           // Floor squares.
           vec3 sc = vec3(1)/12.;
           p.xz += sc.xz/3.;
           vec2 q = p.xz;
           vec2 iq = floor(q/sc.xz);
           q -= (iq + .5)*sc.xz; 
           
           // Diagonal triangle subdivision.
           float tID = q.x>-q.y? 0. : 1.;
           
           // Square floor cell.
           float bx = sBoxS(q, sc.xz/2., 0.);
           
           // Random diagonal subdivision.
           float rnd = hash21(iq + .01);
           if(rnd<.35){
               float divLn = (-q.x - q.y)*.7071;
               if(tID==0.) bx = max(bx, divLn);
               else bx = bx = max(bx, -divLn);
           }
           
           // Cell coloring.
           vec4 gCol = vec4(1, .9, .6, 0)*.5;
   
           float id = mod(iq.x + iq.y, 2.)==1.? 0. : 2.;
           if(rnd<.35) id += tID;
           else id = 0.;
          
           // Random coloring.
           gCol *= hash21(iq + id/4. + .11)*.15 + .85;
           
           // Render the cell's darkish lines and color.
           c = gCol*.6;
           c = mix(c, gCol, 1. - smoothstep(0., .01, bx + .005));
           
           
        }
             
        
        // Edge lines.
        c = mix(c, min(c*.6, 1.), abs(crv - .5)*2.);
      
        
        // Applying lighting and ambient occlusion.
        c.xyz = c.xyz*(dif*dif*2.5 + .5)*ao;
       
     
    }
    
    
    
    // Applying fog: This fog begins at 90% towards the horizon.
    c = mix(c, vec4(1, .9, .6, 0), smoothstep(0., .9, t/FAR));
  
    c.xyz = mix(c.xyz, c.yzx, clamp(-u.x/4.-u.y/2. + .25, 0., 1.)*.7);
 
  
    // Rough gamma correction.
    c = vec4(sqrt(clamp(c.xyz, 0., 1.)), 1.);
    
    
}