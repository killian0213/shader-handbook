// Image (image) — SmoothLife(L)  by chronos
// https://www.shadertoy.com/view/XtdSDn

const vec3 CellColor = vec3(0.2, 0.2, 0.2);
const vec3 RingColor = vec3(0.0, 0.2, 0.2);
const vec3 DiskColor = vec3(0.0, 0.0, 0.0);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec4 buffer = texture(iChannel0, uv);
    
    vec3 color = 1.0*(buffer.x * CellColor + buffer.y * RingColor + buffer.z * DiskColor);
    
    float c = 1.0 - buffer.z;
    float c2 = 1. - texture(iChannel0, uv + .5/iResolution.xy).y;
    color += vec3(.6, .85, 1.)*max(c2*c2 - c*c, 0.)*4.;
    
    
	fragColor = vec4(color, 1.0);
}