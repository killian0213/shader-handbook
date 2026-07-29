// Buffer B (buffer) — Art : Boids by Gijs
// https://www.shadertoy.com/view/3tcSWH

ivec4 getClosest(ivec2 xy){
    return ivec4(texelFetch(iChannel1, xy, 0));
}

ivec2 locFromID(int id){
    int width = int(iResolution.x);
    return ivec2( id % width, id / width);
}

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

    ivec4 new = ivec4(-1);
    vec4 dis = vec4(1e20);

    ivec4 old   = getClosest( iFragCoord + ivec2( 0, 0) );            
    ivec4 east  = getClosest( iFragCoord + ivec2( 1, 0) );
	ivec4 north = getClosest( iFragCoord + ivec2( 0, 1) );
    ivec4 west  = getClosest( iFragCoord + ivec2(-1, 0) );
    ivec4 south = getClosest( iFragCoord + ivec2( 0,-1) );
    ivec4[5] candidates = ivec4[5](old, east, north, west, south); 
    
    for(int i=0; i<5; i++){
        for(int j=0; j<4; j++){
            int id = candidates[i][j];
            float dis2 = distance2Particle(id, fragCoord);
            insertion_sort( new, dis, id, dis2 );
        }
    }
    
    for(int k = 0; k < 1; k++){
        float h = hash(
            iFragCoord.x + 
            iFragCoord.y*int(iResolution.x) + 
            iFrame*int(iResolution.x*iResolution.y) +
            k
        );
        int p = int(h*float(PARTICLES));
        insertion_sort(new, dis, p, distance2Particle(p, fragCoord) );
    }
    
    fragColor = vec4(new); 
    
}