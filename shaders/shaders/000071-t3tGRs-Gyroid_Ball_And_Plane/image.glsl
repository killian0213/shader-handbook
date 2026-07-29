// Image (image) — Gyroid Ball And Plane by Shane
// https://www.shadertoy.com/view/t3tGRs

/*

    Gyroid Ball And Plane
    ---------------------
    
    This is a typical gyroid ball and plane. The forground consists of a
    gyroid surface bounded by a sphere, and the background consists of 
    the planar equivalent. Mathematical objects like this are everywhere, 
    and a bit of a cliche, but I like them because they look interesting,
    plus they're easy to make. They also render pretty quickly, which 
    leaves plenty of room to pretty the scene up.
    
    I like to use simple scenes like this to play around with lighting,
    whether it be serious or just for fun. The lighting here is a mixture 
    of cheap illumination techniques mixed in with a heap of fakery, so I 
    wouldn't take any of it too seriously.
    
    I'd originally produced an all metallic scene, which then morphed into a
    metal and ceramic look, but I eventually got curious as to how it would 
    look with some subsurface scattering. The scatterig formula I'm using is
    a rough version of one of IQ's routines. Cheap SSS is not my forte, so
    if an expert out there would like to suggest improvements, feel free to.
    
    
    
    Other examples:
    
    // This was written 11 years ago. I used to enjoy reading Syntopia's
    // blog. I'd imagine he's quite busy these days.
    Spherical Gyroid -- Syntopia
    https://www.shadertoy.com/view/Md23Rd
    
    // Really interesting rendering style.
    randomly rotated cubes noise cut -- jt
    https://www.shadertoy.com/view/tXKXzh
   
    // Beautiful shader with understated, yet very effective lighting.
    // I could probably say that about all his shaders though. :)
    Ladybug -- iq
    https://www.shadertoy.com/view/4tByz3
    
    // Lighting doesn't need to be fancy to look nice.
    20250701 Ray marching torus -- baxin1919 
    https://www.shadertoy.com/view/WXc3zj


*/

// Far plane.
#define FAR 20.

// PI and 2PI.
#define PI 3.14159265
#define TAU 6.2831853


// Inner ridge of sorts, in order to add some extra detail...
// Probably a little too much detail, in this case.
//#define RIDGE

// Enamel, or perspex, color -- Pink and Yellow: 0, Bluish: 1., Greenish: 2.
#define COLOR 0

// Trim color - Platinum: 0, Rose gold: 1.
#define TRIM_COL 0


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


// Object rotation, with some optional mouse movement.
vec3 objRot(vec3 p){

    // Mouse movement.
    if(iMouse.z>1.){
        p.yz *= rot2(-(iMouse.y - iResolution.y*.5)/iResolution.y*3.1459);  
        p.xz *= rot2(-(iMouse.x - iResolution.x*.5)/iResolution.x*3.1459);  
    } 
    else {
        p.xy *= rot2(iTime/4.);
        p.yz *= rot2(iTime/2.);
        
    }
    
    return p;
}


/*
// Cheap transcendental surface. Not used here. Maybe next time.
float sinNoise(vec3 p){
    return dot(sin(p*2. - cos(p.zxy*8./3.)), vec3(1./6.)) + .5;
}
*/

// There are a few types of minimal surfaces, but this is 
// the more common gyroid.
float minimalSurf(vec3 p){
    
    // Gyroid
    return dot(sin(p), cos(p.yzx));
}

vec4 vObj; // Object distance container.

float map(vec3 p){

    
    
    // The back gyroid plane.
    vec3 q = p;
    q.xz *= rot2(PI/32.*sin(iTime/4.));
   
    float fl = -q.z + 3.;
    
    // Tapering at the edges.
    q.z = mix(q.z, 3., 1. - smoothstep(0., .05, abs(fl - .1) - .1));
     
    // The gyroid surface, rotated at an angle to the plane.
    q.xy *= rot2(PI/8. + iTime/8.*0. + 1.72/6.);
    q.yz *= rot2(PI/8. + iTime/8.*0. + 1.72/8.);
    const float sc2 = TAU/2.;
    float srf = minimalSurf(q*sc2)/sc2;
    //float srf =(sinNoise(q*1.25 +vec3(0, 0, 3.43))  - .55)*1.5;//
  
    // The gyroid plane outer frame.
    float fr2D = abs(srf - .05) - .14;
    float oFr2D = fr2D;
    #ifdef RIDGE
    fr2D = max(fr2D, -max(fr2D + .14, fl - .08));
    #endif
    float fr = smax(fr2D, abs(fl + .5) - .6, .05);
    
    // The inner surface.
    float inner = smax(max(-srf + .1, -(oFr2D - .05)), abs(fl + .5) - .5, .05);
    inner -= fr2D*.25; // Raising the surface a bit.
     
    //fr = smin(fr, fl + 1.25, .5);
    //fl = (fl + .5);
    fl = 1e5;
     
     
     
    // The spherical object. Starting with rotation.
    p = objRot(p);
    
    
    // Ball field, and spherical normalized tapering.
    float ball = length(p) - 1.1;
    float rTaper = smoothstep(0., .025, ball + .1);
    p = mix(p, normalize(p), rTaper);
 
 
    // Outer spherical netting. 
    float t = iTime*.25;
    float frq = 9.;
    //float net = (length(cos(p*frq + t) - sin(p.zxy*frq + t)) - 1.35)/frq;
    float net = (dot(sin(p*frq + t), cos(p.zxy*frq + t)) - .35)/frq/1.5;
    float o2D = abs(net) - .02 - rTaper*.015;
    #ifdef RIDGE
    o2D = max(o2D, -max(o2D + .035, -ball - .005));
    #endif
    float obj = smax(ball, o2D, .02);
     
  
    // Inner sphere object.
    float obj2 = smax(abs(obj + .01) - .1, ball + .1, .02);
    inner = smin(obj2, inner, .02);
    
    // Surface bump experiments.
    //if(q.z<0.) inner -= sin(obj*TAU*24.)*.002;
    //else inner -= sin(fr*TAU*16.)*.004;
 
   
    // Individual object distance.
    vObj = vec4(fl, inner, fr, obj);
 
    
    // Minimum scene distance.
    return min(obj, min(fl, min(inner, fr)));

}


// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 calcNormal(in vec3 p){
	
    //const vec2 e = vec2(.001, 0);
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(iFrame, 0); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){
    
    float shade = 1.; // Fully lit to begin with.
    float t = 0.; 
 
    // Coincides with the hit condition in the "trace" function. I've added in 
    // a touch of jittering to alleviate banding.
    ro += n*.0015 + rd*hash31(ro + rd + n)*.05;


    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<64; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        
        // Early exit, if necessary.
        if (d<0. || t>lDist) break;       

        //shade = min(shade, smoothstep(0., 1., k*d/t)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += clamp(d, .01, stepDist), etc.
        t += clamp(d, .005, .15); 
        
    }

    // Shadow.
    return max(shade, 0.); 
}



// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = min(0, iFrame); i<128; i++){
    
        d = map(ro + rd*t);
        if(abs(d)<.001 || t>FAR) break;
        
        t += d*.8; 
    }

    return min(t, FAR);
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
    
        float hr = float(i + 1)*.125/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
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
float curve(in vec3 p, vec3 n, in float spr, in float amp, in float offs){
    
    // Sample spread. Measured in the order of pixels.
    spr /= 450.;
/*  
    // Seven tap curvature. Fine for cheap scenes, but not for all. 
    
    float sgn = 1.;
    vec3 e = vec3(spr, 0, 0); 
    float d = -map(p)*6.;
    for(int i = min(iFrame, 0); i<6; i++){
		d += map(p + sgn*e);
        sgn = -sgn;
        if((i&1)==1){ e = e.zxy; }
    }
    
    // By the way, I take a lot of liberties with this part of the formula. 
    // Dividing by the sample spread squared (e.x*e.x) is technically correct, 
    // but I'll sometimes divide by other things to get the result I want.
    //
    return clamp(d/e.x/e.x*amp/16. + offs, -1., 1.)*.5 + .5;
    //return smoothstep(-1., 1., d/e.x/e.x*amp/16. + offs);
 
*/ 

    // A five tap version that is pretty close to the seven tap one.
    // There's a tetrahedral version as well.
    
    vec3 an = (abs(n.x)<.99) ? vec3(1, 0, 0) : vec3(0, 1, 0);
    // Basis related vectors.
    vec3 t1 = normalize(cross(an, n));
    vec3 t2 = cross(n, t1);
    
    float d = -map(p)*4.;
    for(int i = min(iFrame, 0); i<4; i++){
        if(i==2) t1 = t2;
		d += map(p + t1*spr);
        spr = -spr;        
    }    

    return clamp(d/spr/spr*amp/16. + .5 + offs, 0., 1.);

}

#define SUB 1

// Scattering calculation preferences.
//
#if SUB == 0
// This is a slight retweaking of Poisson's SSS function,
// which can be found, here:
//
// Conetraced Soft Shadows -- Poisson
// https://www.shadertoy.com/view/DdtGWf
//
// ra is the subsurface radius.
float subsurface(vec3 ro, vec3 rd, vec3 ld, float ra) {
    
    const int sN = 10; // Sample number.
    float sss = 0.;
    
    // Randomly march out from the surface in the direction 
    // of the light accumulating weighted values.
    for (int i = 0; i<sN; i++){
    
        // Random, but increasing, sample distance.
        float rnd = hash31(ro + float(i))*.1;
        float d = float(i)*ra*(1. + rnd); 
        // Accumulate weighted samples.
        sss += clamp(map(ro + rd*d)/d, 0., 1.);
        //sss += smoothstep(0., 1., map(ro + rd*h)/h);
    }
    
    sss /= float(sN); // Average the scattering value.
    
    // Giving the results more of a bell curve distribution.
    return smoothstep(0., 1., sss); 
}
#else
// This is a rough version of one of IQ's subsurface formulas and XT95's
// thickness formula, which you can find at the links below:
// I haven't finished tweaking everything yet, but the results seem more
// authentic... I think. It's hard to tell what the scattering distribution
// should look like.
//
// Snail -- iq
// https://www.shadertoy.com/view/ld3Gz2
//
// Alien Cocoons -- XT95
// https://www.shadertoy.com/view/MsdGz2
//
float subsurface(in vec3 ro, in vec3 rd, vec3 ld, float ra){
 
    ra /= 4.; 
     
	float occ = 0.;
    vec3 p = ro;
    for( int i = 0; i<16; i++){
    
        //float h = i0 + float(i)*ra;
        // Smoother scattering.
        //vec3 dir = normalize(sin(float(i)*16.01 + vec3(0, 2.03, 4.02)));
        // More dispersed, but noisy (due to the sample count) and expensive, distribution.
        vec3 dir = normalize(rd + (hash33(ro + vec3(i)) - .5)*.25);
        dir *= sign(dot(dir, rd));
        //occ += (h - map(p - h*dir));
        
        
        float m = -map(p);
        // Experiments with gradients.
        //float m2 = -map(p - ld*.003);
        if(m<0.){ break; }
        p += dir*ra;
        
        occ += m/4.;
        //occ += max(max(m - m2, 0.)/.003, 0.)/2.;//)/length(p - ro)/8.;
  
    }
    
    //return max(1. - occ, 0.);
    return smoothstep(0., 1., 1. - occ);  // Gaussian smoothing.   
}
#endif

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
    // Screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Ray or camera origin, unit direction ray and light position.
    vec3 ro = vec3 (0, 0, -3);
    vec3 rd = normalize(vec3(uv, .9));
    vec3 lp = ro + vec3(1, 3, -1);
    
 
    // Trace.
    float t = trace(ro, rd);
    
    // Object ID sorting.
    int objID;
    float d = 1e5;
    for(int i = 0; i<4; i++){
         
        if(vObj[i]<d){ d = vObj[i]; objID = i;  }
    
    }
    
    // Hacky sky color. Kind of redundant here.
    vec3 sky = mix(vec3(.8, .6, 1), vec3(.1, .3, .6), clamp(rd.y*2., 0., 1.));
    // Initializing the scene to the sky.
    vec3 col = sky;

    // If we've hit a surface, light it up.   
    if(t<FAR) {

        // Position and normal.
        vec3 p = ro + rd*t;
        vec3 n = calcNormal(p);
        
        // Curvature.
        float spr = 2., amp = 1., offs = .0;
        float crv = curve(p, n, spr, amp, offs);

        // Point light.
        vec3 ld = lp - p;
        float lDist = length(ld);
        ld /= lDist;
        
        // Light attenuation.
        float atten = 1./(1. + lDist*.05);
        
        // Material color: I hacked this together quickly, then hacked
        // in changes. The logic is full of redundancies, but I'll tidy 
        // it up later.
        
        vec3 matCol;
        
        if(objID==1) matCol = vec3(.5, .05, .07);
        else {
            // Object, or material color, as its sometimes called.
            #if TRIM_COL == 0
            matCol = vec3(.22, .2, .18); // Platinum.
            #else
            matCol = vec3(.35, .22, .14); // Gold.
            #endif
        }        
        
        
        // Adding highlight colors with respect to some kind of falloff is 
        // pretty common. IQ does it in various things. This snippet is 
        // based on something I saw in Baxin1919's "Ray marching torus"
        // example. The link is included in the introducion above.
        vec3 glazeCol = matCol*4.; 
        //if(objID==1) glazeCol = glazeCol.xzy;
        float nY = smoothstep(.2, .7, n.y);
        float gloss = mix(32., 128., nY);
        matCol = mix(matCol, glazeCol, nY*.6);
        
        // Ceramic and meteal coloring.
        if(objID==1) matCol = mix(matCol.xzy, matCol.zxy, (-uv.y + .5)*.5)*1.25;
        else matCol *= .25;
 
        vec3 svMatCol = matCol; // Saving the material color.
        
        // Enamel coloring... The color logic is all over the place,
        // even for me. :D I'll tidy it up later.
        if(objID==1){
            #if COLOR == 0
            svMatCol = svMatCol.xzy;
            matCol = matCol.xzy;
            #elif COLOR == 1
            svMatCol = svMatCol.zyx;
            svMatCol *= svMatCol*3.;
            matCol = matCol.zyx;
            #else
            svMatCol = svMatCol.yxz;
            svMatCol *= svMatCol*2.;
            matCol = matCol.yxz*.8 + .02;
            #endif
        }
        
        // Texturing, depending upon object.
        vec3 txP = p;
        vec3 txN = n;
        
        mat2 mR = rot2(PI/32.*sin(iTime/4.));
        vec3 tmpP = p;
        tmpP.xz *= mR;
        
        if(tmpP.z<1.5){
        
            // The ball in the foreground.
            
            // Rotating the texture coordinates.
            txP = objRot(txP);
            txN = objRot(txN);
            
             
            // Match he "platinum" trim to the enamel, but not the gold...
            // To a certain degree, clean code is a bit of a myth. :D
            #if TRIM_COL == 1
            if(objID==1) 
            #endif 
            #if COLOR == 0
               matCol = matCol.xxy*.7; // Yellow.
            #else
               matCol = matCol;
            #endif
            
        }
        else{
        
            // The back wall.            
            txP.xz *= mR;
            txN.xz *= mR;             
  
        }
       
            
        // Applying the texture.
        vec3 tx = tex3D(iChannel0, txP/3., txN);
        matCol *= tx*4.;

        // Soft shadows and ambient occlusion.
        float sh = softShadow(p, ld, n, lDist, 24.);
        float ao = calcAO(p, n);

         
        /////////////////////
        // Rough BDRF lighting.
        //        
 
        // Material properties.
        float type = objID<=1? .1 : 1.; // Dialectric or metallic.
        float rough = dot(tx, vec3(.299, .587, .114)); // Texture based roughness.
        float fresRef = rough*4.; // Texture based reflectivity.

        // Different properties for different materials.  
        if(type>.5){
            // Metal.
            rough *= 2.; 
            fresRef *= 2.;
        }
        else {
            // Ceramic... or glossy plastic? Not metal anyway. :)
            rough *= .2;
            fresRef = min(fresRef*2., 1.);
        }
        
        
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio and outdoor.
        float amb = pow(length(sin(n*2.)*.5 + .5), 2.);
        //float amb = length(sin(n*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., n.y); 
 
  
        // Standard BRDF dot product calculations.
        vec3 h = normalize(ld - rd); // Half vector.
        float ndl = dot(n, ld);
        float nr = clamp(dot(n, -rd), 0., 1.);
        float nl = clamp(ndl, 0., 1.);
        float nh = clamp(dot(n, h), 0., 1.);
        float vh = clamp(dot(-rd, h), 0., 1.);  
 
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
        f0 = mix(f0, matCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.
        
        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, rough, type);
        
        vec3 sunCol = vec3(1, .97, .92)*1.5;
        
        // Subsurface scattering.
        #if SUB == 0
        vec3 sRay = ld;
        #else
        vec3 sRay = -n;//mix(-n, rd, .5);
        #endif
        float sss = subsurface(p - n*.005, sRay, ld, .2); 
        vec3 sss3 = sss*vec3(1, .3, .1);

        // Applying lighting to the materials.
        col = matCol*(diff*sh + amb*(sh*.5 + .5))  + spec*sh;
        
        // Rim lighting to brighten the edges... but just a touch.
        float rm = pow(clamp(1. + dot(n, rd), 0., 1.), 2.);
        col += col*rm*sunCol*.7;

        
        if(objID==1) col += sunCol*svMatCol*sss3*(1. - diff)*4.8; 
        
        /*
        float bou = .5 - .5*n.y; // Bounce light.
        //float bac = clamp(dot(sn, -ld), 0., 1.); // Back scatter light.
        float bac = clamp(dot(n, -normalize(vec3(ld.xy, 0))), 0., 1.);
        bac = (bac*.5 + .5)*bou; // Apply the back scatter.
 
        // Using pseudo science to apply a bit of faux back scatter. :)
        col += col*vec3(1, .3, .1)*bac;
        */
        
        // Applying the ambient occlusion... I hear that applying it to the
        // diffuse lighting is a style choice for some, but you probably 
        // shouldn't... I do it out of laziness. :D
        col *= ao; 
         

       
        // Specular reflection.
        vec3 ref = reflect(rd, n); // Surface reflection.
        vec3 refTx = texture(iChannel1, ref).xyz; refTx *= refTx; // Cube map.
        float spRef = pow(nh, gloss/2.);
        float rf = (objID <= 1)? 8. : 64.;//mix(.5, 1., 1. - smoothstep(0., .01, d + .08));
        col = col + col*spRef*refTx*rf*ao; //smoothstep(.03, 1., spRef) 

        // Applying the curvature shade.
        col *= crv*1.1 + .2;
        // Dark edges. I'll sometimes use this as a debug to see how 
        // well the curvature function is working.
        //col *= 1. - abs(crv - .5)*2.*.7;
        
        // Overall light attenuation.
        col *= atten;        
   
    }
    
    
    // Horizon fog. Not visible here, but provided for completeness.
    col = mix(col, vec3(0), smoothstep(.2, .9, t/FAR));
    
    // Tanh sigmoid tone mapping -- Popularized by Xor. It's a great
    // all-rounder, if you just want to tone down the upper range. I'm 
    // not sure why I put "1.1" exposure in there... Probably left over 
    // from something else. :)
    col = tanh(col*1.1);

    // Rough gamma correction.
    fragColor = vec4(pow(max(col, 0.), vec3(1./2.2)), 1);
    
    
}