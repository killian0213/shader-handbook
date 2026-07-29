// Image (image) — Adjugate by iq
// https://www.shadertoy.com/view/3s33zj

// Inigo Quilez 2019

// Based on https://github.com/graphitemaster/normals_revisited
// Also see https://en.wikipedia.org/wiki/Adjugate_matrix
//
// Using the adjugate matrix to transform the normals of
// an object when the scale is not uniform (sphere in this
// case). The adjugate matrix is quicker to compute than
// the traditional transpose(inverse(m)), is more stable,
// and does not break with zero or negative determinants.

// Compare methods:
//
// 0: n = adjoint(m)            --> correct
// 1: n = transpose(inverse(m)) --> sometimes incorrect, and slow
// 2: n = m                     --> always incorrect
//
#define METHOD 0


//===================================================

// Use to transform normals with transformation of arbitrary
// non-uniform scales (including negative) and skewing. The
// code assumes the last column of m is [0,0,0,1].

mat3 adjugate( in mat4 m )
{
    return mat3(cross(m[1].xyz, m[2].xyz), 
                cross(m[2].xyz, m[0].xyz), 
                cross(m[0].xyz, m[1].xyz));

    /*
    // alternative way to write the adjoint

    return mat3( 
     m[1].yzx*m[2].zxy-m[1].zxy*m[2].yzx,
     m[2].yzx*m[0].zxy-m[2].zxy*m[0].yzx,
     m[0].yzx*m[1].zxy-m[0].zxy*m[1].yzx );
    */
    
    /*
    // alternative way to write the adjoint

    return mat3( 
     m[1][1]*m[2][2]-m[1][2]*m[2][1],
     m[1][2]*m[2][0]-m[1][0]*m[2][2],
     m[1][0]*m[2][1]-m[1][1]*m[2][0],
     m[0][2]*m[2][1]-m[0][1]*m[2][2],
	 m[0][0]*m[2][2]-m[0][2]*m[2][0],
     m[0][1]*m[2][0]-m[0][0]*m[2][1],
     m[0][1]*m[1][2]-m[0][2]*m[1][1],
     m[0][2]*m[1][0]-m[0][0]*m[1][2],
     m[0][0]*m[1][1]-m[0][1]*m[1][0] );
    */
}

// this one below is the full 4x4 implementation, from
// https://github.com/graphitemaster/normals_revisited

/*
float minor( in mat4x4 m, int r0, int r1, int r2, int c0, int c1, int c2)
{
  return m[r0][c0] * (m[r1][c1] * m[r2][c2] - m[r2][c1] * m[r1][c2]) -
         m[r0][c1] * (m[r1][c0] * m[r2][c2] - m[r2][c0] * m[r1][c2]) +
         m[r0][c2] * (m[r1][c0] * m[r2][c1] - m[r2][c0] * m[r1][c1]);
}

mat4x4 cofactor( mat4x4 m )
{
  mat4x4 dst;

  // dst[0][0] =  minor(m, 1, 2, 3, 1, 2, 3);
  //
  // dst[0][0] = m[1][1]*(m[2][2]*m[3][3]-m[3][2]*m[2][3]) -
  //             m[1][2]*(m[2][1]*m[3][3]-m[3][1]*m[2][3]) +
  //             m[1][3]*(m[2][1]*m[3][2]-m[3][1]*m[2][2]);
  //
  // but assuming a regular 4x4 matrix with last columne [0,0,0,1], then
  //
  // m[0][3] = 0
  // m[1][3] = 0
  // m[2][3] = 0
  // m[3][3] = 1
  //
  // so
  //
  // dst[0][0] = m[1][1]*m[2][2] - m[1][2]*m[2][1];
  //
  // which is the simplification above in the adjoint() function.

  
  dst[0][0] =  minor(m, 1, 2, 3, 1, 2, 3);
  dst[0][1] = -minor(m, 1, 2, 3, 0, 2, 3);
  dst[0][2] =  minor(m, 1, 2, 3, 0, 1, 3);
  dst[0][3] = -minor(m, 1, 2, 3, 0, 1, 2);
  
  dst[1][0] = -minor(m, 0, 2, 3, 1, 2, 3);
  dst[1][1] =  minor(m, 0, 2, 3, 0, 2, 3);
  dst[1][2] = -minor(m, 0, 2, 3, 0, 1, 3);
  dst[1][3] =  minor(m, 0, 2, 3, 0, 1, 2);
  
  dst[2][0] =  minor(m, 0, 1, 3, 1, 2, 3);
  dst[2][1] = -minor(m, 0, 1, 3, 0, 2, 3);
  dst[2][2] =  minor(m, 0, 1, 3, 0, 1, 3);
  dst[2][3] = -minor(m, 0, 1, 3, 0, 1, 2);
  
  dst[3][0] = -minor(m, 0, 1, 2, 1, 2, 3);
  dst[3][1] =  minor(m, 0, 1, 2, 0, 2, 3);
  dst[3][2] = -minor(m, 0, 1, 2, 0, 1, 3);
  dst[3][3] =  minor(m, 0, 1, 2, 0, 1, 2);
  
  return dst;
}
*/


// sphere intersection : https://iquilezles.org/articles/intersectors/
float iSphere( in vec3 ro, in vec3 rd, in mat4 worldToObject )
{
	vec3 roo = (worldToObject*vec4(ro,1.0)).xyz;
    vec3 rdd = (worldToObject*vec4(rd,0.0)).xyz;
    float a = dot( rdd, rdd );
	float b = dot( roo, rdd );
	float c = dot( roo, roo ) - 1.0;
	float h = b*b - a*c;
	if( h<0.0 ) return -1.0;
	return (-b-sqrt(h))/a;
}

// sphere shadow : https://iquilezles.org/articles/intersectors/
float sSphere( in vec3 ro, in vec3 rd, in mat4 worldToObject )
{
	vec3 roo = (worldToObject*vec4(ro,1.0)).xyz;
    vec3 rdd = (worldToObject*vec4(rd,0.0)).xyz;
    float a = dot( rdd, rdd );
	float b = dot( roo, rdd );
	float c = dot( roo, roo ) - 1.0;
	float h = b*b - a*c;
	if( h<0.0 ) return -1.0;
    if( b<0.0 ) return  1.0;
    return -sign(c);
}

//-----------------------------------------------------------------------------------------

mat4 rotateAxisAngle( vec3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1.0 - c;

    return mat4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
			     0.0,                0.0,                0.0,                1.0 );
}

mat4 translate( in vec3 v )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
				 0.0, 1.0, 0.0, 0.0,
				 0.0, 0.0, 1.0, 0.0,
				 v.x, v.y, v.z, 1.0 );
}

mat4 scale( in vec3 v )
{
    return mat4( v.x, 0.0, 0.0, 0.0,
				 0.0, v.y, 0.0, 0.0,
				 0.0, 0.0, v.z, 0.0,
				 0.0, 0.0, 0.0, 1.0 );
}

//-----------------------------------------------------------------------------------------

mat4 getSphereToWorld( in int i, out bool isFlipped )
{
    float t = iTime*0.2;
    vec3 fli = sign(sin(float(i)+vec3(1.0,2.0,3.0)));
    mat4 rot = rotateAxisAngle( normalize(sin(float(11*i)+vec3(0.0,2.0,1.0))), 0.0+t*1.3 );
    mat4 ros = rotateAxisAngle( normalize(sin(float( 7*i)+vec3(4.0,3.0,5.0))), 2.0+t*1.1 );
    mat4 sca = scale( (0.3+0.25*sin(float(13*i)+vec3(0.0,1.0,4.0)+t*1.7))*fli );
    mat4 tra = translate( vec3(0.0,0.5,0.0) + 0.5*sin(float(17*i)+vec3(2.0,5.0,3.0)+t*1.2) );
    
    isFlipped = (fli.x*fli.y*fli.z) < 0.0;
    return ros * tra * sca * rot;
}

const int kNumSpheres = 12;

float shadow( in vec3 ro, in vec3 rd )
{
    for( int i=0; i<kNumSpheres; i++ )
    {
        bool tmp;
        mat4 objectToWorld = getSphereToWorld( i, tmp );
        mat4 worldToObject = inverse( objectToWorld );
        if( sSphere( ro, rd, worldToObject ) > 0.0 )
            return 0.0;
    }
    return 1.0;
}

vec3 shade( in vec3 ro, in vec3 rd, in float t, 
            in float oid, in vec3 wnor )
{
    vec3 lig = normalize(vec3(-0.8,0.4,0.1));
    vec3 wpos = ro + t*rd;

    // material
    vec3  mate = vec3(0.18);
    if( oid>1.5 ) mate = 0.18*(0.55+0.45*cos(7.0*oid+vec3(0.0,2.0,4.0)));

    // lighting
    vec3 hal = normalize( lig-rd );
    float dif = clamp( dot(wnor,lig), 0.0, 1.0 );
    float sha = shadow( wpos+0.01*wnor, lig );
    float fre = clamp(1.0+dot(rd,wnor),0.0,1.0);
    float spe = clamp(dot(wnor,hal),0.0,1.0);

    // material * lighting		
    vec3 col = vec3(0.0);
    col += 8.0*vec3(1.00,0.90,0.80)*dif*sha;
    col += 2.0*vec3(0.10,0.20,0.30)*(0.6+0.4*wnor.y);
    col += 1.0*vec3(0.10,0.10,0.10)*(0.5-0.5*wnor.y);
    col += fre*(0.6+0.4*wnor.y);
    col *= mate;
    col += pow(spe,16.0)*dif*sha*(0.1+0.9*fre);

    // fog
    col = mix( col, vec3(0.7,0.8,1.0), 1.0-exp( -0.003*t*t ) );

    return col;
}
        
#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2  // Set AA to 1 if your machine is too slow
#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera movement	
	float an = 0.4*iTime;
	vec3 ro = vec3( 2.5*cos(an), 0.7, 2.5*sin(an) );
    vec3 ta = vec3( 0.0, 0.2, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/iResolution.y;
#else    
        vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
#endif

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

        // raytrace
        float tmin = 1e10;
        vec3  wnor = vec3(0.0);
        float oid = 0.0;

        // raytrace plane
        float h = (-0.5-ro.y)/rd.y;
        if( h>0.0 ) 
        { 
            tmin = h; 
            wnor = vec3(0.0,1.0,0.0); 
            vec3 wpos = ro+tmin*rd;
            oid = 1.0;
        }

        // raytrace spheres
        for( int i=0; i<kNumSpheres; i++ )
        {
            // location of sphere i
            bool isFlipped = false;
            mat4 objectToWorld = getSphereToWorld( i, isFlipped );
            mat4 worldToObject = inverse( objectToWorld );

            float res = iSphere( ro, rd, worldToObject );
            if( res>0.0 && res<tmin )
            {
                tmin = res; 
                vec3 wpos = ro+tmin*rd;
                vec3 opos = (worldToObject*vec4(wpos,1.0)).xyz;
                vec3 onor = normalize(opos) *(isFlipped?-1.0:1.0);

                #if METHOD==0 // CORRECT
                wnor = normalize(adjugate(objectToWorld)*onor);
                //wnor = normalize((cofactor(objectToWorld)*vec4(onor,0.0)).xyz );
                #endif
                #if METHOD==1 // WRONG OFTEN
                wnor = normalize((transpose(inverse(objectToWorld))*vec4(onor,0.0)).xyz);
                #endif
                #if METHOD==2 // WRONG ALWAYS
                wnor = normalize((objectToWorld*vec4(onor,0.0)).xyz);
                #endif

                oid = 2.0 + float(i);
            }
        }

        // shading/lighting	
        vec3 col = vec3(0.7,0.8,1.0);
        if( oid>0.5 )
        {
            col = shade( ro, rd, tmin, oid, wnor );
        }

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    tot = pow( tot, vec3(0.4545) );

	fragColor = vec4( tot, 1.0 );
}