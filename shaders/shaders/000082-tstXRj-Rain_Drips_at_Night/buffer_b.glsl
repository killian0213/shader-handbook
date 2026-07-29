// Buffer B (buffer) — Rain Drips at Night by granito
// https://www.shadertoy.com/view/tstXRj

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 res = iResolution.xy;
    vec2 uv = fragCoord/res;
    vec2 inv = vec2(1., res.y / res.x); 
    vec4 bufA = multisample( iChannel0, uv, 0., 0.0005); //bufer A input
    vec2 uvoffset = (texture(iChannel2, uv * inv * 0.5).xy * 2. - 1.) * 0.00005; //distortion offset
    vec4 bufB = multisample( iChannel1, uv + uvoffset, 0., 0.001); //history buffer
    fragColor = mix( bufB * 0.98, bufA, bufA.w); //mix history buffer behind
    fragColor.z = dot(texture(iChannel3,uv * vec2(9.0, 6.0)).xyz, vec3(0.3,0.6,0.1)) * 0.5; //glass texture
    fragColor.z += smoothstep(0.,1.0,abs(sin(uv.x * 120.0))) * 0.2;
}