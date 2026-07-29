// Image (image) — Isometric Hexagon Cube Pattern by Shane
// https://www.shadertoy.com/view/tXcSzr

/*

	Isometric Hexagon Cube Pattern
	------------------------------
    
    This is a common isometric hexagon-based cube pattern that I've always
    been fond of. I see it every now and again, but I'm not sure where it 
    originated. However, a great deal of isometric art along these lines can 
    usually be traced back to the hand sketched Eschesque art of Regolo Bizzi, 
    so I suspect that's where this one came from. Although, it could be older
    than that.
    
    Obviously, a lot of the authenticity and magic dissipates when you subject 
    a geometric hand-sketched design to an algorithmic process, but the results
    can still look pretty interesting.
      
    Pixelshaders are probably not the best environment in which to produce 
    designs of this nature, but it can be done. In fact, I was expecting the 
    pattern to be more difficult to render than it was. Thankfully, it came 
    together pretty quickly. 
    
    Construction involved rendering six inner hexagon shaped boxes in a 
    circular fashion, then 12 outer ones for the next circular layer. 
    Positioning objects was simple enough, so the only thing left to do was 
    organize the rendering order.
    
    That involved determining which boxes were in front of which, then
    performing some simple CSG to cut away any obstructions. Rendering the box 
    faces and details was just a case of basic line partitioning. Coloring the 
    boxes required assigning six face IDs to six possible face orientations.
    
    In regard to efficiency, it's fine, but I wrote this from start to finish 
    in a rather brute force fashion, so there'd undoubtedly be better ways to
    approach it.
    
    
    
    
    Based on:

    Isometric math art sketch -- Regolo Bizzi
    https://br.pinterest.com/pin/74590937560960068/
    
    Isometric math art sketch -- Regolo Bizzi
    https://br.pinterest.com/pin/136656169925612756/
    

*/

// Subtle background animation. I realized at the last minute that 
// hitting the pause button would work too. :) 
#define ANIMATE

// Pertubate the coordinates. I did this to give some kind of moving paper 
// effect, but I'm not sure about it, so I've relegated it to an option.
#define PERTURB

// Render the outer boxes. This is more for debugging, but it can
// be helpful to see the rendering layers.
#define OUTER1
#define OUTER2


// Global scale.
const float gSc = 1./1.8;
 

// Face ID: The faces are oriented in 6 different directions, which
// are based on their layer and circularr position.
int getColID(int faceID, int i){

    int colID = 5;
    if((faceID + i*3)%3==2) colID = 3;
    if((faceID + i*3)%3==1) colID = 1;
    if((i&1)==0) colID -= 1;
    
    return colID;
}

vec3 getCol(int colID, vec2 pI, int faceID){
    
    // Debug shading.
    //float sh = 1. - float(faceID)/5.;
    //return vec3(sh*sqrt(sh)*.6);
   
    // Color based shading.
    float rnd = hash21(pI + float(faceID)/6. + .1) - .5;
    return .5 + .45*cos(TAU*float(5 - colID)/6./3.5 + rnd*.35 + vec3(0, 1, 2));

}

// Saving the background coordinates.
vec2 bgP;

// Spiral stiped background pattern.
vec3 bgPattern(vec2 p){

    
    vec2 sc = vec2(2, 1)/6.*gSc; // Scale.
    
    float tm = 0.; // Time.
    #ifdef ANIMATE
    p *= rot2(cos(iTime/6.)*TAU/96.);
    tm = iTime/32.;
    #endif 
    

    // Polar spiral coordinates.
    p = vec2((length(p)) - tm, fract(atan(p.y, p.x)/TAU + .25)*6.*gSc + length(p)/3.);
    
    // Save the background coordinates.
    bgP = p; 
    
    // Repeat lines.
    float iY = floor(p.y/sc.y);
    vec2 ip = floor(p/sc);
    p.y -= (ip.y + .5)*sc.y;
    
    

    
    // Polygon strips.
    float poly = abs(p.y) - sc.y/2.;// 
 
    vec3 ln3;
        
    // Polar wrapping.
    ip = mod(ip, vec2(4, 12.));
   
  
    // Variable width strips.
    poly += sc.y/4.*(hash21(vec2(2, ip.y) + .22)*.5 + .5);
    //poly = abs(poly + .016) - .016;    
     
    // Distance and ID.
    return vec3(poly, vec2(2, ip.y));
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // Aspect correct screen coordinates.
    vec2 res = iResolution.xy;
    vec2 uv = (fragCoord.xy - res.xy*.5)/res.y;
    
    // A bit of spherization. Interesting, but not for this example.
    //uv *= .9 + dot(uv, uv)*.5;
 
    
    // Global scale factor.
    const float sc = 1.;
    // Smoothing factor.
    float sf = sc/res.y;
    // Shadow factor.
    float shF = res.y/450.;
    
    // Scene rotation, scaling and translation.
    vec2 p = uv*sc; 
    
    
    // Coordinate perturbation. There's small rigid one to enhance the hand-drawn look, 
    // and a larger animated one to wave the image around a bit.
    vec2 offs = vec2(fbm(p*2.), fbm(p*24. + .35));
    vec2 offs2 = vec2(fbm(p*1. + iTime/4.), fbm(p*1. + .5 + iTime/4.));
    const float oFct = .005;
    const float oFct2 = .025;
    p -= (offs - .5)*oFct;
    #ifdef PERTURB
    p -= (offs2 - .5)*oFct2;
    #endif
 
   
     
    // Edge width.
    float ew = .004;
  
  
    // Background color.
    vec3 col = vec3(.3, .25, .2);
    // Background disc shadow.
    col = mix(col, col*.8, 1. - smoothstep(0., sf*shF*128., length(uv) - .32));
    
    // Background design and coloring.
    vec3 d3 = bgPattern(p);
   
    float rnd = hash21(d3.yz + .21);
    // Colored stripes to match the foreground. Too much, maybe.
    //vec3 sCol = .5 + .45*cos(TAU*rnd/3.5 + vec3(0, 1, 2));
    //sCol = mix(sCol*.7, col*1.2, .8);
    // Lighter stripes.
    vec3 sCol = col*1.2; 
    
    // Pattern application.
    vec3 svBg = col;
    col = mix(col, col*.8, 1. - smoothstep(0., sf*shF*12., d3.x));
    col = mix(col, col*.0, (1. - smoothstep(0., sf, d3.x)));
    col = mix(col, sCol, (1. - smoothstep(0., sf, d3.x + ew)));
    // Applying the background design whilst fading from the center.
    col = mix(svBg, col, smoothstep(.3, 1., length(uv)));
   
   
    
  
    // All the to polygon grouped together. It's used to create a silouette 
    // of the object.
    float polyTot = 1e5;
    
    
    // This is just a cute trick to avoid rendering all six arms of the 
    // design. Instead you obtain the polar segment number then render that.
    // In this case, due to overlap, you need to render the folowing segment 
    // as well, but it's still three times faster.
    //
    int k = int(mod(atan(p.x, p.y)/TAU*6. + .5, 6.));
        
    for(int i = k; i<k + 2; i++){
    
       
        
        // Inner hexagon.
        vec2 pI = rot2(float(i)*TAU/6. + TAU/12.)*vec2(-1, 0)*(gSc/3. - gSc/3./6.);
        float polyI = sdHex(p - pI, gSc/6. + gSc/3./6.);
        //
        // Inner hexagon mask.
        vec2 pI2 = rot2(float(i - 1)*TAU/6. + TAU/12.)*vec2(-1, 0)*(gSc/3. - gSc/3./6.);
        float polyI2 = sdHex(p - pI2, gSc/6. + gSc/3./6.);
        
        // Outer hexagon.
        vec2 pI3 = pI + rot2(float(i + 1)*TAU/6. + TAU/12.)*vec2(-1, 0)*(gSc/sqrt(3.)/2.);
        float polyI3 = sdHex(p - pI3, gSc/6. + gSc/3./6.);
        //
        // Outer hexagon mask.
        vec2 pI4 = pI2 + rot2(float(i)*TAU/6. + TAU/12.)*vec2(-1, 0)*(gSc/sqrt(3.)/2.);;
        float polyI4 = sdHex(p - pI4, gSc/6. + gSc/3./6.);
         
        // Between outer hexagon -- There are twice as many outer hexagons.
        vec2 pI5 = pI3 + rot2(float(i + 2)*TAU/6. + TAU/12.)*vec2(-1, 0)*(gSc/sqrt(3.)/2.);
        float polyI5 = sdHex(p - pI5, gSc/6. + gSc/3./6.);
        //
        // Between outer hexagon mask.
        vec2 pI6 = pI4 + rot2(float(i + 1)*TAU/6. + TAU/12.)*vec2(-1, 0)*(gSc/sqrt(3.)/2.);;
        float polyI6 = sdHex(p - pI6, gSc/6. + gSc/3./6.);
        //
        // Inner circle mask for these hexagons.
        vec2 pI2B = rot2(float(i + 1)*TAU/6. + TAU/12.)*vec2(-1, 0)*(gSc/3. - gSc/3./6.);
        float polyI2B = sdHex(p - pI2B, gSc/6. + gSc/3./6.);
 
////////
        
        // Used to create a silouette of the object -- Not part of the design.
        polyTot = min(polyTot, min(polyI, min(polyI3, polyI5)));
       

        // Masking. Order counts. 
        // Maskng can get confusing, but it's a simple process: If an object has
        // another one rendering over the top of it when it shouldn't, chop the
        // first object away from the second one, thus taking away its ability
        // to obscure.

        // Between outer. It needs to be behind of the outer object below it (polyI3)
        // and behind the inner object beside it. 
        #ifdef OUTER1
        polyI5 = max(polyI5, -polyI3); // Below.
        #endif
        polyI5 = max(polyI5, -polyI2B); // Beside.
        
        // Behind one of the inner and one of the outer objects.
        polyI3 = max(polyI3, -polyI); 
        #ifdef OUTER2
        polyI3 = max(polyI3, -polyI6); 
        #endif
        
        // Behind one of the inner and one of the outer objects.
        polyI = max(polyI, -polyI2); 
        #ifdef OUTER1
        polyI = max(polyI, -polyI4);
        #endif
     
      
        #ifdef OUTER1
        // If this outer polygon is nearer to the pixel, update
        // the distance field and position.
        if(polyI3<polyI){
            
            polyI = polyI3;
            pI = pI3;        
        }
        #endif
        
        #ifdef OUTER2
        // If this outer polygon is nearer to the pixel, update
        // the distance field and position.
        if(polyI5<polyI){
            
            polyI = polyI5;
            pI = pI5;        
        }
        #endif
        
/////////        
       
        
        
        // Hexagon to rhomboid partioning: Use three lines from the center
        // to every second vertex.
         
        vec3 ln3;
        
        // Every second segment has the opposite rhomboid partitioning, so
        // move to the vertices in between.
        float offs = (i&1)==1? 0. : PI/3.;
       
        for(int j = 0; j<3; j++){
            
            // Closest hexagon center to each vertex.
            vec2 pV2 = rot2(float(j)*TAU/3. + offs)*vec2(-1, 0)*gSc;
            ln3[j] = distLineS(p - pI, vec2(0), pV2); 
          
        }
        
        // Line trickery. On the right of the first line and left of the other.
        ln3 = max(ln3, -ln3.yzx);
        
        
        // Cube face ID. One of three visible faces.
        int faceID;
 
        // Vertices for the closest rhomboid.
        mat4x2 pV;
        
        for(int j = 0; j<3; j++){
            
            if(ln3[j]<0.){
                
                // Rhomboid distance.
                polyI = max(polyI, ln3[j]);
                
                // Vertices.
                float fj = float(j);
                vec2 pV1 = rot2(fj*TAU/3. + offs)*vec2(-1, 0)*gSc/4.;
                vec2 pV2 = rot2((fj + .5)*TAU/3. + offs)*vec2(-1, 0)*gSc/4.;
                vec2 pV3 = rot2((fj + 1.)*TAU/3. + offs)*vec2(-1, 0)*gSc/4.;
                
                pV[0] = pI;
                pV[1] = pI + pV1;
                pV[2] = pI + pV2;
                pV[3] = pI + pV3;
                
                // Rhomboid face ID.
                faceID = j;
                
                break;
            
            }
        
        }
        
        
        // There are six face directions, depending where the cube
        // is situated.
        int colID = getColID(faceID, i);
        // Color based on face ID.
        vec3 pCol = getCol(colID, pI, faceID);
     

         
        // Save the face color.
        vec3 svCol = pCol;
        
        // Block rendering.
        //col = mix(col, col*.8, (1. - smoothstep(0., sf*shF*8., polyI))); // AO
        col = mix(col, vec3(0), (1. - smoothstep(0., sf, polyI))); // Edge.
        col = mix(col, pCol, (1. - smoothstep(0., sf, polyI + ew))); // Color.
        
        // Faces with holes.
        if(((i + 1 + faceID*4)%6)/2==0){
        
            float ew2 = gSc/2.*.08;
             
            polyI += ew2;
        
            float dvLnC = distLineS(p, pV[0], pV[2]);
           
            // Opposite side wall color ID.
            if(dvLnC<0.){
                colID = getColID((faceID + 2)%3, i);
                //polyI = max(polyI, dvLnC);
            }
            else {
                colID = getColID((faceID + 1)%3, i);
                //polyI = max(polyI, -dvLnC);
            }
            
            // Inner face wall color.
            pCol = getCol(colID, pI, faceID);

            // Center line.
            pCol = mix(pCol, vec3(0), (1. - smoothstep(0., sf, abs(dvLnC) - ew/2.)));
     
            // Inner rhomboid rendering.
            col = mix(col, vec3(0), (1. - smoothstep(0., sf, polyI)));
            col = mix(col, pCol, (1. - smoothstep(0., sf, polyI + ew*1.5)));
          
            // Dark floor rhomboid.
            // Horizontal and vertical (relatively speaking);
            float hD = .6; // Relative hole depth.
            float dvLn1 = distLineS(p, mix(pV[0], pV[1], hD), mix(pV[3], pV[2], hD));
            float dvLn2 = distLineS(p, mix(pV[1], pV[2], hD), mix(pV[0], pV[3], hD));
            //
            polyI = max(polyI, max(dvLn1, dvLn2));
            // Floor rendering.
            col = mix(col, vec3(0), (1. - smoothstep(0., sf, polyI)));
            col = mix(col, svBg*.25, (1. - smoothstep(0., sf, polyI + ew*1.5)));
           
            
        
        }
 
    
    }    
    
    
    // Not really necessary, but evening up the outer silhouette lines,then adding
    // an outer shadow... I should have approache this in a different way, but
    // this will do.
    col = mix(col, col*0., 1. - smoothstep(0., sf, abs(polyTot - ew/2.) - ew/2.)); 
    col = mix(col, col*.8, 1. - smoothstep(0., sf*shF*6., abs(polyTot - .01) - .01)); 
    
    
    uv = fragCoord/iResolution.xy;
    
    // Gradient coloring.
    col = mix(col.xzy*1.4, col*1.3, uv.y*.5 + .5);
    
    // Discerning between the background and foreground coordinates that
    // will be passed into the sketch function.
    p = mix(bgP, p, 1. - smoothstep(0., sf, polyTot));
    
    vec3 sk = pencil(p, col);
    col = mix(col, colFunc(col, sk), .4); 
    
    
    // Vignette.    
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , 1./8.);

    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);;
}