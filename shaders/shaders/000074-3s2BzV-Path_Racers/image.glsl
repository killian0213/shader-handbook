// Image (image) — Path Racers by friol
// https://www.shadertoy.com/view/3s2BzV


//
// friol 2o2o
// choose your noise function wisely
// dof/bokeh blur readapted from halcy
// 29.05.2020: cleaned up a bit and darkened the walls&reflective sphere
//

vec3 dof(sampler2D tex, vec2 uv) 
{
    vec3 col = vec3(0.0);
    float asum = 0.0;
    float coc = texture(tex,uv).a;
    for(float t=0.0;t<2.0*3.141592;t+=3.141592/16.0) 
    {
    	float r = cos(3.14 / 6.0) / cos(mod(t, 2.0 * 3.14 / 6.0) - 3.14 / 6.0);
        
        vec2 offset = vec2(sin(t), cos(t)) * r * t * vec2(1.0) / iResolution.xy * coc;
        vec4 samp = texture(tex, uv + offset * 1.0);
        
        offset = vec2(sin(t), cos(t)) * r * t * vec2(1.0) / iResolution.xy * samp.a;
        samp = texture(tex,uv+offset);
        
        col += samp.rgb * samp.a * t;
        asum+=samp.a*t;
    }
    col = col / asum;
    return(col);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) 
{
    vec2 uv = fragCoord / iResolution.xy;
	fragColor = vec4(dof(iChannel0, uv), 0.0);
    if (iTime<8.0) fragColor=mix(fragColor,vec4(0.0),(8.0-iTime)/8.0);
	//fragColor = vec4(texture(iChannel0, uv));
}
