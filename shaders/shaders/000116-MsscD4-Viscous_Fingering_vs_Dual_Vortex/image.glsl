// Image (image) — Viscous Fingering vs Dual Vortex by Flexi
// https://www.shadertoy.com/view/MsscD4

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 texel = 1. / iResolution.xy;
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 components = texture(iChannel0, uv).xyz;
    vec3 norm = normalize(components);
    //fragColor = vec4(0.5 + norm.z);
    
    // below line originally by jdrage with yet another tweak by cornusammonis. (see: https://twitter.com/paniq/status/836899595804413952)
    vec4 m= vec4(norm.zzz,1);
    fragColor=mix(vec4(0,0,0.2,1),vec4(1,0.9,0,1),sign(m.xwxw)*pow(abs(m),vec4(0.4,2.8,1,1)));

}