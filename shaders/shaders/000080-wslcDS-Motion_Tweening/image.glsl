// Image (image) — Motion Tweening by Shane
// https://www.shadertoy.com/view/wslcDS

/*


	Motion Tweening
	---------------

	Creating a looping animation with magnetized blocks utilizing basic motion 
    tweening techniques. The animation sequence itself is a rough recreation 
    of a sequence I've seen around in GIF form on the internet. I'm not sure 
    where the original came from, but if I were to take a guess, I'd say it was 
    created by Andreas Wannerstedt, who produces a lot of mesmerizing looping 
    animations... but I wouldn't quote me on it.

    I've been away for a while, so wanted to start with something relatively
	simple. Motion tweening requires a bit of effort, but is relatively easy
	repetitive work. Demosceners do stuff like this all the time, but for those 
	not familar with the process, you just choose a total looping time 
    (tm = mod(iTime, totalTime)), then partition it into individual time segments 
    using a case statement, or some if-elseif statements. The segment intervals 
    themselves are filled with interpolated motion, distortion, morphing, etc.

    As you can see, none of the individual movements are particularly complex;
    rotations, pivots, translations, etc -- A lot of it was made up on the fly,
	so I'd imagine there'd be more efficient ways to achieve the same. One thing
	to note is that the colored cube moves in conjunction with the larger one, 
    which might throw some people off, but that's just a simple case of moving 
    the chrome looking box, setting the cube coordinates to the chrome box 
	coordinate system (p = pPrevious), then peforming more simple operations.
	
    I seem to say this a lot, but apologies in advance for the extended compile
	time. This should run pretty quickly, but the lengthy decision-making logic
	inside the raymarching loop taxes the compiler, which is amplified with the 
	reflection pass. By the way, you could simplify the objects and use IQ's 
    raytraced rounded-box intersection formulas to make this way, way more
	efficient. However, keeping track of the rotations for normal calculations, 
    and so forth, would get pretty tiresome... It's the kind of thing I'll leave 
    for Dr2 to do. :)



    Other examples:


    // This is one of the most clever and innovative examples on here.
    [SH18] Human Document - reinder
    https://www.shadertoy.com/view/XtcyW4

*/

#define FAR 30.

vec4 vObjID;
int objID;


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){    
    
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

// Time variables.
float tm, t, t2;

// Animation segment ID.
int segID = 0;

// The motion tween block. There's another withing the raymarching loop. 
// We're performing whatever nonpositional lengthy calculations we can outside 
// the raymarching loop. Usually, declaring things locally can help speed things
// up, but there is a point where precalculation is necessary. In any case, taking
// things outside the raymarching loop should reduce compile time... Although,
// with GPUs, who knows. A lot of it's hit and miss.
//
void doTweenTime(){
    
    
    // The total loop time. We're starting after the ten second mark.
    tm = mod(iTime + 10., 10.25);
    
    if(tm<1.){ // if(tm>=0. && tm<1.)
        
        // Normalize to the zero to one range: Time minus start time, divide total time;
        t = tm;//(tm - 0.)/(1. - 0.);
        // At this point, you can perform whatever kind of easing function, etc, on the 
        // normalized figures. 
        t = bounceOut(t);
          
        // Afterwards, adjust according to start value and end value.
        // In this case, we wish to rotate from zero to PI/2.
        t = mix(0., PI/2., t);
        
        // Setting a segment ID. This isn't really necessary, but I wanted the logic
        // inside the raymarching loop as simple as possible. The theory being that
        // "if(segID == 0)" should compile better than "if(tm<1.)," but it also allows
        // for "switch" statement usage.
        segID = 0;
        
    }
    else if(tm<2.){ // if(tm>=1. && tm<2.)
        
        t = tm - 1.; // (tm - 1.)/(2. - 1.);
        t2 = exponentialInOut(t);
        t = easeInOutCubic(t);
        
        segID = 1;
      
    }      
    else if(tm<3.){
        
        t = tm - 2.; // (tm - 2.)/(3. - 2.);
        t2 = t;
        t = exponentialOut(t);
        
        
        segID = 2;
  
    }    
    else if(tm<4.){
         
        // Normalize to the zero to one range: Time minus start time, divide total time;
        t = tm - 3.; // (tm - 3.)/(4. - 3.);
        t2 = t; // easeOutQuad(t);
        t = bounceOut(t);
        t = mix(0., PI/2., t);
        
        segID = 3;
    }
    else if(tm<5.){
        
        t = tm - 4.; // (tm - 4.)/(5. - 4.);
        t2 = easeInQuad(t);
        t = easeInOutCubic(t);
        t = mix(PI/2., 0., t);
        
        segID = 4;
        
     }
    else if(tm<6.){
        
        // Time minus start time, divide total time;
        t = tm - 5.; // (tm - 5.)/(6. - 5.);
        t2 = t;
        // Easing.
        t = easeInOutCubic(t);
        // We're performing a half turn.
        t = mix(0., PI/1., t);
        
         segID = 5;
 
    }
    else if(tm<7.){
       
        // Time minus start time, divide total time;
        t = tm - 6.; // (tm - 6.)/(7. - 6.);
        // Easing.
        t = bounceOut(t);
        // We're performing a half turn.
        t = mix(0., -PI/2., t);
        
        segID = 6;
    }
    else if(tm<8.){
       
        // Gold cube pivot to join the left leaning larger block.
        t = tm - 7.; // (tm - 7.)/(8. - 7.);
        t = easeInOutCubic(t);
        t2 = t;
        
        segID = 7;
       
    }
    else if(tm<9.){
       
        t = tm - 8.; // (tm - 8.)/(9. - 8.);
        t2 = t;
        t = easeInOutCubic(t);
        t = mix(PI/2., 0., t);
        
        segID = 8;
        
     }  
    else if(tm<10.){
       
        t = tm - 9.; // (tm - 9.)/(10. - 9.);
        t2 = easeOutQuad(t);
        
        segID = 9;
           
    }
    else if(tm<10.25){
     
        segID = 10;
    }    
    
    
}


void move(in vec3 p, inout vec3 q, inout vec3 q2, inout vec3 svDim, in vec3 bDim2){

    // Make a copy of the large box dimensions to account for varying length.
    vec3 bDim = svDim;
    
        // I debated over whether to use a switch statement versus the else-if mess you see here. 
    // They say switches are faster with more that a few items, but for whatever reason, my 
    // compiler hated the switch statement... When all's said and done, I know of a much,
    // much faster way, but it'll require some considerable restructuring.
    
    if(segID == 0){
        
        
        // "segID == 0" corresponds to the time period between zero and one second. The
        //  time, "t," has been normalized to the zero to one range (trivial, in this case)
        // and has been passed through an easing function. Which easing function is chosen 
        // depends on the movement style you're after; ease-in, exponential-out, bounce, etc. 

        
        
        // Begin with the large box at floor level.
        q.y -= bDim.y;
        
        // Lean down right.
        // This is a pivot motion. Basically, you offset the position to the pivot point,
        // whilst rotating and offsetting by the pivot amount. In this case, the pivot
        // point is at moved from the middle pivot position, vec3(0) to vec3(bDim.x, bDim.y, 0),
        // which represents the middle of the lower left edge, and we're rotating about the
        // XY plane. By the way, 3D rotations could be utilized, but I'm trying to stick to
        // the basics.
        q.xy = rot2(-t)*(q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        
        // Gold cube pivotal flip, with respect to the larger cube's preoriented transform.
        //
        // Set the colored cube coordinates to the chrome boxes coordinats. Using a second 
        // variable for the second objects coordinates isn't absolutely necessary, but I think
        // it reads better.
        q2 = q; 
        q2.y -= -bDim2.y; // Move into position with respect to the chrome cube.
        // Pivot -- See the pivot explanation above.
        q2.xy = rot2(-t)*(q2.xy - vec2(-bDim2.x, bDim2.y)) - vec2(-bDim2.x, -bDim2.y);
   
        
    }
    else if(segID == 1){
        
        
        // Slide and shrink the height.
        q.x -= mix(0., -bDim.x*3., t);
        q.y -= bDim.y;
        svDim.y = mix(bDim.y, bDim.y/2., t);
        
        q.xy = rot2(-PI/2.)*(q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        
        // Gold cube slide.
        // Move the cube relative to the large block position, q.
        q2 = q;
        q2.x -= -bDim.x*2.; 
        q2.y -= mix(bDim.x, 0., t);

        // Spinning relative to the q axes -- The global XZ axes to the viewer, but the
        // YZ axes from the perspective of the chrome cube.
        q2.yz = rot2(t2*PI*2.)*q2.yz;
     
    }      
    else if(segID == 2){
        
        // Grow taller.
        svDim.y = mix(bDim.y/2., bDim.y, t);
        
        q.y -= svDim.y;
        q.xy = rot2(0.)*(q.xy - vec2(bDim.x, -svDim.y)) - vec2(-bDim.x, svDim.y);
        
        
         
        // Gold cube jump and flip.
        q2 = p;
        q2.y -= svDim.y*2. + bDim2.y;//mix(bDim.y/2., bDim.y, t)*2.; // Grow with the bottom object.
        
        
        if(t2<.35) q2.y -= t2/.35*bDim.y*.7; // Ascend from the top of the object below.
        else q2.y -= (bDim.y - bounceOut((t2 - .35)/.65)*bDim.y)*.7; // Decend back to the top.
              
       
        q2.yz = rot2(-t2*PI/1.)*(q2.yz); // Front flip.
  
  
    }    
    else if(segID == 3){
       

        
        // Lean down right.
        q.y -= svDim.y;
        q.xy = rot2(-t)*(q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        
        q2 = q;
        q2.y -= bDim.y + bDim2.y;
        // Pivot the gold cube anticlockwise from the top by 2 PI.
        q2.xy = rot2(t*2.)*(q2.xy - vec2(-bDim2.x, -bDim2.y)) - vec2(bDim2.x, bDim2.y);
 
        //
    }
    else if(segID == 4){
        
        
        // Lean up left.
        q.y -= bDim.y;
        q.xy = rot2(-t)*(q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
        
        // Gold cube: Slide from top to bottom.
        q2 = q;
        q2.x -= -bDim2.x*2.;
        q2.y -= mix(bDim2.y, -bDim2.y, t2);
        
    }
    else if(segID == 5){
        
        
        q.y -= bDim.y;
        q.xz = rot2(t)*(q.xz - vec2(bDim.x, bDim.z)) - vec2(-bDim.x, -bDim.z);
        
        
        // Gold cube.
        q2 = q;
        q2.y -= -bDim2.y; // Move into position.
        q2.x -= -bDim2.x*2.; // Move into position.
        
        q2.xz = rot2(-t)*(q2.xz - vec2(bDim.x, bDim.z)) - vec2(-bDim.x, -bDim.z);

    }
    else if(segID == 6){
        
        
        //Lean down left (one cell up).
        q.y -= bDim.y;
        q.x -= bDim.x*2.;
        q.z -= bDim.z*2.;
        q.xy = rot2(-t)*(q.xy - vec2(-bDim.x, -bDim.y)) - vec2(bDim.x, bDim.y);
        //q.z -= bDim.z;
        
        // Gold cube: Leave stationary.
        q2 = p; // Detatch from the larger box coordinate system, and use the global one.
        q2.y -= bDim2.y; // Move into position.
        q2.x -= bDim2.x*2.;
        
    }
    else if(segID == 7){
       
       
        //From a down left position (one cell up), slide to the right.
        q.y -= bDim.y;
        //q.x -= bDim.x*2.;
        q.x -= mix(bDim.x*2., bDim.x*4., t);
        q.z -= bDim.z*2.;
        q.xy = rot2(PI/2.)*(q.xy - vec2(-bDim.x, -bDim.y)) - vec2(bDim.x, bDim.y);
        
        // Gold cube.
        q2 = q; 
        q2.y -= -bDim2.y*3.; 
        q2.z -= -bDim2.z*2.; 
        
        // Whilst sliding, pivot the gold cube to the top of the larger object.
        q2.yz = rot2(-t2*PI/2.)*(q2.yz - vec2(bDim.x, bDim.z)) - vec2(-bDim.x, -bDim.z);
       
    }
    else if(segID == 8){
       
        
        // Move the chrome cube into this frame's position.
        q.y -= bDim.y;
        q.x -= -bDim.x*2.;
        q.z -= bDim.z*2.;
        
        // Pivot about XZ.
   		q.xz = rot2(t2*PI/1.)*(q.xz - vec2(bDim.x, -bDim.z)) - vec2(-bDim.x, bDim.z);           
        // Pivot about XY.
        q.xy = rot2(-t)*(q.xy - vec2(bDim.x, -bDim.y)) - vec2(-bDim.x, bDim.y);
 
        
        // Gold cube flip back down a level.
        q2 = q; 
        
        q2.xy = rot2(t2*PI)*(q2.xy - vec2(-bDim.x, bDim.y)) - vec2(bDim.x, -bDim.y);
        q2.y -= bDim2.y*3.;
        
    }  
    else if(segID == 9){
       
         
        //Rotate and slide back to the original position.
        q.y -= bDim.y;
       
        // Rotate about XZ with no pivoting.
        q.xz = rot2(t*PI/2.)*(q.xz);           
         
        
        // Pivot the gold cube about XZ whilst sliding back down to the ground.
        q2 = q;
        q2.x -= bDim.x*2.;
        q2.y -= mix(bDim2.y, -bDim2.y, t2);
      
        q2.xz = rot2(t*PI)*(q2.xz - vec2(-bDim.x, bDim.z)) - vec2(bDim.x, -bDim.z);
          
    }
    else {
        
        // Pause briefly before continuing the looping process again.
        q.y -= bDim.y;
        
        q2 = q;
        q2.y -= -bDim2.y;
        q2.x -= -bDim.x*2.;
        
    }

}

// Distance function: This one is pretty simple.
float map(vec3 p){


    // Floor.
    float fl = p.y;  //-sBoxS(p - vec3(0, 3, 0), vec3(6, 3, 6),.04);//min(p.y, -p.y + 3.8);
    
    

    // Object dimensions.
    vec3 bDim = vec3(.25, .5, .25); // Large box.
    const vec3 bDim2 = vec3(.25, .25, .25); // Small cube.
   
    // Local coordinates for each moving object.
    vec3 q = p, q2 = p;
    
    // Move the objects.
    move(p, q, q2, bDim, bDim2);
 
    
    // The rendering portion is the easy bit; Just some standard distance
    // field operations with IQ's box formula.
    
    
    // The chrome box.
    float obj = sBox(q, bDim, .04);
    
    // The colored cube.
    float obj2 = sBox(q2, bDim2, .04); 
    
    // Chrome box grooves.
    //obj = max(obj, -sBox(q, bDim*vec3(.25, .667, 1.2), .04));   
    //obj = max(obj, -sBox(q, bDim*vec3(.25, 1.2, .25), .04)); 
    //obj = max(obj, -sBox(q, bDim*vec3(1.2, .667, .25), .04)); 
    obj = max(obj, -sBox(q.xy, bDim.xy*vec2(.25, .667), .04));   
    obj = max(obj, -sBox(q.xz, bDim.xz*vec2(.25, .25), .04)); 
    obj = max(obj, -sBox(q.yz, bDim.yz*vec2(.667, .25), .04)); 
    
    // Colored box nodules.
    obj = min(obj, sBox(q2, bDim2*vec3(.25, .25, 1.2), .04));   
    obj = min(obj, sBox(q2, bDim2*vec3(.25, 1.2, .25), .04)); 
    obj = min(obj, sBox(q2, bDim2*vec3(1.2, .25, .25), .04));
    
    // Center of the chrome box.
    obj = min(obj, sBox(q, bDim*vec3(.833), .04)); 

 

    // Store the floor, chrome box and gold cube positions for sorting
    // and surface identification outside the loop.
    vObjID = vec4(fl, obj, obj2, 0);
    
    
    // Return the minimum object.
    return min(min(fl, obj), obj2);
}

// Standard raymarching routine.
float trace(vec3 ro, vec3 rd){
   
    float t = 0., d;
    
    for (int i = min(0, iFrame); i<80; i++){

        d = map(ro + rd*t);
        
        // Using the hacky "abs," trick, for more accuracy. 
        if(abs(d)<.001 || t>FAR) break;        
        
        t += d;  // Using more accuracy, in the first pass.
    }
    
    return t;
}

// Second pass, which is the first, and only, reflected bounce. 
// Virtually the same as above, but with fewer iterations and less 
// accuracy.
//
// The reason for a second, virtually identical equation is that 
// raymarching is usually a pretty expensive exercise, so since the 
// reflected ray doesn't require as much detail, you can relax things 
// a bit - in the hope of speeding things up a little.
float traceRef(vec3 ro, vec3 rd){
    
    float t = 0., d;
    
    for (int i = min(0, iFrame); i<48; i++){

        d = map(ro + rd*t);
        
        if(abs(d)<.002 || t>FAR) break;
        
        t += d;
    }
    
    return t;
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing repeat objects - in a setting like this - with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 24; 
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .002;    
    float end = max(length(rd), .001);
    float stepDist = end/float(maxIterationsShad);
    
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = min(0, iFrame); i<maxIterationsShad; i++){

        float h = map(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, .2), 
        // clamp(h, .02, stepDist*2.), etc.
        dist += clamp(h, .01, .25);
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0. || dist>end) break; 
        //if (h<.001 || dist > end) break; // If you're prepared to put up with more artifacts.
    }

    // I've added 0.5 to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me.
    return max(shade, 0.); 
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 1.5, occ = 0.;
    for( int i = min(0, iFrame); i<5; i++ ){
    
        float hr = float(i + 1)*.25/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        
        if(occ>1e5) break; // Fake break to get compile time down.
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p) {
	
    const vec2 e = vec2(.001, 0);
    
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(0, iFrame); i<6; i++){
		mp[i] = map(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}




// The floor, chrome cube, and colored cube materials. These ones are pretty
// basic, but you could put more effort in.
//
vec3 getObjectColor(vec3 p, vec3 r, vec3 n){
    
    
    vec3 col;
        
    if(objID == 0) {
       
        // The floor.
        vec3 tx = texture(iChannel0, p.xz/4.).xyz; tx *= tx;
        col = tx*vec3(1, .7, .5)*.5;
        
    }
    else if(objID == 1) {
        
        // The chrome colored box. It's something I tend to get, but tinging
        // things blue can help bring about a metallic color... kind of. :)
        col = vec3(.65, .85, 1);
    }
    else {
        
        // The cube. 
        col = vec3(2, .9, .45); // Redish gold.
        //col = vec3(.7, 1.2, .3); // Green.
        //col = vec3(2, .35, .85); // Pink.
        //col = vec3(.3, 1, 2.5); // Blue.
        //col = vec3(.3); // Grey
    }
    

    // Adding some fake cube mapping information. The science is terrible, but it 
    // adds a bit of shine. :)
    vec3 cTx = tex3D(iChannel0, reflect(r, n)/1.5, n);
    cTx *= vec3(1, .8, .6);
    
    // Add a dose of fake reflection to the box and cube, and just a bit to the floor.
    if(objID>0) col *= cTx*2.;
    else col += cTx*.1;
    
    return col;

}

// Using the hit point, unit direction ray, etc, to color the 
// scene. Diffuse, specular, falloff, etc. It's all pretty 
// standard stuff.
vec3 doColor(in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, float t){
    
    
    // Initiate the scene color to zero.
    vec3 sceneCol = vec3(0);
    
    if(t<FAR){
        
        vec3 ld = lp - sp; // Light direction vector.
        float lDist = max(length(ld), .0001); // Light to surface distance.
        ld /= lDist; // Normalizing the light vector.
        
        float ao = calcAO(sp, sn);

        // Attenuating the light, based on distance.
        float atten = 1./(1. + lDist*.2 + lDist*lDist*.05);

        // Standard diffuse term.
        float diff = max(dot(sn, ld), 0.);
        // Standard specualr term.
        float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.), 8.);
        
        // Ramp up the diffuse value. Sometimes, it can help things look metallic.
        diff = pow(diff, 4.)*2.;

        // Coloring the object. You could set it to a single color, to
        // make things simpler, if you wanted.
        vec3 objCol = getObjectColor(sp, rd, sn);
        

        // Combining the above terms to produce the final scene color.
        sceneCol = objCol*((diff + ao*.2) + vec3(1, .97, .92)*spec*4.);
        
        // Apply the attenuation and ambient occlusion.
        sceneCol *= atten*ao;
        
    }
    
    
    // Fog factor -- based on the distance from the camera.
    float fogF = smoothstep(0., .9, t/FAR);
    //
    // Applying the background fog. Just black, in this case, but you could
    // render sky, etc, as well.
    sceneCol = mix(sceneCol, vec3(0), fogF); 

    
    // Return the color. Performed once every pass... of which there are
    // only two, in this particular instance.
    return sceneCol;
    
}


vec3 getRd(vec2 u, vec3 ro){
   
    // Camera Setup.     
    vec3 lk = vec3(0, .5, 0);  // "Look At" position.

 
    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159265/3.; // FOV - Field of view.
    vec3 fw = normalize(lk - ro);
    vec3 rt = normalize(vec3(fw.z, 0, -fw.x )); 
    vec3 up = cross(fw, rt);

    // rd - Ray direction.
    vec3 rd = normalize(fw + (u.x*rt + u.y*up)*FOV);
    // Warping the ray to give that curved lens effect.
    //rd = normalize(vec3(rd.xy, rd.z*(1. - length(rd.xy)*.25)));
    
    return rd;
    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    

    // Aspect correct screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    
    // Slight barrel distortion.
    float r = dot(uv, uv);
    uv *= 1. + .2*(r*r + r);
    
    float cTm = iTime/2.;
    vec3 ro = vec3(sin(cTm)*2.65, cos(tm)*sin(cTm)*.25 + 2.25, cos(cTm)*2.65);//vec3(0, 0, 0);
    //vec3 ro = vec3(sin(cTm)*.75, cos(tm)*sin(cTm)*.25 + 2.25, -2.65);//vec3(0, 0, 0);
 
    
    vec3 rd = getRd(uv, ro);
    
    // Ray origin. Doubling as the surface position, in this particular example.
    // I hope that doesn't confuse anyone.

    vec3 lp = vec3(1, 3, -1); // Light position. Set in the vicinity the ray origin.

 
    // Movement calculations -- Outside the loop, in an attempt to save on compiler time.
    doTweenTime();
    
    
    
    // FIRST PASS.
    
    // Raymarch.
    float t = trace(ro, rd);
 
    // Obtain the current object ID.
    objID = vObjID.x < vObjID.y && vObjID.x < vObjID.z? 0 : vObjID.y < vObjID.z? 1 : 2;
    
    // Advancing the ray origin, "ro," to the new hit point.
    ro += rd*t;
    
    // Retrieving the normal at the hit point.
    vec3 sn = getNormal(ro);
    
    // Retrieving the color at the hit point, which is now "ro." I agree, reusing 
    // the ray origin to describe the surface hit point is kind of confusing. The reason 
    // we do it is because the reflective ray will begin from the hit point in the 
    // direction of the reflected ray. Thus the new ray origin will be the hit point. 
    // See "traceRef" below.
    vec3 sceneColor = doColor(ro, rd, sn, lp, t);
    
    // Checking to see if the surface is in shadow. Ideally, you'd also check to
    // see if the reflected surface is in shadow. However, shadows are expensive, so
    // it's only performed on the first pass. If you pause and check the reflections,
    // you'll see that they're not shadowed. OMG! Better call the shadow police. :)
    float sh = softShadow(ro +  sn*.0015, lp, 12.);
    sh = min(sh + .3, 1.);
    
    
    // SECOND PASS - REFLECTED RAY
    
    // Standard reflected ray, which is just a reflection of the unit
    // direction ray off of the intersected surface. You use the normal
    // at the surface point to do that. Hopefully, it's common sense.
    rd = reflect(rd, sn);
    
    
    // The reflected pass begins where the first ray ended, which is the suface
    // hit point, or in a few cases, beyond the far plane. By the way, for the sake
    // of simplicity, we'll perform a reflective pass for non hit points too. Kind
    // of wasteful, but not really noticeable. The direction of the new ray will
    // obviously be in the direction of the reflected ray. See just above.
    //
    // To anyone who's new to this, don't forgot to nudge the ray off of the 
    // initial surface point. Otherwise, you'll intersect with the surface
    // you've just hit. After years of doing this, I still forget on occasion.
    t = traceRef(ro +  sn*.003, rd);
    

    // Obtain the current object ID.
    objID = vObjID.x < vObjID.y && vObjID.x < vObjID.z? 0 : vObjID.y < vObjID.z? 1 : 2;
    
    // Advancing the ray origin, "ro," to the new reflected hit point.
    ro += rd*t;
    
    // Retrieving the normal at the reflected hit point.
    sn = getNormal(ro);
    
    // Coloring the reflected hit point, then adding a portion of it to the final scene color.
    // How much you add, and how you apply it is up to you, but I'm simply adding 35 percent.
    //sceneColor += doColor(ro, rd, sn, lp, t)*.5;
    // Other combinations... depending what you're trying to achieve.
    vec3 rCol = doColor(ro, rd, sn, lp, t);
    sceneColor = sceneColor + rCol*.75;
    
    
    // APPLYING SHADOWS
    //
    // Multiply the shadow from the first pass by the final scene color. Ideally, you'd check to
    // see if the reflected point was in shadow, and incorporate that too, but we're cheating to
    // save cycles and skipping it. It's not really noticeable anyway. By the way, ambient
    // occlusion would make it a little nicer, but we're saving cycles and keeping things simple.
    sceneColor *= sh;
    
    
    // Extra coloring.
    //sceneColor *= vec3(1.1, 1, .9);

    // Clamping the scene color, performing some rough gamma correction (the "sqrt" bit), then 
    // presenting it to the screen.
	fragColor = vec4(sqrt(clamp(sceneColor, 0., 1.)), 1);
}