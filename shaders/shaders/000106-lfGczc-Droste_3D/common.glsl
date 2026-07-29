// Common (common) — Droste 3D by Shane
// https://www.shadertoy.com/view/lfGczc

// Distance metric: Circle: 0, Square: 1, Superellipxe: 2, 
// Hexagon: 3., Octagon: 4.
#define METRIC 1


// I put this in as an afterthought to show that this process will
// work with natural logarithms (log), and the "power of 2" type (log2).
// Of course, the natural log version looks more natural, but the 
// "power of 2" version has a kind of quirky distorted charm.
//
// Log type: Natural (log): 0, Power of 2 (log2): 1
#define LOG_TYPE 1


float distMetric(vec2 p, vec2 b){

    p = abs(p);
     
    #if METRIC == 0
    return length(p) - b.x;
    #elif METRIC == 1
    return max(p.x, p.y) - b.x;
    #elif METRIC == 2
    float sEF = 8.;//1./1.15; // Superellipse factor.
    return pow(dot(pow(abs(p), vec2(sEF)), vec2(1)), 1./sEF) - b.x;
    #elif METRIC == 3
    return max(p.x*.8660254 + p.y*.5, p.y) - b.x;
    #else
    return max(max(p.x, p.y), (p.x + p.y)*.7071) - b.x;
    #endif
}


#if LOG_TYPE == 1
#define Log log
#define Exp exp
#else 
#define Log log2
#define Exp exp2
#endif

// 2 times PI.
#define TAU 6.2831853

// The scale. Range [0, 1], with ".5" being the preferred default. 
//
// Visually, the scale is analogous to a winding or twisting factor.
// Lower numbers twist less, and larger ones twist more. For me, it 
// represents the scale between successive spiral blocks.
const float scale = .32;

// The cyclic spiral expansion transform, more commonly referred
// to as the Droste transform.
vec2 DrosteTransform(vec2 uv, float tm){
     
    // Log polar coordinates They're like regular polar coordinates,
    // but with a radial logarithmic factor.
    uv = vec2(Log(length(uv)), atan(uv.y, uv.x));
    
    
    // Number of spiral arms. Non-negative ntegers only. Setting this to zero
    // will result in zero spirals. Visually, just concentric shapes.
    const float spiralN = 1.;
    
    // The logarithmic radial scale. You can incorporate the spiral arms into
    // this calculation "scF = log(pow(scale, -spiralArms))", but I prefer to 
    // include the spiral arms inside the spiral rotation matrix. 
    //
    // By the way, the value, "scF", is actually negative, so I've negated 
    // the two terms in the middle of the spiral matrix to account for this. 
    // In the end, it doesn't really matter, because reversing signs simply 
    // reverses the spiral direction.
    const float scF = Log(scale); //float scF = Log(pow(scale, -arms)); 
    
    // Log spiral rotation: Oddly enough, the best way to see what this line
    // does is to comment it out. :) 
    // 
    // "scF/TAU" is analogous to one radial unit every time we loop
    // around by TAU (2*PI).
    // 
    uv *= mat2(1, -spiralN*scF/TAU, spiralN*scF/TAU, 1);
 
    // Converting to cartesian coordinates. At the same time, we're
    // animating the radial coordinate from the center to the maximum
    // radial length, "scF" before snapping back to the center. It's 
    // a pretty common infinite zoom animation move.
    uv = Exp(mod(uv.x - tm/2., scF))*vec2( cos(uv.y), sin(uv.y));
 

    // Using the coordinates above do obtain a distance in the form of
    // any distance metric you like. Squares and circles are common, but 
    // there are other options, like a superellispse, which I rarely see.
    float shape = distMetric(uv, vec2(0));
 
   
    // Determine which block the spirally shaped pixel belongs to 
    // then adjust the scale accordingly. 
    //
    // Obviously, larger shapes correspond to larger images. A smaller 
    // image block will spiral around to meet the next larger one.... 
    // Simple enough to understand, but I'm glad I wasn't someone like 
    // Escher trying to figure this all out by hand - Quite amazing.
    //
    // The coordinates are segmented by non-linear "log(scale)" increments, 
    // so there's some log related division and power scaling involved. 
    // By the way, this all works with other log systems, like "log 2", 
    // but the natural log system looks more natural, strangely enough. :)
    //
    // Natural log calculation.
    float nP = pow(scale, floor(Log(shape)/scF));
    //
    // I've seen people use the following expression, which will 
    // work if you get lucky and the integers line up. In general 
    // though, you should use the above expression.
    //float nP = exp2(floor(log2(shape/scale)));
   
    // We only want half the distance, so take that into account.
    return uv/nP/2.;    
    
}

