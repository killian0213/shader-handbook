// Image (image) — Offset Stochastic Tiling by Shane
// https://www.shadertoy.com/view/w3V3Dh

/*

    Offset Stochastic Tiling
    ------------------------
    
    A while ago, I put together a stochastic rectangle tiling. At the 
    time, there were very few tiling options on Shadertoy, and I wanted
    a cheap random looking rectangle pattern to use on walls, and so 
    forth. Not long afterward, I coded up the asymmetric quad version,
    but couldn't think of an interesting way to present it. In fact, I
    still haven't, but here it is anyway. :)
    
    The construction is similar to the way in which you'd put together a
    regular quasi-random packed rectangle pattern, but with sloped 
    non-perpendicular lines instead of the usual horizontal and vertical
    ones. It is almost trivial to determine the intersection vertex points
    for vertical and horizontal border lines. Sloped lines require more
    work to construct and intersect, but is conceptually the same.
    
    The code works just fine, but there's a lot of it. The stochastic 
    pattern itself is more involved than its perpendicular-edge 
    counterpart, but is only partly responsible for the blowout. A lot of 
    that is window dressing that I accumulated over time. For whatever 
    reason, I wanted to provide a regular quad pattern for comparison, 
    then I decided that I wanted to provide subdivision  options, etc., 
    and before I knew it... Way too many characters. :)
    
    Anyway, there are some "define" options below for anyone interested.
    I'll post a couple of more interesting scenes at a later date.
    
    
    Based on:
    
    // Here's a much cleaner version... The code here also
    // requires work, but is a lot easier to consume.
    Stochastic Asymmetric Quads -- Shane
    https://www.shadertoy.com/view/wfKyRh
    
*/


// Pattern type -- Offset Asymmetric Quad: 0, 
//                 Asymmetric Quad (for comparisson): 1.
#define PATTERN_TYPE 0

// Subdivision type: I put this in as an afterthought. The code 
// works fine, but is in need of reorganization.
// No subdivision: 0, Random Quadtree: 1, Triangles: 2.
#define SUBDIV 0 

// Hacky border vertices. There's a more exact way to do this, but
// it's expensive... It's kind of interesting, but not on by default.
//#define SHOW_VERTICES


// Global pattern scale.
const vec2 gSc = vec2(1, 1)/6.;



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


  
// Grid square vertex and mid edge ID.
const mat4x2 vID = mat4x2(vec2(-.5), vec2(-.5, .5), vec2(.5), vec2(.5, -.5));
const mat4x2 eID = mat4x2(vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));

// Vertex and edge points.
const mat4x2 v = mat4x2(vec2(-.5)*gSc, vec2(-.5, .5)*gSc, 
                        vec2(.5)*gSc, vec2(.5, -.5)*gSc);
const mat4x2 e = mat4x2(vec2(-.5, 0)*gSc, vec2(0, .5)*gSc, 
                        vec2(.5, 0)*gSc, vec2(0, -.5)*gSc);

// Vertex and border values.
float vert;
float bord;


mat4x2 vP; // Quad or triangle points.
vec2 gP;   // Local coordinates.

// Polygon vertex ID, and triangle ID.
int pID = 0;
int triID = 0;

// Quadrant and triangle IDs. I'm not really using them, but
// it can be handy to know which triangle and quadrant we're in.
int quadrant = 0; 


#if PATTERN_TYPE == 0
// THE OFFSET ASYMMETRIC (STOCHASTIC) PATTERN. 

// Grid Offset point.
vec2 getOffs(vec2 offs, vec2 ip, vec2 e){
    return (offs + e*hash21B(ip + offs))*gSc;
}
 
vec4 distField(vec2 p){

    // The 8 end points of the 4 lines that surround the
    // nearest quad. The idea is to determine these 8 points,
    // then use them to calculate the four intersection points.
    // Those will be the four nearest quad vertices. The code
    // below looks involved, but it just some simple geometry
    // bookkeeping.
    vec2[8] eP;
    
    // Square grid ID and local coordinates.
    vec2 ip = floor(p/gSc) + .5;
    p -= (ip)*gSc;
    
    
    // Alternate checker value.
    int check = mod(ip.x + ip.y, 2.)==0.? 1 : 0;
    
    // Initialize the ID t0 the central square position.
    vec2 id = ip;
    
    //float minSc = min(gSc.x, gSc.y);
    
    //float d = sBox(p, gSc/2.);
    
    vert = 1e5;
    
    
    // Offset vertices.
    vec2 e0 = vec2(0, 1);
    mat4x2 vOffs, vOffs2; // Neigbor offset, and neighbor one deeper
    for(int i = min(0, iFrame); i<4; i++){
    
        vOffs[i] = getOffs(eID[i], ip, e0);
        vOffs2[i] = getOffs(eID[i]*3., ip, e0);
        e0 = e0.yx;
    }

    
    // Divding lines.
    vec4 ln = vec4(1e5); 
    
    
    // Determine whether we're calculating the horizontal dominated
    // tile or the vertical one. There are obviously some patterns 
    // to exploit below, which should result in some code reduction,
    // so I'll try to do that later.
    if(check==1){
        
        // Horizontal tile.
        
        ln[0] = distLineS(p, vOffs[2], vOffs[0]); // Left to right.
         
        
        if(ln[0]<0.){
            
            // Top to horizontal line intersection.
    
            ln[1] = distLineS(p, vOffs2[1], vOffs[1]); // Neighbor up.
            
            // Horizontal.
            eP[6] = vOffs[2]; eP[7] = vOffs[0];
            
            if(ln[1]<0.){ // Top left. (Horizontal).
            
                eP[4] = vOffs2[1]; eP[5] = vOffs[1];
                
                id += vID[1];
                
                // Left line: Left neighbor, top and bottom.
                vec2 pT = getOffs(eID[0]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[0]*2. + eID[3], ip, e0.yx);
                 
                // Top line: Top Left neighbor, left and right.
                vec2 pL = getOffs(eID[0]*2. + eID[1]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[0]*2. + eID[1]*2. + eID[2], ip, e0);
                 
                eP[0] = pB; eP[1] = pT;
                eP[2] = pL; eP[3] = pR;
                
                quadrant = 1;
                    
            }
            else { // Top right. (Horizontal).
            
                eP[0] = vOffs[1]; eP[1] = vOffs2[1];
                
                id += vID[2];
            
                 
                // Right line: Right neighbor, top and bottom.
                vec2 pT = getOffs(eID[2]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[2]*2. + eID[3], ip, e0.yx);
                 
                // Top line: Top right neighbor, left and right.
                vec2 pL = getOffs(eID[2]*2. + eID[1]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[2]*2. + eID[1]*2. + eID[2], ip, e0);
                 
                eP[4] = pT; eP[5] = pB;
                eP[2] = pL; eP[3] = pR;
                
                quadrant = 2;
                     
            }
        }
        else {
            
            // Bottom to horizontal line intersection.
             
            eP[6] = vOffs[0]; eP[7] = vOffs[2];
 
            ln[1] = distLineS(p, vOffs[3], vOffs2[3]); /// Neighbor down.
                
            if(ln[1]<0.){ // Bottom left. (Horizontal).
            
                eP[0] = vOffs[3]; eP[1] = vOffs2[3];
                
                id += vID[0];
          
                  
                // Left line: Left neighbor, top and bottom.
                vec2 pT = getOffs(eID[0]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[0]*2. + eID[3], ip, e0.yx);
                  
                // Bottom line: Bottom left neighbor, left and right.
                vec2 pL = getOffs(eID[0]*2. + eID[3]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[0]*2. + eID[3]*2. + eID[2], ip, e0);
                 
                eP[4] = pB; eP[5] = pT;
                eP[2] = pR; eP[3] = pL;
                
                quadrant = 0;

            }
            else { // Bottom right. (Horizontal).
            
                eP[4] = vOffs2[3]; eP[5] = vOffs[3];
                
                id += vID[3];
           
                  
                // Right line: Right neighbor, top and bottom.
                vec2 pT = getOffs(eID[2]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[2]*2. + eID[3], ip, e0.yx);
                 
                // Bottom line: Bottom right neighbor, left and right.
                vec2 pL = getOffs(eID[2]*2. + eID[3]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[2]*2. + eID[3]*2. + eID[2], ip, e0);
                 
                eP[0] = pT; eP[1] = pB;
                eP[2] = pR; eP[3] = pL;
                
                quadrant = 3;


            }
        
        }
        
        // Horizontal needs to be rotated clockwise two spots.
      
        
    
    }
    
    if(check==0){
    
    
        // Vertical tile.
    
        ln[0] = distLineS(p, vOffs[1], vOffs[3]); // Top to bottom.
        
        if(ln[0]<0.){
        
            eP[0] = vOffs[1]; eP[1] = vOffs[3];
        
            // Left to vertical line intersection.
  
            ln[1] = distLineS(p, vOffs2[0], vOffs[0]); // Neighbor up.
              
            if(ln[1]<0.){  // Bottom left. (Vertical).
            
                eP[6] = vOffs2[0]; eP[7] = vOffs[0];
               
                id += vID[0];
           
                
                 // Left line: Bottom left neighbor, top and bottom.
                vec2 pT = getOffs(eID[0]*2. + eID[3]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[0]*2. + eID[3]*2. + eID[3], ip, e0.yx);
                 
                // Top line: Bottom neighbor, left and right.
                vec2 pL = getOffs(eID[3]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[3]*2. + eID[2], ip, e0);
                 
                eP[4] = pB; eP[5] = pT;
                eP[2] = pR; eP[3] = pL;
                
                quadrant = 0;
                       
            }
            else {  // Top left. (Vertical).
            
                eP[2] = vOffs[0]; eP[3] = vOffs2[0];
                
                id += vID[1];
                
                // Left line: Top left neighbor, top and bottom.
                vec2 pT = getOffs(eID[0]*2. + eID[1]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[0]*2. + eID[1]*2. + eID[3], ip, e0.yx);
                
                // Top line: Top neighbor, left and right.
                vec2 pL = getOffs(eID[1]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[1]*2. + eID[2], ip, e0);
                
                eP[4] = pB; eP[5] = pT;
                eP[6] = pL; eP[7] = pR;
                
                quadrant = 1;
            }
        }
        else {
        
            // Right to vertical line intersection.
 
       
            ln[1] = distLineS(p, vOffs[2], vOffs2[2]); /// Neighbor down.
            
            
            eP[0] = vOffs[3]; eP[1] = vOffs[1];
             
            if(ln[1]<0.){  // Bottom right. (Vertical).
                
                eP[2] = vOffs[2]; eP[3] = vOffs2[2];
                
                id += vID[3];
                
                 
                // Right line: Bottom right neighbor, top and bottom.
                vec2 pT = getOffs(eID[2]*2. + eID[3]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[2]*2. + eID[3]*2. + eID[3], ip, e0.yx);
                 
                // Bottom line: Bottom neighbor, left and right.
                vec2 pL = getOffs(eID[3]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[3]*2. + eID[2], ip, e0);
                 
                eP[4] = pT; eP[5] = pB;
                eP[6] = pR; eP[7] = pL;
                
                quadrant = 3;
                
            }
            else { // Top right. (Vertical).
            
                eP[6] = vOffs2[2]; eP[7] = vOffs[2];
            
                id += vID[2];                 
                  
                // Right line: Top right neighbor, top and bottom.
                vec2 pT = getOffs(eID[2]*2. + eID[1]*2. + eID[1], ip, e0.yx);
                vec2 pB = getOffs(eID[2]*2. + eID[1]*2. + eID[3], ip, e0.yx);
                  
                // Top line: Top neighbor, left and right.
                vec2 pL = getOffs(eID[1]*2. + eID[0], ip, e0);
                vec2 pR = getOffs(eID[1]*2. + eID[2], ip, e0);
                 
                eP[4] = pT; eP[5] = pB;
                eP[2] = pL; eP[3] = pR;
                
                quadrant = 2;
            }
        }

    } 
  
    
    pID = 4;
    
    // lineIntersect: ro, rd, a, b;
    vec2 ro, rd;
    float t;

    
    vec2 cntr = vec2(0);
    // Intersection points.
    for(int i=min(0, iFrame); i<4; i++){
        ro = eP[(i*2 + 6)%8];
        rd = normalize(eP[(i*2 + 7)%8] - ro);
        vec2 tn = (eP[i*2 + 1] - eP[i*2]);
        t = lineIntersect(ro, rd, eP[i*2] - tn, eP[i*2 + 1] + tn);
        vP[i] = ro + rd*t;
        
        cntr += vP[i]/4.;
    }
    
    // Centering. Not absolutely necessary, but can be helpful. 
    p -= cntr;
    vP[0] -= cntr; vP[1] -= cntr; vP[2] -= cntr; vP[3] -= cntr;
    
    // Quadrant ID. Not really used, but handy to have.
    vec2 qIP = mod(ip + vID[quadrant], 2.);
    quadrant = 0;
    if(qIP.y==0.  && qIP.x==1.) quadrant = 3;
    if(qIP.y==1.){ 
       if(qIP.x==0.) quadrant = 1;
       else quadrant = 2;
    }


    
    // SUBDIVISION.

    #if SUBDIV == 1

    int qID = quadrant&1;
    vec2 divF = vec2(2);
    for(int j = 0; j<2; j++){
    
        if(hash21(id + .07 + float(j)/32.)<.4){

            vec2 a, b, a2, b2;
            
            // Mid-point split offset.
            float offsMid = hash21(id + .31 + float(j)/64.)*.5  + .75;
            offsMid *= .5; 
            a = mix(vP[0], vP[1], offsMid); b = mix(vP[2], vP[3], offsMid);
            a2 = mix(vP[1], vP[2], offsMid); b2 = mix(vP[3], vP[0], offsMid);

            //int swp = hash21(id + .35 + float(j)/32.)<.5? 0 : 1; // Random swap.
            int swp = length(a - b)<length(a2 - b2)? 0 : 1; // Distance swap.

            // Swap orientation.
            if(swp == 1){ a = a2; b = b2; }

            //vec2 tn = a - b;
            float ln2 = distLineS(p, a, b); 


            if(ln2<0.){

                 // Bottom quad.
                 //d = smax(d, ln2, .0);
                 pID = 4;

                 triID = 0; 

                 // Bottom triangle coordinates.
                 if(swp==0) vP = mat4x2(vP[0], a, b, vP[3]);
                 else vP = mat4x2(vP[0], vP[1], a, b);

            }
            else {
            
                 // Top quad.
                 //d = smax(d, -ln2, .0);
                 pID = 4;

                 triID = 1;

                 // Top triangle coordinates. Unchanged.
                 //vP = mat4x2(vP[0], vP[1], vP[2], vP[3]);
                 if(swp==0) vP = mat4x2(a, vP[1], vP[2], b);
                 else vP = mat4x2(b, a, vP[2], vP[3]);

            }

            if(mod(ip.x +.5, 2.)==0.) triID = 1 - triID;
            if(qID==0 && check==0) triID = 1 - triID;
            if(quadrant==1 || quadrant==2) triID = 1 - triID;


            if(triID==0){
               
               if(swp==0){ id += eID[3]/divF; divF.y *= 2.; } // Bottom.
               else{ id += eID[0]/divF; divF.x *= 2.; } //  Left.
            }
            else {

               if(swp==0){ id -= eID[3]/divF;  divF.y *= 2.; } // Top.
               else{ id -= eID[0]/divF; divF.x *= 2.; } // Right.
            }           

            
        }
        
        
    }
    
    /*
    // Centering coordinates, if you wanted to do that.
    cntr = (vP[0] + vP[1] + vP[2] + vP[3])/4.;
    p -= cntr;
    vP[0] -= cntr; vP[1] -= cntr; vP[2] -= cntr; vP[3] -= cntr;
    */
    #endif
    /////////////

    #if SUBDIV == 2
    //if(hash21(id + .06)<.5){
    int qID = quadrant&1;
   
  
    //int swp = hash21(id + .33)<.5? 0 : 1;
    int swp = length(vP[0] - vP[2])<length(vP[1] - vP[3])? 0 : 1;
    vec2 a, b;
    a = vP[0]; b = vP[2];
    if(swp == 1){ a = vP[1]; b = vP[3]; }
      
    float ln2 = distLineS(p, a, b); 
 
    
    if(ln2<0.){
    
         // Bottom triangle.
         //d = smax(d, ln2, .0);
         pID = 3;
         triID = 0;//qID;//check==swp? 0 : 1;
         
         // Bottom triangle coordinates.
         if(swp==0) vP = mat4x2(vP[0], vP[2], vP[3], vP[3]);
         else vP = mat4x2(vP[0], vP[1], vP[3], vP[3]);
     
    
    }
    else {
        // Top triangle.
         //d = smax(d, -ln2, .0);
         pID = 3;
         triID = 1;// - qID;//check==swp? 1 : 0;
        
         // Top triangle coordinates. Unchanged.
         //vP = mat4x2(vP[0], vP[1], vP[2], vP[3]);
         if(swp==1) vP = mat4x2(vP[1], vP[2], vP[3], vP[3]);
 
    }
    
    if(mod(ip.x +.5, 2.)==0.) triID = 1 - triID;
    if(qID==0 && check==0) triID = 1 - triID;
    if(quadrant==1 || quadrant==2) triID = 1 - triID;
   
  
    if(triID==0){
       // Bottom.
       if(swp==0) id += vID[3]/2.8;
       else id += vID[0]/2.8;
    }
    else {
    
       if(swp==0) id -= vID[3]/2.8;
       else id -= vID[0]/2.8;
    }

    
    /*
    cntr = (vP[0] + vP[1] + vP[2])/3.;
    p -= cntr;
    vP[0] -= cntr; vP[1] -= cntr; vP[2] -= cntr;
    */
    
    //}
    #endif
    /////////////
 
     
    // Polygon rendering.
    float d = sdPoly(p, vP, pID);
 
    // Local coordinates.
    gP = p;
    

   
    return vec4(d, id, quadrant);
    
}

#else
////////////////

// THE ASYMMETRIC QUAD PATTERN (For comparison).

// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 2 out, 2 in...
vec2 rndOffs(vec2 p){

	vec3 p3 = fract(vec3(p.xyx)*vec3(.3031, .4030, .5973));
    p3 += dot(p3, p3.yzx + 142.5237);
    //return (fract((p3.xx + p3.yz)*p3.zy) - .5)*.7;
    // Animated option.
    p = fract((p3.xx + p3.yz)*p3.zy);
    return sin(TAU*p + iTime)*.5*.7;
} 

vec4 distField(vec2 p){

    // Scale.
    vec2 sc = gSc;
    
    // Cell ID and local coordinates.
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    // Vertex and offset points.
    mat4x2 v;
    mat4x2 pOffs;
   
    // Center offset point.
    vec2 cntr = rndOffs(ip)*sc;
    
    // Dividing lines -- The best way to partition a cell into random
    // quads. Unfortunately, it doesn't work for obtuse angles. The
    // solution is a less appealing line angle check.
    //vec4 ln;
    
    // Angles.
    vec2 pC = p - cntr;
    float cAng = mod(atan(pC.y, -pC.x), TAU);
    
    vec4 vAng;
  
    for(int i = 0; i<4; i++){
        
        // Neighboring edge cell offset points.
        pOffs[i] = (eID[i]*2. + rndOffs(ip + eID[i]*2.))*sc;
       
        // Line from the offset center point to the point above.
        //ln[i] = distLineS(p, cntr, pOffs[i]);
        
        // Each of the four line angles.
        vec2 pCI = pOffs[i] - cntr;
        vAng[i] = mod(atan(pCI.y, -pCI.x), TAU);
    }
    
    
    //ln = max(-ln, ln.wxyz);
    
    
    
    // Set the slice index to zero, then check the other three
    // to make sure it's not one of them. The last quadrant
    // wraps around the unit circle, so requires some... I was
    // going to say, "finesse", but this is definitely hackery. :)
    // There's a trick involving five array spaces for wrappping
    // situations, but I can't remember how it goes. :)
    int index = 0;
    // We're doing it reverse order to deal with a possible
    // overwrite when "i" equal 1.
    for(int i = 3; i>0; i--){ 
       
        // Angle of first line and the preceding line.
        float ang = vAng[i];
        float angM1 = vAng[(i + 3)%4];
           
        if(ang<angM1){  // i == 1.
            cAng = cAng<ang? cAng - ang + TAU : cAng - ang; 
            angM1 -= ang; 
            ang = TAU;
        }
        
        // If the pixel is between these two angles, flag it and exit.
        if(cAng<ang && cAng>=angM1){ 
           index = i; break;            
           //if(abs(angM1 - ang)>PI) valOn = 1;
         }
    }
    
    
    ////////////////
    // We now know which quadrant we're in, so determine the quad vertices.
    int i = index;
    int st = (i + 2)%4;

    v[st] = cntr;
    v[(st + 1)%4] = pOffs[(i + 3)%4];
    v[(st + 2)%4] = (vID[i]*2. + rndOffs(ip + vID[i]*2.))*sc;
    v[(st + 3)%4] = pOffs[i];
    
    
    // Position based ID.
    ip += vID[i];
    
    pID = 4; // Number of vertices.
    
    
    
    // SUBDIVISION.
    
    // QUAD SPLIT.
    #if SUBDIV == 1
    
    vec2 divF = vec2(2);
    for(int j = 0; j<2; j++){
    
        
        if(hash21(ip + .03 + float(j)/32.)<.5){

            // Triangle split. Cut down the center.
            ivec2 cnrID = ivec2(0, 2);

            vec2 a, b, a2, b2;
            // Mid-point split offset.
            float offsMid = hash21(ip + .31 + float(j)/64.)*.5  + .75;
            a = mix(v[0],  v[1], .5*offsMid);
            b = mix(v[2],  v[3], .5*offsMid);

            a2 = mix(v[1],  v[2], .5*offsMid);
            b2 = mix(v[3],  v[0], .5*offsMid);
            
            // Random split.
            //if(mod(ip.x + ip.y, 2.)<.5){ cnrID = ivec2(1, 3); a = a2; b = b2; }
            //if(hash21(ip + .24 + float(j)/64.)<.5){ cnrID = ivec2(1, 3); a = a2; b = b2; }
            if(length(a2 - b2)<length(a - b)){ cnrID = ivec2(1, 3); a = a2; b = b2; }// Even split.

 
            float lnD = distLineS(p, a,  b);
            if(lnD<0.){

               ip -= eID[(cnrID.x + 1)%4]/divF;//float(2<<(j + 1));
               
               divF[(cnrID.x + 1)%2] *= 2.;
         
               if(cnrID.x == 1) v = mat4x2(v[0], v[1], a, b); // Left.
               else v = mat4x2(v[0], a, b, v[3]); // Bottom.

               triID = 1;

               pID = 4;

            }
            else {

               ip += eID[(cnrID.x + 1)%4]/divF;//float(2<<(j + 1));
               
               divF[(cnrID.x + 1)%2] *= 2.;
          
               if(cnrID.x == 1) v = mat4x2(b, a, v[2], v[3]); // Top.
               else v = mat4x2(a, v[1], v[2], b); // Right.

               triID = 0;

               pID = 4;

            }

        }
    }
    #endif

    
    // TRIANGLE SPLIT.
    #if SUBDIV == 2
    // Triangle split. Cut down the center.
    ivec2 cnrID = ivec2(0, 2);
    
    // Because some quads are obtuse, that needs to be tested first, since there
    // is only one way to split it. If it's not, then you can split on either diagonal.
    // How you do that is up to you. Here, I'm choosing the shortest diagonal, which
    // is common, since it tends to be more aesthetically pleasing.
    
  
    //if(mod(ip.x + ip.y, 2.)<.5) cnrID = ivec2(1, 3);
    if(length(v[1] - v[3])<length(v[0] - v[2])) cnrID = ivec2(1, 3); // Delaunay split.

    // If the mid-point of the diagonal is outside the quad, split in the other direction. 
    if(inQuad(v, mix(v[1], v[3], .5))==false) cnrID = ivec2(0, 2);  
    if(inQuad(v, mix(v[0], v[2], .5))==false) cnrID = ivec2(1, 3);  
 
    
    float lnD = distLineS(p, v[cnrID.x],  v[cnrID.y]);
    if(lnD<0.){
    
       //d = smax(d, lnD, .02);
       //d = max(d, lnD);
       ip -= vID[(cnrID.x + 1)%4]/2.;
       
       if(cnrID.x == 1) v = mat4x2(v[0], v[1], v[3], v[0]);
       else v = mat4x2(v[0], v[2], v[3], v[0]);
       
       triID = 1;
       
       pID = 3;
     
    }
    else {
    
       //d = smax(d, -lnD, .02);
       //d = max(d, -lnD);
       ip += vID[(cnrID.x + 1)%4]/2.;
       
       if(cnrID.x == 1) v = mat4x2(v[3], v[1], v[2], v[3]);
       else v = mat4x2(v[0], v[1], v[2], v[0]);
       
       triID = 0;
       
       pID = 3;
    
    }
    #endif
    
    
    // Polygon distance.
    float d = sdPoly(p, v, pID);
    
     
    // Vertices and local coordinates.
    vec2 vI = vID[i]*gSc;
    vP = v - mat4x2(vI, vI, vI, vI);
    gP = p - vI;
 
    /////////////////
    
    return vec4(d, ip, index);

} 

#endif

float gridField(vec2 p){
    
    vec2 ip = floor(p/gSc) + .5;
    p -= ip*gSc;
    

    float minSc = min(gSc.x, gSc.y);
    float grid = sBox(p, gSc/2.);
    
    return abs(grid);
}

// Global holder for pattern values.
vec4 svVal;

float func(vec2 p){
    
    // Pattern (polygon) distance, ID and quadrant.
    svVal = distField(p);
    return svVal.x;
 
}
 

 
vec4 vObj;
float svFn;
float map(vec3 p){

    float fl = -p.z;
    float fn = func(p.xy);
    
    svFn = fn;
    
    float oFn = fn;
    
     
    float ball = length(vec3(gP, p.z) - vec3(0, 0, .25)) - .25;
    
    #ifndef GRID
    fn += .0115;//.015;
    float bord = abs(fn) - .0135;
    bord = smax(bord, abs(p.z) - .03, .011);//  + max(bord, -.0125)*.25;;
    #else
    fn += .006;//.015;
    float bord = abs(fn) - .012;
    bord = smax(bord, abs(p.z) - .008, .015);//  + max(bord, -.0125)*.25;;
    #endif

 
    float srf = -p.z + fn*.5;
    
    // Metallic only.
    //bord = min(bord, srf);
    //srf = 1e5;
    
    
    #ifdef SHOW_VERTICES
    // Hacky border vertices. There's a more exact way to do this, but
    // it's expensive... Either way, I don't think it adds to the visuals.
    float vert = 1e5;
    for(int i = 0; i<4; i++){
        vert = min(vert, length(gP - vP[i] + normalize(vP[i])*.02) - .015);
    }
    vert = smax(vert, abs(p.z) - .04, .01); 
    bord = min(bord, vert);
    #endif
    
    
    /*
    // Central vertices... Kind of interesting... but I
    // think I'll pass. :)
    vert = length(gP) - .015;;
    srf = smax(srf, -vert, .005);
    vert = smax(vert, abs(p.z) - .03, .01);
    bord = min(bord, vert);
    */ 
     
    // Nearest distance.
    svVal.x = bord<srf?  bord : fn;
    
    // Objects.
    vObj = vec4(fl, srf, bord, 1e5);
    
    
   
    // Nearest object.
    return min(fl, min(srf, bord));
   

}

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p) {
	
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    vec3 e = vec3(.001, 0, 0), mp = e.zzz; // Spalmer's clever zeroing.
    for(int i = min(0, iFrame); i<6; i++){
		mp.x += map(p + sgn*e)*sgn;
        sgn = -sgn;
        if((i&1)==1){ mp = mp.yzx; e = e.zxy; }
    }
    
    return normalize(mp);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Set the global timer.
    gTm = iTime;

    // Scale and smoothing factor.
    const float sc = 1.;
    float sf = sc/iResolution.y;
    
    
    // Scaling and translation.
    vec2 p = uv*sc;
    
  
    // Camera origin and unit direction vector.
    vec3 rd = normalize(vec3(uv, 1));
    //rd.xy *= rot2(PI/18.);
    //rd.yz *= rot2(-PI/32.);
    //rd.xz *= rot2(-PI/32.);
    
    vec3 ro = vec3(0, 0, -1);
    ro.xy += vec2(1, .5)/16.*iTime;
    
    // A very basic raymarching loop.
    float de, t = 0.;
    #define FAR 20.
    for(int j=0;j<64;j++){
       
        de = map(ro + rd*t); // Distance to the function.
        // The plane "is" the far plane, so no far plane break
        // is needed.
        if(abs(de)<.001 || t>FAR) break; 
        t += de*.7; // Total distance from the camera to the surface.
    }
    t = min(t, FAR); // Clamping the far distance.

    
    // Object ID.
    int objID = vObj.x<vObj.y && vObj.x<vObj.z? 0 : vObj.y<vObj.z? 1: 2;
    
    // Object distance and ID.
    float d = svVal.x;
    vec2 id = svVal.yz;
    
    vec2 svGP = gP; // Object (polygon) local coordinates.
    //mat4x2 svVP = vP; // Object vertices.
    
    // Scene color.
    vec3 col = vec3(0);
    
    if(t<FAR){
    
        // Surface position and normal.
        vec3 sp = ro + rd*t;    
        vec3 n = normal(sp);

        // Point light.
        vec3 lp = ro + vec3(.25, .25, -.25);
        vec3 ld = lp - sp;
        //vec3 ld = normalize(vec3(.5, .35, -1));

        float lDist = length(ld);
        ld /= max(lDist, 1e-5);

        // Attenuation.
        float atten = 1./(1. + lDist*lDist*.05);


        // Cell and frame coloring.
        float rnd = hash21(id + .11);
        vec3 pGold = .5 + .45*cos(TAU*rnd/7. + vec3(0, 1, 2)*.7 + .5);
        pGold = mix(pGold/2., vec3(.25)*dot(pGold, vec3(.299, .587, .114)), .5);
        
        // Color gradient hackery.
        vec3 oCol = .5 + .45*cos(TAU*rnd + vec3(0, PI/2., PI));
        float sgn = oCol.b<.65? 1. : -1.; // Flip blueish gradients.
        vec3 oColHi = .5 + .45*cos(TAU*rnd + vec3(0, PI/2., PI) - sgn);
        if(dot(oColHi, vec3(.299, .587, .114))<dot(oCol, vec3(.299, .587, .114))){
            vec3 tmp = oCol; oCol = oColHi; oColHi = tmp;
        }
        
        // Mixing the color gradients.
        //vec2 lP = rot2(-atan(ld.y, -ld.x))*svGP; // Light angle based.
        vec2 lP = rot2(-PI/2.)*svGP.xy;
        oCol = mix(oColHi, oCol, smoothstep(-.5, .5, lP.x/gSc.x));

        // 
        vec3 pCol = vec3(.05);
        int gold = 0;
        int silver = 0;
           
        if(objID==2){
        
         // Frame: Silver of gold.

         #if FRAME_COL == 1
         pCol = pGold*.6 + vec3(1, .7, .3)*.3;
         //pCol *= vec3(.68, .6, .7);
         #else
         //pCol = pGold.zyx + .15;
         pCol = dot(pGold, vec3(.299, .587, .114))*.6 + vec3(1, .7, .5).zyx*.3;
         //pCol *= vec3(1.1, .6, .4);
         #endif

        }
        else if(objID==1){
          // Colored face.
          pCol = oCol;//pGold;
          gold = 1;

        }


   
        // Inside edges.
        //if(objID==2) pCol = mix(pCol, pCol*.7, smoothstep(0., .005, sp.z + .032));

        // Layered gradient noise value. Used for roughness
        // and coloring.
        float ns = gradN3D(sp*64.)*.66 + gradN3D(sp*128.)*.34;
        ns = smoothstep(.3, 1., ns)*.8 + .2;

        // Texturing.
        vec3 tx = tex3D(iChannel1, sp*2., n);
        float grTx = dot(tx, vec3(.299, .587, .114));
        //pCol = vec3(rnd*.2 + .1); // Debug greyscale.
        pCol *= grTx*1.5 + .25;


        //////////////////////

        // Material properties.
        float fresRef = .35;  // Reflectivity.
        float type = 1.;     // Dielectric or metallic.
        float rough = 1.;   // Roughness.

        int svGID = 1;
        // Frame and cell material.
        if(svGID>0){
        
             rough = min(grTx*.3 + .25, 1.);
             // Colored cell. Non metallic.
             if(objID==1){ type = 0.; rough *= .7; fresRef = .7; }
        }
        else {
             // Ground... Not seen, but there anyway.
             rough = min(grTx*.3 + .25, 1.); 
        }




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
        f0 = mix(f0, pCol, type);
        vec3 FS = f0 + (1. - f0)*pow(1. - vh, 5.); // Fresnel-Schlick reflected light term.

        // BRDF style specular and diffuse calculations. There is so little
        // extra work involved, but the lighting quality is much better.
        vec3 spec = getSpec(FS, nh, nr, nl, rough);
        vec3 diff = getDiff(FS, nl, type);


        // Apply some back scatter.
        float bac = clamp(dot(n, -normalize(vec3(ld.xy, 0))), 0., 1.);
        if(objID>0) pCol += oColHi*bac*bac*2.;
        //if(objID>0) pCol += vec3(1, .1, .2)*pCol*bac*bac*8.;


        // Ambient light.
        //
        // Quick Lighting Tech - blackle
        // https://www.shadertoy.com/view/ttGfz1
        // Studio and outdoor.
        //float amb = pow(length(sin(n*2.)*.5 + .5), 2.);
        float amb = length(sin(n*2.)*.5 + .5)/sqrt(3.)*smoothstep(-1., 1., -n.z); 



        float oFn = svFn;

        // False shadows.
        float sh = 1.;
        map(sp + n*.001 + ld*.037);
        if(objID!=2){
            sh = smoothstep(0., .015, -(svFn + .037 - .015));
            #ifdef GRID
            sh = sh*.5 + .5;
            #endif
        }


        // Applying lighting to the scene.
        col = pCol*(amb + diff*sh + vec3(1)*spec*sh);//vec3(1, .7, .5)*


        // Angling the sky in the environment map toward the upright surface. 
        // Completely fake, but it lights the chrome up more envenly.
        //rd.xy *= rot2(iTime/6.);
        rd.yz *= rot2(-PI/6.);    
        vec3 ref = reflect(rd, n);//.yzx*vec3(-1);
        vec3 rTx = texture(iChannel0, ref).xyz; rTx *= rTx;
        float specStr = objID==2? 16. : 16.;
        if(objID>0) col += rTx*spec*specStr;
        specStr = objID==2? 1. : .0;
        if(objID>0) if(objID>0) col += col*rTx*pow(nh, 5.)*specStr;

        // Extra shading.
        if(objID==1) col *= smoothstep(-.2, .4, -d*8.)*.8 + .2;
        else col *= max(.5 - d*8., 0.)*.8 + .2;

        // Darkening the border cell edges.
        if(objID!=1) col = mix(col, col*.0, 1. - smoothstep(0., .002, abs(oFn)));


        #ifdef GRID
        if(objID!=2){
            // Display the square grid.
            float grid = gridField(sp.xy);
            col = mix(col, col*.1, (1. - smoothstep(0., sf, grid - .0025)));
        }
        #endif 

        // Attenuation.
        col *= atten;
    
    }
    

    
    // Vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./16.);

 

    // Output to screen
    fragColor = vec4(pow(max(col, 0.), vec3(1)/2.2), 1);
}