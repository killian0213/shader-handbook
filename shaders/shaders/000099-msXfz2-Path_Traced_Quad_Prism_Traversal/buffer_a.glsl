// Buffer A (buffer) — Path Traced Quad Prism Traversal by Shane
// https://www.shadertoy.com/view/msXfz2

/*

    Path Traced Quad Prism Traversal
    --------------------------------
    
    This is a realtime path traced asymmetric quad prism grid traversal. I put
    it together as a fun exercise to see whether it was possible to produce a 
    passable looking globally illuminated scene with just a few samples. As with
    other examples, I've used IQ's temporal reprojection routine to give the 
    appearance of a higher sample count. I also wanted to post an offset quad
    cell by cell traversal to Shadertoy.
    
    Since this is realtime path tracing, things aren't going to be perfect on an
    average system -- and apologies in advance for those with slower systems. A 
    basic static path traced scene normally takes seconds to minutes to produce in 
    a fast application like Blender, but realtime requirements only allow for a 
    fraction of a second per frame, so perfect quality is a big ask.
    
    Asymmetric grid cell traversals are not common at all, but there are some
    pretty clever people on here, so they do exist on Shadertoy. There are a few 
    Voronoi traversals, and Fizzer put together a really cool asymmetric triangle 
    example that I'll link to below. I'm pretty sure I haven't come across a quad 
    version before, and I'm definitely sure there are no path traced ones.
    
    The obvious advantage to a path traced approach is the pretty lighting. The
    downside is debilitating your GPU with multiple passes. I attempted to speed 
    up this particular scene by traversing a precalculated texture. If you peruse 
    the code, you'll see that it's not exactly user friendly. Unfortunately, some 
    plane tilings are too complicated to produce in realtime, let alone path 
    trace, so precalculation is the only way to do it on current hardware.
    
  
    
    
    Other examples:
    
    // An offset triangle prism traversal. Fizzer was able to put his 
    // example together almost instantly. I did not finish mine instantly. :D
    Irregular Trianglular Prisms - fizzer
    https://www.shadertoy.com/view/wtjfDt
    
    // Path tracing a heap of boxes in realtime with the help of camera
    // reprojection -- It's one of IQ's many understated examples that 
    // does something amazing.
    Some boxes - iq
    https://www.shadertoy.com/view/Xd2fzR


*/



// Unfortunately, if you have a slow machine IQ's temporal reprojection option
// will usually result in blur. Regular accumulation might work, but you'll 
// probably have to use straight samples (BUFF_ACCUM 0).
// Buffer accumulation style:
// 0: No accumulation -- Noisy, sharper picture, but with no blur. 
// 1: Regular accumulation with no reprojection -- A mixture.
// 2: Temporal reprojection. -- Smoother for faster machines.
#define BUFF_ACCUM 2


// Far plane. I've kept it close.
#define FAR 25.


///////////////

// Random seed value.
vec2 seed = vec2(.143, .217);

 
// A slight variation on a function from Nimitz's hash collection, here: 
// Quality hashes collection WebGL2 - https://www.shadertoy.com/view/Xt3cDn
vec2 hash22(){

    // I should probably use a "uvec2" seed, but I hacked this from an old
    // example. I'll update it later.
    seed = fract(seed + vec2(.7123, .6457));
    uvec2 p = floatBitsToUint(seed);
    
    // Modified from: iq's "Integer Hash - III" (https://www.shadertoy.com/view/4tXyWN)
    // Faster than "full" xxHash and good quality.
    p = 1103515245U*((p>>1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    uint n = h32^(h32>>16);

    uvec2 rz = uvec2(n, n*48271U);
    // Standard uvec2 to vec2 conversion with wrapping and normalizing.
    return vec2((rz>>1)&uvec2(0x7fffffffU))/float(0x7fffffff);
}


 

 
// A nice random hemispherical routine taken out of one of IQ's examples.
// The routine itself was written by Fizzer.
vec3 cosDir( in float seed, in vec3 n){

    vec2 rnd = hash22();
    float u = rnd.x;
    float v = rnd.y;
    
    // Method 1 and 2 first generate a frame of reference to use with an arbitrary
    // distribution, cosine in this case. Method 3 (invented by fizzer) specializes 
    // the whole math to the cosine distribution and simplfies the result to a more 
    // compact version that does not depend on a full frame of reference.

    // Method by fizzer: http://www.amietia.com/lambertnotangent.html
    float a = 6.2831853*v;
    u = 2.*u - 1.;
    return normalize(n + vec3(sqrt(1. - u*u)*vec2(cos(a), sin(a)), u));
    
}



// The following is based on John Hable's Uncharted 2 tone mapping, which
// I feel does a really good job at toning down the high color frequencies
// whilst leaving the essence of the gamma corrected linear image intact.
//
// To arrive at this non-tweakable overly simplified formula, I've plugged
// in the most basic settings that work with scenes like this, then cut things
// right back. Anyway, if you want to read about the extended formula, here
// it is.
//
// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/
// A nice rounded article to read. 
// https://64.github.io/tonemapping/#uncharted-2
vec4 uTone(vec4 x){
    return ((x*(x*.6 + .1) + .004)/(x*(x*.6 + 1.)  + .06) - .0667)*1.933526;    
}


////////////////


// Ray origin, ray direction, point on the line, normal. 
float rayLine(vec2 ro, vec2 rd, vec2 p, vec2 n){
   
   // This it trimmed down, and can be trimmed down more. Note that 
   // "1./dot(rd, n)" can be precalculated outside the loop. However,
   // this isn't a GPU intensive example, so it doesn't matter here.
   //return dot(p - ro, n)/dot(rd, n);
   float dn = dot(rd, n);
   return dn>0.? dot(p - ro, n)/dn : 1e8;   

}

// Height function.
float h(vec2 p){

    //float f = dot(sin(p*.75 - cos(p.yx)*1.5), vec2(.25)) + .5;
    //return f*3. + hash21(p)*1.;
    
    // Keeping things cheap and simple with only one texture read.
    float h = texture(iChannel0, p/64.).x;
    //h = mix(h - .1, h, smoothstep(.8, .9, sin(h*6.2831853 + iTime)));
    return h*5.;
}

vec2 getUV(vec2 p){

    // Cube map texture coordinate conversion.
    p *= cubemapRes;
    return fract((floor(p) + .5)/cubemapRes) - .5;
    
}

// Rectangle scale: This was hacked in at the last minute and is a little
// fickle. Sizes one to about 8 are OK. Lower numbers mean smaller rectangles,
// which require more traversal steps in the "raycast" function.
const vec2 txSc = vec2(4);

// Grid offset.
mat4x2 gV;

// Grid cell function.
vec4 gridID(vec2 p){

    // Same size squares, for comparison. 
    //return vec4(floor(p/txSc) + .5, txSc);

    // Texture multiple ID.
    vec2 p0 = (floor(p/txSc)*txSc.xy);

    // Texture grid information -- Cube map faces are annoying to read into.
    vec2 uv = getUV(p/txSc);
    
    // Read the texture face information.
    vec4 hm2 = texture(iChannel3, vec3(-.5, uv.yx)); 
    // Converting to exact pixel positions for wrapping purposes.
    hm2.xy = convert2(hm2).xy*txSc.xy;
    //hm2.zw = convert2(hm2).zw*txSc.xy;

    
    // Read in and encode the vertex information.
    vec4 v4A = EncodeFloatRGBA(hm2.z);
    vec4 v4B = EncodeFloatRGBA(hm2.w);
    mat4x2 sv = mat4x2(v4A, v4B);
    
    // Recreate the quad vertices.
    gV = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5)); 
    gV += ((sv/float(ni))*2. - 1.)*.25;
    // Scale.
    //gV[0] *= s*txSc; gV[1] *= s*txSc; gV[2] *= s*txSc; gV[3] *= s*txSc;
    gV *= s.x*txSc.x; // Only works for square dimensions, which is the case here.
    
    // Return the central position and dimension of the nearest quad.
    return vec4((p0 + hm2.xy), hm2.zw);

}



// Sign function without the zero, which can cause problems for some routines.
vec3 sign2(in vec3 p){ return vec3(p.x<0.? -1 : 1, p.y<0.? -1 : 1,  p.z<0.? -1 : 1); }
//vec2 sign2(in vec2 p){ return vec2(p.x<0.? -1 : 1, p.y<0.? -1 : 1); }

vec4 gGrid;
vec3 gN = vec3(0);
// A standard square cell by cell traversal. Not optimized enough for path tracing
// purposes, but it's reasonable quick otherwise.
vec4 raycast(vec3 ro, vec3 rd){
 
    // Initializing to far.
    vec4 res = vec4(FAR);
    
    
    vec3 srd = sign2(rd);
    
   
    // Initiate the ray position at the ray origin.
    vec3 pos = ro;
    
    // Obtain the coordinates of the cell that the current ray position 
    // is contained in -- I've arranged for the cell coordinates to 
    // represent the cell center to make things easier.
    //
    // I found the following fudge in an old example of mine, and it gets rid 
    // of banding. It took ages to realize what I was thinking at the time. My 
    // notes mention stepping forward by a pixel (or scaled pixels) to the next 
    // cell. If you don't, your reflected rays, shadow rays, etc, risk counting
    // the initial cell again -- This is the equivalent of a self-collision,
    // which results in banded shadows, etc... Another explanation is, just make 
    // sure you do it. :D
    vec4 ip4 = gridID(pos.xz + srd.xz*txSc/1024.);
    vec2 ip = ip4.xy;
    gGrid = ip4;
    
    // Set all distances to the maximum.
    float t1 = 1e8, t2 = 1e8, t3 = 1e8, t4 = 1e8, tT = 1e8;
    
    // Clockwise edge direction vectors -- Used for jumping from cell to cell.
    vec2 nn1 = vec2(-1, 0), nn2 = vec2(0, 1), nn3 = vec2(1, 0), nn4 = vec2(0, -1);
    // Offset edge normal vectors.
    vec2 n1, n2, n3, n4;
  
    
    vec3 tn;
    
    int hit = 0;
    
    
    // Iterate through the cells -- Obviously, if the cells were smaller,
    // you'd need more to cover the distance.
    for(int i = 0; i<32; i++){ 

         
        // Height. 
        ip = ip4.xy;
        float ma = h(ip);
        
         
        // At this point, we haven't advanced the ray to the back of the cell boundary,
        // so we're at one of the front cell face positions. Therefore, check to see if 
        // we're under the pylon height. If so, we've hit a face, so mark the face as hit, 
        // then break.
        if(pos.y<ma){
            // Hit a side.
            hit = 1;
            break; 
        
        } 
        

 
        // Edge normal calculation: You could precalculate these, but for some reason, 
        // it's faster on my machine to recalculate them in situ... No idea why, but 
        // probably special GPU cache reasons. :)
        n1 = normalize((gV[1] - gV[0]).yx*vec2(1, -1));  
        n2 = normalize((gV[2] - gV[1]).yx*vec2(1, -1));
        n3 = normalize((gV[3] - gV[2]).yx*vec2(1, -1)); 
        n4 = normalize((gV[0] - gV[3]).yx*vec2(1, -1)); 
      

       
        // Ray intersection from the currect cell position to each of the 
        // visible cell walls. Normals face inward.
        // You pass in the current position, the unit direction ray, a known 
        // point on the cell wall (any will do) and the cell wall's normal.
        t1 = rayLine(pos.xz, rd.xz, (ip) + gV[0], -n1);
        t2 = rayLine(pos.xz, rd.xz, (ip) + gV[1], -n2);
        t3 = rayLine(pos.xz, rd.xz, (ip) + gV[2], -n3);
        t4 = rayLine(pos.xz, rd.xz, (ip) + gV[3], -n4); 
        
        // Determine the closest edge then record the closest distance and
        // asign its normal index.         
        tn = t1<t2 && t1<t3? vec3(t1, -nn1) : t2<t3? vec3(t2, -nn2) : vec3(t3, -nn3);
        if(t4<tn.x) tn = vec3(t4, -nn4); 
        
        //tn.x = min(min(t1, t2), min(t3, t4));
         
         
        
        
        // Top face distance.
        tT = (ma - pos.y)/rd.y;
        tT = tT>0.? tT : 1e8;
        
        
        // We've now advanced to one of the back faces of the cell. Check to see whether
        // we're still under the pylon height, and if so, we've hit the top face --  
        // I always have to think about this, but the logic is that we haven't hit a front
        // cell face and we're still under the height, so we've hit the top. Anyway, mark 
        // the top face as hit, advance the distance in the Y direction to the top face, 
        // then break.
        if(tT<tn.x){
            gN = vec3(0, 1, 0);
            //dist += tT;
            pos += rd*tT; 
            hit = 2;
            break;
             
        }       
   
        
        // Advance the cell index position by the indices of the 
        // cell wall normal that you hit. 
        //ip += tn.yz;
        // Advance the ray position by the distance to the next cell wall.
        pos += rd*tn.x;
        
        // Textures have fixed size, so increasing the scale affects stepping from
        // one grid cell to the next. Hence, the "txSc" variable.
        ip4 = gridID((ip -  tn.yz*(txSc*s)));
         
        gGrid = ip4;
    }
    
    // If we've hit one of the prism sides, return the correct side normal.
    if(hit==1){
    
        tn = t1<t2? vec3(t1, n1) : vec3(t2, n2);
        if(t3<tn.x) tn = vec3(t3, n3);
        if(t4<tn.x) tn = vec3(t4, n4);
        gN = normalize(vec3(tn.y, 0, tn.z));
        
    }
  
    
    // Face ID.
    float fID = tT<t1 && tT<t2 && tT<t3 && tT<t4? 0. : 
    t1<t2 && t1<t3 && t1<t4? 1. : t2<t3 && t2<t4? 2. : t3<t4? 3. : 4.;
    
    
    // Distance.
    res.x = length(pos - ro);
    // If we haven't hit anything, set it to the maxium ray distance.
    if(hit == 0) res.x = FAR;
    
    // Return the distance, face ID, and central position based ID.
    return vec4(res.x, fID, ip);
    
}

// Standard normal function.
vec3 nr(float fID, vec3 rd) {

    return gN;
/*
    if(fID==0.) return vec3(0, 1, 0);
    vec2 n1, n2, n3, n4;
    n1 = (gV[1] - gV[0]);
    n2 = (gV[2] - gV[1]);
    n3 = (gV[3] - gV[2]);
    n4 = (gV[0] - gV[3]);
 
    vec2 n = fID == 1.? n1 : n2;
    if(fID==3.) n = n3;
    if(fID==4.) n = n4;
 
    // Tangent to normal conversion.
    n = n.yx*vec2(1, -1);
	return normalize(vec3(n.x, 0, n.y));*/
}

// mat3 rotation... I did this in a hurry, but I think it's right. :)
// I have a much better one than this somewhere. 
mat3 rot(vec3 ang){
    
    vec3 c = cos(ang), s = sin(ang);

    return mat3(c.x*c.z - s.x*s.y*s.z, -s.x*c.y, -c.x*s.z - s.x*s.y*c.z,
                c.x*s.y*s.z + s.x*c.z, c.x*c.y, c.x*s.y*c.z - s.x*s.z,
                c.y*s.z, -s.y, c.y*c.z);    
}

void mainImage(out vec4 fragColor, vec2 fragCoord){



    #if BUFF_ACCUM == 2
    // Initial hit point and distance.
    vec3 resPos = vec3(0);
    #endif
    float resT = 0.;

    // Screen pixel coordinates.
    vec2 uv0 = (fragCoord - iResolution.xy*.5)/iResolution.y;
    

    // Initializing the seed value. It needs to be different every frame.
    seed = uv0 + vec2(fract(iTime/113.671)*.123, fract(iTime/57.913)*.14527);
    
    // Ray origin.
    vec3 ro = vec3(iTime*.2, 8., iTime*.2); 
    // Setting the camera to the ray origin. The ray origin vector will change
    // from bounce to bounce, so we'll need a record of the initial camera position.
    vec3 cam = ro;
    
    
    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.; // FOV - Field of view.
    
    // Lazy identity camera -- No to and from. I might update it later.
    mat3 mCam = mat3(vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1));

 
    mCam *= rot(vec3(0, 0, cos(iTime/8.*.25)/4. + .35)); // Camera yaw.
    mCam *= rot(vec3(-sin(iTime/4.*.25)/8., 0, 0)); // Camera roll.
    mCam *= rot(vec3(0, 1, 0)); // Y axis tilt, or pitch.
    
     
    // Artistic black movie strips. 15% faster "1337" democoder move. :D
    if(abs(uv0.y)>.425) { 
        ivec2 q = ivec2(fragCoord);
        vec4 c = vec4(0, 0, 0, 1); 
    	if(q.y == 0 && q.x<3){
    
    	// Camera matrix in lower left three pixels, for next frame.
        if(q.x == 0) c = vec4(mCam[0], -dot(mCam[0], cam));
        else if(q.x == 1) c = vec4( mCam[1], -dot(mCam[1], cam));
        else c = vec4( mCam[2], -dot(mCam[2], cam));
        } 
        fragColor = c;
        return; 
    }
 
    
    // Accumulative color and sample number.  Some computers would be able to 
    // handle more and others less.
    vec3 atot = vec3(0);
    const int sampNum = 3;
    
    for(int j = min(0, iFrame); j<sampNum; j++){
    
    
        //vec2 jit = vec2(hash21(uv0 + seed + vec2(j, j + 1)), 
        //                hash21(uv0 - seed + vec2(j + 5, j + 7))) - .5;
        
        // Jittering for antialiasing.
        vec2 jit = hash22() - .5;
                        
        vec2 uv = uv0 + jit/iResolution.y;
    
        // Unit direction vector.
        vec3 rd = mCam*normalize(vec3(uv, 1./FOV)); 
        
        /*      
        // Depth of field. I hacked this in as an afterthought... It seems
        // about right, but I'll have to take a closer look later.
        float fDist = 6.;
        vec2 jitDOF = hash22()*2. - 1.;
        vec3 vDOF = mCam*vec3(jitDOF, 0.)*.06;
        rd = normalize(rd - vDOF/fDist);
        ro = cam + vDOF;
        */        

        ro = cam;
        
        // Accumulative, and thoughput.
        vec3 acc = vec3(0);
        
        // Throughput -- Initialized to one.
        vec3 through = vec3(1);

        // First hit distance. It's used for fog, amongst other things.
        float t0; 
        
  
        for(int i = min(0, iFrame); i<2; i++){

            // Raycasting
            vec4 res = raycast(ro, rd);

            // Distance, face ID and central position based ID.
            float t = res.x;
            float fID = res.y;
            vec2 id = res.zw;
            
            // Saving the face normal and vertices.
            vec3 svN = gN;
            mat4x2 svV = gV; 
            
           
            t = min(t, FAR); // Clipping to the far distance, which helps avoid artifacts.

            if(i == 0) t0 = t; // Recording the first hit distance.


            // Hit point.
            vec3 p = ro + rd*t;
            
            if(i==0){
                #if BUFF_ACCUM == 2
                // Only save the initial hit point and distance. Ignore other bounces.
                resPos += p/float(sampNum); // Accumulative position.
                #endif
                resT += t/float(sampNum); // Accumulative distance.
            }
            
    
            // If we've hit an object, light it up.
            if(t<FAR){
            
                
                // Surface normal.
                 
                vec3 n = nr(fID, rd);//normalize(svN);//
                 
                // Scene object color.

                vec2 qq = p.xz - id;
                // Edging routine.
                float h0 = h(id); // Square prism height.

                
                 // Local coordinates.
                vec2 lc = p.xz - id*s;
                
                // Texture coordinates.
                vec2 rp = lc*rot2(atan(n.x, n.z));
                vec2 tuv = fID == 0.? p.xz : vec2(rp.x, p.y);
                vec3 tx = texture(iChannel1, tuv/2.).xyz; tx *= tx;
       
                vec3 oCol = .125 + tx*2.5;
                oCol *= vec3(.6, .8, 1.1)/4.;
            
                // Edge construction.
              
                
                // Face edges.
                /////
                float fEdge = sdQuadBound(qq, svV);
                fEdge = max(abs(fEdge), -(p.y - h0)) - .02;
                // Side edges.
                /////
                float sEdge = 1e5;
                for(int j = 0; j<4; j++){
                    // Current vertex.
                    vec2 g = svV[j];
                    float ang = atan(g.y, g.x);
                    // Polar transform to the corner.
                    vec2 nP = qq - vec2(cos(ang), sin(ang))*length(g);
                    // Corner edge.
                    sEdge = min(sEdge, length(nP) - .02);
                    
                    /* 
                    // Corner dots.
                    vec2 tn0 = normalize(svV[j] - svV[(j + 3)&3]);
                    vec2 tn1 = normalize(svV[j] - svV[(j + 1)&3]);
                    nP = qq - svV[j] + (tn0 + tn1)*.11;                    
                    sEdge = min(sEdge, length(nP) - .035);
                    */
                }
                /////////////
                
                
           
                // Smoothing facor... Not even sure if it's needed in a multisample
                // example, but it's here anyway.
                float sf = .02;//*(1. + res.x*res.x*.05);
                
                // Combining the side and face edges, then smoothstepping.
                fEdge = min(fEdge, sEdge);
                
                // Lighter inner edges.
                oCol = mix(oCol, oCol*3., (1. - smoothstep(0., sf, fEdge - .02)));
 
                // Surface roughness. Larger values are duller in appearance, and lower
                // values are more relective.
                float rough = .9;

                // Substance emissive color. Initialized to zero.
                vec3 emissive = vec3(0);
               
                // Color random prisms and set their emission color. 
                if(hash21(id + .103)<.1){
                //if(hash21(id + .103)<.2 && abs(p.y - h0 + .4) < .1){ // Strips only.
                    
                
                    // Random emitter color.
                    vec3 eCol = .5 + .45*cos(6.2831853*hash21(id +.17)/24. + 
                                vec3(0, 1.4, 2) + 1.);
                  
                    // Color variations.
                    // Random alternate hues.
                    //if(hash21(id + .027)<.25) eCol = mix(eCol, eCol.yzx, .25); 
                    // Height or screen height based color mixing.
                    //eCol = mix(eCol.xzy, eCol, smoothstep(0., 2., p.y*.7)*.4 + .6);
                    //eCol = mix(eCol, eCol.zyx, smoothstep(0., 1., uv0.y + .15));
                    
                    // Ramping it up.
                    eCol *= eCol*4.;  
                    
                    
                    // Randomly turn lights on and off for some visual interest.
                    float blink = smoothstep(-.6, -.4, sin(hash21(id + .2)*6.2831853 + iTime));
                    
                    
                   
                    // Apply the edges.
                    vec3 edCol = mix(eCol/32., vec3(0), blink);
                    //oCol = mix(vec3(gre), oCol, blink);
                    //oCol = mix(oCol, edCol, (1. - smoothstep(0., sf, fEdge))*.9);
                    
                    // Apply the edges.                    
                    oCol = mix(oCol, edCol, (1. - smoothstep(0., sf, fEdge)));
                    
                    // Blinking emissive color -- ramped up to really glow.
                    emissive = oCol*eCol*mix(1., 0., blink)*48.; // Fiery hues.
                    
                    // Make the glowing pylons less rough, and randomize a bit.
                    rough = mix(.5, rough, blink); //hash21(id + .21)*.5 + .25;
                    
                }
                else {
                
                    // Subtly Color the other pylons.
                    oCol *= .9 + .2*hash21(id + .06);
                    
                     // Apply the edges.
                    oCol = mix(oCol, vec3(0), (1. - smoothstep(0., sf, fEdge)));

                }
            
                // Applying the edging to the emission value. You don't have to, 
                // but it looks better. 
                //emissive = mix(emissive, vec3(0), (1. - fEdge)*.5);
 
                // Tapering emission into the distance.
                //emissive = mix(emissive, vec4(0), smoothstep(.25, .99, t0/FAR));

                // If an emissive sustance has been hit, use it to light the surface.
                acc += emissive*through;
                through *= oCol; // Integrate colors from previous surfaces. 
 
              
                vec3 ref = reflect(rd, n); // Purely reflected vector.
                vec3 rrd = cosDir(0., n); // Random half hemisphere vector.
 
                // Mimicking surface inconsistancies with fuzzy reflections.
                // Rougher surfaces have a greater chance of random reflecting at any 
                // direction and smoother surfaces are more likely to purely reflect.
                float rChance = step(0., rough - hash21(uv + vec2(i*277, j*113) + 
                                fract(iTime*.97 + .137)));
                rd = (mix(ref, rrd, rChance));
                // Other variations. Not physically correct, but they have their purposes.
                //float rChance = hash21(uv + vec2(i*277, j*113) + 
                //                  fract(iTime*.97 + .137))*rough;
                //rd = normalize(ref + rrd*rChance);
                //rd = normalize(mix(ref, rrd, rough));
                //rd = normalize(ref + normalize(rnd23() - .5)*rChance);  
                //rd = normalize(ref + rrd*rough*4.);

                // Bump the ray off of the hit surface to avoid self collision.
                ro = p + n*.001;

            }
            else { 
                // If the scene hasn't been hit, add a touch of atmospheric haze, then quit.
                vec3 aCol = .2 + vec3(.03, .025, .035)*5.;//tx*.2;//vec3(.1);
                acc += aCol*through/2.;//*.05; 
                
                break;
            }

    
        }
       
        // Very simple sky fog, or whatever. Not really the way you apply atmosphere 
        // in a path tracer, but way, way cheaper. :)
        //vec3 sky = mix(vec3(1, .7, .5), vec3(.4, .6, 1), uv0.y*2.5 - .15);
        //acc = mix(acc, sky/4., smoothstep(.35, .99, t0/FAR));
        
        
        // Add this sample to the running total.
        atot += acc;
        
    }
    
    // Average the samples.
    vec3 col = atot/float(sampNum);
    
    
    
    // Toning down the high frequency values. A simple Reinhard toner would 
    // get the job done, but I've dropped in a heavily modified and trimmed 
    // down Uncharted 2 tone mapping formula.
    col = uTone(col.xyzx).xyz;
   
    
    // This is IQ's temporal reprojection code: It's well written and
    // it makes sense. I wrote some 2D reprojection code and was not
    // looking forward to writing the 3D version, and then this 
    // suddenly appeared on Shadertoy. If you're interested in rigid 
    // realtime path traced scenes with slowly moving cameras, this is 
    // much appreciated. :)
    //
    #if BUFF_ACCUM == 2
    //-----------------------------------------------
	// Reproject to previous frame and pull history.
    //-----------------------------------------------
    
    float kFocLen = 1./FOV;
    vec3 pos = resPos;
    ivec2 q = ivec2(fragCoord);
    col = clamp(col, 0., 1.);

    // Fetch previous camera matrix from the bottom left three pixels.
    mat3x4 oldCam = mat3x4(texelFetch(iChannel2, ivec2(0, 0), 0),
                           texelFetch(iChannel2, ivec2(1, 0), 0),
                           texelFetch(iChannel2, ivec2(2, 0), 0));
    // World space point.
    vec4 wpos = vec4(pos, 1.);
    // Convert to camera space (note inverse multiply).
    vec3 cpos = wpos*oldCam;
    // Convert to NDC space (project).
    vec2 npos = (kFocLen*2.)*cpos.xy/cpos.z;//*iRes/iResolution.y;
    // Convert to screen space.
    vec2 spos = .5 + .5*npos*vec2(iResolution.y/iResolution.x, 1);
	// Convert to raster space.
    vec2 rpos = spos*iResolution.xy;

    // Read color+depth from this point's previous screen location.
    vec4 ocolt = textureLod( iChannel2, spos, 0.);
    // If we consider the data contains the history for this point.
    if(iFrame>0 && resT<FAR && (rpos.y>1.5 ||rpos.x>3.5)){
    
        // Blend with history (it's an IIR low pas filter really).
        col = mix( ocolt.xyz, col, 1./12.);
    }
    
    // Color and depth.
    fragColor = vec4(col, resT);
    
    // Output.
	if(q.y == 0 && q.x<3){
    
    	// Camera matrix in lower left three pixels, for next frame.
        if(q.x == 0) fragColor = vec4(mCam[0], -dot(mCam[0], cam));
        else if(q.x == 1) fragColor = vec4( mCam[1], -dot(mCam[1], cam));
        else fragColor = vec4( mCam[2], -dot(mCam[2], cam));
    } 
    #elif BUFF_ACCUM == 1
    // Mix the previous frames in with no camera reprojection.
    // It's OK, but full temporal blur will be experienced.
    vec4 preCol = texelFetch(iChannel2, ivec2(fragCoord), 0);
    float blend = (iFrame < 2) ? 1. : 1./4.; 
    fragColor = mix(preCol, vec4(clamp(col, 0., 1.), 1), blend);
    #else
    // No reprojection or temporal blur, for comparisson.
    fragColor = vec4(clamp(col, 0., 1.), 1);
    #endif
    

    
}