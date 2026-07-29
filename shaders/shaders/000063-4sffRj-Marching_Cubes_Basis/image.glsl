// Image (image) — Marching Cubes Basis by gltracy
// https://www.shadertoy.com/view/4sffRj

///////////////////////////////////////////////////
// csg
float opUnion( float d0, float d1 ) {
    return min( d0, d1 );
}

///////////////////////////////////////////////////
// 2d primitive
float udBox( vec2 v, vec2 a, vec2 b ) {
    return length( v - clamp( v, a, b ) );
}

float sdDot( vec2 v, vec2 c, float r ) {
    return length( v - c ) - r;
}

float udLine( vec2 v, vec2 p0, vec2 p1 ) {
    p1 -= p0;
    v  -= p0;
    
    float e = dot( v, p1 ) / dot( p1, p1 );
    
    return length( v - p1 * clamp( e, 0.0, 1.0 ) );
}

// @iq : https://www.shadertoy.com/view/XsXSz4
float sdTri( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
	vec2 e0 = p1 - p0;
	vec2 e1 = p2 - p1;
	vec2 e2 = p0 - p2;

	vec2 v0 = p - p0;
	vec2 v1 = p - p1;
	vec2 v2 = p - p2;

	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    vec2 d = min( min( vec2( dot( pq0, pq0 ), v0.x*e0.y-v0.y*e0.x ),
                       vec2( dot( pq1, pq1 ), v1.x*e1.y-v1.y*e1.x )),
                       vec2( dot( pq2, pq2 ), v2.x*e2.y-v2.y*e2.x ));

	return -sqrt(d.x)*sign(d.y);
}

///////////////////////////////////////////////////
// 2d graphics
vec4 sl_colorBuffer;
vec4 sl_color;
float sl_size;
float sl_sharp;
mat3 sl_mat;

void slClearColor( float r, float g, float b, float a ) {
    sl_colorBuffer = vec4( r, g, b, a );
}

void slColor( vec4 c ) {
    sl_color = c;
}

void slSize( float s ) {
    sl_size = s;
}

void slSharp( float s ) {
    sl_sharp = s;
}

void slIdentity( void ) {
    sl_mat = mat3( 1.0 );
}

void slMat( mat3 m ) {
    sl_mat = m;
}

vec2 slMap( vec2 v ) {
    vec3 p = sl_mat * vec3( v, 1.0 );
    return p.xy / p.z;
}

float slMap( float v ) {
    vec3 p = sl_mat * vec3( v, v, 0.0 );
    return length( p.xy ) / sqrt( 2.0 );
}

void slDraw( float d )	{
    float size = slMap( sl_size );
    float sharp = sl_sharp;
    
    float e = smoothstep( size * clamp( sharp, 0.0, 1.0 ), size, d );
    
    sl_colorBuffer.xyz = mix( sl_colorBuffer.xyz, sl_color.xyz, ( 1.0 - e ) * sl_color.a );
}

vec4 slGetPixel( void ) {
    return sl_colorBuffer;
}

///////////////////////////////////////////////////
// matrix
float mtDet( mat2 m ) {
    return m[0][0] * m[1][1] - m[0][1] * m[1][0];
}

mat3 mtMove( float x, float y ) {
    return mat3( 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, x, y, 1.0);
}

mat3 mtScale( float x, float y ) {
    return mat3( x, 0.0, 0.0, 0.0, y, 0.0, 0.0, 0.0, 1.0);
}

mat3 mtRot( float angle ) {
    angle = radians( angle );
    float c = cos( angle );
    float s = sin( angle );
    return mat3( c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0);
}

///////////////////////////////////////////////////
// Marching Cubes
const float MC_H = 0.288675; // 0.5 / sqrt( 3.0 )
vec2 mc_verts[8], mc_edge_mids[12];
vec4 mc_line_color = vec4( 0.0, 0.0, 0.0, 1.0 );
vec4 mc_vert_color = vec4( 1.0, 0.3, 0.2, 1.0 );
vec4 mc_face_color  = vec4( 0.4, 0.7, 1.0, 0.6 );
vec4 mc_face_color2 = vec4( 1.0, 0.6, 0.0, 0.6 );
vec4 mc_face_color3 = vec4( 1.0, 0.4, 0.3, 0.6 );
vec4 mc_face_color4 = vec4( 0.6, 0.9, 0.3, 0.6 );

void mcInit( void ) {
    mc_verts[0] = vec2( 0.0, 0.0 );
    mc_verts[1] = vec2( 1.0, 0.0 );
    mc_verts[2] = vec2( 0.0 + 0.5, 0.0 + MC_H );
    mc_verts[3] = vec2( 1.0 + 0.5, 0.0 + MC_H );

    mc_verts[4] = vec2( 0.0, 1.0 );
    mc_verts[5] = vec2( 1.0, 1.0 );
    mc_verts[6] = vec2( 0.0 + 0.5, 1.0 + MC_H );
    mc_verts[7] = vec2( 1.0 + 0.5, 1.0 + MC_H );

    mc_edge_mids[0]  = (mc_verts[0] + mc_verts[1]) * 0.5;
    mc_edge_mids[1]  = (mc_verts[2] + mc_verts[3]) * 0.5;
    mc_edge_mids[2]  = (mc_verts[4] + mc_verts[5]) * 0.5;
    mc_edge_mids[3]  = (mc_verts[6] + mc_verts[7]) * 0.5;
    
    mc_edge_mids[4]  = (mc_verts[0] + mc_verts[2]) * 0.5;
    mc_edge_mids[5]  = (mc_verts[4] + mc_verts[6]) * 0.5;
    mc_edge_mids[6]  = (mc_verts[1] + mc_verts[3]) * 0.5;
    mc_edge_mids[7]  = (mc_verts[5] + mc_verts[7]) * 0.5;
    
    mc_edge_mids[8]  = (mc_verts[0] + mc_verts[4]) * 0.5;
    mc_edge_mids[9]  = (mc_verts[1] + mc_verts[5]) * 0.5;
    mc_edge_mids[10] = (mc_verts[2] + mc_verts[6]) * 0.5;
    mc_edge_mids[11] = (mc_verts[3] + mc_verts[7]) * 0.5;
}

// no vertex 5
void mcCubeBack( vec2 u ) {
    slColor( mc_line_color );
    
    slDraw( udLine( u, mc_verts[0], mc_verts[1] ) );
    slDraw( udLine( u, mc_verts[2], mc_verts[3] ) );
    slDraw( udLine( u, mc_verts[6], mc_verts[7] ) );
    
    slDraw( udLine( u, mc_verts[0], mc_verts[2] ) );
    slDraw( udLine( u, mc_verts[1], mc_verts[3] ) );
    slDraw( udLine( u, mc_verts[4], mc_verts[6] ) );
    
    slDraw( udLine( u, mc_verts[0], mc_verts[4] ) );
    slDraw( udLine( u, mc_verts[2], mc_verts[6] ) );
    slDraw( udLine( u, mc_verts[3], mc_verts[7] ) );
}

void mcCubeFront( vec2 u ) {
    slColor( mc_line_color );
    
    slDraw( udLine( u, mc_verts[4], mc_verts[5] ) );
    slDraw( udLine( u, mc_verts[5], mc_verts[7] ) );
    slDraw( udLine( u, mc_verts[1], mc_verts[5] ) );
}

void mcTri( vec2 u, vec2 v0, vec2 v1, vec2 v2 ) {
    float sd = sdTri( u, v0, v1, v2 );
    slDraw( max(sd, 0.0) );
    
    slColor( mc_line_color );
    slDraw( abs(sd) );
}

void mcVerts( vec2 u, int bits ) {
    int mask = 256;
    for ( int i = 7; i >= 0; i-- ) {
        mask /= 2;
        if ( bits >= mask ) {
            bits -= mask;
            
            float sd = sdDot( u, mc_verts[i], 0.05 );
            
            slColor( mc_vert_color );
            slDraw( max(sd, 0.0) );
            
            slColor( mc_line_color );
            slDraw( abs(sd) );
        }
    }
}

bool mcCheck( vec2 v ) {
    return udBox( v, vec2( 0.0 ) - 0.1, vec2( 1.0 + 0.5, 1.0 + MC_H ) + 0.1 ) <= 1e-6;
}

///////////////////////////////////////////////////
// main

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // init context
    slSize( 2.0 );
    slSharp( 0.0 );
    slIdentity();

    // clear buffer
    slClearColor( 1.0, 1.0, 1.0, 1.0 );

    // camera
    float scale = 6.0 / iResolution.y;
    mat3 M = mtMove( 0.5 + 0.25, 0.5 + MC_H * 0.5 - 0.8 ) * mtScale( scale, scale );
    
    // pixel pos
    vec2 u = fragCoord.xy - iResolution.xy * 0.5;

    // init marching cube list
    mcInit();
    
    // case 0
	slMat( mtMove( +4.0, -1.5 ) * M );
    {
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcCubeFront( v );
        }
    }
   
    // case 1
	slMat( mtMove( 2.0, -1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );   
        	slColor( mc_face_color ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[8] );
    		mcCubeFront( v );
 			mcVerts( v, 1 );
        }
    }
    
    // case 2
	slMat( mtMove( 0.0, -1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );   
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[8], mc_edge_mids[6] );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[6], mc_edge_mids[8], mc_edge_mids[9] );
            mcCubeFront( v );
            mcVerts( v, 1 + 2 );
    	}
    }

    // case 3
	slMat( mtMove( -2.0, -1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );    
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[8] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[9], mc_edge_mids[2], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 1 + 32 );
        }
    }   

    // case 4
	slMat( mtMove( -4.0, -1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[9] );
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[10], mc_edge_mids[9] );
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[9], mc_edge_mids[10], mc_edge_mids[11] );
            mcCubeFront( v );
            mcVerts( v, 2 + 8 );
        }
    }

    // case 5
	slMat( mtMove( +4.0, 0.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[8], mc_edge_mids[11], mc_edge_mids[9] );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[8], mc_edge_mids[10], mc_edge_mids[11] );
            mcCubeFront( v );
            mcVerts( v, 1 + 2 + 8 );
        }
    }
   
    // case 6
    slMat( mtMove( +2.0, 0.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 ); 
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[9] );
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[10], mc_edge_mids[9] );
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[9], mc_edge_mids[10], mc_edge_mids[11] );
            slColor( mc_face_color  ); mcTri( v, mc_edge_mids[8], mc_edge_mids[5], mc_edge_mids[2] );
            mcCubeFront( v );
            mcVerts( v, 2 + 8 + 16 );
        }
    }
 
    // case 7
	slMat( mtMove( 0.0, 0.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v ); 
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[1], mc_edge_mids[11], mc_edge_mids[6] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[10], mc_edge_mids[5], mc_edge_mids[3] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[8] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[9], mc_edge_mids[2], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 1 + 8 + 32 + 64 );
        }
    } 
    
    // case 8
	slMat( mtMove( -2.0, 0.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );   
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[11], mc_edge_mids[6] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[8], mc_edge_mids[3] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[3], mc_edge_mids[11] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[8], mc_edge_mids[5], mc_edge_mids[3] );
            mcCubeFront( v );
            mcVerts( v, 1 + 8 + 64 );
        }
	}
  
    // case 9
	slMat( mtMove( -4.0, 0.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[5] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[5], mc_edge_mids[11] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[9], mc_edge_mids[11] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[5], mc_edge_mids[3], mc_edge_mids[11] );
            mcCubeFront( v );
            mcVerts( v, 2 + 8 + 64 );
        }
    }
    
    // case 10
	slMat( mtMove( +4.0, +1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );   
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[8] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[11], mc_edge_mids[3], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 1 + 128 );
        }
    } 

    // case 11
	slMat( mtMove( +2.0, +1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[8], mc_edge_mids[6] );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[6], mc_edge_mids[8], mc_edge_mids[9] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[11], mc_edge_mids[3], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 1 + 2 + 128 );
        }
    }
    
    // case 12
	slMat( mtMove( 0.0, +1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v ); 
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[0], mc_edge_mids[9], mc_edge_mids[6] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[8], mc_edge_mids[5], mc_edge_mids[2] );
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[11], mc_edge_mids[3], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 2 + 16 + 128 );
        }
    }

   // case 13
	slMat( mtMove( -2.0, +1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );   
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[5] );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[5], mc_edge_mids[2] );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[6], mc_edge_mids[1], mc_edge_mids[3] );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[6], mc_edge_mids[3], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 1 + 8 + 16 + 128 );
        }
    }

    // case 14
	slMat( mtMove( -4.0, +1.5 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[8], mc_edge_mids[10] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[10], mc_edge_mids[7] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[10], mc_edge_mids[3], mc_edge_mids[7] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[7], mc_edge_mids[6] );
            mcCubeFront( v );
            mcVerts( v, 1 + 8 + 128 );
        }
    }
    
     // case 3c
	slMat( mtMove( 2.0, +3.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[4], mc_edge_mids[9] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[7], mc_edge_mids[9] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[2], mc_edge_mids[7] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[8], mc_edge_mids[2] );
            mcCubeFront( v );
            mcVerts( v, 2 + 8 + 16 + 64 + 128 );
        }
    }
    
    // case 6c
	slMat( mtMove( 0.0, +3.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );   
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[3], mc_edge_mids[6] );
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[4], mc_edge_mids[8], mc_edge_mids[3] );
            slColor( mc_face_color3 ); mcTri( v, mc_edge_mids[6], mc_edge_mids[3], mc_edge_mids[11] );
            
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[8], mc_edge_mids[3], mc_edge_mids[9] );
            slColor( mc_face_color2 ); mcTri( v, mc_edge_mids[9], mc_edge_mids[3], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 8 + 16 + 32 + 64 );
        }
	}
    
    // case 7c
	slMat( mtMove( -2.0, +3.0 ) * M );
  	{
        vec2 v = slMap(u);
        if ( mcCheck( v ) ) {
            mcCubeBack( v );
            mcVerts( v, 4 );   
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[11], mc_edge_mids[6] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[8], mc_edge_mids[3] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[0], mc_edge_mids[3], mc_edge_mids[11] );
            slColor( mc_face_color4 ); mcTri( v, mc_edge_mids[8], mc_edge_mids[5], mc_edge_mids[3] );
            
            slColor( mc_face_color ); mcTri( v, mc_edge_mids[9], mc_edge_mids[2], mc_edge_mids[7] );
            mcCubeFront( v );
            mcVerts( v, 1 + 8 + 32 + 64 );
        }
	}
    
    fragColor = slGetPixel();
}