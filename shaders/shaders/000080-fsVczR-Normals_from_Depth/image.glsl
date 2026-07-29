// Image (image) — Normals from Depth by iq
// https://www.shadertoy.com/view/fsVczR

// When computing world space normals from a camera space depth buffer
// the naive way, artifact appear at the edges of the objects. This
// shaders shows one way to reduce these artifacts, described by Yuwen Wu
// here: https://atyuwen.github.io/posts/normal-reconstruction
//
// On the left you see the naive method to compute normals, which produces
// wrong results. On the right side you see the improved method which is
// very close to the ground truth, as long as the surface details are larger
// than 2 pixels. Both the naive and improved method are compared to the
// ground truth normals every second.
//
// Like the naive method, the improved one computes world space normals
// by considering the world position derivatives with respect to the
// pixel's X and Y coordinates.
//
// However, instead of using central differences blindly, it picks either
// the left or right neighbor based on which one is estimated to belong to
// the same surface as the pixel for which we are currently computing a
// normal. This is done by examining a second pixel to the right and left
// and doing a comparison between the current pixel's depth and that we'd
// expect to have at the current pixel if the neighbors were forming a
// plane. Because such interpolation is linear, we do it in 1/z rather
// than z space. So,
//
// 1/(1/a+1/a-1/b) rather than a+a-b, which leads to ab/(2b-a)
//
// The side with lowest discontinuity is picked, to avoid edge artifacts
// as much as poosible.

// recoved world space from depth
vec3 getPos( in ivec2 fragCoord, in float depth );

// computes the normal at pixel "p" based on the deph buffer "depth"
vec3 computeNormalImproved( const sampler2D depth, in ivec2 p )
{
    float c0 = texelFetch(depth,p           ,0).w;
    float l2 = texelFetch(depth,p-ivec2(2,0),0).w;
    float l1 = texelFetch(depth,p-ivec2(1,0),0).w;
    float r1 = texelFetch(depth,p+ivec2(1,0),0).w;
    float r2 = texelFetch(depth,p+ivec2(2,0),0).w;
    float b2 = texelFetch(depth,p-ivec2(0,2),0).w;
    float b1 = texelFetch(depth,p-ivec2(0,1),0).w;
    float t1 = texelFetch(depth,p+ivec2(0,1),0).w;
    float t2 = texelFetch(depth,p+ivec2(0,2),0).w;
    
    float dl = abs(l1*l2/(2.0*l2-l1)-c0);
    float dr = abs(r1*r2/(2.0*r2-r1)-c0);
    float db = abs(b1*b2/(2.0*b2-b1)-c0);
    float dt = abs(t1*t2/(2.0*t2-t1)-c0);
    
    vec3 ce = getPos(p,c0);

    vec3 dpdx = (dl<dr) ?  ce-getPos(p-ivec2(1,0),l1) : 
                          -ce+getPos(p+ivec2(1,0),r1) ;
    vec3 dpdy = (db<dt) ?  ce-getPos(p-ivec2(0,1),b1) : 
                          -ce+getPos(p+ivec2(0,1),t1) ;

    return normalize(cross(dpdx,dpdy));
}

// naive way of computing the normal
vec3 computeNormalNaive( const sampler2D depth, in ivec2 p )
{
    vec3 l1 = getPos(p-ivec2(1,0),texelFetch(depth,p-ivec2(1,0),0).w);
    vec3 r1 = getPos(p+ivec2(1,0),texelFetch(depth,p+ivec2(1,0),0).w);
    vec3 t1 = getPos(p+ivec2(0,1),texelFetch(depth,p+ivec2(0,1),0).w);
    vec3 b1 = getPos(p-ivec2(0,1),texelFetch(depth,p-ivec2(0,1),0).w);
    vec3 dpdx = r1-l1;
    vec3 dpdy = t1-b1;
    return normalize(cross(dpdx,dpdy));
}

// compute the world space position of a pixel with coordinates
// fragCoord and distance "depth" to camera. This will need to
// change depending on wether your depth buffer stores "depth"
// "z", "reverse z", etc
vec3 getPos( in ivec2 fragCoord, in float depth )
{
    vec2 p = (2.0*vec2(fragCoord)-iResolution.xy)/iResolution.y;
    vec3 ro, rd;
    camera( ro, rd, iTime, p );
    return depth*rd;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 p = ivec2(fragCoord);
 
    //----------
    // compute
    //----------

    // ground truth normal
    vec3 norT = texelFetch( iChannel0, p, 0 ).xyz;
 
    // naive way of computing the normal
    vec3 norN = computeNormalNaive( iChannel0, p );
    
    // improved normal computation
    vec3 norI = computeNormalImproved( iChannel0, p );

    //----------
    // display
    //----------

    // left: naive, right: improved
    float x = fragCoord.x/iResolution.x;
    vec3 nor = (x<0.5) ? norN : norI;
    
    // compare to true normal
    if( sin(0.5*6.283185*iTime)<0.0 ) nor = norT;

    // color : switch normals and lighting
    vec3 col = nor;
    if( sin(6.283185*iTime/16.0)<0.0 ) col = vec3(0.1,0.15,0.2)*nor.y + vec3(1.0,0.9,0.85)*vec3(nor.x*0.8+nor.y*0.5+nor.z*0.6);
    
    // depth darkening to hide geometry aliasing
    float t = texelFetch( iChannel0, p, 0 ).w;
    col *= exp2(-0.12*t*t);
    
    // separation bar
    col = mix( vec3(1.0), col, smoothstep( 0.002, 0.003, abs(x-0.5) ) );
    
    fragColor = vec4(col,1.0);
}