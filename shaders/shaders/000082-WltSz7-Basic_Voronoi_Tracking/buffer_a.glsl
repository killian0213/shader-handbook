// Buffer A (buffer) — Basic : Voronoi Tracking by Gijs
// https://www.shadertoy.com/view/WltSz7

// Particle Buffer
// in this buffer every pixel represents a particle
// the particles positions is stored in .xy
//           its velocity  is stored in .zw
// Only the first PARTICLES amount of pixels are actually used.


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
    ivec2 iFragCoord = ivec2(fragCoord);
    
    //we only simulate PARTICLES amount of particles
    int id = iFragCoord.x + iFragCoord.y*int(iResolution.x);
    if(id>=PARTICLES) return;
    
    vec4 prev = texelFetch( iChannel0, ivec2(fragCoord), 0 );
    vec2 pos = prev.xy;
    vec2 vel = prev.zw;
     
    if(iFrame==0){
       	//pick a "random" starting position
        float h1 = hash(id);
        float h2 = hash(int(h1*41343.));
        pos = vec2(h1,h2)*iResolution.xy;
    }

    //gather forces
    vec2 force = vec2(0);
    
        //friction
        force -= vel*0.3;

        //interaction
        if(iMouse.z > 0.){
            vec2 delta = pos-iMouse.xy;
            float dis = length(delta);
            force += delta/(dis*dis) * 10.;
        }

        //repulsion from others
        ivec4 closest = getClosest(ivec2(pos));
        for(int i = 0; i < 4; i++){
            int cid = closest[i];
            if(cid==id) continue;
            
            vec2 delta = pos-getParticle(cid).xy;
            float dis = length(delta);
            force += delta /(dis*dis*dis) * 30.;
        }
    
    	//repulsion from walls
    	vec2 dis = max(iResolution.xy-pos, vec2(1));
    	force -= 1./(dis*dis) * 10.;
    	     dis = max(pos, vec2(1));
    	force += 1./(dis*dis) * 10.;

    //integrate forces
    vel += force;
    
    //cap velocity at max speed
    float dv = length(vel);
    if(dv>SPEED) vel *= SPEED/dv;
    
    //integrate velocity
    pos += vel;
    
    fragColor = vec4(pos,vel);
}