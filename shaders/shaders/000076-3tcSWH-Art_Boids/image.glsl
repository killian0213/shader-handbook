// Image (image) — Art : Boids by Gijs
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
    
    fragColor = vec4(0);

    ivec4 ids = getClosest(ivec2(fragCoord));

    for(int i = 0; i < 4; i++){
        int id = ids[i];
        vec2 pos = getParticle(id).xy;
        float d = distance(fragCoord,pos);
        fragColor += .25/(d);
    }

    vec2  p1 = getParticle(ids.x).xy;
    vec2  p2 = getParticle(ids.y).xy;
    float r = dot(fragCoord-(p1+p2)/2.,normalize(p2-p1));
    fragColor.g += smoothstep(2.,0.,abs(r))*.1;
}