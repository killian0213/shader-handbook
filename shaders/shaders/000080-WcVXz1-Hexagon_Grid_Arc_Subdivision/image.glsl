// Image (image) — Hexagon Grid Arc Subdivision by Shane
// https://www.shadertoy.com/view/WcVXz1

/*

	Hexagon Grid Arc Subdivision
	----------------------------
	
    I love those curved line patterns that are constructed from various 2D 
    grid setups. They're less common than straight line patterns for the
    obvious reason that straight lines are easier to work with. However, 
    curved designs based on circular arcs don't involve too much extra work.
    
    This particular pattern is reasonably common, and involves partitioning
    hexagon cells with some strategically placed circular arcs. DjinnKahn 
    already posted a nice black and white version a while ago, which prompted 
    me to put this together. The link to his original is below. I took a 
    different approach to its construction, since I needed to include distance 
    field information. I'd also like to code up a traversal later, so I needed 
    to take that into account as well.
    
    I'd imagine if DjinnKahn was tasked with coding this particular version, 
    it'd be twice as efficient and completed in a fraction of the time. :)
    Nevertheless, the code here is fast enough and reasonably trustworthy.
    
	There are a couple of "defines" in the "Common' tab for anyone interested 
    in that. The "SHOW_GRID" define is there for anyone who might want to see 
    the underlying hexagon grid upon which the pattern is based.
    
    I might revisit this at some stage and put together the version that I 
    intended to make in the first place. I also plan to produce some other 
    curved patterns.
    
    

	Other examples:


    // There's a lot to be said for the simplicity of black and white. 
    // Myself, and Elenzil, were pretty happy with this pattern. :)
    circular tiling -- DjinnKahn
    https://www.shadertoy.com/view/lftcD4

*/

 
// Far plane.
#define FAR 10.

 
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


// Compact, self-contained version of IQ's 3D value noise function. I have a transparent 
// noise example that explains the process, if you require it.
float n3D(vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(mod(h, TAU))*43758.5453), 
            fract(sin(mod(h + s.x, TAU))*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}



// IQ's extrusion formula.
float opExt(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}


// Polygon information.
vec4 gVal;
int gID;
 
// The height map values. In this case, it's just a Voronoi variation. By the way, 
// I could optimize this a lot further.
float heightMap(vec3 p){
 
    
    vec4 d4 = getPattern(p.xy);
    
    float poly = d4.x;
    int pID = int(d4.w);
    vec2 id = d4.yz;
    
    /*
    float colID = hash21(id + .1);
    //float colID = float(pID)/3.;//25.;
    vec3 pCol = .5 + .45*cos(TAU*colID + vec3(0, 1, 2)*1.5);
    */
 
    gVal = vec4(poly, id, pID);
    
    return poly;
}

// Object glow.
//vec3 glow;

// Hexagon border flag. Hacked in at the last minute in order to
// give the ability to see hexagon borders.
int gHexBord;

// Back plane height map.
float m(vec3 p){
   
     // Polygon pattern heightmap.
    float h = heightMap(p);
    
    // The floor -- Not seen here.
    float fl = -p.z;
   
    // Edges.
    // Extruding the 2D object along the Z-axis.
    float edge2D = abs(h + .008) - .005; // 2D edge.
    float edge = opExt(edge2D, p.z + .0525/2., .0525/2., .001);// 3D edge.
    // Less correct, but does roughly the same thing.
    //float edge = max(edge2D, abs(p.z + .025/2.) - .025/2.); 
    
    // Inner polygons.
    float poly2D = h + .005*2. + .008;
    float poly = opExt(poly2D, p.z + .025/2., .025/2., .001);
    //float fl = max(poly + .015, abs(p.z + .025/2.) - .025/2.);
    poly += poly2D*.25; // Using the 2D field to raise the tops a bit.
    //poly += max(poly2D, -.015)*.15;
    
    #ifdef SHOW_GRID
    // Hexagon grid construction. I've put it in at the last minute.
    float edge2 = max(gPoly, abs(p.z + .035) - .035);
    gHexBord = edge2<poly? 1 : 0;
    poly = min(poly, edge2);
    #endif

    /* 
    // A sprinkling of noise. 
    vec3 tx = texture(iChannel0, p.xy).xyz; //tx *= tx;
    float gr = dot(tx, vec3(.299, .587, .114));
    //float gr = hash22(floor(p.xy*32.)/32.).x;
    poly -= (gr - .5)*.0015;
    edge -= (gr - .5)*.0015;
    */
    
    // Determining the object ID. I usually prefer to calculate
    // this outside the raymarching loop, but this is easier.
    gID = fl<edge && fl<poly? 0 : edge<poly? 1 : 2;
   
    // Minimum distance.
    return min(fl, min(edge, poly));
    
}


// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float d, t = 0.;
  
    
    vec2 dt = vec2(1e5, 0); // IQ's clever desparkling trick.
    
    // Reset the glow to zero.
    //glow = vec3(0);
    
    int i;
    const int iMax = 128;
    for (i = min(iFrame, 0); i<iMax; i++){ 
    
        d = m(ro + rd*t);       
        dt = d<dt.x? vec2(d, dt.x) : dt; // Shuffle things along.
        
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, 
        // as "t" increases. It's a cheap trick that works in most situations.
        if(abs(d)<.001 || t>FAR) break; 
        
        //t += i<32? d*.75 : d; 
        t += d*.9; 
    }
    
    // If we've run through the entire loop and hit the far boundary, 
    // check to see that we haven't clipped an edge point along the way. 
    // Obvious... to IQ, but it never occurred to me. :)
    if(i>=iMax - 1) t = dt.y;

    return min(t, FAR);
}

// Standard normal function. It's not as fast as the tetrahedral calculation, 
// but more symmetrical.
vec3 nr(in vec3 p) {
	
    //const vec2 e = vec2(.001, 0);
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //                      map(p + e.yxy) - map(p - e.yxy),	
    //                      map(p + e.yyx) - map(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.0025, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
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
float softShadow(vec3 ro, vec3 rd, float lDist, float k){

    // More would be nicer. More is always nicer, but not always affordable. :)
    const int iters = 32; 
    
    float shade = 1.;
    float t = 0.; 


    // Max shadow iterations - More iterations make nicer shadows, but slow things down. 
    // Obviously, the lowest number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<iters; i++){

        float d = m(ro + rd*t);
       
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), 
        // dist += clamp(h, .01, stepDist), etc.
        t += clamp(d*.8, .01, .25); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>lDist) break; 
    }

    // Shadow.
    return max(shade, 0.); 
}
 
 
// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float cAO(in vec3 p, in vec3 n)
{
	float sca = 3., occ = 0.;
    for(int i = 0; i<5; i++){
    
        float hr = .01 + float(i)*.25/4.;        
        float dd = m(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= .75;
    }
    return clamp(1. - occ, 0., 1.);    
}
 
 
/*
// Modified version of Nimitz's curve function.
//
// I think it's based on a discrete finite difference approximation to the continuous
// Laplace differential operator? Either way, it gives you the curvature of a surface, 
// which is pretty handy.
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
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
   
    //return clamp(d/e.x*amp + offs + .05, -.1, .1)/.1;
    return smoothstep(-.05, .05, d/e.x/e.x*amp + offs);

}
*/


void mainImage(out vec4 c, vec2 u){

    // Coordinates.
    u = (u - iResolution.xy*.5)/iResolution.y;
    
    // Time for the "Common" tab.
    tm = iTime;
    
    //u *= rot2(TAU/24.);
    
    // Screen bulge.
    u *= .94 + dot(u, u)*.08;
    
    // Unit direction ray, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), 
         o = vec3(iTime/8., iTime/16., -1), l = vec3(.35, .5, 0);
   
    // Rotate the unit direction ray, and light to match.
    r.yz *= rot2(-.1);
    r.xz *= rot2(-.1);
    l.yz *= rot2(-.1);
    l.xz *= rot2(-.1);
    l += o; // Moving the light with the camera.
    
    
    // The vertex and edge IDs are multiplied by 12, so we're factoring that in.
    vec2 sDiv12 = s/12.;
    
    // Precalculate.
    for(int i = 0; i<6; i++){
        v[i] = vID[i]*sDiv12; // Vertices.
        e[i] = eID[i]*sDiv12; // Edges.
    } 

    
    // Standard raymarching routine.
    float t = trace(o, r);
 
    
    int svID = gID; // Object ID. Unused.
    // Voronoi cell ID.
    vec4 svVal = gVal;
    
    // Hexagonal grid border flag.
    int svHexBord = gHexBord;
    
    // Set the initial scene color to black.
    vec3 col = vec3(0);
    
    // If the ray hits something in the scene, light it up.
    if(t<FAR){
    
        // Position and normal.
        vec3 p = o + r*t, n = nr(p);

        l -= p; // Light to surface vector. Ie: Light direction vector.
        float lDist = max(length(l), .001); // Light to surface distance.
        l /= lDist; // Normalizing the light direction vector.
        
        
        float atten = 1./(.5 + lDist*lDist*.25);


        // The shadows barely make an impact here, so we may as well
        // save some cycles.
        float sh = softShadow(p + n*.0015, l, lDist, 16.);
        float ao = cAO(p, n);

        // Scene curvature.
        //float spr = 2., amp = 1., offs = .0;
        //float crv = curve(p, spr, amp, offs);
 
     
        
        // Surface object coloring.
     
        // Texture.
        vec3 tx = tex3D(iChannel0, (p), n);
        vec3 oCol = vec3(.05);
        vec3 inGCol = vec3(2.5, 2, 1.5); // Inner glow color.
        
        if(svID==2){
        
            // The extruded polygons.
            
            // Cell coloring.
            float colID = hash21(svVal.yz + .1);
            //float colID = float(pID)/3.;//25.;
            
            #if COLOR == 1
            // Blue and purple.
            vec3 pCol = .5 + .45*cos(TAU*colID/8. + vec3(0, 1, 2)*1.5);
            if(svVal.w == 1.){ oCol = pCol.zyx; }
            if(svVal.w == 2.){ oCol = mix(pCol.yzx, pCol, .0); }
            #else
            // Blood rose and leafy green. With the brownish copper frame, I was 
            // trying to go for some kind of natural theme... It's interesting. :D
            vec3 pCol = .5 + .45*cos(TAU*colID/6. + vec3(0, 1, 2) + .5);
            inGCol = inGCol.zyx;
            if(svVal.w == 1.){ oCol = mix(pCol.xzy, pCol, .2);  }
            if(svVal.w == 2.){ oCol = mix(pCol.yxz, pCol.zyx, .2);  }
            #endif
            
            // Neutral dark colors.
            if(svVal.w == 0.){ oCol = vec3(.25)*dot(pCol, vec3(.299, .587, .114)); }
            if(svVal.w == 3.){ oCol = vec3(.25)*dot(pCol, vec3(.299, .587, .114)); }
            
            // If selected (see the "SHOW_GRID" define), color the hexagonal border 
            // something bright to make it  stand out.
            if(svHexBord==1) oCol = vec3(.8, .9, 1);
        
        }
        
        if(svID==1){
        
            // Metallic borders.
            #if COLOR == 1
            oCol = vec3(.7); // Silver.
            #else
            oCol = vec3(.75, .67, .65); // Copper.
            #endif
            
        }
        
        
        
        // Inner edge glow.
        oCol = mix(oCol, oCol*(oCol)*inGCol*.5, 
                   1. - smoothstep(0., .03, abs(svVal.x + .018) - .005));

        // Greyscale.
        //if(svVal.w == 1. || svVal.w == 2.)
        //    oCol = vec3(.7)*dot(oCol, vec3(.299, .587, .114));
        
        
        // Extra faux surface shading.
        oCol *= max(-svVal.x/gSc, 0.)*3. + .25;
   
        
        // Apply some mild texturing.
        oCol *= tx*2. + .5;
  
         
        // Backfill light.
	    float backFill = max(dot(vec3(-l.xy, 0.), n), 0.);
        float ns0 = n3D(p*3. + iTime/4.);
        ns0 = smoothstep(-.25, .25, ns0 - .5);
        oCol += oCol*mix(vec3(1, .05, .0), vec3(1, .1, .2), ns0*.5)*backFill*4.*sh;
         
        
        
        // Faux Fresnel edge glow.
        //float fres = pow(max(1. - max(dot(-r, n), 0.), 0.), 3.);
        //oCol += oCol*vec3(.1, .3, 1)*fres*12.; 
      
      
   
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio and outdoor.
        float ambience = pow(length(sin(n*2.)*.5 + .5), 2.);
        //float ambience = length(sin(n*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -n.z)*1.; 
 
         
        #if 1 
        // Rough BDRF lighting.
        //
 
        // Make some of the flat tops metallic.
        float matType = svID==2? 0. : 1.; // Dialectric or metallic.
        float roughness = dot(tx, vec3(.299, .587, .114)); // Texture based roughness.
        float reflectance = roughness*2.; // Texture based reflectivity.

        //oCol *= 1. + matType; // Brighter metallic colors.
        roughness *= 1. + matType; // Rougher metallic surfaces.
        
        if(matType==1.){
            
            roughness *= .7;
             
        }

        // Cook-Torrance based lighting.
        vec3 ct = BRDF(oCol, n, l, -r, matType, roughness, reflectance);

        // Combining the ambient and microfaceted terms to form the final color:
        // None of it is technically correct, but it does the job. Note the hacky 
        // ambient shadow term. Shadows on the microfaceted metal doesn't look 
        // right without it... If an expert out there knows of simple ways to 
        // improve this, feel free to let me know. :)
        col = (oCol*ambience*(sh*.75 + .25) + ct*(sh));

        #else 
        // Blinn Phong.
        float df = max(dot(l, n), 0.); // Diffuse.
        df = pow(df, 2.) + pow(df, 4.)*.5;
        
        float sp = pow(max(dot(reflect(-l, n), -r), 0.), 32.); // Specular.
        // Fresnel term. Good for giving a surface a bit of a reflective glow.
        //float fr = pow( clamp(dot(n, r) + 1., .0, 1.), 2.);

        // Regular diffuse and specular terms.
        float gr = dot(tx, vec3(.299, .587, .114));
        if(svID==1) df = pow(df, 4. + 8.*gr)*.5;
        else df *= df + gr;
        col = oCol*(df*sh + sp*sh*2. + ambience*.5);
        #endif 
        
        
        
        // Specular reflections.
        vec3 hv = normalize(-r + l);
        vec3 ref = reflect(r, n);
        // Hacky environmental mapping... I should put more effort into this. :)
        vec3 tx2 = texture(iChannel1, reflect(r, n)).xyz; tx2 *= tx2;
        float specR = pow(max(dot(hv, n), 0.), 8.);
        float rF = svID==1? 2. : 3.; // Reflecting the metal a little less.
        col += col*specR*tx2*rF;   
       
        
        // Apply the curvature based lines.
        //col *= crv*.8 + .4;
        //col *= 1. - abs(crv - .5)*2.*.8;
     
     
        // AO - The effect is probably too subtle, but I'm using it anyway.
        col *= ao*atten;

        
    }
    
    
    // Save to the backbuffer.
    c = vec4(pow(max(col, 0.), vec3(1)/2.2), 1);
    
    
}
