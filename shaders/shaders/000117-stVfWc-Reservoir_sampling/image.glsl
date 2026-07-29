// Image (image) — Reservoir sampling by iq
// https://www.shadertoy.com/view/stVfWc

// Inigo Quilez 2022
//
// A very loose interpretation of the ReSTIR paper,
//
// https://research.nvidia.com/sites/default/files/pubs/2020-07_Spatiotemporal-reservoir-resampling/ReSTIR.pdf
//
// but without the pdf resampling bit. I'm just implementing the spation-temporal
// reservoir for ambient occlusion, but I might be making mistakes ^__^
//
// The paper is awesome although a bit too vague and unclear at times, but the
// main insight anyways is that one can share "samples" across pixels and frames,
// instead of sharing the "lighting" resulting from those samples. A "sample" in
// this context is a raycast direction for the ambient occlusion visibility test.
//
// When a pixel casts a ray that doesn't hit geometry and gets ambient light as a
// result, it informs its neigbors and future self about this unocluded direction
// for them to consider raycasting in that direction as well. Recall we ideally
// cast only in the direction of unoccluded incoming light, if we had such knowledge
// that is. Along with the sample direction, the per pixel reservoir also shares
// the weight that the sample should be reused with. In an ideal world all samples
// converge into unoccluded directions and their weights to the real ambient
// occlusion value. That would produce noise free images!
//
// I think I probably got some of the math wrong, including the sample invalidation.
// Also I'm casting cosine distributed rays, which in theory cannot be reused just
// like that with neighboring pixels. Some re-weighting needs to happen, but I am
// not doing anything about it right now. Regardless, the shader is doing something
// useful, at least images come cleaner, especially in higher res monitors.
//
// Also because Shadertoy only has RGBA32F buffers, I had to be a bit creative with
// data packing, since I needed to store surface normals, object IDs, intersection
// distances, the reservoir's sample direction and its weight. So I'm encoding
// samples in a single float insted of three floats by choosing its closest
// spherical fibonacci point. I used 2^21 (2 million) such points so I can store
// the point ID in a float32 without exceeding its mantissa bits. Surface normals
// are also stored that way in a single float.
//
// Buffer A contains the main render pass, and the initial random sample. Buffer B
// does the temporal reservoir reuse. Buffers C and D do the spatial reservoir
// reuse. The Image pass casts the second and final occlusion ray, using a good 
// sample direction by looking into the reservoir.
//
// You can use the mouse to compare 2 naive samples of ambient occlusion to the
// reservoir method, which also uses 2 samples. Also you can disable the temporal 
// and spatial reservoirs in the Common tab. You can also choose to compare to
// ground-truth:

// 0: 64 samples - ground truth
// 1:  2 samples - same cost as reservoir, so fair comparison
#define COMPARE_TO 1

// set to 0 for clean but wrong images...
#define UNBIASED 0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ip = ivec2(fragCoord);
    
    // init randoms
    int ifr = int(iTime*144.0); // not using iFrame so I can pause and compare
    srand( ip, ifr + 5 );

    // read gbuffer
    vec4 data = texelFetch(iChannel0,ip,0);

    // get reservoir, object id and intersection distance from gbuffer
    Reservoir r; vec2 tm;
    read_gbuffer( data, r, tm );
    
    // reconstruct current camera
    vec3 ro, rd; mat3 ca;
    raster_to_camera( fragCoord, iResolution.xy, iTime, ro, rd, ca );


    // pixel and mouse coordiantes
    float px = (2.0*fragCoord.x-iResolution.x)/iResolution.y;
    float mx = (2.0*   iMouse.x-iResolution.x)/iResolution.y;
    if( iMouse.z<0.5 ) mx = -cos((iTime-7.0)*6.283185/6.0)*iResolution.x/iResolution.y;
    
    // animation
    float ani = smoothstep(7.0,8.0,iTime);
    mx = mix(-2.0,mx,ani);
    
    // do lighting/shading
    vec3 col = vec3(0.0);
    if( tm.y>0.0 )
    {
        vec3 pos = ro + tm.x*rd;
        
        // read normap from G-Buffer and decompress it
        vec3 nor = id_to_nor( texelFetch(iChannel1,ip,0).z );

        // coloring/material
        float al = smoothstep( 0.01, 0.2, -sin((iTime-7.0)*6.283185/12.0) );
        vec3 mate = mix( vec3(1.0), 0.6 + 0.5*sin(tm.y+vec3(0,2,4)), al*ani );
        
        // do ambient occlusion as usual... (left)
        if( px<mx )
        {
             #if COMPARE_TO==0
                 // 36 stratified samples as "ground truth"
                 col = vec3(0.0);
                 const int num = 6;
                 for( int j=0; j<num; j++ )
                 for( int i=0; i<num; i++ )
                 {
                    vec2 uv = vec2(float(i)+frand(), float(j)+frand())/float(num);
                    vec3 dir = cosineDirection( uv, nor );
                    if( raycast(pos+0.001*nor, dir ).y < 0.0 ) col += 1.0;
                 }
                 col /= float(num*num);
             #else
                 // one or two blue noise samples
                 vec4 ra = texelFetch( iChannel2, (ip+ifr*ivec2(71,313))&1023, 0 );
                 vec3 dir = cosineDirection( ra.xy, nor ); if( raycast(pos+0.001*nor, dir ).y < 0.0 ) col += 1.0;
                 #if UNBIASED==1
                 dir = cosineDirection( ra.zw, nor ); if( raycast(pos+0.001*nor, dir ).y < 0.0 ) col += 1.0;
                 col /= 2.0;
                 #endif
             #endif
        }
        // ... or using the reservoir (right)
        else
        {
            #if UNBIASED==1
            vec3 dir = id_to_nor(r.y); dir *= sign(dot(dir,nor));
            float sha = (raycast(pos+0.001*nor,dir).y<0.0) ? 1.0 : 0.0;
            col = vec3( sha * r.wsum/r.m );
            #else
            col = vec3(       r.wsum/r.m ); 
            #endif
        }
        col *= mate;
    }

    // gammaish
    // col = sqrt(col);
    
    // vertical separating line
    col = mix( col, vec3(1,0,0), 1.0-smoothstep( 0.0, 0.01, abs(px-mx) ) );
    
    fragColor = vec4( col, 1.0 );
}