// Common (common) — Islamic Decagon Star Pattern by Shane
// https://www.shadertoy.com/view/3cffDB


// PI and 2PI.
#define PI 3.14159265
#define TAU 6.2831853

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// Line step only. No distance involved.
float lineStep(vec2 p, vec2 a, vec2 b){ 

   // Cheap, line stepping. I tend to use this when I need the cycles.
    b -= a; 
    return dot(p - a, vec2(-b.y, b.x));

}

// Bidirectional Reflectance Distribution Function (BRDF). 
//
// If you want a quick crash course in BRDF, see the following:
// Microfacet BRDF: Theory and Implementation of Basic PBR Materials
// https://www.youtube.com/watch?v=gya7x9H3mV0&t=730s
//

// Surface geometry function.
float GGX_Schlick(float nv, float rough) {
    //float r = roughness; // original
    float r = .5 + .5*rough; // Disney remapping.
    float k = (r*r)/2.;
    float denom = nv*(1. - k) + k;
    return max(nv, .001)/denom;
}

float G_Smith(float nr, float nl, float rough) {
    float g1_l = GGX_Schlick(nl, rough);
    float g1_v = GGX_Schlick(nr, rough);
    return g1_l*g1_v;
}

// Specular calculation.
vec3 getSpec(vec3 FS, float nh, float nr, float nl, float rough){

    // Microfacet distribution... Most dominant term.
    // Microfaceted normal distribution function.
    float alpha = pow(rough, 4.);
    float b = (nh*nh*(alpha - 1.) + 1.);
    float D = alpha/(3.14159265*b*b);    
    
    // Geometry self shadowing term.
    float G = G_Smith(nr, nl, rough);
    
    // Combining the terms above.
    return FS*D*G/(4.*max(nr, .001))*3.14159265;
}

vec3 getDiff(vec3 FS, float nl, float rough, float type){

    // Diffuse calculations.
    vec3 diff = nl*(1. - FS); // If not specular, use as diffuse (optional)
    return diff*(1. - type); // No diffuse for metals.
}

 

///////////

// IQ's distance to a regular pentagon, without trigonometric functions. 
// Other distances here:
// https://iquilezles.org/articles/distfunctions2d
//
#define NV 10
//
float sdPoly(in vec2 p, in vec2[NV] v, int num){

    //const int num = v.length() - 1;
    float d = dot(p - v[0], p - v[0]);
    float s = 1.;
    for( int i = 0, j = num - 1; i < num; j = i, i++){
    
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp(dot(w, e)/dot(e, e), 0., 1. );
        d = min( d, dot(b,b) );
        
        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, 
                            p.y <v[j].y, 
                            e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s=-s; 

    }
    
    return sqrt(d)*s;
}


// IQ's specialized pentagram function. This is way, way faster than
// a generalized polygon function. You can find it on IQ's site, here:
// https://iquilezles.org/articles/distfunctions2d/
float sdPentagram(in vec2 p, in float r){
    
    const float k1x = .809016994; // cos(PI/5) 
    const float k2x = .309016994; // sin(PI/10) 
    const float k1y = .587785252; // sin(PI/5) 
    const float k2y = .951056516; // cos(PI/10) 
    const float k1z = .726542528; // tan(PI/5)
    const vec2 v1 = vec2( k1x, -k1y);
    const vec2 v2 = vec2(-k1x, -k1y);
    const vec2 v3 = vec2( k2x, -k2y);
    
    p.y = -p.y;
    p.x = abs(p.x);
    p -= 2.0*max(dot(v1, p), 0.)*v1;
    p -= 2.0*max(dot(v2, p), 0.)*v2;
    p.x = abs(p.x);
    p.y -= r;
        
    return length(p - v3*clamp(dot(p, v3),0.0,k1z*r))
           * sign(p.y*v3.x-p.x*v3.y);
}
 