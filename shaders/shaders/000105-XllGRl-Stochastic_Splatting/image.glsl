// Image (image) — Stochastic Splatting by iq
// https://www.shadertoy.com/view/XllGRl

// Created by inigo quilez - iq/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Stochastic rasterization of splats.
//
// Random points are generated at the surface of some parametric objects,
// and the points are projected into screen space. The object probability
// distribution is proportional to the area of the object's surface.
//
// Then a depth buffer resolves visibility, and then shading happens in a
// deferred manner.
//
// I think I first saw this technique in Texel's entry to js01k a few
// years ago.
//
// My twist is to make the pointcloud/splats different and random for every
// pixel.

vec3 sphere( in vec2 t )
{
    float y = -1.0 + 2.0*t.y;
    vec2 q = vec2( t.x*6.2831, acos(y) );
    return vec3( cos(q.x)*sin(q.y), y, sin(q.x)*sin(q.y) );
}

vec3 cylinder( in vec2 t )
{
    float q = t.x*6.2831;
    return vec3( 0.5*cos(q), -1.0 + 4.0*t.y, 0.5*sin(q) );
}

vec3 quad( in vec2 t )
{
    return 3.0*vec3( -1.0+2.0*t.x, 0.0, -1.0+2.0*t.y );
}

//------------------------------------------------------------------
// rand()
//------------------------------------------------------------------
int   seed = 1;
int   rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float frand(void) { return float(rand())/32767.0; }
void  srand( ivec2 p, int frame )
{
    int n = frame;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589; // hash by Hugo Elias
    n += p.y;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    n += p.x;
    n = (n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    seed = n;
}

mat4 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat4( cu.x, cu.y, cu.z, 0.0,
                 cv.x, cv.y, cv.z, 0.0,
                 cw.x, cw.y, cw.z, 0.0,
                 ro.x, ro.y, ro.z, 1.0 );
}

float dot2( in vec2 v ) { return dot(v,v); }

//==============================================================================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // pixel    
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    
    // camera
    float an = iTime;
    vec3  ro = 4.0*normalize(vec3(cos(an), 0.0, sin(an)));
	vec3  ta = vec3(0.0, 0.0, 0.0);
    
    // camera-to-world and world-to-camera transform
    mat4 c2w = setCamera( ro, ta, 0.0 );
    mat4 w2c = inverse(c2w);
    
    vec3 col = vec3( 0.0 );


    // Init randoms
    if( sin(iTime) > 0.0 ) 
    srand( ivec2(fragCoord), iFrame );
    else
    srand( ivec2(0), 0 );
    
    
    float fz = 1e10;         // depth buffer
    vec2  uv = vec2(-1.0);                  
    float fi = -1.0;
    for( int i=0; i<1024; i++ )
    {
        // generate a random sample        
        vec3 t = vec3(frand(),frand(),frand());
        
        // pick a random point on the surface of the scene
        //
        // area of the sphere   = 12.6
        // area of the plane    = 36.0
        // area of the cylinder = 15.7
        vec3 w; float id;
             if( t.z<((15.7     )/64.3) ) { id=0.0; w = vec3(2.0, 0.0,0.0)+cylinder( t.xy ); }
        else if( t.z<((15.7+36.0)/64.3) ) { id=1.0; w = vec3(0.0,-1.0,0.0)+quad(     t.xy ); }
        else                              { id=2.0; w =                    sphere(   t.xy ); }
            
        // convert to camera space
        vec3 q = (w2c * vec4(w,1.0)).xyz;
            
        // if in front of clipping plane
        if( q.z>0.01 )
        {
#if 0            
            // project            
            vec2 s = q.xy/q.z;

            // splat with depth test        
            if( (q.z*q.z*dot2(s-p))<0.02 && q.z<fz )
#else
            // project and splat with depth test, WITHOUT divisions!!
            if( dot2(q.xy-p*q.z)<0.02 && q.z<fz )
#endif
            {
                fz = q.z;
                uv = t.xy;
                fi = id;
            }
        }
    }
    
    // if splat
    if( fi>-0.5 )
    {
        // compute position, normals and occlusion
        vec3 pos, nor; float occ;
        
             if( fi<0.5 ) { pos = vec3(2.0, 0.0,0.0)+cylinder( uv ); nor = normalize( cylinder( uv )*vec3(1.0,0.0,1.0) ); occ = 0.5 + 0.5*smoothstep(-1.0,1.0,pos.y ); }
        else if( fi<1.5 ) { pos = vec3(0.0,-1.0,0.0)+quad(     uv ); nor = vec3(0.0,1.0,0.0);                             occ = smoothstep(0.0,2.0,length(pos.xz)) * smoothstep(0.0,2.0,length(pos.xz-vec2(2.0,0.0)));}
        else              { pos =                    sphere(   uv ); nor = normalize(sphere( uv ));                       occ = 0.5 + 0.5*nor.y; }

        // shade        
        col = textureLod( iChannel0, 2.0*uv, 0.0 ).xyz * occ + 0.1*nor.yxz*occ;
        
        // gamma
        col = sqrt( col );
    }
    
	fragColor = vec4( col, 1.0 );
}