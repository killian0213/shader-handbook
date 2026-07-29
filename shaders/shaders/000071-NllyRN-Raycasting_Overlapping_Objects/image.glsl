// Image (image) — Raycasting Overlapping Objects by Shane
// https://www.shadertoy.com/view/NllyRN

/*

    Raycasting Overlapping Objects
    ------------------------------
    
    Rendering inside a pixelshader environment can be challenging, and 
    in many cases, restrictive. If you've ever tried to render a grid
    of closely packed or overlapping objects, you'll notice neighboring 
    grid cell overlap artifacts. Sometimes, you can render four cells at
    a time to account for the overlap, but in a 3D scene, a pixel ray 
    can usually visit more cells than you can accomodate for. Traversing 
    a grid in a cell by cell manner along the line of sight can fix that
    problem, but isn't of much use when objects overlap cell boundaries.
    
    In that case, you will have to perform a neighboring cell by cell 
    traversal, like this one. A cell by cell traversal with neighbor
    checks is not ideal, but will be artifact free. This traversal only
    accounts for four neighboring cells, so only a certain amount of 
    overlap is possible, but as you can see, you can create more 
    interesting variations when overlap is allowed. If you wanted to 
    create a more interesting cityscape, a traversal like this would give
    you more options.
    
    This scene works on an extruded 2D (XZ) grid schematic, but a proper 
    3D voxel version (XYZ) is possible. In fact, Reinder has incorporated 
    just that in his "RIOW 2.09" scene. It's in static form, but I think
    a realtime version would be possible.
    
    Rendering overlapped artifact free scenes in this manner gives the 
    user another tool to work with, but ultimately, I'd imagine more 
    sophisticated partitioning structures would be required to render 
    more sophisticated scenes.
    
    As for the scene itself, I made it up as I went along, so I'm not 
    really sure what it's supposed to represent, but it reminds me of 
    the final minutes of touchdown in various places I've flown to... 
    I've been to some dreary places in my time. :)


    Other traversal rendering schemes:
    
    // This is a static image, but I believe it is the first example 
    // on Shadertoy involving a 3D voxel cell traversal that caters 
    // for overlapping objects (the cube of white spheres).
    RIOW 2.09: A Scene Testing All - reinder
    https://www.shadertoy.com/view/MtycDD
    
    // Fizzer has all kinds of really cool traversal examples.
    Procedural Octree - Fizzer
    https://www.shadertoy.com/view/3dSGDR
    
    // One of IQ's BVH examples. There are a few on Shadertoy, and
    // all are worth a look.
    Boxes traced - IQ
    https://www.shadertoy.com/view/4tKBWy
    
    // Abje's stackless version, based on IQ's example.
    many boxes - abje
    https://www.shadertoy.com/view/wsS3Wz
    
    // OCB's really nice architectural sci-fi scene constructed
    // with three variable sized grids. OCB has similar examples
    // that are worth the look too.
    Hope - ocb
    https://www.shadertoy.com/view/MllfDX

*/


#define FAR 25.
 

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 2 out, 2 in...
vec2 hash22(vec2 p){

	vec3 p3 = fract(vec3(p.xyx)*vec3(.3031, .4030, .5973));
    p3 += dot(p3, p3.yzx + 42.1237);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// Rectangle scale. Smaller scales mean smaller squares, thus more of
// them. Sometimes, people (including myself) will confuse matters
// and use the inverse number. :)
vec2 s = vec2(1, 1)/4.; 

 // Ray origin, ray direction, point on the line, normal. 
float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop. However,
   // this isn't a GPU intensive example, so it doesn't matter here.
   return dot(p - ro, n)/dot(rd, n);

}

// Grid cell function.
vec2 gridID(vec2 p){
    // Using the rectangle's center position for the ID. 
    return floor(p/s) + .5;

}


float hm(vec2 p){

    // Only one texture read.
    vec3 tx = texture(iChannel0, p/iChannelResolution[0].xy*24.).xyz;  tx *= tx;
    // Greyscale height. Using "tx.x" would work, too.
	float f = dot(tx, vec3(.299, .587, .114));
    float f2 = f; 
    
    return f*1.8;//min(f*2., 1.8);//max(f*2. - .075, 0.);//*12. + f2*4.;

}

// IQ's box routine.
// https://iquilezles.org/articles/boxfunctions
vec4 iBox( in vec3 ro, in vec3 invRd, in vec3 dim){ 

	// Ray-box intersection.
    vec3 n = ro*invRd;
    vec3 k = abs(invRd)*dim;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max(max(t1.x, t1.y ), t1.z);
	float tF = min(min(t2.x, t2.y ), t2.z);
	
	if( tN>tF || tF<0.) return vec4(1e8);

	//vec3 nor = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
	return vec4(tN, t1);
}

vec3 gN;
float gObjID;

vec2 gDist;

vec4 raycast(vec3 ro, vec3 rd, int iters){
   
    vec4 res = vec4(FAR, 0, 0, 0);
    
    vec3 invRd = 1./rd;
    
    gObjID = -1.;
    
    
    // Rectangle normals: Any two will do. By the way, there's nothing
    // stopping you from declaring all four normals for all surrounding
    // walls, but since you know only two will be in front of the
    // direction ray at any given time, it makes sense to only choose
    // two.
    //
    // Declare two normals. Any side by side ones will do.
    vec2 n1 = vec2(-1, 0), n2 = vec2(0, -1); // Right and top edges.
    
    // If the cell wall is behind the ray (or the ray is facing the opposing cell
    // wall, if you prefer), use the normal index from the back cell wall. This 
    // trick is possible because of the rectangle symmetry. As an aside, for 
    // anyone who doesn't know, dotting the direction ray with the face normal 
    // is something you do in software engines for back face culling.
    n1 = dot(rd.xz, n1)<0.? -n1 : n1;
    n2 = dot(rd.xz, n2)<0.? -n2 : n2;
    
    // Initiate the ray position at the ray origin.
    vec3 pos = ro;
    
    // Obtain the coordinates of the cell that the current ray position 
    // is contained in -- I've arranged for the cell coordinates to 
    // represent the cell center to make things easier.
    vec2 ip = gridID(pos.xz);
    
    vec2 gIP = ip;
    
    float t1 = 1e8, t2 = 1e8, tT = 1e8;
    
    float floorDist = (0. - ro.y)/rd.y;
    
    int hit = 0;
    
    gDist = vec2(1e8);
    
    gDist.y = floorDist;
    
    vec4 t44 = vec4(FAR);
    
    //vec3 ip0 = vec3(ip.x*s.x, pos.y, ip.y*s.y);
   float d = 1e8;
    // Iterate through 24 cells -- Obviously, if the cells were smaller,
    // you'd need more to cover the distance.
    for(int i = 0; i<iters; i++){ 
    
        // If we've hit the ocean plane, return immediately.
        if (pos.y<0.){ gN = vec3(0, 1, 0); gObjID = 0.; return vec4(floorDist, vec3(0)); }

         
        vec2 svIP;
        //d = 1e8;
        t1 = rayLine(pos.xz, rd.xz, (ip + n1*.5)*s, -n1);
        t2 = rayLine(pos.xz, rd.xz, (ip + n2*.5)*s, -n2);
        
        // This example doesn't differ much from a simple cell by cell traversal.
        // The difference is the neighbor check. 
        float gMa;
        // Checking four cells to cater for overlap, instead of the usual one only.
        for(int j = 0; j<4; j++){ 
         
            // Standard 2x2 neighbor check.
            vec2 offs = vec2(j&1, j>>1) - .5;
            vec2 ipJ = floor(ip - offs) + .5;
            
            // Height.
            float ma = hm(ipJ*s);
            // Skipping blocks below a certain height to make a clear water line distinction.
            if(ma<1./20.) continue; 

            // At this point, we haven't advanced the ray to the back of the cell boundary,
            // so we're at one of the front cell face positions. Therefore, check to see if 
            // we're under the pylon height. If so, we've hit a face, so mark the face as hit, 
            // then break.

            vec2 w = hash22(ipJ + .21)*.8 + .05;//(min(ma, 1.)*.7 + .3) + .1;// - .02;
                
            t44 = iBox(ro - vec3(ipJ.x*s.x, ma/2., ipJ.y*s.y), invRd, vec3(s.x*w.x, ma/2., s.y*w.y));

            // Nearest of the four boxes.
            if(t44.x<d && (t44.x<length(pos - ro) + min(t1, t2))){

                d = t44.x;
                gN = t44.yzw;
                gN = -sign(rd)*step(gN.yzx, gN)*step(gN.zxy, gN);
                svIP = ipJ;
                gMa = ma;
   
            }
        
        }
       
 
        gDist.x = d; 
     
        // We've hit a box, so return.
        if(d<FAR) { hit = 1; gObjID = 1.; return vec4(d, 0, svIP); }

        // Determine the closest edge then record the closest distance and
        // asign its normal index.
        vec3 tn = t1<t2? vec3(t1, n1) : vec3(t2, n2);

        
        // Advance the cell index position by the indices of the 
        // cell wall normal that you hit. 
        ip += tn.yz;
        // Advance the ray position by the distance to the next cell wall.
        pos += rd*tn.x;
    
    }
    
    
  /*  
    float fID = tT<t1 && tT<t2? 0. : t1<t2? 1. : 2.;
    if(fID == 1.){ fID = dot(rd.xz, vec2(-1, 0))<0.? -fID : fID; }
    else if(fID == 2.){ fID = dot(rd.xz, vec2(0, -1))<0.? -fID : fID; }
    
    
    
    res.x = length(pos - ro);*/
    
    // Top face distance.
    //float tB = (.0 - ro.y)/rd.y;
    //if (tB>=0.){ gN = vec3(0, 1, 0); gObjID = 0.; return vec4(tB, 0, vec2(0)); }
 
    // No hit, so return the far plane.
    if(hit == 0) res.x = FAR;
    
    float fID = -1.;
    return vec4(res.x, fID, ip);
    
}

// Standard normal function.
vec3 nr(float fID, vec3 rd) {
	
    vec3 n = fID == 0.? vec3(0, 1, 0) : abs(fID) == 1.? vec3(1, 0, 0) : vec3(0, 0, 1);
    n *= fID<-.001? -1. : 1.; 
	return n;
}

///////

float surface(vec3 p){

    // Very cheap sinusoidal water effect.
    vec3 q = p*3.;
    float t = iTime;
    float wat = dot(sin(q + vec3(t*.75, 0, 0) - cos(q.yzx*2. - vec3(0, t, 0))*2.), vec3(.333));
    q.xy *= rot2(3.14159/4.)*2.;
    float wat2 = dot(sin(q + vec3(t*.75*2., 0, 0) - cos(q.yzx*2. - vec3(0, t*2., 0))*2.), vec3(.333));
    wat = mix(wat, wat2, 1./3.);
    
    // For anyone not familiar, abs(x*x + a) is a smooth absolute function trick.
    // In this case, it's used to subtly smooth off the crests of the waves.
    return 1. - sqrt(wat*wat*.98 + .02);
}

float bObjID;
// Surface bump function..
float bumpSurf3D(in vec3 p, in vec3 n){
    
    // Water surface bump map only.
    return surface(p);
    
    /*
    // Water surface bump map.
    if(bObjID<.5) return surface(p);
    else {
        // More subtle texture based bump mapping on the blocks.
        vec2 uv = abs(n.y) > .5? p.xz : abs(n.x)>.5 ? p.zy : p.xy;
        vec3 tx = texture(iChannel1, uv).xyz; tx *= tx;
        return dot(tx, vec3(.299, .587, .114));
    }
    */
}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(.001, 0); 
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    float ref = bumpSurf3D(p, n);
    
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy, n),
                      bumpSurf3D(p - e.yxy, n),
                      bumpSurf3D(p - e.yyx, n)) - ref)/e.x; 
   
    
    // Six tap version, for comparisson. No discernible visual difference, in a lot of cases.
    //vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
    //                 bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
    //                 bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    
  
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some kind 
    // of orthogonal space fix using the Gram-Schmidt process, or something to that effect.
    grad -= n*dot(n, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more bumpy.
    return normalize(n + grad*bumpfactor);
	
}
///////

void mainImage( out vec4 c, vec2 u )
{
    
    // Unit direction vector, camera (moving along Z), and point light (above the camera).
    // A "to" and "from" camera system is better, and only requires a few more lines, but
    // we're keeping things simple.
    vec3 r = normalize(vec3(u - iResolution.xy*.5, iResolution.y*2.5)), 
         o = vec3(iTime, 2, iTime*.25), l = o + vec3(-1, 4, 12);
    
    
    
    // Rotating the unit direction ray, for a bit of visual interest.
    r.xz = rot2(.5)*r.xz;
    r.xy = rot2(.1)*r.xy;
    r.yz = rot2(-.25)*r.yz;

    // Raycasting
    vec4 res = raycast(o, r, 160);
    
     
    float t = res.x; // Ray distance.
    float fID = res.y; // Face ID.
    vec2 id = res.zw; // Block position ID.
    
    float objID = gObjID; // Scene object ID: Blocks or water.
    bObjID = gObjID; // Bump object ID: Something I've hacked in at the last minute. 
    
    // Object height.
    float h = hm(id*s);
    
    t = min(t, FAR); // Clipping to the far distance, which helps avoid artifacts.
    
    // Scene color, initialized to zero.
    c = vec4(0);
    
    // If we've hit an object, light it up.
    if(t<FAR){
    
        // Hit position and normal.
        vec3 p = o + r*t, n = gN;//nr(fID, r);
 
        if(objID<.5) n = doBumpMap(p, n, .01);

        // Point light.
        //l -= p; // Light to surface vector. Ie: Light direction vector.
        //float d = max(length(l), 0.001); // Light to surface distance.
        //l /= d; // Normalizing the light direction vector.
        
        // Directional light.
        l = normalize(vec3(-.8, .25, .9)); 
        
        // Diffuse.
        float dif = max(dot(l, n), 0.);
        
        // Shadows.
        float sh = 0.;
        if(dif>0.){
           vec4 resSh = raycast(p + n*.002, l, 64);
           
           if(resSh.x>FAR - 1e-3) sh = 1.; //
           //if(resSh.x>d - 1e-3) sh = 1.; // Point light.
           
        }
         
         

        // Scene object color.
        //
        // UV coordinates.
        //vec2 uv = fID == 0.? p.xz : abs(fID) == 1.? p.zy : p.xy;
        vec2 uv = abs(n.y) > .5? p.xz : abs(n.x)>.5 ? p.zy : p.xy;
        //
        // Texture color.
        vec3 tx = texture(iChannel1, rot2(3.14159/1.)*uv/2.).xyz; tx *= tx;
        vec3 tx2 = texture(iChannel1, rot2(-3.14159/1.)*uv/1. + .5).xyz; tx2 *= tx2;
        tx = mix(tx, tx2, .5);
        //
        c.xyz = .05 + tx*1.5;
        
        // Random Earth tone coloring.
        vec3 bCol = .65 + .3*cos(6.2831*hash21(id + .04)/3. + vec3(0, 1, 2) - .5);
        //vec3 bCol = .65 + .3*cos(6.2831*id.y*s.y/8. + vec3(0, 1, 2)*1.5 - 1.);
        c.xyz *= bCol*1.5;
        // Applying a little river weathering to the blocks -- Obviously more
        // to the surfaces that are closer to the water level.
        const vec3 wCol = vec3(.7, 1, .9);
        c.xyz *= mix(vec3(1), wCol*1.1, tx*clamp(1. - p.y/h, 0., 1.));//

        
        vec3 c2 = wCol*(tx*.5 + .5);
   
        if(objID<.5) c.xyz = c2;
       

       
        // Fake water level shore line AO. I'll look for a better way, but
        // this is cheap and it works well enough for this example.
        if(p.y<.1){//objID<.5
       
           // Raytrace just above water level for a few cells in the direction of 
           // the unit ray, and if you hit a block, you're near enough to it to
           // be occluded... That's my story and I'm sticking to it. :D
           vec4 resR = raycast(p + n*.002, normalize(vec3(r.x, 0, r.z)), 8);
           resR.x = max(resR.x - .15, p.y-.05);
           
           c.xyz = mix(c.xyz, c2/2., 1. - smoothstep(-.1, .1, resR.x));// - .25
       
        }
        
        // IQ's rim lighting snippet: For anyone not familiar, he's using 
        // the Fresnel factor for some sillouette lighting.
        float rim = pow(clamp(1. + dot(r, n), 0., 1.), 5.);
        
         
        // Specular reflection. 
        //float spe = pow(clamp(dot(l, reflect(r, n)), 0., 1.), 8.);
        float spe = pow(clamp(dot(reflect(l, n), r), 0., 1.), 8.);
        
       
        // AO routine. Hacked together from one of IQ's old routines.
        // I started this example a while ago, so I don't think it's
        // complete. I'll need to take a proper look later.
        vec2 p2 = (p.xz - id*s);
        float h0 = hm(id*s);
        float py = (1. - smoothstep(0., 1., -p.y + h0));
        vec4 h4 = vec4(hm((id + vec2(-1, 0))*s), hm((id + vec2(1, 0))*s), 
                       hm((id + vec2(0, -1))*s), hm((id + vec2(0, 1))*s));
                       
        vec4 h4mh0 = h4 - h0;
        
        float ao = 1.;
        float minEdge = min(s.x, s.y)/4.;
        float edge = s.y/4.;
        float edge2 = s.x/4.;
        
        float aoSh = .5;
        if(n.y>.5){
            if(p2.y>minEdge && h4mh0.w>0.) ao = min(ao, 1. - smoothstep(0., 1., (p2.y - edge)/edge)*aoSh);
            if(p2.y<-minEdge && h4mh0.z>0.) ao = min(ao, 1. - smoothstep(0., 1., (-p2.y - edge)/edge)*aoSh);
            if(p2.x<-minEdge && h4mh0.x>0.) ao = min(ao, 1. - smoothstep(0., 1., (-p2.x - edge2)/edge2)*aoSh);
            if(p2.x>minEdge && h4mh0.y>0.) ao = min(ao, 1. - smoothstep(0., 1., (p2.x - edge2)/edge2)*aoSh);
        }
        else {
            
            vec4 mEdge4 = vec4(minEdge) - (h4 - h0)/2.;
            vec4 hp = p.y - h4 - mEdge4;
            
            if(n.z<-.5 && hp.z<0.) ao = min(ao, 1. - smoothstep(0., 1., -(hp.z)/(mEdge4.z))*aoSh);
            if(n.z>.5  && hp.w<0.) ao = min(ao, 1. - smoothstep(0., 1., -(hp.w)/(mEdge4.w))*aoSh);
            if(n.x<-.5 && hp.x<0.) ao = min(ao, 1. - smoothstep(0., 1., -(hp.x)/(mEdge4.x))*aoSh);
            if(n.x>.5 && hp.y<0.) ao = min(ao, 1. - smoothstep(0., 1., -(hp.y)/(mEdge4.y))*aoSh);
             
        }
        ao = max(ao, 0.);
       
        
        //////////////////

        // Last minute edge routine. I've returned the nearest rectangle ID
        // and dimensions from the "raycasting" routine, and the rest 
        // figures itself out.
        vec2 ipJ = id;
        float ma = h0;
        vec2 w = (hash22(ipJ + .21)*.8 + .05)*s;
        p2 = (p.xz - id*s); // Local coordinates.
        float rct = abs(max(abs(p2.x) - w.x, abs(p2.y) - w.y));
        float topEdge = max(abs(p.y - ma), rct);
        float sideEdge = abs(abs(p2.x) - w.x);
        sideEdge = max(sideEdge, abs(abs(p2.y) - w.y));
        float objEdge = min(topEdge, sideEdge) - .006;

        // Rendering light and dark edges.
        //c.xyz = mix(c.xyz, vec3(0), 1. - smoothstep(0., 2./iResolution.y, length(p2) - .02));
        c.xyz = mix(c.xyz, c.xyz*1.5, 1. - smoothstep(0., 2./iResolution.y, objEdge - .006));
        c.xyz = mix(c.xyz, c.xyz/1.5/2., 1. - smoothstep(0., 2./iResolution.y, objEdge));

        ///////////////////// 
        
        // Applying diffuse lighting, ambient lighting, and attenuation.
        c.xyz = c.xyz*(dif*sh + vec3(1, .2, .1)*spe*sh*4. + vec3(.5, .7, 1).zyx*rim*1. + .25);
        
        // Applying ambient occlusion.
        c.xyz *= ao;
  
        // Reflections: It's based on one of IQ's nice looking reflective
        // pass shortcuts. Not quite as realistic as proper object and sky coloring,
        // but really effective for scenarios like these.
        vec3 ref = reflect(r, n);
        vec4 resRef = raycast(p + n*.001, ref, 64); // Note the fewer iterations.
        vec3 refTx = texture(iChannel3, ref).xyz; refTx *= refTx;
        if(resRef.x<FAR - 1e-3) refTx *= 0.;
        // Fresnel reflection.
        float fr = mix(.03, .25, pow(max(0., 1. + dot(r, n)), 3.));
        if(objID<.5) refTx *= 2.; // More reflection on the water.
        c.xyz = mix(c.xyz, refTx, fr);
        // Alternate reflections. Gives it a cartoonish look.
        //c.xyz += c.xyz*refTx*2.;  
        
    }
    
    // Applying horizon fog.
    c = mix(clamp(c, 0., 1.), vec4(.87, .95, .95, 0), smoothstep(0., .99, t*t/FAR/FAR));
    
    // Subtle vignette.
    u /= iResolution.xy;
    c *= pow(16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .0625);
    
    // Very subtle tone mapping, which can sometimes even things out.
    //c *= 1.1/(1. + c*.2);
    
    // Rough gamma correction. The short explanation is that that if you don't do
    // this, all your colors and shades will be wrong. :)
    c = vec4(sqrt(clamp(c.xyz, 0., 1.)), 1.);
    
    
}