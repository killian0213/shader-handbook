// Image (image) — Gray-Scott diffusion by knighty
// https://www.shadertoy.com/view/MdVGRh

//Adapted from original fragmentarium shader by Syntopia
//I've only added F-k parametrization and coloring
vec3 normal(vec2 uv){
    vec3 delta = vec3(1./iResolution.xy, 0.);
    float du = texture(iChannel0, uv + delta.xz).x - texture(iChannel0, uv - delta.xz).x;
    float dv = texture(iChannel0, uv + delta.zy).x - texture(iChannel0, uv - delta.zy).x;
    return normalize(vec3(du,dv,1.));
}
vec3 getColor(vec2 uv){
    return 0.5+0.5*sin(vec3(uv,uv.x-uv.y)*vec3(12.2,6.8,1.25)+vec3(1.,.0,1.25));
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec2 val=texture(iChannel0, uv).xy;
    vec3 col = getColor(val)*(1.5*val.y+0.25);
    col += texture(iChannel1, reflect(vec3(0.,1.,0.),normal(uv))).xyz*0.15;
    fragColor = vec4(col,1.0);
}