// Cube A (cubemap) — iResolution, iMouse, iDate, etc by FabriceNeyret2
// https://www.shadertoy.com/view/llySRh

// cubemaps provides 6 x 1024x1024 textures.
// - power of 2 allows correct MIPmapping, ease quadtrees, etc.
// - secure 1024 size whatever the window size.
// - attention: only half-floats, no texelFetch, 
//              different MIPmap LODmax; take T( vec2(0,0), 10. )
//              iResolution = 1024 rather than screen size.

#define T(U)       texture( iChannel0, vec3(U,1)  ) // access. U in [-1,1]
//#define T(U,l)   textureLod( iChannel0, vec3(U,1), l  ) 


void mainCubemap( out vec4 O, vec2 U, vec3 o, vec3 D )
{
    O = vec4(0); // or side effect on border pixels
    if ( D.z < max(abs(D.x),abs(D.y)) ) return;
    U.y = 1024. - U.y;              // like buffA, but 1024 x 1024.
    
    // ... your stuff here ......................
}