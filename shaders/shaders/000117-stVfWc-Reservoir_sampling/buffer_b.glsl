// Buffer B (buffer) — Reservoir sampling by iq
// https://www.shadertoy.com/view/stVfWc

// --------------------------------------------------------
// temporal reservoir reuse
// --------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ip = ivec2(fragCoord);
    
    // init randoms
    int ifr = int(iTime*144.0);
    srand( ip, ifr + 2 );

    
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
    
    Reservoir r = Reservoir( data.x, data.y, 1.0 );
    vec2 tm = float_to_tm(data.w);

    #if USE_TEMPORAL==1
    
    // get old camear matrix
    mat3x4 oldCam = mat3x4( texelFetch(iChannel1,ivec2(0,0), 0),
                            texelFetch(iChannel1,ivec2(1,0), 0),
                            texelFetch(iChannel1,ivec2(2,0), 0) );

    // recontruct current intersection in world space
    vec4 wpos = vec4(ro + rd*tm.x,1.0);
    
    // project to previous camera space
    vec3 cpos = wpos*oldCam; // note inverse multiply
    
    // convert to previous ndc space
    ivec2 rpos = ivec2( camera_to_raster( cpos, iResolution.xy ) );
    
    if( rpos.x>=0 && rpos.y>=0 && rpos.x<int(iResolution.x) && rpos.y<int(iResolution.y) )
    {
        // fetch reservoir from gbuffer at previous frame's pixel's location
        vec4 old_data = texelFetch(iChannel1,rpos,0);
        // depack data
        Reservoir prev_r;
        vec2 prev_tm;
        read_gbuffer( old_data, prev_r, prev_tm );
        
        // is this what the paper means by "clamp"?
        if( prev_r.m>r.m*20.0 ) { prev_r.wsum=r.m*20.0*prev_r.wsum/prev_r.m; prev_r.m=r.m*20.0; }

        // if this is still same object...
        if( abs(prev_tm.y-tm.y)<0.5 ) 
        {
            // ... then combine its reservoir with current reservoir
            r = combineReservoirs( r, prev_r );
        }
    }
    #endif

   
    fragColor = store_gbuffer( r, tm );
}