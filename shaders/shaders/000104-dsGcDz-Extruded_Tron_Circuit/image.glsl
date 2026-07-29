// Image (image) — Extruded Tron Circuit by Shane
// https://www.shadertoy.com/view/dsGcDz

/*

    Extruded Tron Circuit
    ---------------------
    
    I guess you'd call this a muli-path non-intersecting random walk example, 
    but for anyone old enough to remember, it's a glorified Windows screen saver. :)
    
    A few months ago, Shadertoy user, Gunthern, posted a rough 2D version of the 
    Windows pipe screensaver. He must have posted it at a weird time, because it 
    didn't receive a great deal of attention, but I thought it was awesome and 
    wanted to make my own one. Gunthern's was created using brute force array 
    methods, which worked great, but I wanted to use neighboring cell techniques. 
    I hacked away and got there in the end, but the non-intersecting random walk 
    code needs a logical overhaul. At some stage, I'll rewrite it, but for now it 
    works, so I'll leave it alone. By the way, if someone wants to write a nicer 
    cleaner version, I'd welcome that. :)
    
    The display code is pretty standard, so there's not much to garnish from that. 
    I took a while to post this because I didn't like the original result. However, 
    I got bored a week ago and added some blinking lights which added the extra 
    detail that I felt was lacking, so here it is. :) The comments have been
    rushed, so if some of them don't make sense, it's probably because they don't. :)
    However, I'll tidy them up in due course. I intend to write a 3D version at 
    some stage. Gunthern has one of those too. The link is below.
    
    
    
    Inspired by:
    
    // 2D Windows pipes.
    Windows Pipe Dream 2D - Gunthern
    https://www.shadertoy.com/view/mdGGRw
    
    // The 3D version.
    Windows Pipe Dream 3D - Gunthern
    https://www.shadertoy.com/view/dsGGRw

*/
 
 
// Object ID: Either the back plane, extruded object or beacons.
int objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


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

    
// Height map value.
float hm(in vec2 p, float id){ 

    float h = .1;
    if(id>0.) h = .15; // + id/4.;
    return h;

}

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}



/////////

// IQ's unsigned distance to the segment joining "a" and "b".
float distLine(vec2 p, vec2 a, vec2 b){

    p -= a; b -= a;
    float h = clamp(dot(p, b)/dot(b, b), 0., 1.);
    return length(p - b*h);
}

// Wrapped texture lookup.
vec4 aTx(vec2 uv){ 
    uv = mod(uv, SIZE);
    return texelFetch(iChannel0, ivec2(uv), 0);
}

//////////
 

// Global scale.
float gScale = 1./4.;


// Global cell boundary distance variables.
vec3 gDir; // Cell traversing direction.
vec3 gRd; // Ray direction.
float gCD; // Cell boundary distance.
 
// Global cell ID. 
vec2 gIP;

// Constructing the Tron (random walk) pattern.
void tr(inout vec2 oP, inout vec4 d, inout vec2 id){


    vec2 p = oP; 
 
   
    // Positional cell ID and local coordinates. If you didn't want to shift
    // rows and columns, you wouldn't need any of the code above, nor would you
    // need the three lines below.
    vec2 ip = floor(p/gScale);
    p -= (ip + .5)*gScale;
    
    
    gIP = ip; // Record the ID for usage elsewhere.
    oP = p; // Record the local position.
    
 

    
    // Three distances and IDs, to represent up to three shapes per cell.
    d = vec4(1e5);
    


/////////
         
    
    // Cell border, border width and line width.
    float bw = .03;
    float lw = .325*gScale;
    vec2 q = abs(p);
    float sq = max(q.x, q.y) - (.5 - bw)*gScale; // Square boundary.


    // Read in from the buffer.
    vec4 bufA = aTx(ip);
    // Bit value, telling us which line directions to draw.
    int iVal = int(bufA.x);

    // Neighboring directions.
    mat4x2 dir = mat4x2(vec2(-1, 0), vec2(0, 1), vec2(1, 0), vec2(0, -1));
 
    // Neighboring values.
    vec4 mDir = vec4(aTx(ip + vec2(-1, 0)).x,  // Left
                     aTx(ip + vec2(0, 1)).x,   // Up.
                     aTx(ip + vec2(1, 0)).x,   // Right.
                     aTx(ip + vec2(0, -1)).x); // Down.

    // Left, up, right, down bits.
    ivec4 bit = ivec4(1, 2, 4, 8);
    bit = bit.zwxy; // Left pixel needs a right connection, up pixel needs a down one, etc.

    // Connection values.
    int cnct = 0;
    int cnct4 = 0;

    
    // Debug: Active connections.
    // int activeCon = 0;

    // Line value.
    float ln = 1e5;

    // Render the four lines eminating from the cell center.
    q = p;

    for(int i = 0; i<4; i++){

        //vec2 q2 = rot2(3.14159265/2.*float(i))*(q - dir[i]*.5);
        
        // If the direction bit is set, render the line.
        if((iVal&(1<<i))>0){

           if((int(mDir[i])&bit[i])>0){ // If the neighboring connection exists.
               
               // Line.
               ln = min(ln, distLine(q, vec2(0), dir[i]*gScale*(.5)) - lw);
               //ln = min(ln, sBoxS(q2, vec2(.5 + lw, lw), 0.));//(.5 + lw
               cnct++;

               cnct4 += 1<<i;

           }
           //else activeCon = 1;
        }


    }

////////
    
    // Rounded curves. Commenting this out will result in sharp corners.
    #define CURVES

    #ifdef CURVES

    float sm = .2*gScale;
    vec2 sz = vec2(.5)*gScale;
    if(cnct4==3 && iVal == 3) ln = abs(sBoxS(q - vec2(-1, 1)*sz, sz, sm)) - lw;
    if(cnct4==6 && iVal == 6) ln = abs(sBoxS(q - vec2(1, 1)*sz, sz, sm)) - lw;
    if(cnct4==12 && iVal == 12) ln = abs(sBoxS(q - vec2(1, -1)*sz, sz, sm)) - lw;
    if(cnct4==9 && iVal == 9) ln = abs(sBoxS(q - vec2(-1, -1)*sz, sz, sm)) - lw;

 
    #endif  

    // Single square override.
    // q = abs(fract(p) - .5);
    
    // If there are no connections in the cell, render a single nodule. This
    // was an aesthetic choice, but it's not necessary.
    if(iVal==0){
       //ln = sBoxS(q, vec2(.25*gScale), .1*gScale);
       ln = length(q) - .325*gScale;
    }

    // If there is just one connecting line, render round circle in the center.
    // This is another nonfunctional aesthetic choice.
    if(cnct==1){
        ln = min(ln, length(q) -.4*gScale);
        //ln = max(ln, -(length(q) -.05*gScale));
    }

    
    // ID.
    id = ip;

    // Saving some values for later usage.
    //d.x = max(ln, sq - gScale*.25*.5);
    d.x = ln; //sq;
    d.y = bufA.y>-1e-5? hash21(vec2(6, bufA.y)) : bufA.y;
    d.z = sq;
    d.w = float(iVal);
 
}


// Glow variable.
vec3 glow;

  
// The scene's distance function: There'd be faster ways to do this, but it's
// more readable this way. Plus, this  is a pretty simple scene, so it's 
// efficient enough.
float m(vec3 p){
    
    // Back plane.
    float fl = -p.z;
    
    // 2D Truchet distance, for the extrusion cross section.
    vec4 d; vec2 id;
    vec2 gP = p.xy;
    tr(gP, d, id);
 
    // Extrude the 2D field object along the Z-plane.
    // A bit of face beveling to reflect the light a little more.
    float bev = min(-d.x/gScale*2., .2)*.05; // 03;
    float h2 = hash21(gIP + .04);
    float h = hm(gIP, d.y);// + d.y*.25; // Cell ID, and individual curve ID.
    float blockH = .05 + max(d.y*.25, 0.);
    float obj = opExtrusion(d.x, p.z + blockH + h/2., h/2., .0)  - bev; 
    
    
    // Beveling and extruded block.
    bev = min(-d.z/gScale*2., .2)*.025;
    float block = opExtrusion(d.z, p.z + blockH/2., blockH/2., .0) - bev;
    fl = min(fl, block); 
    fl -= smoothstep(0., .125, (abs(fract(d.x*32.) - .5) - .25)/32.)*.25;
    
    // Directional ray collision with the square cell boundaries.
    vec2 rC = (gDir.xy*gScale - gP)/gRd.xy; // For 2D, this will work too.
    
    // Minimum of all distances, plus not allowing negative distances, which
    // stops the ray from tracing backwards... I'm not entirely sure it's
    // necessary here, but it stops artifacts from appearing with other 
    // non-rectangular grids.
    //gCD = max(min(min(rC.x, rC.y), rC.z), 0.) + .0015;
    gCD = max(min(rC.x, rC.y), 0.) + .0015; // Adding a touch to advance to the next cell.
 
 
    // Last minute glow code.
    float rW = .05*gScale;
    if(obj<fl && d.y>-1e-5){//
    
        // Color.
        float id2 = hash21(vec2(d.y, 8));
        vec3 sCol = .5 + .45*cos(6.72831589*id2/4. + vec3(0, 1, 2.)*1.5);
        if(hash21(vec2(2, d.y))<.5) sCol = mix(sCol ,sCol.yxz, .9);
 
        
        d.x = min(d.x, gCD);
        float rnd = hash21(gIP + .01);
        rnd = smoothstep(.8, .95, sin(6.2831589*rnd + iTime*2.))*2. + .25;
        
        // Add the glow.
        glow += sCol*rnd*64./(1. + obj*obj*32.)*smoothstep(0., .35, -(d.x + rW));
    
    }
    
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





void mainImage(out vec4 c, vec2 u){

    
    // Aspect correct coordinates. Only one line necessary.
    u = (u - iResolution.xy*.5)/iResolution.y;    
    
    // Unit direction vector, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), o = vec3(iTime/2., 0, -3), l = o + vec3(.5, 1, 1.5);
    
    // Rotating the camera about the XY plane.
    r.yz = rot2(-.2)*r.yz;
    r.xz = rot2(-cos(iTime*3.14159/32.)/8.)*r.xz;
    r.xy = rot2(sin(iTime*3.14159/32.)/8.)*r.xy; 
    
  
    
    // Standard raymarching setup.
    float d, t = hash31(o + r + fract(iTime))*.25;
    
    // Set the global ray direction varibles -- Used to calculate
    // the cell boundary distance inside the "map" function.
    gDir = sign(r)*.5;
    gRd = r; 

    // Glow initialization.
    glow = vec3(0);
    
    // Raymarch.
    for(int i = min(iFrame, 0); i<96; i++){ 
        
        vec3 p = o + r*t;
        d = m(p); // Surface distance.
        // Surface hit -- No far plane break, since it's just the floor.
        if(abs(d)<.001) break; 
        t += min(d*.9, gCD);  // Advance the overall distance closer to the surface.
         
    }
    
    
    vec3 svGlow = glow;
    
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
    
    // 2D pattern face distace -- Used to render borders, etc.
    //scale *= 3.;
    vec4 d4; vec2 vID;
    vec2 p2 = p.xy;
    tr(p2, d4, vID);
    
    // Minimum tile object index.
    int index = 0;//(d4.x<d4.y && d4.x<d4.z)? 0 : d4.y<d4.z? 1 : 2;
    // 2D object face distance and ID.
    float obj2D = d4[index];
    vec2 id = vID*scale;
    
    // Object heights.
    float h2 = hash21(gIP + .04);
    float blockH = .05 + max(d4.y*.25, 0.);
    float h = hm(gIP, d4.y) + blockH;// + h2*.125;
 
 
    // Texture position.
    vec3 txP = vec3(p2, p.z);
    vec3 txN = n;
    vec3 tx = tex3D(iChannel1, txP/2., txN); 

     

  
    // Standard material properties: Roughness, matType and reflectance.
    //
    float roughness = .2; // Lower roughness reflects more light, as expected.
    float matType = 0.; // Dielectric (non conducting): 0, or metallic: 1.
    float reflectance = .5; // Reflective strength.
    
    
    // Object color.
    vec3 oCol = vec3(0);
    
    // Use whatever logic to color the individual scene components. I made it
    // all up as I went along.
    //
    if(gObjID == 0){
    
    
       // Floor, or wall, depending on perspective.
       oCol = vec3(.125);
       matType = 1.; // Metallic material.
       roughness = .5;
       
       
    }
    else if(gObjID==1){
    
        // Extruded Tron pattern:

        // Noise texture, used for a hacky scratched surface look.
        // Usually, you'd tailor this to specific material needs.
        vec3 txR = txP;
        txR.xy *= rot2(-3.14159/6.);
        vec3 rTx = tex3D(iChannel2, txR*vec3(.5, 3, .5), txN);
        float rGr = dot(rTx, vec3(.299, .587, .114));
 
        
        // The tile base color.
         
        ////////////////    

        float rW = .125*gScale; // Rim width.
        float sf = .007; // Smoothing factor.
        float ew = .02; // Edge width.


        
 
        // Face rim and face distance values for edge rendering. 
        float b = abs(obj2D) - .01;
        float pH = p.z + h - .04;
        b = max(b, (p.z + h - .02));
        

        // Object color.
        vec3 sCol = vec3(.25);
         
        
        
        // Applying edges to the light color.   
        vec3 lgtCol = mix(min(sCol*1.4, 1.), vec3(1), .2);
        lgtCol = mix(lgtCol, oCol*.15, (1. - smoothstep(0., sf, -d4.z)));


        // Applying face color patterns, edges, etc..
        oCol = sCol*.5;
        oCol = mix(oCol, oCol*.15, (1. - smoothstep(0., sf, pH)));
        oCol = mix(oCol, sCol, (1. - smoothstep(0., sf, pH + ew)));
        oCol = mix(oCol, oCol*.15, (1. - smoothstep(0., sf, obj2D + rW)));

        // Mixing in the light color.
        oCol = mix(oCol, lgtCol, (1. - smoothstep(0., sf, obj2D + rW + ew)));
        //roughness = mix(.6,.2, (1. - smoothstep(0., sf, obj2D + rW + ew)));
        oCol *= tx*.6 + .9;

        // Dielectic material roughness.

        roughness = .3;
        roughness *= (rGr*.4 + .6);
       

        
    }
    
    
    
    // More last minute dark texturing and glow.
    tx = tex3D(iChannel2, p/3., n);
    oCol *= tx*2. + .2;
    oCol = oCol + oCol*svGlow;  
    

    /*
    // Shiny... Doesn't really work here. Perhaps with extra tweaking.
    // Requires "Forest" cube map loaded into "iChannel3".
    // Specular reflection.
    vec3 hv = normalize(-r + ld); // Half vector.
    vec3 ref = reflect(r, n); // Surface reflection.
    vec4 refTx = texture(iChannel3, -ref.yzx, 1.); refTx *= refTx; // Cube map.
    float spRef = pow(max(dot(hv, n), 0.), 8.); // Specular reflection.
    //spRef = mix(spRef/4., spRef, 1. - smoothstep(0., .01, d + .05));   
    float rf = (matType < .5)? 8. : 1.;//mix(.25, 4., 1. - smoothstep(0., .01, d + .05));
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
    c = pow(max(c, 0.), vec4(1./2.2)); 

}