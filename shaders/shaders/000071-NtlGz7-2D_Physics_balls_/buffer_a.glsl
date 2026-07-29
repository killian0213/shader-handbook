// Buffer A (buffer) — 2D Physics (balls) by TDM
// https://www.shadertoy.com/view/NtlGz7

/*
 * Dynamics
 */
 
vec2 getForce(vec2 x, vec2 v) {
    vec2 force = vec2(0.0);
    
    if(iMouse.z > 0.5) {
        vec2 mouse = iMouse.xy / iResolution.xy * 2.0 - 1.0;
        mouse.x *= iResolution.x / iResolution.y;
        vec2 dir = x.xy - mouse;
        float p = length(dir);        
        force += 5.0 * normalize(dir) / p;
    }
    
    return force;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    int id = int(fragCoord.x);
    if(id >= NUM_OBJECTS) discard;
    vec2 ires = 1.0 / iChannelResolution[0].xy;
    
    // load    
    Body body = getBody(iChannel0, ires, id);
    if(iFrame == 0) initBody(id, body); // init
    
    float dt = min(iTimeDelta, 0.07);
    
    // integrate forces
    vec2 pvel = body.vel;
    float pang_vel = body.ang_vel;
    vec2 force = getForce(body.pos, body.vel);
    body.vel += (force * body.inv_mass + GRAVITY) * dt;
    
    // limit max velocity
    float len2 = dot(body.vel,body.vel);
    if(len2 > MAX_VELOCITY * MAX_VELOCITY)
        body.vel *= inversesqrt(len2) * MAX_VELOCITY;
    
    // integrate velocity
    body.pos += (pvel + body.vel) * 0.5 * dt;
    body.ang += (pang_vel + body.ang_vel) * 0.5 * dt;
    
    // store
    fragColor = vec4(0.0);
    storeBody(id, body, fragColor, fragCoord);
}