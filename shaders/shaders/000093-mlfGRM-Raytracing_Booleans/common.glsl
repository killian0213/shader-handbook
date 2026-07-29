// Common (common) — Raytracing Booleans by iq
// https://www.shadertoy.com/view/mlfGRM

// Intersection functions

// Keeps track of only 1 segment of solid mass at the time
// (form entry to exit of the ray and a primitive), but more
// segments should be added in order to handle more complex
// booleans
struct Intersection
{
    vec4 a;  // distance and normal at entry
    vec4 b;  // distance and normal at exit
};

const Intersection kEmpty = Intersection(vec4(1e20,0.0,0.0,0.0),vec4(-1e20,0.0,0.0,0.0));

bool isEmpty( Intersection i )
{
    return i.b.x < i.a.x;
}



// https://iquilezles.org/articles/boxfunctions
Intersection iBox( in vec3 ro, in vec3 rd, in vec3 siz ) 
{
    vec3 m = 1.0/rd;
    vec3 k = vec3(rd.x>=0.0?siz.x:-siz.x, rd.y>=0.0?siz.y:-siz.y, rd.z>=0.0?siz.z:-siz.z);
    vec3 t1 = (-ro - k)*m;
    vec3 t2 = (-ro + k)*m;
    float tN = max(max(t1.x,t1.y),t1.z);
    float tF = min(min(t2.x,t2.y),t2.z);
	if( tN>tF || tF<0.0 ) return kEmpty;
    return Intersection( vec4(tN, -sign(rd)*step(vec3(tN),t1)), 
                         vec4(tF, -sign(rd)*step(t2,vec3(tF))) );
}

// just solve for t, |ro+t*d|² = r²
Intersection iSphere( in vec3 ro, in vec3 rd, float r )
{   
    float b = dot(ro, rd);
    float c = dot(ro, ro) - r*r;
    float h = b*b - c;
    if( h<0.0 ) return kEmpty;
    h = sqrt( h );
    float ta = -b-h; vec3 na = (ro+ta*rd)/r;
    float tb = -b+h; vec3 nb = (ro+tb*rd)/r;
    return Intersection(vec4(ta,na),vec4(tb,nb));
}

// just solve for t, < ro+t*d, nor > - k = 0
Intersection iPlane( in vec3 ro, in vec3 rd, vec4 pla )
{ 
    float k1 = dot(ro, pla.xyz);
    float k2 = dot(rd, pla.xyz);
    float t = (pla.w-k1)/k2;        
    vec2 ab = (k2>0.0) ? vec2( t, 1e20 ) : vec2( -1e20, t );
    return Intersection( vec4(ab.x, -pla.xyz), vec4(ab.y, pla.xyz) );
}


struct Ray
{
    vec3 o;
    vec3 d;
};
    
Ray transform( Ray r, mat4x4 m )
{
	return Ray( (m*vec4(r.o,1.0)).xyz, (m*vec4(r.d,0.0)).xyz );
}

mat4 rotationAxisAngle( vec3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1.0 - c;

    return mat4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
			     0.0,                0.0,                0.0,                1.0 );
}

mat4 translate( float x, float y, float z )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
				 0.0, 1.0, 0.0, 0.0,
				 0.0, 0.0, 1.0, 0.0,
				 x,   y,   z,   1.0 );
}