// Buffer C (buffer) — Reservoir sampling by iq
// https://www.shadertoy.com/view/stVfWc

// --------------------------------------------------------
// spatial reservoir reuse
// --------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ip = ivec2(fragCoord);
    
    // init randoms
    int ifr = int(iTime*144.0);
    srand( ip, ifr + 3 );


    // reconstruct current camera
    vec3 ro, rd; mat3 ca;
    raster_to_camera( fragCoord, iResolution.xy, iTime, ro, rd, ca );
    
    // store it for next frame
    if( ip.y==0 && ip.x<=2 )
    {
        fragColor = vec4( ca[ip.x], -dot(ca[ip.x],ro) );
        return;
    }
    
    // read gbuffer
    vec4 data = texelFetch(iChannel0,ip,0);
    if( data.w<0.0 ) { fragColor= vec4(0.0,0.0,0.0,-1.0); return; }
    
    // get reservoir, object id and intersection distance from gbuffer
    Reservoir r; vec2 tm;
    read_gbuffer( data, r, tm );
    
    #if USE_SPATIAL==1

    //vec3 nor = calcNormal( ro + tm.x*rd, tm.x );
    vec3 nor = id_to_nor( texelFetch(iChannel1,ip,0).z );
    
    vec2 ran = texelFetch( iChannel2, (ivec2(fragCoord)+ifr*ivec2(71,313))&1023, 0 ).xy;
    
    // gather samples from 32 neighboring pixels
    for( int i=0; i<32; i++ )
    {
        float h = float(i)/float(32-1);
        // note I am using h and NOT sqrt(h), which would be the correct
        // thing to do to get homegeneous coverage. However, concentrating
        // more samples around the origin seems like a good idea, since
        // that's where the most relevant information is
        float a = 6.2831*(h*13.0 + ran.x);
        vec2 q = h*vec2(cos(a),sin(a));
        
        ivec2 of = ivec2( 30.0*h*vec2(cos(a),sin(a)) );
        
        vec4 neig_data = texelFetch(iChannel0,ip+of,0);

        Reservoir neig_r;
        vec2 neig_tm;
        read_gbuffer( neig_data, neig_r, neig_tm );

        if( abs(tm.x-neig_tm.x)<0.1*tm.x )
        {
            vec3 mor = id_to_nor( texelFetch(iChannel1,ip+of,0).z );
            if( dot(nor,mor)>cos(25.0*3.14159/180.0) )
            
            r = combineReservoirs( r, neig_r );
        }
    }

    #endif
    
    fragColor = store_gbuffer( r, tm );
}