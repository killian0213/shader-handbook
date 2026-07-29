// Common (common) — Tentacle Object by fizzer
// https://www.shadertoy.com/view/3tXXRn


// Spherical Fibonnacci points, as described by Benjamin Keinert, Matthias Innmann, 
// Michael Sanger and Marc Stamminger in their paper (below)

//=================================================================================================
// http://lgdv.cs.fau.de/uploads/publications/spherical_fibonacci_mapping_opt.pdf
//=================================================================================================
const float PI  = 3.14159265359;
const float PHI = 1.61803398875;

// Originally from https://www.shadertoy.com/view/lllXz4
// Modified by fizzer to put out the vector q.
vec2 inverseSF( vec3 p, float n, out vec3 outq ) 
{
    float m = 1.0 - 1.0/n;
    
    float phi = min(atan(p.y, p.x), PI), cosTheta = p.z;
    
    float k  = max(2.0, floor( log(n * PI * sqrt(5.0) * (1.0 - cosTheta*cosTheta))/ log(PHI+1.0)));
    float Fk = pow(PHI, k)/sqrt(5.0);
    vec2  F  = vec2( round(Fk), round(Fk * PHI) ); // k, k+1

    vec2 ka = 2.0*F/n;
    vec2 kb = 2.0*PI*( fract((F+1.0)*PHI) - (PHI-1.0) );    
    
    mat2 iB = mat2( ka.y, -ka.x, 
                    kb.y, -kb.x ) / (ka.y*kb.x - ka.x*kb.y);
    
    vec2 c = floor( iB * vec2(phi, cosTheta - m));
    float d = 8.0;
    float j = 0.0;
    for( int s=0; s<4; s++ ) 
    {
        vec2 uv = vec2( float(s-2*(s/2)), float(s/2) );
        
        float i = round(dot(F, uv + c));
        
        float phi = 2.0*PI*fract(i*PHI);
        float cosTheta = m - 2.0*i/n;
        float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
        
        vec3 q = vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, cosTheta );
        float squaredDistance = dot(q-p, q-p);
        if (squaredDistance < d) 
        {
            outq = q;
            d = squaredDistance;
            j = i;
        }
    }
    return vec2( j, sqrt(d) );
}

vec2 intersectSphere(vec3 ro, vec3 rd, vec3 org, float rad)
{
   float a = dot(rd, rd);
   float b = 2. * dot(rd, ro - org);
   float c = dot(ro - org, ro - org) - rad * rad;
   float desc = b * b - 4. * a * c;
   if (desc < 0.)
      return vec2(1, 0);

   return vec2((-b - sqrt(desc)) / (2. * a), (-b + sqrt(desc)) / (2. * a));
}

// polynomial smooth min
// from iq: https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a,float b,float k){ return -smin(-a,-b,k);}

mat3 rotX(float a)
{
    return mat3(1., 0., 0.,
                0., cos(a), sin(a),
                0., -sin(a), cos(a));
}

mat3 rotY(float a)
{
    return mat3(cos(a), 0., sin(a),
                0., 1., 0.,
                -sin(a), 0., cos(a));
}

mat3 rotZ(float a)
{
    return mat3(cos(a), sin(a), 0.,
                -sin(a), cos(a), 0.,
                0., 0., 1.);
}
