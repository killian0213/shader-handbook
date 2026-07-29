// Image (image) — Mobius Spiral Metaball Field by Shane
// https://www.shadertoy.com/view/4ftBzS

/*

    Mobius Spiral Metaball Field
    ----------------------------
    
    Applying a log polar Mobius spiral transformation to a metaball field.
    I've mentioned a few times that the humble metaball effect is one of 
    my oldschool favorites. As metaball examples go, I'd imagine this 
    variation doesn't come up often. :)
    
    I'm sure a lot people know that you can take a particle or more then 
    render some field lines around it. This just takes it a few steps
    further by applying some common complex arithmetic functions.
    
    Anyway, I've explained things briefly. At some stage, I intend to post
    a few other examples along these lines.
    
    
    
    Other examples:
    
    // Beautiful example. MLA is really good at applying less 
    // commonly applied complex analysis related material to the 
    // canvas.
    Complex Atanh Made Simple - mla
    https://www.shadertoy.com/view/WtjczR
    
    // The following unlisted example should explain how to 
    // put together a simple Mobius spiral.
    Logarithmic Mobius Transform - Shane
    https://www.shadertoy.com/view/4dcSWs
    
*/

// The complex coordinate transformations. When all three are commented
// out, the repeat image will appear. Not that exciting, but helpful in
// understanding how things work. :)
//
// The spiral transform on its own will simply shift the original texture
// lines across, which will make it look rotated. 

// Mobius transform.
#define MOBIUS
// Log polar transform.
#define LOG_POLAR
// Spiral transform.
#define SPIRAL


///////////////////////////
// PI and 2PI.
#define PI 3.14159265358979
#define TAU 6.283185307179

// Real and imaginary vectors. Handy to have.
#define R vec2(1, 0)
//#define I vec2(0, 1)

// Common complex arithmetic functions. Most are self explanatory...
// provided you know a little bit about complex analysis. If you don't,
// it's not difficult to learn.
vec2 conj(vec2 a){ return vec2(a.x, -a.y); }
vec2 cmul(vec2 a, vec2 b){ return mat2(a, -a.y, a.x)*b; }
vec2 cinv(vec2 a){ return vec2(a.x, -a.y)/dot(a, a); }
vec2 cdiv(vec2 a, vec2 b){ return cmul(a, cinv(b)); }
vec2 clog(in vec2 z){ return vec2(log(length(z)), atan(z.y, z.x)); }


// The Mobius function.
vec2 mobius(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d){

    return cdiv(cmul(z, a) + b, cmul(z, c) + d);
}


//////////////////////
 
// The complex metaball transformation function.
vec2 transf(in vec2 z){


    // Function coordinates.
    vec2 fz = vec2(0);
    
    // Two metaball movement time variables.
    float time = iTime/4.;
    
    float time2 = time + 3.;
    
    int pNum = 5;
    // Set the particle's position, calculated it's field strength contribution, then
    // add it to the total field strength value.
	for(int i = 0; i<pNum; i++){	
        
        float fi = float(i);
        // Random sinusoidal motion for each particle. Made up on the spot, so could 
        // definitely be improved upon.
        float rnd = fi*(PI*2. + .5453); //(hash(i)*.5 + .5)*PI*2.;
		vec2 pos = vec2(sin(time*.97 + rnd*3.11)*.5, 
                        cos(time*1.03 + rnd*5.73)*.4);
		pos *= vec2(sin(time*1.05 + fi*(fi + 1.)*PI/9.11), 
                    cos(time*.95 + fi*(fi - 1.)*PI/7.73))*1.25;
        
        // Modulating the radius from zero to maximum to give the impression that the 
        // particles are attracted to the center. 
        //pos *= abs(sin(time*1.5 + i*3.14159/pNum))*1.2; // Bounce.
        // Smoother motion.
        if((i%2) == 1) pos *= (cos(time*3. + fi*3.14159/float(pNum))*.5 + .5); 
        
        
 	    vec2 pos2 = vec2(sin(time2*.97 + rnd*3.11)*.5, 
                        cos(time2*1.03 + rnd*5.73)*.4);
		pos *= vec2(sin(time2*1.05 + fi*(fi + 1.)*PI/9.11), 
                    cos(time2*.95 + fi*(fi - 1.)*PI/7.73))*1.25;
        
        // Modulating the radius from zero to maximum to give the impression that the 
        // particles are attracted to the center. 
        //pos *= abs(sin(time*1.5 + i*3.14159/pNum))*1.2; // Bounce
        if((i%2) == 1) pos2 *= (cos(time2*3. + fi*3.14159/float(pNum))*.5 + .5); // Smoother motion.
        
        
        // The complex transformation portion. Without any of these, this would
        // just be a regular metaball demonstration.
        
        #ifdef MOBIUS
        // I can't recall ever seeing the usage of this function explained in simple 
        // terms, so I'll do it here. Put two negative real vectors (R = vec2(1, 0)) 
        // in the positions shown, then place the anchor points in the remaining spots 
        // (pos and pos2), and that's it... Whether this is "technically" correct, I'm 
        // not sure. However, if you're a democoder, etc, who just wants to render a 
        // double spiral with moving anchor points, this will get you there.
        vec2 zi = mobius(z, -R, pos, -R, pos2); 
        #else
        // Just the repeat texture.
        vec2 zi = z - pos;
        #endif 
        
        #ifdef LOG_POLAR
        // A Mobius transform differs aesthetically from a log polar Mobius 
        // transform, although we often imply a log polar Mobius transfomm.
        // Anyway, this is a log polar transform, which is just a regular polar
        // transform with the natural logarithm applied to the radial portion.
        //
        zi = clog(zi);
        // Including the other particles when not using a Mobius transform.
        // I find it a little busy.
        //#ifndef MOBIUS
        //zi += clog(z - pos2);
        //#endif
        #endif
        
        #ifdef SPIRAL
        // Spirals are created by arranging for concentric rings to move out 
        // along the radial direction by one or more rings per revolution --
        // As an aside, for things like hexagon or bridck patterns, it might
        // be half a radial cell. Anyway, this can be effected by complex 
        // multiplication of the angular component in the order of a cell width 
        // (half, or whatever) divided by a full revolution, TAU. In this case, 
        // we're moving out by 2 cell units in order for the colors to match 
        // up -- which has something to do with the custom cell subdivision I 
        // wanted to perform.
        vec2 e = vec2(1, 2./TAU);
        zi = cmul(zi, e); 
        #endif
         
        // Scaling.
        //if((i%2) == 0) 
        zi = zi/2.; // Or: cmul(vec2(.5, 0), zi); // Just a.x*b;
    
        
        fz += zi;
 
     }
     
     
     // Return the transformed coordinates.
     return fz;

}


vec2 dP;
vec3 distField(vec2 p){

    // The transformation function itself.
    p = transf(p);
    
    // Coordinat copy.e
    vec2 op = p;
    
    // A bit of animation.
    //p -= vec2(1, 4)*iTime/8.;
    //p.y *= op.y<0.? 1. : -1.;
    
    vec2 sc = vec2(1, 1)/4.;
    sc.y *= 6.2831853/6.; // Lining things up.
    
    //if(mod(floor(p.y/sc.y), 2.)<.5) p.x += sc.x/2.;
    //if(mod(floor(p.x/sc.x), 2.)<.5) p.y += sc.y/2.;
    //if(mod(floor(p.x/sc.x), 2.)<.5) p.y += mod(iTime/2., 6.2831853/6.*1.);
    
    //float dir = mod(floor(p.y/sc.y), 2.)<.5? -1. : 1.;
    //p.x += mod(dir*iTime/4., 1.);
    
    // Sliding in opposite directions.
    float dir = mod(floor(p.x/sc.x), 2.)<.5? -1. : 1.;
    p.y += mod(dir*iTime/4., 6.2831853/6.*1.);

    // Cell ID and local coordinates.
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    
    
    
    // ip.x += mod(floor(ip.x), 4.);
  
    //
    // Wrap the radial coordinates in sync.
    ip.y = mod(ip.y, 4.);
    ip.x = mod(ip.x, 4.);
    
    
    // Render a box.
    float d = sBoxS(p, sc/2., sc.x*.1);
    
    // Rivots.
    //vec2 q = abs(p) - sc/2.*.6;
    //d = max(d, -(length(q) - sc.x*.025));
    //if(mod(ip.x, 2.)<.5) d = max(d, -(length(p) - sc.x*.025));
    //if(mod(ip.x, 2.)<.5) d = abs(d + sc.x*.22) - sc.x*.22;
    //d = max(d, -(abs(p.x) - sc.x*.0));
    
   
    // Global coordinate copy, for debugging.
    dP = p;
    
    // Return the distance value and cell ID.
    return vec3(d, ip);

}



void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
 
 
    // Scale and smoothing factor.
    const float sc = 1.;
    float sf = sc/iResolution.y;

    
    // Scaling and translation.
    vec2 p = sc*uv;
    
    
    // The function differential. If you want nice clean lines then 
    // you'll have to differentiate the transformation function and
    // apply that to the distance field. In this case the angle 
    // remains constant, so you only need to apply it to the distorted
    // radial component.
    float px = 1e-2/iResolution.y;
    vec2 dtX = (transf(uv + vec2(px, 0)) - transf(uv))/px;
    //vec2 dtY = (transf(uv + vec2(0, px)) - transf(uv))/px;
    //float dt = (length(dtX) + length(dtY))/2.;
    float dt = length(dtX);
    
    // Faster but leaves artifacts, which is why you need
    // to do it by hand.
    //float dt = length(dFdx(transf(uv)))*iResolution.y;
  
     
    // Scene object.
    vec3 d3 = distField(p);
  
    // Distance and ID.
    float d = d3.x;
    vec2 id = d3.yz;
    
    // Bump mapping samples.
    //vec3 d3X = distField(p + vec2(px, 0)); 
    vec3 d3Y = distField(p + vec2(0, px));
    float dB = d3Y.x;
    
    vec2 pp = dP;
    
    // Random values.
    float rnd4 = hash21(id + .14);
    float rnd = hash21(floor(id/vec2(1, 4)) + .23) + rnd4*.2 - .05;
    
    // Color. I experimented with a few combinations. I'll tidy it up later.
    //vec3 sCol = .5 + .45*cos(TAU*rnd4/1. + vec3(0, 1, 2)*1.6);
    vec3 sCol = .5 + .45*cos(TAU*(id.x + abs(id.y - 2.)/4.)/4. + vec3(0, 1, 2)*1.6);
    //sCol = vec3(1)*sCol.y;//dot(sCol, vec3(.299, .587, .114));
   
    //vec3 sCol = .5 + .45*cos(TAU*rnd/6. + vec3(0, 1, 2)*1.1);
    //if(hash21(id + .02)<.5) sCol = sCol.zyx;
    //if(hash21(floor(id/vec2(1, 4)) + .02)<.5) sCol = sCol.zyx;
    //else sCol = min(sCol*sCol*1.6 + .03, 1.);
     
    
    //if(hash21(floor(id/vec2(1, 4)) + .03)<.5) sCol = vec3(.2)*dot(sCol, vec3(.299, .587, .114));
    //else sCol = min(sCol*sCol*2. + .03, 1.);
    
    
    // Flat bump mapping.
    float b = (max(dB, -.025) - max(d, -.025))/px;//.0125
    //b += (dB - d)/px/8.;
    b = max(.5 + b, 0.);
    sCol *= .5 + b;
    
      
    // Rough noise texture to even things out a little.
    vec3 tx = texture(iChannel0, dP/dt).xyz; tx *= tx;
    sCol *= tx + .75;
    
    // Field lines.
    //float fL = (abs(fract(d*30. - .5) - .5) - .1)/30.;
    //sCol *= smoothstep(0., sf, fL)*.9 + .2;
  
    
    d /= dt; // Divide by the derivative, after the bump calculations.

    
      
    // Scene color.
    //pp = abs(pp);
    vec3 col = vec3(0);//vec3(1, 2, 4)*max(1. - length(mUV)/dt, 0.);
    
    // Rendering onto the background.
    //
    //col = mix(col, sCol*0., 1. - smoothstep(0., sf, (d + .002))); // Top layer.
    
    float thF = sqrt(450./iResolution.y); // Thickness factor.
    col = mix(col, sCol, 1. - smoothstep(0., sf, d + .005*thF)); // Top layer.
    

    
    // Phone screen border.
/*    
    //col *= step(abs(uv.y - .5) - .49, 0.);
    //col *= step(abs(uv.x - .5) - .495, 0.);
    vec2 scDim = vec2(iResolution.x/iResolution.y, 1);
    float fr = sBoxS(uv, scDim/2., .05);
    vec3 svCol = col;
    col = mix(vec3(0), svCol*1.5, 1. - smoothstep(0., sf*4., fr + .0175));
    col = mix(col, svCol, 1. - smoothstep(0., sf, fr + .0175 + .0025));
*/   
    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./32.)*1.05;


    // Output to screen
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}