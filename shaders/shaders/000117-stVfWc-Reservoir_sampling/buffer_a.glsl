// Buffer A (buffer) — Reservoir sampling by iq
// https://www.shadertoy.com/view/stVfWc

// --------------------------------------------------------
// render G-Buffer and shoot initial random occlusion ray
// --------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ip = ivec2(fragCoord);
    
    // init randoms
    int ifr = int(iTime*144.0);
    srand( ip, ifr + 0 );


    // camera and ray
    vec3 ro, rd; mat3 ca;
    raster_to_camera( fragCoord, iResolution.xy, iTime, ro, rd, ca );

    // raycast scene (.x = distance, .y = material)
    vec2 tm = raycast( ro, rd );
    
    if( tm.y<0.0 )
    {
        fragColor = vec4( 0.0, 0.0, 0.0, -1.0 );
        return;
    }
    
    // compute intersection and normal
    vec3 pos = ro + tm.x*rd;
    vec3 nor = calcNormal(pos,tm.x);

    // pick one random direction and shoot an shadow/occlusion ray
    vec2  ran = texelFetch( iChannel2, (ivec2(fragCoord)+ifr*ivec2(71,313))&1023, 0 ).xy;
    vec3  dir = cosineDirection( ran, nor );
    float sha = (raycast(pos+0.001*nor, dir ).y < 0.0) ? 1.0 : 0.0;
    
    // store occlusion information in reservoir
    Reservoir r = Reservoir( nor_to_id(dir), sha, 1.0 );

    // store all this in G-Buffer (4 floats)
    //    reservoir (sample direction and weight - no need to store M, which is 1)
    //    normal
    //    object id
    //    intersection distance
    fragColor = vec4( r.y, r.wsum, nor_to_id(nor), tm_to_float(tm) );
}