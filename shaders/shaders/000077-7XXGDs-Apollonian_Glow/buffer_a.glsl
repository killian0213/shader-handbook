// Buffer A (buffer) — Apollonian Glow by Shane
// https://www.shadertoy.com/view/7XXGDs

/*

    Apollonian Glow
    ---------------
    
    This is a pretty standard Apollonian scene with aesthetics that were
    heavily inspired by MrRange's "Reflecting Metallic Apollonian" post. 
    The link is below, for anyone who hasn't seen it.
    
    The geometry itself was based on some old experiments involving placing
    geometric patterns onto the surfaces of Apollonian structures. The 
    surface pattern used here is very basic, but it's possible to affix more
    elaborate ones, which I might demonstrate later. I had originally 
    planned to produce some kind of barren wasteland beneath the structures, 
    but I ran out of steam.
    
    There's not much to this. These kinds of Apollonian structures are pretty
    easy to produce. Basically, you apply some recursive transformations and 
    inversion to 3D space, then render a simple object in the resultant 
    distorted space...  I'm sure there are more sophisticated explanations 
    out there, but that's essentially the process.
    
   
   
    Based on:
    
    // MrRange's original below has a nicer, cleaner feel to it. I didn't
    // make use of his superelliptical multi-bounce enviromental lighting,
    // but that's worth looking at.
    //
    Reflecting metallic apollonian -- mrrange
    https://www.shadertoy.com/view/N3sGWB
    

*/

#define FAR 20.

// PI and 2PI.
#define PI 3.14159265358979
#define TAU 6.28318530718

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// vec3 to float hash.
float hash31(vec3 p){
   
    float n = dot(p, vec3(13.163, 157.247, 7.951)); 
    return fract(sin(mod(n, 6.2831))*43758.5453); 
}
 
// Smooth maximum, based on the function above.
float smax(float a, float b, float s){
    
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*s;
}


// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Abosolute normal with a bit of tightning.
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.zy).xyz;
    vec3 ty = texture(tex, p.xz).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture 
    // sample, represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like
    // that. :) Once the final color value is gamma corrected, you should see correct 
    // looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n;
} 

 
// Coordinates and scale.
vec3 gP;
float gSc;
 
 
// Like most of these routines, the following is based on IQ's original 
// demonstration, here:
//
// Apollonian -- iq
// https://www.shadertoy.com/view/4ds3zn
//
// I'm not sure where the original came from, but democoders have been 
// doing stuff like this for years.
float Apollonian3D(vec3 p){
  
    float scale = 1., r;
    
    float d = 1e5;
    
    // Repeat Apollonian distance field. It's just a few fractal related 
    // operations. Break up space, distort it, repeat, etc. I've used
    // the minimum iterations to give just enough intricate detail. 
    // Values of roughly 2 to 6 look interesting.
    for(int i = 0; i<4; i++) {

        // Repeat space with a shift.
        p = mod(p - 1., 2.) - 1.;
        
        // Iterative circle and sphere inversion plays a big part
        // in creating Apollonian structures.
        r = dot(p, p)*.75;
        
        // Failed experiment. Trying to use a different metric to 
        // warp the bulbs... I'll try something elsee later.
        //float N = 3.; // Superelliptical factor.
        //r = pow(dot(pow(abs(p), vec3(N)), vec3(1)), 2./N)*pow(N/2., 1./N)*.85;
   
        // Applying the inversion to the coordinates and scale.
        p /= r;
        scale /= r;
        
        // Saving the coordinates and scale at the earlier stages in
        // order to apply surface patterns.
        if(i<=3){ gP = p; gSc = scale; }
        
    }
    
 
     
    // Inverted Y-planes, which look like spheres, and the minimum length
    // to the X and Z planes, which manifest as cylindrical edges. You would
    // seen this combination all over the internet. There's probably some 
    // fascinating story behind it's discovery, but I'm pretty sure most of
    // us like it because the combination of spheres and cylinders look cool. :)
    return .25*min(abs(p.y), length(p.xz))/scale - .0015;
    
    // Other variations. 
    // Just one set of the inverted 3D space plane borders, which appear as spheres.
    //return .25*abs(p.y)/scale - .0015;
    // Where two of the inverted borders intersect, which manifest as great arc borders.
    //return .25*max(abs(p.x), abs(p.z))/scale - .0015;
    // Three intersections -- Analogous to corner vertex blocks.
    //return .25*max(max(abs(p.x), abs(p.z)), abs(p.y))/scale - .0015;
    //p = abs(p);
    //return .25*max(abs(p.y) - .5*scale, max(p.x, p.z) - .003*scale)/scale;
    // Classic sphere particle Apollonian. Usually needs 8 or more iterations.
    //return .25*length(p)/scale - .001;
    
    
}

// The glow variable. 
vec3 glow;

// Surface pattern variable.
int gFlS = 0;

// The scene function.
float m(vec3 p) {
  
    // Floor.
    float fl = p.y + .015;
    
    // Apollonian object.
    float d = Apollonian3D(p);
    
    // Ball, for the glowing orbs.
    float ball = length(mod(p - 1., 2.) - 1.) - .175;


    // Surface pattern.
    float sD = d;
    float lnN = 10.; // Repeat concentric square rings.
    float le = length(gP)/sqrt(3.); // Scaling.

    // The square pattern -- Not a lot of effort was put into this.
    // Other, nicer tessellations and patterns are possible.
    float pat = smoothstep(0., .02, (abs(fract(le*lnN + .5) - .5) - .5*.33)/lnN);
    // Apply the pattern in height-map form to the Apollonian structure.
    d -= pat*.01/gSc;

    // A global flag to discern between high and low surface pattern 
    // regions, which allows for coloring later.
    gFlS = pat==0.? 0 : 1;


    // If the ray is in the vacinity of the glowing orb, add some
    // some light.
    if(ball<d + .5) glow += vec3(1, .08, .02)*.02/(.01 + ball*ball*128.);

    // Adding the invisible glowing ball to the field... I'm not sure
    // why I did this, but just to be on the safe side, I'll leave it.
    d = min(d, ball);

    // Return the scene distance.
    return d;
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


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){

    // Initialize the shade and ray distance.
    float shade = 1.;
    float t = 0.;
    
    
    // Coincides with the hit condition in the "trace" function. I've added in 
    // a touch of jittering to alleviate banding.
    ro += n*.0015 + rd*hash31(ro + rd + n)*.005;


    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<64; i++){

        float d = m(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
       
        
        // Early exit, if necessary.
        if (d<0. || t>lDist) break;       

        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .01, .15); 
        
    }

    // Shadow.
    return max(shade, 0.); 
}




// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.

// For anyone not familiar with the process, the idea of the function is to very 
// roughly approximate the self shadowing that occurs around a surface when light 
// is being bounced all over the place. In particular, it marches out from the 
// surface in the direction of the surface normal, then determines the overall light
// occlusion based on how far the ray is from any given surface. It also factors in 
// how far away the ray is from orginating surface point itself. You can see all that 
// in the workings.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.2/5.;        
        float d = m(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .75;
    }
    
    return clamp(1. - occ, 0., 1.);  
}

// The normal function is just an application of the finite (central, forward) 
// difference method. The less used curvature function is a second derivative 
// extension of the former -- In fact, you can derive the curvature function 
// from it.
//
// I think it's technically called a discrete finite difference approximation to 
// the continuous Laplace differential operator? Either way, it gives you the 
// curvature of a surface, which is pretty handy.
//
// Original pixelshader usage (I think?) - Cheap curvature: 
// https://www.shadertoy.com/view/Xts3WM
//
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec3 p, in float spr, in float amp, in float offs){

    
    spr /= 450.;
    
    float sgn = 1.;
    vec3 e = vec3(spr, 0, 0); 
    float d = -m(p)*6.;
    for(int i = min(iFrame, 0); i<6; i++){
		d += m(p + sgn*e);
        sgn = -sgn;
        if((i&1)==1){ e = e.zxy; }
    }
    
    // By the way, I take a lot of liberties with this part of the formula. 
    // Dividing by the sample spread squared (e.x*e.x) is technically correct, 
    // but I'll sometimes divide by other things to get the result I want.
    //
    return clamp(d/e.x/e.x*amp/16. + offs, -1., 1.)*.5 + .5;
    //return smoothstep(-1., 1., d/e.x/e.x*amp/16. + offs);

}



// Standard raymarching function.
float trace(in vec3 ro, in vec3 rd){

    // Reset the glow to zero.
    glow = vec3(0);    
    
    // Note the jittering, since we're using cheap glow.
    float d, t = hash31(fract(ro*89.567)*7. + rd)*.5;
    
    for(int i = min(0, iFrame); i<160; i++){
        
        // Surface distance.
        d = m(ro + rd*t);
        // In most cases, the "abs" call can reduce artifacts by forcing the ray to
        // close in on the surface by the set distance from either side.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.)
        // Since we're calculatig glow inside the distance function (which is
        // a cheap hack), we need to delimit the ray jumping distance a bit.
        t += min(d*.8, .2);//min(d*.9, .2);
        
    }

    // Clamp the distace to the far plane, in order to avoid occasional artifacts.
    return min(t, FAR);
}


void mainImage(out vec4 fCol, vec2 fCoor){
    
    
    // Screen coordinates.
    vec2 uv = (fCoor - iResolution.xy*.5)/iResolution.y;

    // Unit direction vector, camera, and point light (above the camera).
    // A "to" and "from" camera system is better, and only requires a few 
    // more lines, but we're keeping things simple.
    
    float tm = iTime/2. + 5.48; // Time.
    vec3 r = normalize(vec3(uv, 1)), // Unit normal ray. 
         o = vec3(0, .5 + sin(tm)*.15, -1); // Camera position.
         o.xz = r2(tm)*o.xz; // Rotate camera.       
    vec3 l = vec3(0, 1, -1); // Light position.
    l.xz = r2(tm)*l.xz; // Rotate the light.
    
    // Rotating the unit direction ray, for a bit of visual interest.
    r.yz *= r2(-.35);
    r.xz *= r2(-tm);
    r.xy *= r2(-.25);
 
    // Raymarch.
    float t = trace(o, r);
 
    // Scene color, initialized to zero.
    vec3 c = vec3(0);
    
    // Surface pattern demarcation... I coded this a while ago,
    // so I can't remember what the name means. :)
    int flS = gFlS;    
   
    // Global position.
    vec3 svP = gP;
    
    // Glow variable.
    vec3 svGlow = glow;
    
      
    // If we've hit an object, light it up.
    if(t<FAR){
    
        // Scene hit posititon and normal. This is an old template, which is
        // full of short variable name, which I'm not a fan of when not short
        // coding. I might update them later.
        vec3 p = o + r*t, n = nr(p);

        l -= p; // Light to surface vector. Ie: Light direction vector.
        float lDist = max(length(l), 0.001); // Light to surface distance.
        l /= lDist; // Normalizing the light direction vector.
        
        float atten = 1./(1. + lDist*lDist*.25); // Attenuation.
            
        // Ambient occlusion and shadows.
        float ao = calcAO(p, n);
        float sh = softShadow(p, l, n, lDist, 12.); 
         
        // Scene curvature.
        float spr = 2.5, ampC = 1., offs = .0;
        float crv = curve(p, spr, ampC, offs);
        
        // There's a bit of fakery involved here. Normally, you'd save the glow 
        // value after performing the raymarching calculations. However, here we're
        // doing it after curvature or shadows, which produces a faux shadowy glow 
        // effect. I don't use it often, but sometimes it works well.
        svGlow = glow; 
        //svGlow *= 2.;
        
        // Texture 
        vec3 tx = tex3D(iChannel0, p, n);
        float gr = dot(tx, vec3(.299, .587, .114)); // Greyscale.

 
        // Scene object color.
        c = vec3(.66);
        
        // Color lower surface pattern regions darker.
        //c *= mix(vec3(1.3, .9, .5), vec3(1.1, 1, .9), crv);
        if(flS==0) c *= .4;
       
        // Apply the texture.
        c *= tx;// *(1. - smoothstep(.04, .18, t/FAR)*.9);
        
        
        
        //////////////        
        
         // Material properties.
        float fresRef = .7;  // Reflectivity.
        float type = .9;     // Dielectric or metallic.
        float rough = min(gr*2., 1.); // Roughness.
        
 

        // Standard BRDF dot product calculations.
        vec3 h = normalize(l - r); // Half vector.
        float ndl = dot(n, l);
        float nr = clamp(dot(n, -r), 0., 1.);
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(n, h), 0., 1.);
        float vh = clamp(dot(-r, h), 0., 1.);  
 
        // Specular microfacet (Cook- Torrance) BRDF.
        //
        // F0 for dielectics in range [0., .16] 
        // Default FO is (.16 * .5^2) = .04
        // Common Fresnel values, F(0), or F0 here.
        // Water: .02, Plastic: .05, Glass: .08, Diamond: .17
        // Copper: vec3(.95, .64, .54), Aluminium: vec3(.91, .92, .92), 
        // Gold: vec3(1, .71, .29), Silver: vec3(.95, .93, .88), 
        // Iron: vec3(.56, .57, .58).
        vec3 f0 = vec3(.16*(fresRef*fresRef)); 
        // For metals, the base color is used for F0.
        f0 = mix(f0, c, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.
        
        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, rough, type);
       
        
        // Ambient light.
        //
	    // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio and outdoor.
        //float amb = pow(length(sin(sn*2.)*.5 + .5), 2.);
        float amb = length(sin(n*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., n.y); 
        
        // Backscatter.  
        float bl = max(dot(-normalize(vec3(l.x, 0, l.z)), n), 0.);
        c = c + c*vec3(1, .4, .2)*bl*8.;
        
        
/////////////////        
        
        
        // Applying diffuse lighting, ambient lighting, and attenuation.
        c = c*(diff*sh + spec*sh*8. + amb*(sh*.5 + .5)*.3);
        
        
        // Curvature shading, for a little extra depth.
        c *= crv*1.33 + .333;

        
        // Ambient occlusion.
        c *= ao*atten;
        
        // Cheap specular reflection.
        float speR = pow(nh, 16.);
        vec3 rf = reflect(r, n); // Surface reflection.
        vec3 rTx = texture(iChannel1, rf).xyz; rTx *= rTx;
        float rF = 8.;
        c = c + c*speR*rTx*rF;  
        
        
        // Debug for AO, shadows, and so forth.
        //c = vec3(ao*crv + .25);
        
    }
    
    
    // Apply the glow to the scene.
    svGlow = mix(svGlow, svGlow.yzx, smoothstep(0., .7, r.y)*.2);
    c += (c*4. + .5)*svGlow;//*(-uv.y + .5);
    
    // Applying fog: This fog begins at 90% towards the horizon.
    c = mix(c, vec3(0), smoothstep(0., .9, t/FAR));
    
    // Add the scene color to the buffer.
    fCol = vec4(max(c, 0.), t);    
    
}