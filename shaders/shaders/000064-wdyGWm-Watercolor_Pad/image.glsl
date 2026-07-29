// Image (image) — Watercolor Pad by ivansafrin
// https://www.shadertoy.com/view/wdyGWm

float getVal(vec2 uv)
{
    return noise(uv);
}
    
vec2 getGrad(vec2 uv,float delta)
{
    vec2 d=vec2(delta,0);
    return vec2(
        getVal(uv+d.xy)-getVal(uv-d.xy),
        getVal(uv+d.yx)-getVal(uv-d.yx)
    )/delta;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 n = vec3(getGrad(fragCoord,1.0),1.0);
	n=normalize(n);
    float paperColor = dot(vec3(1.0, 1.0, 0.0), n);
    
    fragColor = vec4(vec3((paperColor*0.05)+0.95) * (texture(iChannel0, uv).xyz), 1.0);    
    fragColor = mix(vec4(hsv2rgb(vec3(uv.x, 0.75, 1.0)), 1.0), fragColor, smoothstep(iResolution.y-19.0, iResolution.y-20.0, fragCoord.y));
}