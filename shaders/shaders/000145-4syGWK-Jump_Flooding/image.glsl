// Image (image) — Jump Flooding by paniq
// https://www.shadertoy.com/view/4syGWK

// presentation

vec4 load0(ivec2 p) {
    vec2 uv = (vec2(p)-0.5) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);
}

vec4 load1(ivec2 p) {
    vec2 uv = (vec2(p)-0.5) / iChannelResolution[1].xy;
    return texture(iChannel1, uv);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 aspect = vec2(iResolution.x / iResolution.y,1.0); 
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = (uv * 2.0 - 1.0) * aspect;    
    
    float m = ((iMouse.x / iResolution.x) * 2.0 - 1.0) * aspect.x;
    
    vec2 nearest = load1(ivec2(fragCoord + 0.5)).xy / iResolution.xy;
    vec2 p = (nearest * 2.0 - 1.0) * aspect;    
    
    float d = length(uv - p);
    vec3 n = vec3(normalize(uv - p),0.0) * 0.5 + 0.5;
    
    
    int frame = int(mod(iTime,15.0));
    
    vec3 col;
    if (frame < 12) {
        col = vec3(nearest, 0.0);
    } else if (uv.x > m) {
        float h = d - iTime;
        vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
        col = rgb;
        col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.02,abs(d)) );
    } else {
        col = n;
    }
    
	fragColor = vec4(col, 1.0);
}