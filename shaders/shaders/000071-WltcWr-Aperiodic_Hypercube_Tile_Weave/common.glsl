// Common (common) — Aperiodic Hypercube Tile Weave by Shane
// https://www.shadertoy.com/view/WltcWr

#define PI 3.141592653 

// A swap without the extra declaration, but involves extra operations -- 
// It works fine on my machine, but if it causes trouble, let me know. :)
//#define swap(a, b){ a = a + b; b = a - b; a = a - b; }

void swap(inout int a, inout int b){ int tmp = a; a = b; b = tmp; }
void swap(inout vec2 a, inout vec2 b){ vec2 tmp = a; a = b; b = tmp; }

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// A random hash that I made up a while back. It's based on a few things
// I've come across, but is mostly experimental. If it doesn't work on 
// your system, feel free to let me know.
float hash21(vec2 p) {
    
    p = fract(p*2.014371)*128. - vec2(63.537567, 64.484713);
    return fract(dot(p.xyx*p.xyy, vec3(128.390654, 128.713193, 2.1396217)));
}


// Triangle's incenter and radius.
vec3 inCentRad(vec2 p0, vec2 p1, vec2 p2){
    
    // Side lengths.
    float bc = length(p1 - p2), ac = length(p0 - p2), ab = length(p0 - p1);
    vec2 inCir = (bc*p0 + ac*p1 + ab*p2)/(bc + ac + ab);   
    
    // Area.
    float p = (bc + ac + ab)/2.;
    float area = sqrt(p*(p - bc)*(p - ac)*(p - ab));
    
    return vec3(inCir, area/p);
}

// IQ's distance to a regular polygon, without trigonometric functions. 
// Other distances here:
// https://iquilezles.org/articles/distfunctions2d
//
#define NV2 4
//
float sdPoly4(in vec2 p, in vec2[NV2] v){

    const int num = v.length();
    float d = dot(p - v[0],p - v[0]);
    float s = 1.0;
    for( int i = 0, j = num - 1; i < num; j = i, i++){
    
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp(dot(w, e)/dot(e, e), 0., 1. );
        d = min( d, dot(b,b) );

        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s*=-1.0;  
    }
    
    return s*sqrt(d);
}




// IQ's signed distance to a 2D triangle.
float sdTri(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2){
 
    vec2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;

	vec2 v0 = p - p0, v1 = p - p1, v2 = p - p2;

	vec2 pq0 = v0 - e0*clamp( dot(v0, e0)/dot(e0, e0), 0., 1.);
	vec2 pq1 = v1 - e1*clamp( dot(v1, e1)/dot(e1, e1), 0., 1.);
	vec2 pq2 = v2 - e2*clamp( dot(v2, e2)/dot(e2, e2), 0., 1.);
    
    float s = sign( e0.x*e2.y - e0.y*e2.x);
    vec2 d = min( min( vec2(dot(pq0, pq0), s*(v0.x*e0.y - v0.y*e0.x)),
                       vec2(dot(pq1, pq1), s*(v1.x*e1.y - v1.y*e1.x))),
                       vec2(dot(pq2, pq2), s*(v2.x*e2.y - v2.y*e2.x)));

	return -sqrt(d.x)*sign(d.y);
}

// Rounded triangle routine. Not used here, but handy.
float sdTriR(vec2 p, vec2 v0, vec2 v1, vec2 v2){
     
    vec3 inC = inCentRad(v0, v1, v2);
    float ndg = .09/inC.z;
    return sdTri(p, v0 - (v0 - inC.xy)*ndg,  v1 - (v1 - inC.xy)*ndg,  v2 - (v2 - inC.xy)*ndg) - .08;      
        
} 

// Vertice winding order... It works fine, but there'd be better ways.
float winding(in vec2[NV2] v){

    const int num = v.length();
    float sum = 0.;
    for (int i = 0; i < num; i++) {
        vec2 v1 = v[i];
        vec2 v2 = v[(i + 1)%num];
        sum += (v2.x - v1.x)*(v2.y + v1.y);
    }
    
    return sum>0.? 1. : -1.;
}

// Determines which side of a line a pixel is on. Zero is the threshold.
float line(vec2 p, vec2 a, vec2 b){
     return ((b.x - a.x)*(p.y - a.y) - (b.y - a.y)*(p.x - a.x));
}

// IQ's signed distance to a quadratic Bezier. Like all of IQ's code, it's
// quick and reliable. :)
//
// Quadratic Bezier - 2D Distance - IQ
// https://www.shadertoy.com/view/MlKcDD
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C){
  
    // p(t)    = (1 - t)^2*p0 + 2(1 - t)t*p1 + t^2*p2
    // p'(t)   = 2*t*(p0 - 2*p1 + p2) + 2*(p1 - p0)
    // p'(0)   = 2*(p1 - p0)
    // p'(1)   = 2*(p2 - p1)
    // p'(1/2) = 2*(p2 - p0)
    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

     // If I were to make one change to IQ's function, it'd be to cap off the value 
    // below, since I've noticed that the function will fail with straight lines.
    float kk = 1./max(dot(b,b), 1e-6); // 1./dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      

    float res = 0.0;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;

    if(h >= 0.0) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );

        // 1 root
        vec2 qos = d + (c + b*t)*t;
        res = length(qos);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );

        // 3 roots
        vec2 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos,qos);
        
        res = dis;

        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos,qos);
        res = min(res,dis);

        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos,qos);
        res = min(res,dis);

        res = sqrt( res );
    }
    
    return res;
}

// Rendering the smooth Bezier segment. The idea is to calculate the midpoint
// between "a.xy" and "b.xy," then offset it by the average of the combined normals
// at "a" and "b" multiplied by a factor based on the length between "a" and "b."
// At that stage, render a Bezier from "a" to the midpoint, then from the midpoint
// to "b." I hacked away to come up with this, which means there'd have to be a more
// robust method out there, so if anyone is familiar with one, I'd love to know.
float doSeg(vec2 p, vec4 a, vec4 b, float r){
    
    // Mid way point.
    vec2 mid = (a.xy + b.xy)/2.; // mix(a.xy, b.xy, .5);
    
    // The length between "a.xy" and "b.xy," multiplied by... a number that seemed
    // to work... Worst coding ever. :D
    float l = r;//length(b.xy - a.xy)/3.25;//1.732/6.; // ;//
 
    // Points on the same edge each have the same normal, and segments between them
    // require a larger arc. There was no science behind the decision. It's just 
    // something I noticed and hacked a solution for. Comment the line out, and you'll 
    // see why it's necessary. By the way, replacing this with a standard semicircular 
    // arc would be even better, but this is easier.
//    if(abs(length(b.zw - a.zw))<.01) l = r; 
  
    // Offsetting the midpoint between the exit points "a" and "b"
    // by the average of their normals and the line length factor.
    mid += (a.zw + b.zw)/2.*l;

    // Piece together two quadratic Beziers to form the smooth Bezier curve from the
    // entry and exit points. The only reliable part of this method is the quadratic
    // Bezier function, since IQ wrote it. :
    float b1 = sdBezier(p, a.xy, a.xy + a.zw*l, mid);
    float b2 = sdBezier(p, mid, b.xy + b.zw*l, b.xy);
    
    // Return the minimum distance to the smooth Bezier arc.
    return min(b1, b2);
}

