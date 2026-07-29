// Image (image) — Favela by duvengar
// https://www.shadertoy.com/view/ldGcDh

// Favela by Julien Vergnaud @duvengar-2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
///////////////////////////////////////////////////////////////////////////////////////////
// Based on the Minimal Hexagonal Grid example from @Shane.


// Minimal Hexagonal Grid - Shane
// https://www.shadertoy.com/view/Xljczw
///////////////////////////////////////////////////////////////////////////////////////////////////

const vec2 s = vec2(1, 1.7320508);

float hex(in vec2 p)
{
    
    p = abs(p);
    
    return max(dot(p, s *.5), p.x );
}

vec4 getHex(vec2 p)
{  
 
    vec4 hC = floor(vec4(p, p - vec2(.5, 1)) / s.xyxy) + .5;

    vec4 h = vec4(p - hC.xy*s, p - (hC.zw + .5)*s);
 
    return dot(h.xy, h.xy)<dot(h.zw, h.zw) ? vec4(h.xy, hC.xy) : vec4(h.zw, hC.zw + vec2(.5, 1));
    
}
/////////////////////////////////////////////////////////////////////////////////////////////////////


#define M(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define S(a, b, c) smoothstep(a, b, c)
#define SAT(a) clamp(a, .0, 1.)
#define T iTime
#define PI acos(-1.)
#define TWO_PI (PI * 2.)
#define SIZE .4
#define BLUR .02
const float LOWRES = 50.;

float rem(vec2 iR)
{
    float slices = 10. * floor(iR.y / LOWRES);
  
    return  sqrt(slices);
}

float stripes( vec2 uv, mat2 rot, float num, float amp, float blr){
    
    uv *= rot;
    float v =  smoothstep(amp+blr, amp - blr,  length(fract(uv.x * num)-.5));
   // uv *= M(.02);
    float h =  smoothstep(amp+blr, amp - blr,  length(fract(uv.x * num )-.5));
    return h;
}

float dfDiamond (vec2 h) {
    h *= s;									// rescale diamond verticaly with the helper vector
 	vec2 p =  vec2(abs(h.x), abs(h.y));
    float d = (p.x+p.y)/.5; 
    //return S(.2,.9,length(d));
     return d;
}

float rect(vec2 uv,vec2 p, float w, float h, float b){
    
    uv += p;
    float rv = S(h, h + b, length(uv.x));
    float rh = S(w, w + b, length(uv.y));
    return rv + rh;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  
    
    
//  set up pixel coord
//  ------------------
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    //uv *= M(.25 * cos(PI) * .5 * length(uv));                     // twist the pixels domain
    uv *= 1.1;                                                   // scale up the pixels domain
   	uv *= M(PI);                                                 // rotate the pixels domain
    //uv *= .8+dot(uv*.3,uv*.3);                                   // length distortion

//  ------------------------------------------------------------------------------------------------
//  variables
//  ------------------------------------------------------------------------------------------------
    float motion =  T * .5;		   // speed
    float SCALE = rem(iResolution.xy)*SIZE;    // screen rescaling ratio
    //float blr = BLUR;				           // blur value
    float blr = fwidth(uv.x)*length(uv)*8.;
   // blr = S(.0,1.,length(uv)*.13);
    vec2 pos = uv - motion;					   // position
    vec3 lights = vec3(.0);
    vec3 blights = vec3(.0);
    float sun = cos(T*.3);
    
//  Hexagons grid
//  -------------
    vec4 h = getHex( pos + SCALE * uv + s.yx); // hexagons center
    float eDist = hex(h.xy);                   // hexagone Edge distance.   
	float eDist2 = hex(h.xy + vec2(.0,.25));
    float cDist = length(h.xy);                // @Shane: cDist = dot(h.xy, h.xy);  
    
    float tilt  = hash2(h.zw*2376.345791);     // random value depending on cel ids
    

//  ------------------------------------------------------------------------------------------------    
//  sorting the hexagons
//  ------------------------------------------------------------------------------------------------

    //  hexagons states booleans
//  ------------------------
    float hills = .0;
    float red = .0;
    float flip = .0;
    float empty = .0;
    float tex = .0;
	float wnds = .0;
    float tree = .0;
    float doors = .0;

//  wich tile are flipped?
//  ----------------------
    float ff = cos(5. * sin(h.z - h.w)*tilt);
    if( ff > .0)
    {
       flip = 1.;
       h.xy *= M(PI); 
       empty = ff > .99 ? 1. : .0;
    } 
        
        
//  polar coordinates + cubes faces angles
//  --------------------------------------
    vec2 pol  = vec2(atan(h.x, h.y) / TWO_PI + .5, length(uv));
    vec2 ang = vec2(.333333, .666666);
    
    if(pol.x <=  ang.x || tilt >= .7)
    { 
        wnds = 1.;
        if(tilt >=.9)
        {
            doors = 1.;
        }
    }
    
//  wich tiles are hills?
//  ---------------------
    if (flip == .0 && noise(h.zw)*.5 > .3){
    	hills = 1.;
        tree = tilt >.5 ? 1. : .0;
    }

//  ------------------------------------------------------------------------------------------------    
//  create the windows elements 
//  ------------------------------------------------------------------------------------------------    
    
   	vec2 pat = h.xy;                                                              // original position (up lozenge in the hexagon)
    vec2 pat2 = h.xy-(vec2(flip == 1. ? .05 : - .05,flip == 1. ? .03 : - .03));   // offseted and rotated position on the right side
    vec2 pat3 = h.xy-(vec2(flip == 0. ? .05 :  -.05, flip == 1. ? .05 : - .05));  // offseted and rotated position on the left side
     
    float s1 = stripes(pat, M(.0)*M(.02), flip == 1. ? 2.: 4., .3, blr );         // vertical stripes
    float s2 = stripes(pat, M(TWO_PI*.666)*M(.02), 4., .3, blr );                 // oriented stripes
    
    float s3 = stripes(pat, M(TWO_PI*.333 )*M(.02), 4., .3, blr );
    float s4 = stripes(pat, M(.0)*M(.02), flip == 1. ? 4.: 2., .3, blr );
    
    float m1 = stripes(pat2, M(.0)*M(.02), flip == 1. ? 2.: 4., .3, blr );
    float m2 = stripes(pat2, M(TWO_PI*.333 )*M(.02), 4., .3, blr );
    
    float ml1 = stripes(pat3, M(.0)*M(.02), flip == 1. ? 4.: 4., .3, blr );
    float ml2 = stripes(pat3, M(TWO_PI*.666)*M(.02), 4., .3, blr );
    
    float windowsR = min(s1,s3);                    // windows on the Right side
    float windowsL = min(s4,s2);                    // windows on the Left side
    
    float maskR = min(m1,m2);                       // offseted Right windows
    float maskL = min(ml1,ml2);                     // offseted Left windows
    
    float winnerR = min(windowsR, maskR);           // cuted Right inner windows
    float winnerL = min(windowsL, maskL);           // cuted Left inner windows
    
    float wbevelR = min(windowsR,windowsR-winnerR); // cuted Right bevel
    float wbevelL = min(windowsL,windowsL-winnerL); // cuted Left bevels
//  blured windows
//  --------------
    
    float blr2 = BLUR * 8.;
    float bs1 = stripes(pat, M(.0)*M(.02), flip == 1. ? 2.: 4., .3, blr2 );         // vertical stripes
    float bs2 = stripes(pat, M(TWO_PI*.666)*M(.02), 4., .3, blr2 );                 // oriented stripes
    
    float bs3 = stripes(pat, M(TWO_PI*.333 )*M(.02), 4., .3, blr2 );
    float bs4 = stripes(pat, M(.0)*M(.02), flip == 1. ? 4.: 2., .3, blr2 );
    
    float bm1 = stripes(pat2, M(.0)*M(.02), flip == 1. ? 2.: 4., .3, blr2 );
    float bm2 = stripes(pat2, M(TWO_PI*.333 )*M(.02), 4., .3, blr2 );
    
    float bml1 = stripes(pat3, M(.0)*M(.02), flip == 1. ? 4.: 4., .3, blr2 );
    float bml2 = stripes(pat3, M(TWO_PI*.666)*M(.02), 4., .3, blr2 );
    
    
    
    float bwindowsR = min(bs1,bs3);                    // windows on the Right side
    float bwindowsL = min(bs4,bs2);                    // windows on the Left side
    
    float bmaskR = min(bm1,bm2);                       // offseted Right windows
    float bmaskL = min(bml1,bml2);                     // offseted Left windows
    
    float bwinnerR = min(bwindowsR, bmaskR);           // cuted Right inner windows
    float bwinnerL = min(bwindowsL, bmaskL);           // cuted Left inner windows
       
//  ------------------------------------------------------------------------------------------------      
//  shading the cubes faces
//  ------------------------------------------------------------------------------------------------    

//  noise texture
//  -------------
    vec3 col = vec3(1.);
    float n1 = .5-(fbm(((uv -motion*.24)* 20.)));
    float n2 = .5-(fbm(((uv -motion*.31)* 5.)));
    col += .4 * (max(n1,n2));

    
//  painting
//  --------
    vec3 paint = vec3(cos(h.z + h.w *.2),cos(tilt)*.3,noise(h.zw));
     
//  lightning
//  ---------
    vec2 facespos = h.xy;
    facespos *= M(TWO_PI*ang.x);
    
    vec2 fa = facespos;
    float shw = .7 * S(1.1+ blr, 1.-blr, dfDiamond(facespos - (vec2(.0, .3))));
    facespos *= M(TWO_PI*ang.x);
    
    vec2 fb = facespos;
    shw += .2 * S(1.1+blr, 1.-blr, dfDiamond(facespos - (vec2(.0, .3))));
    col -= shw;
   
    
    float fao = clamp(smoothstep(1.,.0,eDist), .0, 1.);                  // Fake lightning gradient 
    //fao = hills == 1. ? fao * 1.5 : fao;
    fao = flip == .0 || empty == .1 ?  .65 * fao :  .65 * (1.-fao);                      // apply it as a shadow or light on the cubes
	col -= fao;
    col = mix(col,vec3(.7,.3,.0),.45);
  
//  face 01 (right)
//  --------------   
    if(pol.x <=  ang.x )
    {    
 		if ( hills == .0)
        {
        	col = tilt > .2  ? col :  col +.3 * paint ;
        	vec2 dir =  cos(T + h.z) > .0 ? M(PI/3.)*h.xy : -M(PI/3.)*h.xy;
        	float blink = S(1.,.9,fract(dir.x*2.)* 3.333 -.5)-.5;
   			
            float on = S(-1.,1.,sun);
            float light = (-1. + tilt * floor(on*10.) > .0 ? blink : -1.);
            light = empty == 1. ? -.5 : light;
            float lum = light > .0 ? -.1 : .3;
        
            col -= tilt > .0 ? lum * wbevelR : .0;
        	col += tilt > .0 ? light * winnerR : .0;
            
            
            lights += tilt > .0 ? light * winnerR : .0;
            blights += tilt > .8 && flip == 1.? light * bwinnerR : .0;
            
            float t1 = stripes(pat - vec2(.01,.0), M(.0)*M(.02), 8., .05, blr*2. );
        	float tt = stripes(pat - vec2(fract(M(-PI*.666)*pat*8.).x >.5 ? .20 : .01,.00), M(.0)*M(.02), 8., .05, blr*2. );
    	    float t2 = stripes(pat - vec2(-.19,.01), M(TWO_PI*.333)*M(.02),   16.  , .05, blr*2. );
            col += hills == .0 ? .1*(t2+tt)* pow(noise((uv-motion*.15)*20.),1.5) : .0;
            
            
        }
        else
        {
        	col = mix(col,vec3(.52,.13,.01), .5);   
   	    	col = mix(col, vec3(.5,.45,.1), 1.-S(.1,.3,length(h.y - fb.y)));
            
        }
    }
    
//  face 02 (left)
//  ---------------
    if(pol.x >= ang.y)     
    { 
        col += tilt > .2 ? vec3(.0) : .3 * paint ;
        vec2 dir =  cos(T + h.z) > .0 ? M(PI)*h.xy : -M(PI)*h.xy; 
        float blink = S(1.,.9,fract(dir.x*2.)* 3.333 -.5)-.5;
        float on = S(-1.,1.,sun);
        float light = .5*(-1. + tilt * floor(on*10.) > .0 ? blink : -1.);
        col = hills == 1. ? mix(col,vec3(.52,.13,.01), .5) : col;  
        col =  hills == 1. ? mix(col, vec3(.5,.45,.1), 1.-S(.1,.3,length(h.y - fa.y))) : col;      
        col += tilt > .8 && flip == 1. ? light * winnerL : .0;
        col += tilt > .8 && flip == 1. ? light*.3 * wbevelL : .0;
        lights += tilt > .8 && flip == 1.? light * winnerL : .0;
        blights += tilt > .8 && flip == 1.? light * bwinnerL : .0;
//      walls texture
        float t1 = stripes(pat - vec2(.01,.0), M(.0)*M(.02), 8., .05, blr*2. );
        float tt = stripes(pat - vec2(fract(M(-PI*.333)*pat*8.).x >.5 ? .20 : .01,.00), M(.0)*M(.02), 8., .05, blr*2. );
    	float t2 = stripes(pat - vec2(-.19,.01), M(TWO_PI*.666)*M(.02),   16.  , .05, blr*2. );
        
        col += hills == .0 ? .15*(t2+tt)* pow(noise((uv-motion*.15)*20.),1.5) : .0;
//      doors        
        vec2 pos1 = vec2(.25,.0);
        vec2 pos2 = vec2(.215,.0);
        float door = stripes(pat + pos1 , M(.0)*M(.02), 1., .05, blr);
        float doorcut = 1.-stripes(pat + pos1 , M(TWO_PI*.666)*M(.02), 1., .18, blr);
        float maskcut = 1.-stripes(pat + pos2 , M(TWO_PI*.666)*M(.02), 1., .18, blr);
        float doormask = stripes(pat + pos2 , M(.0)*M(.02), 1., .05, blr);
        door =  min(door,doorcut);
        doormask = min(doormask, maskcut);
        float dbevel = SAT(min(door,door-doormask));
        col += doors == 1. && flip == .0 && hills == .0 ? dbevel * .2 : .0;
        col += doors == 1. && flip == .0 && hills == .0? doormask * .4 : .0;
       
    }
    
    
//  face 03 (top)
//  -------------
    if(pol.x > ang.x && pol.x < ang.y)
    { 
        if (hills == 1.){
        col += .1 * vec3(.5,.45,.1); 
        float grass = 1.-S(1.1+blr, .5-blr, dfDiamond(h.xy - vec2(.0, .3)));
        col = mix(vec3(.5,.45,.1),col,1.-grass);     
        }
    }
    
//  face 04 (inside)
//  ----------------
    vec2 ang2 = ang + vec2(-.1665,.1665);
    if(pol.x  <= ang2.x  || pol.x >= ang2.y)
    { 
    }

//  trees  
//  -----
    
    if ( tree == 1.)
    {
        float tw = .07;
        float crown = S(.25+blr,.25,eDist2);
      
        float trunk = S(tw+blr, tw, hex(h.xy - vec2(.0, .0)));
        trunk = max(trunk,S(tw+(blr*.5), tw, hex(h.xy - vec2(.0, .5*tw*2.5))));
        trunk = max(trunk,S(tw+(blr*.5), tw, hex(h.xy - vec2(.0, .5*tw*5.))));
        trunk = max(trunk,S(tw+(blr*.5), tw, hex(h.xy - vec2(.0, .5*tw*7.5))));
		
        float a = pol.x < .5 ? 2.5 : .5 ;
        col = mix(col,vec3(.5,.3,.2),trunk*a);
        col = mix(col,vec3(.55,.6,.3),crown);  
        
        float shw = .2 * S(.5 + (blr*3.), .5 - blr, dfDiamond(fb + (vec2(.22, .02))));
        shw += .35 * S(.5 + (blr*3.), .5 - blr, dfDiamond(fa - (vec2(.22, -.02))));
        
        col -= shw;
        
    }
    if(hills == 1.0)
    {
    	col -= fao*.2;
    }    
//  Roof top
//  --------

    vec2 frh = fract(h.xy * 2.);
    float d1 = S(.8+blr, .8-blr, dfDiamond(h.xy - vec2(.0, flip*.3)));
    float d2 = S(.8+blr, .8-blr, dfDiamond(h.xy - vec2(.0, flip*.2)));
    
    if (hills == 1.)
    {
 		col  += .08*(.6-hash2(uv*34869.54334));      
    }
    
    if(hills == .0 && flip == 1.)
    {   
		if (empty == .0)
        {            
       		float shw = pol.x < .5 ? .33 : .15 ;
        	col -= shw *(d1-min(d1,min(d1,d2))); // inner bevel
            if( tilt > .7)
            {	
                vec2 wtp = vec2(.0,-.2);
                vec2 wtp2 = vec2(.0,-.58);
                vec2 wtp3 = vec2(.0,-.25);
            	float watertank = S(.02,.02-(blr*.5),dot(h.xy*s + wtp, h.xy*s + wtp));
                float watertanktop = S(.02,.02-(blr*.5),dot(h.xy*s + wtp2, h.xy*s + wtp2));
                float watertanktop2 = S(.016,.016-(blr*.5),dot(h.xy*s + wtp2, h.xy*s + wtp2));
                float watertankside = 1. - rect(h.xy, wtp3, .1,.125, blr);
                watertank = max(watertank,watertanktop);
                watertank = min(d1,watertank);
                watertankside = SAT(watertankside);
                float wtglobal = max(watertank, min(d1,watertankside));
                
                col = mix(col,vec3(.2,.32,.45),wtglobal);
                col -= watertanktop2 * .15;
                col += max(watertank,watertankside) * S(.0,.15,length(h.x-.05))*.15;
            } else {
            	if(tilt > .3 )
                {
                    vec2 fanpos = vec2(-.1,-.35);
                    float fan = S(.125,.125-blr,hex(h.xy + fanpos));
                    col = mix(col,vec3(1.),fan);
                    col = mix(col,.95*vec3(.9,.75,.6),fan);
                    float ff1 = dfDiamond(fa.xy + vec2(.35,.015));
                    float ff2 = dfDiamond(fb.xy - vec2(.255,-.19));
                    col -= vec3(.45*S(.26,.26-(blr*2.),ff1));
                    col -= vec3(.2*S(.26,.26-(blr*2.),ff2));
                }
            }
            
            
            
        } else {
            float shw = pol.x < .5 ? .4 : .15 ;
        	col -=  shw * d1;                    // empty houses
            
        }
    } 
     
    
    // postprocessing
    
    
    col /=1.1-.2;
    col += mix(.15 * S(.0,6.,length(uv*s)), -.8 * S(.0,6.,length(uv*s)), sun);
    col = clamp(col,vec3(.15), vec3(1.));
    vec3 day = col;
    vec3 night = col;
    night = mix(day, vec3(.2,.5,.9),.5);
    
    night = pow(night, vec3(3.));
    night += SAT(lights);
    night += SAT(blights)*4. ;
    
    vec3 final = mix(day,night,S(-1., 1.,sun));
    
    
    // color output

    fragColor = vec4(final,1.0);
}