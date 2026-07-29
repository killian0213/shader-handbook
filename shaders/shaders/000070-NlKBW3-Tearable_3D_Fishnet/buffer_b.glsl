// Buffer B (buffer) — Tearable 3D Fishnet by fenix
// https://www.shadertoy.com/view/NlKBW3

// Originally derived, many shaders ago, from:
// Gijs's Basic : Voronoi Tracking: https://www.shadertoy.com/view/WltSz7

// Voronoi Buffer
// every pixel stores the 4 closest particles to it
// every frame this data is shared between neighbours

void insertion_sort(inout ivec4 i, inout vec4 d, int i_, float d_)
{	
    if(any(equal(ivec4(i_),i))) return;
    if     (d_ < d[0])             
        i = ivec4(i_,i.xyz),    d = vec4(d_,d.xyz);
    else if(d_ < d[1])             
        i = ivec4(i.x,i_,i.yz), d = vec4(d.x,d_,d.yz);
    else if(d_ < d[2])            
        i = ivec4(i.xy,i_,i.z), d = vec4(d.xy,d_,d.z);
    else if(d_ < d[3])           
        i = ivec4(i.xyz,i_),    d = vec4(d.xyz,d_);
}

float distance2Particle(int id, vec2 fragCoord, mat4 w2cNew)
{
    if(id==-1) return 1e20;
    vec4 worldPos = fxGetParticleData(id, POS);
    if (worldPos.w != 0.) return 1e20;
    vec3 screenPos = (w2cNew * vec4(worldPos.xyz,1.0)).xyz;
    screenPos.xy = screenPos.xy / screenPos.z;
    vec2 delta = (screenPos.xy)-fragCoord;
    return dot(delta, delta);
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
   	ivec2 iFragCoord = ivec2(fragCoord);
    computeClothSide(iResolution);
    if(iFragCoord == ivec2(0))
    {
        // Reset if resolution changes
        vec4 state = texelFetch(iChannel1, ivec2(0), 0);
        if (iFrame == 0 ||
            iResolution.x * iResolution.y != abs(state.x) ||
            keyDown(KEY_SPACE) ||
            state.w > 30.)
        {
            state = vec4(-iResolution.x * iResolution.y, 0.0, 0.0, 0.0);
        }
        else
        {
            state.x = abs(state.x);
        }
        
        if (iMouse.z > 0.)
        {
            state.yz = iMouse.xy;
        }
        
        if (state.yz == vec2(0))
        {
            state.w += iTimeDelta;
        }
        
        fragColor = state;
        return;
    }
    
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    // camera-to-world and world-to-camera transform
    mat4 c2w = fxCalcCameraMat(iResolution, cameraLeft, cameraUp, cameraFwd, cameraPos);
    mat4 w2c = inverse(c2w);

    //in this vector the four new closest particles' ids will be stored
    ivec4 new = ivec4(-1);
    //in this vector the distance to these particles will be stored 
    vec4 dis = vec4(1e6);

    ivec4 old   = fxGetClosest( iFragCoord );      
    for(int j=0; j<4; j++){
        int id = old[j];
        float dis2 = distance2Particle(id, p, w2c);
        insertion_sort( new, dis, id, dis2 );
        
        // randomly check one of the neighbors of the particle, it's likely to be of interest
        int nid;
        switch((iFrame + int(j)) % 4)
        {
            case 0: nid = above(id); break;
            case 1: nid = below(id); break;
            case 2: nid = left(id); break;
            case 3: nid = right(id); break;
        }
        
        if (nid >= 0)
        {
            float dis2 = distance2Particle(nid, p, w2c);
            insertion_sort( new, dis, nid, dis2 );
        }
    }

    uint searchRange = 15u;
    uint searchCount = 32u;
    
    for(uint i=0u; i<searchCount; ++i)
    {
        uvec4 h0 = hash(uvec4(fragCoord, fragCoord) * i);

        ivec4 old   = fxGetClosest( iFragCoord + ivec2( h0.xy % searchRange - searchRange / 2u) );      
        for(int j=0; j<1; j++){
            int id = old[j];
            float dis2 = distance2Particle(id, p, w2c);
            insertion_sort( new, dis, id, dis2 );
        }        
    }

    int searchIterations = 1;
    if (iFrame < 5)
    {
        searchIterations = 100;
    }
    for(int k = 0; k < searchIterations; k++){
        //random hash. We should make sure that two pixels in the same frame never make the same hash!
        float h = hash(
            iFragCoord.x + 
            iFragCoord.y*int(iResolution.x) + 
            iFrame*int(iResolution.x*iResolution.y) +
            k
        );

        //pick random id of particle
        int id = int(h*float(MAX_PARTICLES));
        insertion_sort(new, dis, id, distance2Particle(id, p, w2c));
    }
    
    fragColor = vec4(new);
}