// Image (image) — laplacian+flow noise by FabriceNeyret2
// https://www.shadertoy.com/view/XsXBzH

// --- div(normalize(grad(noise)) idea from nimitz https://www.shadertoy.com/view/MtKSWW
// --- base gradient noise + derivative from iq https://www.shadertoy.com/view/XdXBRH
// --- plus flownoise

float T = 0.;
vec2 hash( in vec2 x ) 
{
    float t = T  * sign(mod(x.x+x.y,2.)-.5), // optional checker swirls
          c = cos(t), s=sin(t);
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    x =  -1. + 2.*fract( 16. * k*fract( x.x*x.y*(x.x+x.y)) );
    return x * mat2(c,-s,s,c); // flownoise
 // return vec2(cos(t+3.1416*x.x), s = sin(t+3.1416*x.x)); // iq variant
}


// return gradient noise (in x) and its derivatives (in yz)
vec3 noised( in vec2 p )
{
    vec2 i = floor( p ),
         f = fract( p );

#if 1 // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.-15.)+10.),
        du = 30.*f*f*(f*(f-2.)+1.);
#else // cubic interpolation
    vec2 u = f*f*(3.-2.*f),
        du = 6.*f*(1.-f);
#endif    
    
    vec2 ga = hash( i + vec2(0,0) ),
         gb = hash( i + vec2(1,0) ),
         gc = hash( i + vec2(0,1) ),
         gd = hash( i + vec2(1,1) );
    
    float va = dot( ga, f - vec2(0,0) ),
          vb = dot( gb, f - vec2(1,0) ),
          vc = dot( gc, f - vec2(0,1) ),
          vd = dot( gd, f - vec2(1,1) );

    return vec3( va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd),   // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
}

// -----------------------------------------------

// normalize(grad(noise)) . div of it is nimitz pseudoLaplace noise
#define N(i,j)  normalize ( noised( s*(p+.5*vec2(i,j))/64. ).yz) // x:noise yz: gradient   
 
/**/  // using finite differences
void mainImage( out vec4 O,  vec2 p )
{
    O -= O; 
    float s = 1.; vec4 C = vec4(1.,.9,.8,0);
    for (int i=0; i<4; i++) {
        // vec2 n = N(0,0);
        T = iTime; // * s;      // optional *s
        float d = N(1,0).x - N(-1,0).x + N(0,1).y - N(0,-1).y; // div(N)
 
        O +=  max(0., d ) *C / s;    // optional / s
     // O +=  max(d*vec4(-1,0,1,0), 0. ) / s;
     // O.b += .1*(.5-.5*noised( s*p/64. ).x )/ s; // blue glow around filaments
     // O.b += .1*(.5+.5*noised( s*p/64. ).x )/ s; // blue glow between filaments
     // O   += .4*noised( s*p/64. ).x/ s *vec4(-1,0,1,0); // blue/red glow mix
     // O.b += .1*length( noised( s*p/64.).yz)/ s; // blue strips between filaments
        s *= 2.; C *= C;
    
    }
    O *= 4.;
 // O = vec4(v*4.);
 // O = v*4.* vec4(1,0,-1,0);
}
/**/




/**  // using hardware derivatives

void mainImage( out vec4 O,  vec2 p )
{
    vec3 n;
    
    float s = 1., v=0.;
    for (int i=0; i<3; i++) {
        n = noised( s*p/64. );                    // x:noise yz: gradient
        n .yz = normalize(n.yz);
        v +=  max(0., dFdx(n.y)+dFdy(n.z) ) / s;  //  dFdx(n.y)+dFdy(n.z) is div(n.yz)
        s *= 2.;
    
    }
   O = vec4(v*4.);
 //O = v*4.* vec4(1,0,-1,0);
}
/**/