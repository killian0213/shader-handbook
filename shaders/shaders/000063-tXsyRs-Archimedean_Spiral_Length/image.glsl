// Image (image) — Archimedean Spiral Length by Shane
// https://www.shadertoy.com/view/tXsyRs

/*

    Archimedean Spiral Length
    -------------------------
    
    Calculating the length of an Archimedean spiral in order to partition 
    it into evenly dispersed cells.
    
    Spirals are a bit of a cliche amongst graphics coders, but I like them. 
    They're popular because they're interesting and easy to make. The thing 
    I don't see so much is partitioning of the spiral length into blocks of 
    equal width. I'm not sure why, because it only involves a few extra lines.
    
    It would have been nice to partition a spiral using other curve metrics. 
    However, determining the length of something resembling a superelliptical 
    spiral, and so forth, seemed to involve more time than I was willing to 
    put in. If anyone else manages to do that, I'd love to see it. :)
    
    The plan is to eventually put together a raymarched version. I'm still 
    considering whether a traversal is worth the effort, since a ray
    intersection (analytic or numeric) with a spiral wall might not be
    feasible inside a large loop... unless there was some cute trick I could
    employ. Either way, I'd need to try it to find out.
    
    
    
    Other examples:
    
    
    // This is a nicely parameterized Archimedean spiral. There might be 
    // others, but it was the only partitioned spiral length shader I could 
    // find on here -- Calculating the Archimedean spiral length is a fairly 
    // common task, so I thought there'd be more. Anyway, it was great having 
    // a working example to check my figures against. By the way, Mrange has 
    // a lot of nice shaders on here, for anyone who hasn't seen his work. 
    //
    Spiral "domain mapping" -- mrange
    https://www.shadertoy.com/view/fsffDS
    
    
    // A different kind of spiral. Mesmerizing and beautiful to watch. 
    // I know of a really cool 3D demonstration based off of this that 
    // I'd like to make at some stage.
    //
    Golden Ratio and Spiral -- iq
    https://www.shadertoy.com/view/fslyW4
    
*/

/////////////

// Color scheme - Spectrum: 0,  Greenish blue: 1, Blue: 2, Terracotta: 3.
#define COLOR 0

// Apply bump mapping.
#define BUMP_MAP

// Using the spiral edge to provide some subtle shadows.
// Faux edge shadowing to give the spiral a slightly raised look.
#define SHADOW

// Subtle texturing.
#define TEXTURE

// Rivot holes.
#define HOLES

// Render lines inside the brightly colored cells.
//#define RANDOM_LINES

//////////////

// PI and 2PI.
#define PI 3.14159265358979
#define TAU 6.28318530718

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Dave Hoskins's hash function.
float hash21(vec2 p){

    p = fract(p*vec2(328.523, 456.245));
    p += dot(p, p + 45.327);
    return fract(p.x*p.y);
}

// IQ's 2D box formula.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
}

//////////////


// Spiral scale.
vec2 scl = vec2(4, 1)/15.;
 
// Globbal cell ID and local coordinates.
vec2 gIP;
vec2 gP;  

 
// The total length the spiral travels from the center to the
// arc angle prescribed by the spiral at a particular point.
//
// There are several derivations of the spiral length, which 
// involve integrating the partial angular distance between the 
// zero point and the angle described above.
float spLength(float ang, float rScale){
    
    // Rough approximation to the length.
    //return ang*ang*rScale/TAU/2.;    
    
    //float l = sqrt(1. + ang*ang);
    //return (ang*l + log(ang + l))*rScale/TAU/2.;
    
    // Equivalent to the expression above. I don't know which one
    // is faster, but this is shorter, so it looks faster. :D
    return (ang*sqrt(1. + ang*ang) + asinh(ang))*rScale/TAU/2.;   
}

/*
// Spiral curvature.
float curvature(float ang, float rScale){

    return (ang*ang + 2.)/(pow(ang*ang + 1., 1.5)/rScale/TAU);
}
*/ 

 
// The classic Archimedean spiral: spiral = radialLength + angle*scale.
//
// The Y-coordinate is the radial distance broken into repeat segments.
// The X-coordinate is the spiral length broken into repeat segments.
//
vec2 spiral(vec2 p) {

    // Pixel angle.
    float a = atan(p.y, -p.x)/TAU;
    // Archimedean spiral.
    p.y = length(p) - a*scl.y;
    
    // Spiral turn number, of sorts.
    float iy = floor(p.y/scl.y + .5);
    // Move the radial component out to the correct distance.
    p.y -= (iy + .5)*scl.y;

    // Total angle.
    a = (a + iy)*TAU;
    // Spiral length.
    p.x = spLength(a, scl.y);    
      
    p.x += iTime/4.; // Animate the length component of the spiral.
    
    // Square grid partitioning.
    vec2 ip = floor(p/scl); // Cell ID.
    p -= (ip + .5)*scl; // Local cell coordinates.

    // Global copies... It's a bit lazy doing it here, but it works.
    gIP = ip;
    gP = p;
    
    // Archimedean spiral cell coordinates.
    return p;
}


float distField(vec2 p){
    
    // Convert to spiral cell coordinates.
    p = spiral(p);
    
    // Fill the cell with a slightly rounded rectangle.
    float d = sBoxS(p, scl*vec2(.5, .5), .015);
    
    #ifdef HOLES
    // Adding some vertex decoration.
    float vert = 1e5; 
    
    // End point rivot holes.
    p.x = abs(p.x) - (scl.x*.5 - scl.y*.5);
    vert = min(vert, length(p));
    d = max(d, -(vert - scl.y*.1));
    #endif
    
    #ifdef RANDOM_LINES
    if(hash21(gIP + .31)>=.35){ 
       d = abs(d + scl.y/4.25) - scl.y/4.25;
    }
    #endif
    
    // Flattening the tops.
    d = max(d, -.02);
    
    // Distance.
    return d;

}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Aspect corret coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    //uv *= .95 + dot(uv, uv)*.1; // Screen bulge.

    // Scale and smoothing factor.
    const float sc = 1.;
    float sf = sc/iResolution.y;
    
    // Scaling.
    vec2 p = sc*uv;
    
    // Scene field calculations.

    // Derviative calculations to ensure  even line width.
    // 
    // This is kind of wasteful, since it only affects the 
    // line length in the very center of the sprial, but it's 
    // here for completeness.
    vec2 e = vec2(1e-4, 0.);
    float dx = distField(p + e);
    float dy = distField(p + e.yx);
   
    // Scene object.
    float d = distField(p);
    
    float r = length(vec2(dx, dy) - d)/e.x;

      
    // Divide the distance by the gradient for even lines. 
    d /= r;
    // Much cheaper, but doesn't work properly.
    //d /= fwidth(d)*iResolution.y/1.5;

    
    
    // Scene color -- Set to the background.
    vec3 col = vec3(.05);
    
    // Cell coloring.
    
    float cScl = 1.; // Color scale, or palette range.
    float cCont = 1.57; // Saturation.
    #if COLOR == 1
    // Mild color range for the green palette.
    cScl = 1./3.;
    cCont = 1.3;
    #elif COLOR > 1
    // Less color range for the blue and reddish palettes.
    cScl = 1./3.5;
    cCont = 1.2;
    #endif
    
    // Produce two slightly differing colors.
    float rnd = fract(gIP.x/8.)*cScl; 
    float rnd2 = fract(gIP.x/8. + 2./8.)*cScl;
    vec3 rCol = .5 + .45*cos(TAU*rnd + vec3(0, 1, 2)*cCont); // Color.
    vec3 rCol2 = .5 + .45*cos(TAU*rnd2 + vec3(0, 1, 2)*cCont); // Nearby color.
 
    // Gradient color blending from one side of the cell to the other.
    rCol = mix(rCol, rCol2, fract(gP.x/scl.x + .5));
     
    #if COLOR == 0
    // Applying a bit of contrast to the spectral colors.
    rCol = pow(rCol, vec3(1.25))*1.25; 
    #elif COLOR == 1
    rCol = rCol.yxz*.8; // Tone down the green shade a bit.
    #elif COLOR == 2
    rCol = rCol.zyx; // Tone down the green shade a bit.
    #endif
    
    // Breaking things up with some grey. Too much color can be a little full on.
    if(hash21(gIP + .31)<.35) 
       rCol = .02 + .2*vec3(1, .925, .85)*dot(rCol, vec3(.299, .587, .114));
    
    
    #ifdef SHADOW
    // Push the shadow against the leading edge.
    rCol *= smoothstep(0., scl.y/2., gP.y + scl.y/2.)*.875 + .25;
    #endif
    
    #ifdef TEXTURE
    vec3 tx = texture(iChannel0, (gP + gIP*scl*2.)).xyz; tx *= tx;
    rCol *= tx*3. + .5;
    // Debug. Just the texture.
    //rCol = smoothstep(0., .5, tx); 
    #endif
     
    #ifdef BUMP_MAP
    // Some quick bump mapping.
    #if 0
    vec3 ld = normalize(vec3(.75, 1, -1)); // Directional light.
    #else
    vec3 lp = vec3(.2, .4, -1); // Point light.
    vec3 ld = normalize(lp - vec3(uv, 0.));
    #endif
    vec3 rd = normalize(vec3(uv, 1)); // Unit direction ray.
    vec3 n = normalize(vec3(dx/r - d, dy/r - d, -e.x*2.)); // Normal.
    float diff = pow(max(dot(n, ld), 0.), 16.); // Diffuse.
    
    //vec3 refl = reflect(ld, n);    
    //float spec = pow(max(dot(refl, rd), 0.), 32.);
    vec3 hlf = normalize(ld - rd);
    float specR = pow(max(dot(hlf, n), 0.), 48.);
    
    // Applying the lighting.
    rCol *= .9 + diff*1. + specR*2.;
    #endif
    
    
    float ew = .005; // Edge width.
    
    // Rendering onto the background.
    //
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, d)); // Edge, or strke.
    col = mix(col, rCol, 1. - smoothstep(0., sf, d + ew)); // Top layer.

    // Extra shading.
    //float sh = max(-d/scl.y*2., 0.);
    //col *= sh*sh*.7 + .7;
    

    // Vignette.
    p.xy = fragCoord/iResolution.xy;
    col *= pow(16.*p.x*p.y*(1. - p.x)*(1. - p.y) , 1./16.);

    // Output to screen
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}