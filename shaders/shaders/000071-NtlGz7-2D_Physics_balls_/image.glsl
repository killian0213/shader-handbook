// Image (image) — 2D Physics (balls) by TDM
// https://www.shadertoy.com/view/NtlGz7

/*
 * "2D Physics (balls)" by Alexander Alekseev aka TDM - 2021
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * Contact: tdmaav@gmail.com
 *
 * Render
 */
 
#define PIX length(fwidth(p))
const vec3[] COLORS = vec3[4] (
    vec3(72, 123, 240) / 255.,
    vec3(240, 46, 80) / 255.,
    vec3(255, 191, 0) / 255.,
    vec3(68, 188, 98) / 255.
);

float circle(vec2 p, vec2 c, float w) {
    float dist = length(p - c) - w;
    return smoothstep(PIX,0.0,dist);
}

float frame(vec2 p, vec2 size, float w) {
    const float SMOOTH = 0.2;
    size -= SMOOTH;
	p = abs(p)-size;
    float dist = length(p-min(p,0.0)) - SMOOTH;
    float shad = 1.0 - dist * 2.0;
    shad = 1.0 - shad * shad * shad;
    shad = 1.0 - (1.0 - shad) * smoothstep(0.0,PIX,dist);
    return shad * 0.1 + 0.9;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    vec2 mouse = iMouse.xy / iResolution.xy * 2.0 - 1.0;
    mouse.x *= iResolution.x / iResolution.y;
    mouse.y = 0.0;
    
    vec3 c = vec3(1.0);
    vec2 ires = 1.0 / iChannelResolution[0].xy;
        
    
    // objects
    for(int i = 0; i < NUM_OBJECTS; i++) {
        Body body = getBody(iChannel0, ires, i);
        float ba = circle(uv,body.pos,BALL_SIZE*0.98);
        ba *= 1.0-circle(uv,body.pos,BALL_SIZE*0.3);
                  
        for(int j = 0; j < 5; j++) {
            float ang = body.ang + float(j) * (360./5.) * DEG2RAD;
            vec2 o = rotateZ(vec2(0.0,BALL_SIZE*1.25), ang);
            ba *= 1.0 - circle(uv, body.pos + o, BALL_SIZE * 0.4);
        }  
        c = mix(c,COLORS[i%4],ba);
    }
    c *= frame(uv,vec2(FRAME_SIZE*1.08),0.01);
    
    // final
	fragColor = vec4(c,1.0);
}