// Buffer B (buffer) — Basic : Voronoi Tracking by Gijs
// https://www.shadertoy.com/view/WltSz7

// Voronoi Buffer
// every pixel stores the 4 closest particles to it
// every frame this data is shared between neighbours

//returns the ids of the four closest particles from the input
ivec4 getClosest(ivec2 xy){
    return ivec4(texelFetch(iChannel1, xy, 0));
}

//returns the location of the particle within the particle buffer corresponding with the input id 
ivec2 locFromID(int id){
    int width = int(iResolution.x);
    return ivec2( id % width, id / width);
}

//get the particle corresponding to the input id
vec4 getParticle(int id){
    return texelFetch(iChannel0, locFromID(id), 0);
}

float distance2Particle(int id, vec2 fragCoord){
    if(id==-1) return 1e20;
    vec2 delta = getParticle(id).xy-fragCoord;
    return dot(delta, delta);
}

void insertion_sort(inout ivec4 i, inout vec4 d, int i_, float d_){	
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

void mainImage( out vec4 fragColor, vec2 fragCoord ){
   	ivec2 iFragCoord = ivec2(fragCoord);

    //in this vector the four new closest particles' ids will be stored
    ivec4 new = ivec4(-1);
    //in this vector the distance to these particles will be stored 
    vec4 dis = vec4(1e20);
    
    //get all known closest particles from old self and neighbours  
    ivec4 old   = getClosest( iFragCoord + ivec2( 0, 0) );      
    ivec4 east  = getClosest( iFragCoord + ivec2( 1, 0) );
	ivec4 north = getClosest( iFragCoord + ivec2( 0, 1) );
    ivec4 west  = getClosest( iFragCoord + ivec2(-1, 0) );
    ivec4 south = getClosest( iFragCoord + ivec2( 0,-1) );
    
    //collect them in a array so we can loop over it
    ivec4[5] candidates = ivec4[5](old, east, north, west, south); 
    
    for(int i=0; i<5; i++){
        for(int j=0; j<4; j++){
            int id = candidates[i][j];
            float dis2 = distance2Particle(id, fragCoord);
            insertion_sort( new, dis, id, dis2 );
        }
    }
    
    for(int k = 0; k < 1; k++){
        //random hash. We should make sure that two pixels in the same frame never make the same hash!
        float h = hash(
            iFragCoord.x + 
            iFragCoord.y*int(iResolution.x) + 
            iFrame*int(iResolution.x*iResolution.y) +
            k
        );
        //pick random id of particle
        int p = int(h*float(PARTICLES));
        insertion_sort(new, dis, p, distance2Particle(p, fragCoord) );
    }
    
    fragColor = vec4(new); 
    
}