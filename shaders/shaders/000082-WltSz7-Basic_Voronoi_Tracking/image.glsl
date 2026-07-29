// Image (image) — Basic : Voronoi Tracking by Gijs
// https://www.shadertoy.com/view/WltSz7

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

void mainImage( out vec4 fragColor, vec2 fragCoord ){
    
    fragColor = vec4(0);

    //get the id's of the 4 particles that (should be) closest.
    //the 4 ids are stored in .x, .y, .z, .w
    ivec4 ids = getClosest(ivec2(fragCoord));
    
    //draw the particles
        for(int i = 0; i < 4; i++){
            //get the particles position
            int id = ids[i];
            vec2 pos = getParticle(id).xy;

            //get the distance to the particle
            float d = distance(fragCoord,pos);

            //color it
            fragColor += .3/(d*d);
        }
    
    //draw voronoi outlines
        //get the position of the closest particle
    	vec2  p1 = getParticle(ids.x).xy;
        //get the position of the second closest particle
		vec2  p2 = getParticle(ids.y).xy;
        //get the distance to voronoi edge
        float r = dot(fragCoord-(p1+p2)/2.,normalize(p2-p1));
        fragColor += smoothstep(2.,0.,abs(r))*.3;
    
    //fragColor += vec4(ids/float(PARTICLES));
}