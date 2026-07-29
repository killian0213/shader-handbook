// Common (common) — Extruded Packed Circle Zoom by Shane
// https://www.shadertoy.com/view/7XsXDr


// PI and 2PI.
#define PI 3.14159265358979
#define TAU 6.28318530718


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Hash without Sine -- Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// 1 out, 2 in...
float hash21(vec2 p) {
    p = fract(p*vec2(623.34, 456.21));
    p += dot(p, p + 145.123);
    return fract(p.x*p.y);
}
 
 
// Signed distance to a line passing through A and B.
float lineStep(vec2 p, vec2 a, vec2 b){

   //if(a == b) return -1e5;
   b = min(b - a, 1.);
   return dot(p - a, vec2(-b.y, b.x));
}

////////////////

 
 
// Inputting three mutually tangent circles, then determining the tangent
// central circle position and radius.
vec3 getCenter(mat3x3 c3){

    
    // Three mutually tangent circles in a plane will have two further tangent 
    // circles. One will touch all three circles externally, and the other 
    // will be internal.
    
    // Soddy circles are a consequence of Descartes' theorem relating to central 
    // circles. All of it is widely written about, and if you're reasonably 
    // confortable with triangle geometry, it's simple enough to derive.
   
    // Related to winding.
    float detA = determinant(mat2x2(c3[0].xy - c3[1].xy, c3[2].xy - c3[1].xy));
    
    // The three tangent circle radii.
    vec3 r3 = vec3(c3[0].z, c3[1].z, c3[2].z);
    
    // Weighting. We want the inner circle, so are using a positive sign
    // in the middle. For the external surrounding circle, we would use
    // a negative sign. This is a consequence of the quadratic formula
    // used in the solving process.
    vec3 w = 1./r3 + 2.*(r3.yzx + r3.zxy)/detA;
      
    // Inner circle radius and central position.
    float r = 1./dot(w, vec3(1));
    vec2 p = mat3x2(c3[0].xy, c3[1].xy, c3[2].xy)*w*r;
    
    // Central circle, position and radius.
    return vec3(p, r);

}

// Golden ratio.
#define PHI ((1. + sqrt(5.))/2.)
  
// Coxeter's loxodromic sequence of tangent circles.
// It can be interpreted as a degenerate special case of the Doyle spiral.

// The centres of the circles in the sequence lie on a logarithmic spiral. 
// Viewed from the centre of the spiral, the angle between the centres of 
// successive circles is the following.
#define SPIRAL_ANGLE acos(-1./PHI) //2.2370357592874117


// Loxodromic geometric progression factor. This represets the ratio
// of the successive circle radii within the loxodromic spiral.
#define GEOMETRIC_SCALE (PHI + sqrt( PHI )) // 2.89005...

// Time marker and ID variables.
float iT;


// Global circle value: Globals might be a lazy way to access variables
// throughout the program, but it's also a quick and easy way to access 
// variables thoughout the progam. :) 
vec3 gCir;

 
// This is a Soddy circle routine. I have DjinnKahn's working
// example to thank for this.
//
// Soddy circles - infinite zoom -- DjinnKahn
// https://www.shadertoy.com/view/ddyGRd
vec3 distField(vec2 p){
    
   
    // A variable to hold three mutually tangent circles, the centers of 
    // which form the vertices of a triangle.
    mat3x3 c3;
    
    // Three mutually tangent circles rendered in a loxodromic
    // spiral pattern.
    //
    // If you were to render lines linking the circular centers, I'm 
    // pretty sure you'd wind up with a series of Kepler triangles,  
    // which involve the same ratios.
    float numC = 3.;
    float piDivN = PI/numC;
    float r = sin(piDivN)/(1. + sin(piDivN));
    c3[0] = vec3(0, 0, 1. - 2.*r);
    for(int i = 0; i<3; i++){
        float ang = (-iT + float(i))*SPIRAL_ANGLE;
        c3[i] = vec3(vec2(-cos(ang), sin(ang)), r)*pow(GEOMETRIC_SCALE, float(i));
    }
    
    // Using the three side lengths between the consecutive
    // circle centers to determine the radii or the circles.
    c3[0].z = length(c3[2].xy - c3[1].xy);
    c3[1].z = length(c3[0].xy - c3[2].xy);
    c3[2].z = length(c3[1].xy - c3[0].xy);
    float s = .5*(c3[0].z + c3[1].z + c3[2].z);
    //
    // The radii of the three starter circles.
    c3[0].z = s - c3[0].z;
    c3[1].z = s - c3[1].z;
    c3[2].z = s - c3[2].z;
    
    
    ////////////////
    // Filling in the gaps between the initial three starter
    // circles with Soddy circles.
   ////////////////
    
    ////////////////
    // Filling in the gaps between the initial three starter
    // circles with Soddy circles.
    
    // Position ID.
    vec2 ip = vec2(0);
    // Distance.
    float d = 1e5;
    
    
    // Center circle. Set to anything to begin with.
    vec3 cI = vec3(0, 0, 1); 
    gCir = cI;
    
    // Triangle region variables.
    int region = 0;
    int oRegion = 0;
    
    for(int j = 0; j<12; j++){
        
        // Use the triangle vertex circle information
        // to obtain the inner Soddy circle. Use its vertex
        // to produce three new triangles from it to the
        // triangle vertices, then determine which triangle
        // we're in. This is a common subdivision technique.
        
        // Internal center Soddy circle.
        cI = getCenter(c3);
        
        // Dividing lines.
        vec3 ln3;
        ln3.x = lineStep(p, cI.xy, c3[0].xy);
        ln3.y = lineStep(p, cI.xy, c3[1].xy);
        ln3.z = lineStep(p, cI.xy, c3[2].xy);
        ln3 = max(ln3, -ln3.yzx);

        // Determine which of the three new triangles the pixel is in.
        region = 2;
        for(int i = 0; i<2; i++){

           if(ln3[i]<0.){
               
               // Region ID.
               region = i;
            
               break;
           }
        }
        
        // Triangle.
        c3 = mat3x3(cI, c3[region], c3[(region + 1)%3]);


        // Normally, you'd just test for "dI<0". Unfortunately, for 3D
        // to work, you need to force the outer boundaries (i=0) to be part
        // of the structure in order to bound the ray... 3D can be annoying.
        // Anyway, this will get rid of artifacts whilst not forcing all
        // 12 or so distance comparisons.
        float dI = length(p -  cI.xy) - cI.z;
        if(dI<d || (j>0 && dI<0.)){
            
            d = dI;
            ip = vec2(j, oRegion);
            gCir = cI;
            
            if(j>0 && dI<0.) break;
        }
        
        oRegion = region;
        
    }
    
   
 
    // Return the distance and ID.
    return vec3(d, ip);
}


////////////////////////////////


// Bidirectional Reflectance Distribution Function (BRDF). 
//
// If you want a quick crash course in BRDF, see the following:
// Microfacet BRDF: Theory and Implementation of Basic PBR Materials
// https://www.youtube.com/watch?v=gya7x9H3mV0&t=730s
//

// Surface geometry function.
float GGX_Schlick(float nv, float rough) {
    //float r = rough; // original
    float r = .5 + .5*rough; // Disney remapping.
    float k = (r*r)/2.;
    float denom = nv*(1. - k) + k;
    return max(nv, .001)/denom;
}

// Specular calculation.
vec3 getSpec(vec3 FS, float nh, float nr, float nl, float rough){

    // Microfacet distribution... Most dominant term.
    // Microfaceted normal distribution function.
    float alpha = pow(rough, 4.);
    float b = (nh*nh*(alpha - 1.) + 1.);
    float D = alpha/(PI*b*b);    
    
    // Geometry self shadowing term.
    // G_Smith calculations.
    float g1_l = GGX_Schlick(nl, rough);
    float g1_v = GGX_Schlick(nr, rough);
    float G = g1_l*g1_v;
    
    // Combining the terms above.
    return FS*D*G/(4.*max(nr, .001))*PI;
}

vec3 getDiff(vec3 FS, float nl, float type){

    // Diffuse calculations.
    vec3 diff = nl*(1. - FS); // If not specular, use as diffuse (optional)
    return diff*(1. - type); // No diffuse for metals.
}

//////////////////////////////////////