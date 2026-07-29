// Image (image) — 4D Cube II / Tesseract by iq
// https://www.shadertoy.com/view/ftcyW4

// Copyright Inigo Quilez, 2022 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

// Another 4D cube. It's like https://www.shadertoy.com/view/4tVyWw
// but rendering faces instead of edges.

    
// make this 2 is your machine is fast
#define AA 1


//------------------------------------------------------------------
// oldschool rand() from Visual Studio
//------------------------------------------------------------------
int   seed = 1;
int   rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float frand(void) { return float(rand())/32767.0; }
void  srand( ivec2 p, int frame )
{
    // based on a 1D hash by Hugo Elias
    int n = 1376312589;
    n += frame; n = (n<<13)^n; n=n*(n*n*15731+789221); 
    n += p.y;   n = (n<<13)^n; n=n*(n*n*15731+789221);
    n += p.x;   n = (n<<13)^n; n=n*(n*n*15731+789221);
    seed = n;
}

//------------------------------------------------------------------
// intersecting a quadrilateral with a window in it
//------------------------------------------------------------------
vec4 quadIntersect( in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2, in vec3 v3, in float tmin, float tmax, out float oDisSq )
{
    // make v0 the origin
    vec3 r1 = v1 - v0;
    vec3 r2 = v2 - v0;
    vec3 r3 = v3 - v0;
    vec3 rz = ro - v0;

    // intersect with the quad's plane
    vec3 nor = cross(r1,r2);
    float t = -dot(rz,nor)/dot(rd,nor);
    
    // early exit
    if( t<tmin || t>tmax ) return vec4(-1.0);
    
    // intersection point
    vec3 rp = rz + t*rd;
    
    
    // build reference frame for the quad (uu,vv,ww)
    vec3 ww = normalize(nor);
    float l1 = length(r1);
    vec3 uu = r1/l1;
    vec3 vv = cross(uu,ww);
    
    // project all vertices to 2D into to the (uu,vv) plane
    vec2 k0 = vec2( 0.0, 0.0 );
    vec2 k1 = vec2( l1,  0.0 );
    vec2 k2 = vec2( dot(r2,uu), dot(r2,vv) );
    vec2 k3 = vec2( dot(r3,uu), dot(r3,vv) );
    vec2 kp = vec2( dot(rp,uu), dot(rp,vv) );

    // compute 2D distance from intersection point to quad edges
    vec2  e0 = k1 - k0, p0 = kp - k0; 
    vec2  e1 = k2 - k1, p1 = kp - k1;
    vec2  e2 = k3 - k2, p2 = kp - k2;
    vec2  e3 = k0 - k3, p3 = kp - k3;
    
    float c0 = e0.x*p0.y - e0.y*p0.x;
    float c1 = e1.x*p1.y - e1.y*p1.x;
    float c2 = e2.x*p2.y - e2.y*p2.x;
    float c3 = e3.x*p3.y - e3.y*p3.x;
    
    // if outside, early out
    if( max(max(c0,c1),max(c2,c3))>0.0 ) return vec4(-1.0);
    
    // euclidean internal distance squared
    float d = min(min(c0*c0/dot(e0,e0),
                      c1*c1/dot(e1,e1)),
                  min(c2*c2/dot(e2,e2),
                      c3*c3/dot(e3,e3)));
    
    // open window of size 0.3
    if( d>0.3*0.3 )  return vec4(-1.0);
    
    // return ray distance, normal, and distance from intersection to quad edges
    oDisSq = d; 
    return vec4(t,ww);
}

//-------------------------------------------------------------------
// 4D cube stuff
//-------------------------------------------------------------------
// 2d ->  4 verts, 1 face  per vertex -> ( 4*1)/4 =  1 quad
// 3d ->  8 verts, 3 faces per vertex -> ( 8*3)/4 =  6 quads
// 4d -> 16 verts, 6 faces per vertex -> (16*6)/4 = 24 quads
//
// So, the vertex indices of a quad differ by one bit each, in
// a 00, 01, 11, 10 pattern. I feel I should be able to generate
// this LUT on the fly instead of hardcoding it here below, but
// I can't afford rabbit-holing myself into this right now :(
#define DF(f) (ivec4((f)>>12,(f)>>8,(f)>>4,(f))&15);
#define EF(a,b,c,d) (((a)<<12)|((b)<<8)|((c)<<4)|(d))
#define QF(x,y,a) EF(a,a^(1<<x),a^(1<<x)^(1<<y),a^(1<<y))
const int kFaces[24] = int[24](
    // xy
    QF(0,1,  0),  //  0, 1, 3, 2
    QF(0,1,  7),  //  7, 6, 4, 5
    QF(0,1, 11),  // 11,10, 8, 9
    QF(0,1, 12),  // 12,13,15,14
    // xz
    QF(0,2,  0),  //  0, 1, 5, 4
    QF(0,2,  7),  //  7, 6, 2, 3
    QF(0,2, 11),  // 11,15,14,10
    QF(0,2, 12),  // 12, 8, 9,13
    // xw
    QF(0,3,  0),  //  0, 1, 9, 8
    QF(0,3,  7),  //  7,15,14, 6
    QF(0,3, 11),  // 11,10, 2, 3
    QF(0,3, 12),  // 12, 4, 5,13
    // yz
    QF(1,2,  0),  //  0, 2, 6, 4
    QF(1,2,  7),  //  7, 5, 1, 3
    QF(1,2, 11),  //  11,15,13,9
    QF(1,2, 12),  //  12,8,10,14
    // yw
    QF(1,3,  0),  //  0, 2,10, 8
    QF(1,3,  7),  //  7,15,13, 5
    QF(1,3, 11),  // 11, 9, 1, 3
    QF(1,3, 12),  // 12, 4, 6,14
    // zw
    QF(2,3,  0),  //  0, 4,12, 8
    QF(2,3,  7),  //  7,15,11, 3
    QF(2,3,  9),  //  9, 1, 5,13
    QF(2,3, 14)); //  14,10,2, 6

vec4 intersectClosest( in vec3 ro, in vec3 rd, in vec3 verts[16], out int oFace, out float oDisSq )
{
    vec4 res = vec4(1e10,0.0,0.0,0.0);
    oFace = -1;
    
    for( int i=0; i<kFaces.length(); i++ )
    {
        float tmpd;
        ivec4 idx = DF(kFaces[i]); // decode face indices
        vec4 tmp = quadIntersect( ro, rd, verts[idx.x], verts[idx.y], verts[idx.z], verts[idx.w], 0.0, res.x, tmpd );
        if( tmp.x>0.0 )
        {
            res = tmp;
            oFace = i;
            oDisSq = tmpd;
        }
    }

    res.yzw = (dot(res.yzw,rd)<0.0) ? res.yzw : -res.yzw;  // face camera

    return (res.x<1e9)?res:vec4(-1.0);
}

float intersectAny( in vec3 ro, in vec3 rd, in vec3 v[16], int obj )
{
    for( int i=0; i<kFaces.length(); i++ )
    {
        if( i!=obj ) // prevent self shadowing, without epsilons
        {
            float kk;
            ivec4 idx = DF(kFaces[i]); // decode face indices
            if( quadIntersect( ro, rd, v[idx.x], v[idx.y], v[idx.z], v[idx.w], 0.001, 10.0, kk ).x>0.0 )
                return 0.0;
        }
    }
    return 1.0;
}

// regular ambient occlusion
float calcOcclusion( in vec3 pos, in vec3 nor, in vec3 verts[16], int obj )
{
    float occ = 0.0;
    const int num = 16;   // 16 samples, can change it of course
    for( int j=0; j<num; j++ )
    {
        // uniform distribution on sphere
        float u = frand();
        float v = frand();
        float a = 6.2831853*v; float b = 2.0*u-1.0;
        vec3 dir = vec3(sqrt(1.0-b*b)*vec2(cos(a),sin(a)),b);
        
        // convert to cosine distribution around normal
        dir = normalize( nor + dir );
        
        // cast shadow ray
        if( dir.y>0.0 ) // but only towards the sky
        occ += intersectAny( pos, dir, verts, obj );
    }
    return occ/float(num);
}

vec3 render( in vec3 ro, in vec3 rd, in vec3 verts[16], in vec2 px )
{ 
    // background
    vec3 col = mix(vec3(0.05,0.4,0.4),vec3(0.05,0.2,0.4),0.5+0.5*px.y)*0.45;
    col *= 1.0-0.4*length(px);

    // 4D cube
    if( abs(px.x)<1.0)
    {
        int   face;
        float disSq;
        vec4  tnor = intersectClosest(ro,rd,verts,face,disSq);
        float t = tnor.x;
        if( t>0.0 )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = tnor.yzw;

            // material
            ivec4 idx = DF(kFaces[face]); // decode face indices
            float l = length( verts[idx.x]-verts[idx.y] );
            l = max(l,length( verts[idx.y]-verts[idx.z] ));
            l = max(l,length( verts[idx.z]-verts[idx.w] ));
            l = max(l,length( verts[idx.w]-verts[idx.x] ));
            l += nor.x*1.5; 
            vec3 mate = vec3(0.6,0.4,0.52) + 0.5*sin(0.26*l+vec3(0,1.5,2)+1.35);
            mate = max(mate,0.0);
            mate.z += 0.2*(1.0-exp2(-0.02*t*t));
            mate *= 1.2-1.2*vec3(0.5,0.5,0.1)*smoothstep(0.6,0.7,-cos(sqrt(disSq)*80.0));

            // lighting
            col = mate * calcOcclusion( pos, nor, verts, face );
        }
    }
    return col;
}

// look-at from r(ray)o(origin) to ta(rget) with c(amera)r(oll)
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

// a rotation matrix
mat2 rot( float a )
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c,-s,s,c);
}

// animation will repeat every 18 second
vec3 transform( in vec4 p, float time )
{
    // some rotations in 4D
    p.xy = rot(6.283185*time/18.0)*p.xy;
    p.zw = rot(6.283185*time/ 6.0)*p.zw;
    // perspective projection (4D to 3D)
    return 2.8*p.xyz/(3.0+p.w); 
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // init randoms
    srand( ivec2(fragCoord), iFrame );
    
    // camera (static)
    vec3 ro = vec3( 3.8, 2.0, 3.3 );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 tot = vec3(0.0);
    #if AA>1
    #define ZERO min(iFrame,0)
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/iResolution.y;
        float time = iTime + frand()/30.0;
        #else    
        vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
        float time = iTime;
        #endif

        // rotate 4D cube
        vec3 v[] = vec3[]( transform(vec4(-1,-1,-1,-1),time),
                           transform(vec4(-1,-1,-1, 1),time),
                           transform(vec4(-1,-1, 1,-1),time),
                           transform(vec4(-1,-1, 1, 1),time),
                           transform(vec4(-1, 1,-1,-1),time),
                           transform(vec4(-1, 1,-1, 1),time),
                           transform(vec4(-1, 1, 1,-1),time),
                           transform(vec4(-1, 1, 1, 1),time),
                           transform(vec4( 1,-1,-1,-1),time),
                           transform(vec4( 1,-1,-1, 1),time),
                           transform(vec4( 1,-1, 1,-1),time),
                           transform(vec4( 1,-1, 1, 1),time),
                           transform(vec4( 1, 1,-1,-1),time),
                           transform(vec4( 1, 1,-1, 1),time),
                           transform(vec4( 1, 1, 1,-1),time),
                           transform(vec4( 1, 1, 1, 1),time));

        // ray direction
        vec3 rd = ca * normalize( vec3(p.xy,2.0) );

        // render	
        vec3 col = render( ro, rd, v, p );

        // gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
        #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    // cheap dither to remove banding from background (should be triangular, ie, two frand()s)
    tot += frand()/255.0;

    fragColor = vec4( tot, 1.0 );
}