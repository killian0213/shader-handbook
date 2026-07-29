// Image (image) — Hyperbolic Poincare Disc Sketch by Shane
// https://www.shadertoy.com/view/tsffDl

/*
    
    Hyperbolic Poincare Disc Sketch
    -------------------------------
    
    Yet another tessellation of a hyperbolic Poincare disc. I put a rough 
    version of this together when making my animated hyperbolic weave shader. 
    I was happy enough with that example, but I made it in a hurry, so it
    contained magic numbers that only worked for a couple of tessellation
    configurations.
    
    This one contains proper setup calculations and should work for all the 
    workable Schlafli numbers that are associated with these kinds of things. 
    
    I've always admired those hand drawn pencil and compass renderings of
    Poincare disc tessellations, so I thought it might be cool to emulate 
    that, but also include things that might be a little difficult to 
    physically draw, like intricate weaves, faux lighting, and so forth. I 
    can thank one of MLA's comments for the necessary line-width adjustments 
    that enabled me to render with roughly constant pencil widths. Variable 
    width lines look interesting in their own right, but don't help with that 
    hand drawn look.
    
    I've also managed to randomly color the individual hyperbolic polygons.
    However, I had to forego the fast angular partition method and use the 
    longer one that involves checking each polygon side. This means rendering 
    can be slower for larger polygon sizes. Having said that, it's not common 
    to go above about 8 sided polygons and the default is a 3 sided triangle,
    so virtually all machines will handle this just fine. If coloring is not
    a priority, then there are faster methods to use for sure.
    
    I've included a few compiler options below for anyone who wants to 
    experiment with the look. Adding all those compiler directives blew the
    code out a bit, but the bulk of it is dress-up. The tessellation part 
    itself is fairly minimal.
    
    
    
    Other examples:
    
    // A multiconfiguration hyperbolic weave. This is more MLA's thing,
    // so he's using fancier methods. :)
    Hyperbolic Weave - mla
    https://www.shadertoy.com/view/XcX3DB
    
    // An animated hyperbolic weave. It works just fine, but I need
    // to replace a couple of magic numbers in there.
    Poincare Disc Animation - Shane
    https://www.shadertoy.com/view/mlGfzV
    
    // A Truchet like weave using Bezier curves.
    Hyperbolic Poincare Weave - Shane
    https://www.shadertoy.com/view/tljyRR


*/

// Weave types, are no weave, inner weave, outer weave, or fulll screen.
// 0: No weave, 1: Inner weave, 2: Outer weave, 3: Full screen.
#define WEAVE_TYPE 2

// Bump mapping the weave.
#define BUMP

// Give it a rough hand drawn look.
#define PENCIL

// Just an animated color effect.. It needs work, but it's interesting
// and it has potential. In fact, I'm going to focus on it in another
// example later. 
//#define ANIMATE_COLOR

// Making everything look like it was projected onto the 
// surface of a sphere. I've left it here for my own benefit, 
// since I intend to do something with it later.
//#define SPHERIZE


// Schlafli symbols.
// It will work provided: 1/P + 1/Q < 1/2.
#define P 3 // Number of polygon sides.
#define Q 7  // Number of polygons surrounding each vertex point.

// PI and 2PI.
#define PI 3.14159265358979
#define TAU 6.283185307179

// Real and imaginary vectors. Handy to have.
#define R vec2(1, 0)
#define I vec2(0, 1)


// Common complex arithmetic functions.
vec2 conj(vec2 a){ return vec2(a.x, -a.y); }

vec2 cmul(vec2 a, vec2 b){ return mat2(a, -a.y, a.x)*b; }

vec2 cinv(vec2 a){ return vec2(a.x, -a.y)/dot(a, a); }

vec2 cdiv(vec2 a, vec2 b){ return cmul(a, cinv(b)); }

vec2 cInvert(vec2 p, vec2 o, float r) {
    p -= o;
    return (p)*r*r/dot(p, p) + o;
}


// Hyperbolic translation.
vec2 hyperTrans(vec2 p, vec2 o){
    return cdiv(p - o, cmul(-conj(o), p) + vec2(1, 0));
}

// Line intersection.
vec2 lnIntersect(vec2 p0, vec2 p1, vec2 p2, vec2 p3){
    
    float detD = determinant(mat2(p1, p3));
    if(detD == 0.){
        return vec2(0);
    }
    float detN = determinant(mat2(p2 - p0, p3));
    float l1 = detN/detD;
    return p0 + l1*p1;
}

// Circle inversion across the hyperbolic line between "a" and "b".
vec2 hyperLine(vec2 a, vec2 b){
    
    
    vec2 a1 = a/dot(a, a); //cinv(conj(a));
    vec2 b1 = b/dot(b, b); //cinv(conj(b));
    
    vec2 p1 = (a + a1)/2.;
    vec2 p2 = (b + b1)/2.;
    
    // Get Intersection.
    return lnIntersect(p1, vec2(-a1.y, a1.x), p2, vec2(-b1.y, b1.x));
}

 

vec3 initDomain(){
    
    // We need three distances (see below). This is a geometrical solution 
    // based on adjoing hyperbolic polygons that I wrote a while back. I can't 
    // remember how I got it, but it works, so I guess it doesn't matter.
    // Either way, refer to the links below, if you'd like to know more about it:
    //
    // The Hyperbolic Chamber - Jos Leys
    // http://www.josleys.com/article_show.php?id=83
    //
    // I also find the imagery on the following page helpful as well:
    // http://www.malinc.se/noneuclidean/en/poincaretiling.php
    
    float a = sin(PI/float(P)), b = cos(PI/float(Q));
	float d2 = cos(PI/float(P) + PI/float(Q))/a;
	float r2 = 1./(b*b/a/a - 1.); // Adjacent polygon radius (squared).
	
    // Distance between adjacent polygon centers, the adjacent polygon radius,
    // and the current polygon radius. We're assuming no negatives, but I'm 
    // capping things above zero, just in case.
	return sqrt(max(vec3(1. + r2, r2, d2*d2*r2), 0.));  
}


vec2 v[P]; // Polygon vertices.
vec2 e[P]; // Polygon edges.
vec2 mCir[P]; // Circles that cut the mid edges.
vec2 cir[P]; // Circles that form the polygon boundaries.


float cR; // Hyperbolic boundary circle radius.
float mCR; // Mid edge circle radius.

vec2 id; // Polygon ID.
vec2 cntr; // Overall polygon center.

vec2 hyperbolic(vec2 p){


    int hit; // Polygon hit flag.
    int iter = 0; // Inversive flip count, for want of a better description. :)
     
    // ID. Normally set to zero, but I accidentally left the negative one
    // there, which gives the center polygon a nice green color, so I'm 
    // leaving it. :)
    id = vec2(0, -1);
    
    // The polygon center. Redundant here, but I'm leaving it in.
    cntr = vec2(0);
    
     
    // Polygon distance... Too wastefull. It's better 
    // to calculate it later.
    //float gD = 1e5;
   
    for(int j = 0; j<20; j++){
        
        // Flag a polygon hit.
        hit = 1; 
        
        // Polygon distance... Too wastefull. It's better 
        // to calculate it later.
        //float d = -1e5;
        
        //int i = j%P;
        for(int i = 0; i<P; i++)
        {
        
            // Fractional angular solution... Unfortunately there 
            // are color wrapping problems involved... However if
            // using a single color, this is considerably faster
            // for polygons with larger numbers of sides.
            //float ii = floor(fract(atan(p.y, p.x)/TAU)*float(P));
            //int i = int(ii)%P;
             
            float circ = length(p - cir[i].xy) - cR;
           
            // Construction the polygon on the fly.
            //d = max(d, -circ);
            
            // If we're outside the hyperbolic polygon edge boundary,
            // perform a circle inversiom across the boundary. Once we've
            // done that, we can try again until we eventually reach the
            // polygon -- or the fundamental region, if you prefer that 
            // terminology.
            //
            // It can get a bit confusing, but this means we're outside one of 
            // the hyperbolic lines surrounding the polygon, which is constructed 
            // from the circle edge of the adjoing polygon. Therefore, if we're 
            // inside the adjoing polygon circle, then we're outside the polygon 
            // we're interested in... If I haven't done this for a while, I'll 
            // forget this basic fact every... single... time. :D
            if(circ<0.){
               
                
                hit = 0; // Outside the boundary, so flag a miss.
                
                // Perform the circle inversion across the boundary.
                p = cInvert(p, cir[i], cR);
                // Obtaining a central position ID. 
              
                // Performing an inversion on the center. Doesn't seem
                // to work for odd number sides anyway, but I'll try to
                // change that later.
                cntr = cInvert(cntr, cir[i], cR);

                // Set an ID for coloring purposes. A positional ID would be
                // more preferrable.
                id = vec2(i, j) + 1.; 

                // Increase the circular inversion count by one. This number
                // can be useful for all kinds of things.
                iter++;
          
            }
             
        } 
        
       
        // If we're inside the polygon, break and render it.
        if(hit==1){
           
           // Retrieving the polygon on the fly.
           //gD = min(gD, d);
           break;
           
        }

        
    }
    
    // Flip and rotate every alternate polygon in order to match
    // weave lines... if we're rendering them.
    if(iter%2 == 0){
        p.y = -p.y;
        p = rot2(float(P/2)*TAU/float(P))*p; // Needed for alignment.
          
    }
    
    return p;
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
 
    // Screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    
    // Perturbing coordinates for that unpredictable hand-drawn feel.
    #ifdef PENCIL
    vec2 offs = vec2(fbm(uv*16.), fbm(uv*16. + .35));
    const float oFct = .0025;
    uv -= (offs - .5)*oFct;  
    #endif


    // If the configuration doesn't tile, return te blue screen
    // of death. I can't remember whose example I got this from,
    // but I'll track it down later. :)
    if(1./float(P) + 1./float(Q)>=.5 || (Q==1 && P>=3)){
       fragColor = vec4(0, 0, 1, 0);
       return;
    }
    
    
    // Scaling factor. Enough to reduced the size of the disc
    // to a little under halp the screen height.
    float sc = 2.4; 
    
    // Smoothing factor.
    float sf = sc/iResolution.y;
    
     
    // The original Euclidean coordinates. The only thing to decide here
    // was whether to use the letter "p" or "z", which complex analysis
    // folk like to use.
    vec2 p = uv*sc;
    
    

    
    // The disc itself.
    float disc = length(p) - 1.;
    

    
    // There is an additional scaling\smoothing factor associated with 
    // hyperbolic disc calculations. I remember really overcomplicating
    // the process, but it turned out to be pretty simple, which was the
    // boundary length minus the inversion factor. This one has been flipped
    // at the boundary to accomodate values outside as well. By the way, 
    // I can thank one of MLA's comments for helping me figure out the 
    // obvious. :)
    float dfF = abs(1. - dot(p, p));
    

    
    #ifdef SPHERIZE
    // Spherization experiment... It needs work.
    if(disc<0.){
     
        #if 1
        vec3 p3 = vec3(p, -sqrt(1. - dot(p, p)));
        p = p3.xy/(1. - p3.z);
        #else
        // According to MLA, this is a Beltrami-Klein transform.
        // I can't tell the difference.
        p *= (1. - sqrt(1. - dot(p, p)))/dot(p, p);
        #endif
        
        // Readjusting the smoothing factor to accommodate the sphere.
        // Pressed for time... Kind of, but not quite... It'll do. :)
        dfF /= abs(1. - dot(p, p))/sqrt(2.);
    }
    #endif 
    

    // Mouse translation.
    vec2 ms = (iMouse.xy - iResolution.xy*.5)/iResolution.y*sc;
    if(abs(length(ms) - 1.)<.07) ms = vec2(1., ms.y); // Hacky border correction.
    p = hyperTrans(p, ms);
 
    
    // Rotation... after the mouse movement.
    p *= rot2(-iTime/8.);
    
    
        
    // Performing an inversion outside the
    // unit disc boundary. 
    if(dot(p, p) > 1.){
        p /= dot(p, p); 
       
    }
  
    // Keep a copy of the coordinates prior to hyperbolic tessellation.
    vec2 oP = p;
    
    
     
    

    // Calculate the necessary hyperbolic polygon infomation.
    vec3 info = initDomain(); 
    float r = info.z; // The current polygon radius.
    float eR = info.x - info.y; // Edge length.
    float aR = info.x + info.y; // Arc length.
    

    for(int i = 0; i<P; i++){
        float angV = float(i)*TAU/float(P);
        float angE = (float(i) + .5)*TAU/float(P); 
        v[i] = vec2(cos(angV), sin(angV))*r; //i+3
        e[i] = vec2(cos(angE), sin(angE))*eR;
    }
    
    for(int i = 0; i<P; i++){
        cir[i] = hyperLine(v[i], v[(i + 1)%P]);
        mCir[i] = hyperLine(e[i], e[(i + 1)%P]);
     }
    
    // Due to symmetry, the radii of all the surrounding inverted circles is the same
    // and equal to the distance between one of the vertices and any circle center.
    cR = length(v[0] - cir[0]);
    
    // Mid edge circle radius.
    mCR = length(e[0] - mCir[0]);
 
    // Hyperbolic highlighting samples
    #ifdef SHOW_WEAVE
    // Highlight sample. 
    vec2 pHi = hyperbolic(p - vec2(1, -1)*.001);
    #else 
    #ifdef BUMP
    // Highlight sample. 
    vec2 pHi = hyperbolic(p - vec2(1, -1)*.001);
    #endif
    #endif
    
    // Hyperbolic tessellation. The process can do your head in if
    // you're new to it, but it's actually quite simple.
    p = hyperbolic(p);
     
     
    // The hyperbolic polygon and nearby sample. 
    float poly = -1e5; 
    float polyHi = -1e5;
     
    // Vertices, edge points, and border lines.
    float vert = 1e5, edge = 1e5, ln = 1e5;
    
    // Nearby vertex and edge samples.
    float vertHi = 1e5, edgeHi = 1e5;
    

    // The mid edge lines that make up the weave.   
    float arc[P];
    float arc2[P];
    
    for(int i = 0; i<P; i++){
    
        // The circle in the adjacent polygon that cuts a
        // border out of the hyperbolic polygon.
        float polyBorder = length(p - cir[i]) - cR; 
        poly = max(poly, -polyBorder);
        
        // Polygon bump map samples.
        // There's probably a better way to use the compiler
        // directives, but this will do.
        #ifdef SHOW_WEAVE
        polyBorder = length(pHi - cir[i]) - cR; 
        polyHi = max(polyHi, -polyBorder);
        #else 
        #ifdef BUMP
        polyBorder = length(pHi - cir[i]) - cR; 
        polyHi = max(polyHi, -polyBorder);
        #endif
        #endif

        vert = min(vert, length(p - v[i]));
        edge = min(edge, length(p - e[i]));

        arc[i] = length(p - mCir[i].xy) - mCR;
        //arc[i] -= .03; // Offset pattern.
        
        // Weave bump map samples.
        #ifdef SHOW_WEAVE
        arc2[i] = length(pHi - mCir[i].xy) - mCR;
        //arc2[i] -= .03; // Offset pattern.
        #else 
        #ifdef BUMP
        arc2[i] = length(pHi - mCir[i].xy) - mCR;
        //arc2[i] -= .03; // Offset pattern.
        
        vertHi = min(vertHi, length(pHi - v[i]));
        edgeHi = min(edgeHi, length(pHi - e[i]));
        #endif
        #endif
        
        
        
     }
    
    
    //poly = gD;
    
    /*
    // Experiments with holes.
    if(disc>0.){
       poly = max(poly, -(length(p) - eR*.7));
       polyHi = max(polyHi, -(length(p) - eR*.7));
       
    }*/
   
    vert *= dfF;
    edge *= dfF;
 
    poly *= dfF;
    polyHi *= dfF;
   
    
    vert -= .04*sqrt(dfF);
    edge -= .04*sqrt(dfF);
    vertHi -= .04*sqrt(dfF);
    edgeHi - .04*sqrt(dfF); 
    
    // Edge width. Add a bit of leeway for resolution.
    float ew = clamp(450./iResolution.y*.01, .007, .013);
    // Custom border scaling. The manner in which you
    // scale the sizes is up to you.
    ew *= smoothstep(0., .05, dfF);


    float shd = clamp(-poly*8., 0., 1.);

    float ic = hash21(id); // Random color.
    //float ic = length(cntr) + .55; // Alternate center distance coloring.
    // Cell number. Used for aditional coloring.
    float ia = floor(fract(atan(p.x, p.y)/TAU - .25)*float(P))/float(P);
    
    // Polygon color.
   
    #ifdef ANIMATE_COLOR
    vec4 pCol = .5 + .45*cos((ic/6. + ia/8.)*TAU + vec4(0, 1, 2, 0)*1.6);
    vec4 gr = vec4(1)*dot(pCol, vec4(.299, .587, .114, 0));
    //if(hash21(id + .12)<.78) pCol = gr/3.;
    //float rndT = dot(sin(cntr*1.5 + iTime - cos(cntr.yx*3.5 - iTime*2.)), vec2(.25)) + .5;
    //float rndT = hash21(id  + .13);
    float rndT = length(cntr);
    if(disc<0.) pCol = mix(gr/3., pCol.yxzw, 
                smoothstep(.2, .4, sin((rndT + ia/12.)*TAU - iTime*3.)*.5));
               
               //smoothstep(.7, .9, sin((rndT + ia/12.)*TAU - iTime*2.)*.5 + .5)
               //smoothstep(.25, 1., rndT)
    else pCol = gr/3.;
    //pCol = mix(pCol, pCol.xzyw*1.5, rndT);//1. - smoothstep(.3, .7, abs(disc))
    #else
    vec4 pCol = .5 + .45*cos(6.2831589*(ic + ia/12.) + vec4(0, 1, 2, 0)*1.6);
    #endif
    
    //pCol = mix(pCol, gr, smoothstep(.33, 1., disc));

    #ifdef BUMP
    float bump = max(polyHi - poly, 0.)/.001*.7;
    pCol *= .95 + bump/dfF*.1;
    #endif
    
    // Background.
    vec4 col = vec4(0);

    // Polygon, rendered in a bit to show some edging.
    col = mix(col, pCol, 1. - smoothstep(0., sf, poly + ew));

    // Center circles.
    //col = mix(col, vec4(0), 1. - smoothstep(0., sf, (length(p) - ew*2.)*dfF));
 
    // Debug testing. 
    //col = mix(col, vec4(0), 1. - smoothstep(0., sf, length(oP - cntr)*dfF - .02));
   
    // Shadow factor. Faux 2D shadows cast different, depending on resolution.
    float shF = iResolution.y/450.;
    
    // More last minute edge tapering.
    float eT = (smoothstep(0., .5, abs(disc))*.8 + .2);
    
    // Weave and vertex color.
    #ifdef ANIMATE_COLOR
    vec4 lCol = min(pCol*2. + .15, 1.);
    #else
    vec4 lCol = min(pCol*8. + .15, 1.);
    #endif
    
    // Weave types, are no weave, inner weave, outer weave, or fulll screen.
    #if WEAVE_TYPE>0
    
    #if WEAVE_TYPE == 1
    if(disc<0.){
    #elif WEAVE_TYPE == 2
    if(disc>0.){
    #else
    #endif
     
        // Rendering the weave pattern.
        float arcW = .035*pow(3./float(P), .25);
        arcW *= (.2 + smoothstep(0., .5, abs(disc))*.8)/dfF;


        // Hyperbolic mid-edge arc lines.
        for(int j = 0; j<P + 1; j++){

            // This is a cute trick to render one extra half line over
            // the top of the weave. CSG doesn't quite work, due to the way
            // cut-out objects render shadows.
           if(j==P && (p.x + 0.<0.)) break;

            int i = j%P;


            // The line.
            float lnI = arc[i];
            #ifdef BUMP
            float sh = max(abs(arc2[i]*dfF*eT) - abs(lnI*dfF*eT), 0.)/.001;
            #else
            float sh = .5;
            #endif
            
            lnI *= dfF;
            lnI = abs(lnI) - arcW*dfF;


            // Shadow, edges and fill color.
            col = mix(col, col*.5, (1. - smoothstep(0., sf*shF*6., lnI)));
            col = mix(col, vec4(0), 1. - smoothstep(0., sf, lnI));
            col = mix(col, lCol*(sh*.5 + .75), 1. - smoothstep(0., sf, lnI + .0125*eT));
            #ifdef BUMP
            col = mix(col, lCol*.65, 1. - smoothstep(0., sf, abs(arc[i])));
            #endif
            

        }
    
    #if WEAVE_TYPE != 3
    }
    #endif

    #endif
    
    
    #ifdef BUMP
    float dir = disc<0.? -1. : 1.;
    float sh = max(dir*(vert - vertHi), 0.)/.001*.7;
    float sh2 = max(dir*(edge - edgeHi), 0.)/.001*.7;
    sh *= eT/dfF;
    //sh2 *= eT;
    #else
    float sh = 1.;
    float sh2 = 1.;
    #endif
   
    // Vertices.
    col = mix(col, col*.75, (1. - smoothstep(0., sf*shF*8.*eT, vert)));
    col = mix(col, vec4(0), 1. - smoothstep(0., sf, vert));
    col = mix(col, lCol*(sh*.5 + .75), 1. - smoothstep(0., sf, vert + ew*1.5));

    // Edges.
    //col = mix(col, vec4(0), 1. - smoothstep(0., sf, edge));
    //col = mix(col, lCol*(sh2*.5 + .5), 1. - smoothstep(0., sf, edge + ew*1.5));
    
    
    #ifdef PENCIL
    // Subtle pencel overlay... It's cheap and definitely not production worthy,
    // but it works well enough for the purpose of the example. The idea is based
    // off of one of Flockaroo's examples.
    vec2 q = p*4.;
    vec3 colP = pencil(col.xyz, q*iResolution.y/450.);
    col.xyz *= colP*1.25 + .5; 
    //col.xyz = colP; 
    #endif 
    
    
    fragColor = sqrt(max(col, 0.));
}

 
 
