// Image (image) — [SH17C] Let's Make A Ray Marcher by TekF
// https://www.shadertoy.com/view/MdBfRK

void _mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = vec4(uv,0.5+0.5*sin(iTime),1.0);
}








































//-------- Don't edit the next line! It will break the tutorial. --------
void mainImage(out vec4 o,vec2 u){vec4 s=texelFetch(iChannel3,ivec2(0),0);_mainImage(o,u*s.zw-s.xy);vec4 t=texelFetch(iChannel3,ivec2(u),0);o=mix(o,t,t.a);}
