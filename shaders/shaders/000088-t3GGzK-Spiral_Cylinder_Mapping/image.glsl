// Image (image) — Spiral Cylinder Mapping by Shane
// https://www.shadertoy.com/view/t3GGzK

/*

    Spiral Cylinder Mapping
    -----------------------

    Mapping a tessellated pattern onto a spiral cylinder, which has a 
    similar feel to a helix structure. Examples like this look technical,
    but they're just a combination of simple procedures and some oldschool 
    raymarching trickery.
    
    Spiral cylinders are simple to make: Render a cyclinder to the side
    of a camera running down the Z axis, then perform a spiral warp on
    the XY plane using the Z distance (p.xy *= rot(p.z*const)). It's 
    possible to use multiple cylinders too.
    
    This spiral cyclinder has a basic diamond and octagon pattern UV mapped
    onto it. Cylindrical mapping is easy too, since it's just a mixture of
    polar and Z coordinates.
    
    
    
    Other examples:
    
    // Using some 2D trickery to produce something similar. Very cool,
    // and the thing that motivated me to complete this. :)
    //
    Hexagon Undulating Spiral -- djstomp
    https://www.shadertoy.com/view/3XyGRG
    
    // A much cleaner way to go about this would be to forgo the space
    // warping and construct a helix. I've tested the distance field in 
    // the following example and it renders really nicely.
    //
    "Exact" sdHelix -- FordPerfect
    https://www.shadertoy.com/view/wfyXWc
    
    // Diatribes has been putting together some really nice
    // examples lately.
    //
    Apollo Spiral -- diatribes
    https://www.shadertoy.com/view/WXVGRG
    
    // Far less code and beautiful to look at.
    //
    Spiral Riders -- Kali
    https://www.shadertoy.com/view/3sGfD3
    

*/


#define FAR 20.

///////////////

// Color scheme -- Spectral wavelengths, silver trim: 0, Purple, gold trim: 1.
#define COLOR 0

// Display the rivots, or vertices.
//#define RIVOTS

/////////////////


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


int objID;
vec2 rmP;
// Frame and rivot 2D UVs, with object ID at the end.
vec3 frUV;
vec3 riUV;
 

float map (vec3 p){
    
    // Twisting along the Z-axis. The modulo is there for machines
    // containing GPUs that don't deal with large values pushing 
    // through their inbuilt sinusoidal functions.
    p.xy *= rot2(mod(p.z*1. + iTime/4.*1., TAU));
    
    rmP = p.xy;
    
    #if 0
    // Using more than one tube. It's not really suited for this example.
    // Repeat angle.
    float na = 6.2831/2.;
    float a = mod(atan(p.y, p.x) - na/2., na) - na/2.;
    p.xy = vec2(cos(a), sin(a))*length(p.xy);   
    #endif
    
    #if 1
    // Shift the spiral tube away from the center.
    p.x -= 1.1;
    float d = length(p.xy) - .8;
    #else
    // Using a plane instead.
    float d = p.y + .5;
    #endif
 
    // UV mapping the cylinder, then passing it into the 2D 
    // pattern function. 
    vec2 u = vec2(p.z, atan(p.y, p.x)/6.2831*6.);
    // Diamond and octagon pattern.
    vec4 d4 = distField(u);
    float sf = d4.x;//max(d4.x, -.0125);
    
    // 2D frame field.
    float fr2D = abs(d4.x) - .04;
    // Frame UV coordinates, and a surface identifier (top, or sides).
    frUV = fr2D<d - .03? vec3(u, 0) : vec3(atan(gP.y, gP.x)/6.2831*2., d, 1);
    float fr = max(fr2D, d - .03);
    fr += max(fr2D, -.015); // Bevel.
    //fr += fr2D*.125; // More beveling.
    
    // Adding some concavity to the inner surface cells. 
    float oD = d;
    float depth = pID==8? .0225 : .005;
    d += dot(gP, gP)*.5 - depth;
    //d = max(d, sf);
    
     
    
    // Display the rivots, or vertices.
    float riv = 1e5;
    #ifdef RIVOTS
    if(oD<.2){
        // Rivots.
        float riv2D = 1e5;
        for(int i = 0; i<pID; i++){
             riv2D = min(riv2D, length(gP - vP[i]));
        }
        riv2D -= .03;
        // Rivot UV coordinates.
        riUV = riv2D<oD - .06? vec3(u, 0) : vec3(u.y, d, 1);
        // 3D rivots.
        riv = max(riv2D, oD - .055);
    }
    #endif
    
    // Debug.
    //fr = 1e5;
    //riv = 1e5;
 
    
    // Object ID.
    objID = d<fr && d<riv? 0 : fr<riv? 1 : 2;
    
    
    // Keeping a record of the XY coordinates.
    rmP = p.xy;
   
   
    // Minimum object distance.
    return min(d, min(fr, riv));
}
 
 
//float ii; // Used for hacky AO, but unused here.

// Raymarching function.
float trace(vec3 ro, vec3 rd){
   
    
    // This is a pretty tricky distance field to home (hone is correct, too)
    // in on, so I'm putting in some jitter. Jitter is also necessary when
    // implementing glow.
    float d, t = hash21(ro.xy + ro.yz + dot(rd, vec3(3, 7, 1)))*.1;
    
    //ii = 0.;
    
    for(int j = 0; j<160; j++){
        
        //ii++; // AO counter.
        
        
        d = map(ro + rd*t); // Distance.
        if(abs(d)<.001 || d>FAR) break; // Break conditions.
        t += d*.5; // Ray shortener for the distorted field.
    }
    
    // Minimum distance, capped to the maximum ray distance.
    return min(t, FAR);    
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with 
// limited iterations is impossible... However, I'd be very grateful if someone could 
// prove me wrong. :)
float softShadow(vec3 ro, vec3 rd, vec3 n, float lDist, float k){

    
    
    float shade = 1.;
    float t = 0.; 
 
    // Coincides with the hit condition in the "trace" function. I've added in 
    // a touch of jittering to alleviate banding.
    ro += n*.0015 + rd*hash21(ro.xy + ro.yz + n.xz)*.05;


    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<80; i++){

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




// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 normal(in vec3 p) {
	
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


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = min(0, iFrame); i<6; i++ ){
    
        float hr = float(i + 1)*.2/6.;        
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
float curve(in vec3 p, in float spr, in float amp, in float offs){

    
    spr /= 450.;
    
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

}


void mainImage(out vec4 fragColor, vec2 fragCoord){


    // Aspect correct coordinates.
    vec2 u = (fragCoord - iResolution.xy/2.)/iResolution.y;
    
    // Screen distortion.
    //u = u/max(.8 + dot(u, u)*.4, 0.);
    
    // Precalculating the octagon vertices.
    octagon();
    
    // Ray origin and point light.
    vec3 ro = vec3(0, 0, iTime*2.);
    vec3 lp = ro + vec3(-.2, .2, .5);
    
    // An exaggerated unit direction ray to give a wide viewing angle.
    vec3 rd = normalize(vec3(u, 4));
    
    // If you'd like to spoil the illusion, uncomment these two lines. :)
    // From this perspective, you can see the excessive warping. There are
    // a few ways to alleviate this, but I wanted to keep things simple.
    //ro.x -= 4.;
    //rd.xz *= rot2(-.7);
    
    float t = trace(ro, rd);
    
    // 2D twisted pipe coordinates.
    vec2 svP = rmP;
    
    // Frame and rivot 2D UVs, plus top and side surface ID.
    vec3 svFrUV = frUV;
    vec3 svRiUV = riUV;
    
    // Fake AO... Left over from something else. I'm keeping it
    // here because I'm a bit of a functionality horder... You never
    // know when I might need this, :D
    //float svI = ii; 
    
    // Objet ID.
    int svObjID = objID;
    
    // Scene initialization.
    vec3 col = vec3(0);
    
    // Light up the hit surface.
    if(t<FAR){    
       
        // Position and normal.
        vec3 sp = ro + rd*t;
        vec3 sn = normal(sp);
        
        #if 0
        // Direct lights. They really don't work in this scene.
        vec3 ld = normalize(-vec3(-.2, .2, .5));
        float lDist = FAR;
        #else
        // Point light.
        vec3 ld = lp - sp;
        float lDist = max(length(ld), .001);
        ld /= lDist;
        #endif
        
        // Rotating the light.
        ld.xy *= rot2(mod(-iTime/4., TAU));
       
        
        // Shadow and ambient occlusion.
        float sh = softShadow(ro, ld, sn, lDist, 32.);
        float ao = calcAO(sp, sn);
        
        // Scene curvature.
        float spr = 2., amp = 1., offs = .0;
        float crv = curve(sp, spr, amp, offs);

        
        // Unused fake AO.
        //svI = max(1. - svI/160.*.75, 0.);
  

        // Light attenuation.
        float atten = 2./(1. + lDist*.05);
        
        // Diffuse light.
        float diff = max(dot(ld, sn), 0.);
        
        // Specular lighting.
 	    float spec = pow(max(dot(reflect(ld, sn), rd), 0.), 16.); 
	  
        // UV coordinates for twisted planes.
        //vec2 u = vec2(svP.x, p.z); 
       
        // Twisted tube cylindrical UV coordinates.
        vec2 u = vec2(sp.z, atan(svP.y, svP.x)/6.2831*6.);

        //float c = getPat(u);

        // 2D distance.
        vec4 d4 = distField(u);
        vec2 id = d4.yz;
        float d2 = d4.x;
        
        // Random cell value.
        float rnd = hash21(id + .2);
        
        #if COLOR==0
        vec3 cCol = .5 + .45*cos(TAU*rnd/4. + vec3(0, 1, 2)*1.5 - sp.z*1. - 1.5);//rnd/6.
        #else
        vec3 cCol = .5 + .45*cos(TAU*rnd/4. + vec3(0, 1, 2)).yzx;
        #endif
        
        
        // Extra cell shading.
        cCol *= max(.5 - d2*8., 0.);
        
        // Blinking lights.
        float rnd2 = hash21(id + .123);
        rnd2 = sin(mod(rnd2*TAU + iTime, TAU))*.5 + .5;
        vec3 gCol = vec3(6);//vec3(12, 4, 1);
        cCol = mix(cCol, cCol*gCol, smoothstep(.92, .97, rnd2)); 
        
        vec3 svCol = cCol;  
        vec3 tx2 = texture(iChannel0, u/2. + vec2(0, .125)).xyz; tx2 *= tx2;
        cCol *= tx2*2.; 
        
         
        // Frame and rivot texture value.
        vec3 txP = sp; 
        vec3 txN = sn;
        txP.xy *= rot2(mod(txP.z*1. + iTime/4.*1., TAU));
        txP.x -= 1.1;
        //txP = svGP3;
        txN.xy *= rot2(mod(txP.z*1. + iTime/4.*1., TAU));
        vec3 tx = tex3D(iChannel0, txP, txN);

     
        
        if(svObjID==1){
        
           // Framework.            
 
           vec3 tx3 = texture(iChannel0, svFrUV.xy).xyz; tx3 *= tx3;
           #if COLOR==0
           tx3 *= vec3(1, .8, .6)*1.1;
           #else
           tx3 *= vec3(1, .6, .2)*1.5;
           #endif
           cCol = tx3*1.;
           
           // Applying the frame texture value to the glow color.
           svCol *= tx3*2.;
           
           float fr = abs(d2) - .04;
           
           /*
           cCol = mix(cCol, tx3*.25, 1. - smoothstep(0., .0005*t, fr));
           cCol = mix(cCol, tx3*3., 1. - smoothstep(0., .0005*t, fr + .005));
           cCol = mix(cCol, tx3*.25, 1. - smoothstep(0., .0005*t, fr + .02));
           cCol = mix(cCol, tx3*1.5, 1. - smoothstep(0., .0005*t, fr + .025));
           */
           
           // Inner frame test.  
           //if(svFrUV.z==1.) cCol = cCol + vec3(4, 1, .2);
           
           // Simulating glow on the outer edges of the frame.
           float shF = iResolution.y/450.; // Shadow blur versus resolution.
           cCol = mix(cCol, cCol + svCol, 1. - smoothstep(0., .004*t*shF, -(fr + .02)));
           
           // Extra shading.
           cCol *= max(.5 - fr*8., 0.);
           
           // Metallic diffuse (power ramp) on the frame.
           float gr = dot(tx, vec3(.299, .587, .114));
           diff = pow(diff, 2. + gr*8.)*2.;
       
        }
        
        // Display the rivots, or vertices.
        #ifdef RIVOTS
        if(svObjID==2){
        
           // Rivots.
           vec3 tx3 = texture(iChannel0, svRiUV.xy).xyz; tx3 *= tx3;
           
           #if COLOR==0
           cCol = tx3*vec3(1, .8, .6)*1.1;
           #else
           cCol = tx3*vec3(1, .7, .2)*1.5;
           #endif
           
           // Rivots.
            float riv2D = 1e5;
            for(int i = 0; i<pID; i++){
                 riv2D = min(riv2D, length(gP - vP[i]));
            }
            riv2D -= .015;
            
            // Center circle.
            cCol = mix(cCol, tx3*.1, 1. - smoothstep(0., .0005*t,  riv2D));
            cCol = mix(cCol, tx3, 1. - smoothstep(0., .0005*t, riv2D + .006));
 
        }
        #endif
        
   
        
        // Specular reflection.
        vec3 hv = normalize(ld - rd); // Half vector.
        vec3 ref = reflect(rd, sn); // Surface reflection.
        vec3 refTx = texture(iChannel1, ref).zyx; // Environment texture.
        refTx = refTx*refTx; 
        // Specular environment reflection.
        float rfF = svObjID==0? .25 : 1.;
        float spRef = pow(max(dot(hv, sn), 0.), 2.); // Specular reflection.
        cCol = cCol + cCol*spRef*refTx*rfF*12.; 

 
        // Putting all the lighting together.
        col = cCol*(diff*sh + spec*sh*8. + .25)*atten*ao;//*atten;//svI;
      
        // Applying the curvature based edges.
        col *= 1. - abs(crv - .5)*2.*.9;
        //col *= crv + .25;
       
    
    }
    
    // Distance fog.
    col = mix(col, vec3(0), smoothstep(0., .99, t/FAR));
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
    
}
