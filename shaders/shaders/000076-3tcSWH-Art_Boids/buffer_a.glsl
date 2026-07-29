// Buffer A (buffer) — Art : Boids by Gijs
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

void mainImage( out vec4 fragColor, vec2 fragCoord ){
    ivec2 iFragCoord = ivec2(fragCoord);
    
    int id = iFragCoord.x + iFragCoord.y*int(iResolution.x);
    if(id>=PARTICLES) return;
    
    vec4 prev = texelFetch( iChannel0, ivec2(fragCoord), 0 );
    vec2 pos = prev.xy;
    vec2 vel = prev.zw;
     
    if(iFrame==0 || keyDown(32)){
        float h1 = hash(id);
        float h2 = hash(int(h1*41343.));
        pos = vec2(h1,h2)*iResolution.xy;
    }

    vec2 force = vec2(0);
    
        if(iMouse.z > 0.){
            vec2 delta = pos-iMouse.xy;
            float dis = length(delta);
            force += delta/(dis*dis*dis) * 100.;
        }

        ivec4 closest = getClosest(ivec2(pos));
        for(int i = 0; i < 4; i++){
            int cid = closest[i];
            if(cid==id) continue;
            
            vec4 part = getParticle(cid);
            vec2 delta = part.xy-pos;
            float dis = length(delta);
            force += -delta /(dis*dis*dis) * SEPERATION;
            
            force += delta * COHESION;
            
            force += (part.zw-vel)/(dis+1.) * ALIGNMENT;
        }
    
    	vec2 dis = max(iResolution.xy-pos, vec2(1));
    	force -= 1./(dis*dis)*20.;
    	     dis = max(pos, vec2(1));
    	force += 1./(dis*dis)*20.;

    vel += force;

    vel = normalize(vel)* SPEED; 
    
    pos += vel;
    
    fragColor = vec4(pos,vel);
}