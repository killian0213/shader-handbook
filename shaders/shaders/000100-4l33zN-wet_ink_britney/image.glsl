// Image (image) — wet ink britney by flockaroo
// https://www.shadertoy.com/view/4l33zN

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec3 getCol(vec2 fc)
{
    return texture(iChannel0,fc/iResolution.xy).xyz;
}

float getVal(vec2 fc)
{
    return dot(getCol(fc),vec3(1./3.));
}
               
vec2 getGrad(vec2 fc, float eps)
{
    vec2 e=vec2(eps,0);
    return vec2(getVal(fc+e.xy)-getVal(fc-e.xy),
        		getVal(fc+e.yx)-getVal(fc-e.yx))/eps;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec3 t1=texture(iChannel1,fragCoord.xy/100.0).xyz;
	vec3 t2=texture(iChannel2,fragCoord.xy/iResolution.xy).xyz;
    vec3 col=texture(iChannel0,uv).xyz;
    vec3 light = normalize(vec3(.5,.5,2));
    vec3 n=normalize(vec3(getGrad(fragCoord,1.4),1.));
    float spec = dot(reflect(vec3(0,0,-1),n),light);
    float diff = clamp(dot(light,n),0.,1.);
    float h = smoothstep(.5,1.,col.x);
    float shin = mix(1.,200.,1.-h);
    spec = pow(clamp(spec,0.,1.),shin)*shin/100.;
    col = mix(vec3(0.0,.0,.4),vec3(1,.97,.9)*.7+0.3*t1,h);
    float vignette=cos(1.7*length((fragCoord.xy-.5*iResolution.xy)/iResolution.x));
	fragColor.xyz = (col*diff + 0.8*spec)*vignette;
	//fragColor.xyz = vec3(1,.97,.9)*.7*(t2.y+.6)+0.3*t1;
 	//fragColor.xyz = vec3(diff*diff);
 	//fragColor.xyz = vec3(getVal(fragCoord));
}
