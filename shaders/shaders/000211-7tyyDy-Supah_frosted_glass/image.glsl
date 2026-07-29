// Image (image) — Supah frosted glass by supah
// https://www.shadertoy.com/view/7tyyDy

#define R iResolution.xy

float Cir (vec2 uv, float r, bool blur) {
    float a = blur ? 0.01 : 0.;
    float b = blur ? 0.13 : 5./R.y;
    return smoothstep(a, b, length(uv)-r);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*R.xy)/R.y;
    vec2 t = vec2(sin(iTime*2.), cos(iTime*3.+cos(iTime*.5)))*.1;
    
    vec3 Col0 = vec3(.9);
    vec3 Col1 = vec3(.1+uv.y*2., .4+uv.x*-1.1, .8)*.828;
    vec3 Col2 = vec3(.86);
    
    float cir1 = Cir(uv-t, .2, false);
    float cir2 = Cir(uv+t, .2, false);
    float cir2B = Cir(uv+t, .15, true);
    
    vec3 col = mix(Col1+vec3(.3,.1,0.), Col2, cir2B);
    col = mix(col, Col0, cir1);
    col = mix(col, Col1, clamp(cir1-cir2, 0., 1.));
    fragColor = vec4(col,1.0);
}