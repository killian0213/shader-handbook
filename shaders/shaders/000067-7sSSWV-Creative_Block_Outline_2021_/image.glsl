// Image (image) — Creative Block [Outline 2021] by yx
// https://www.shadertoy.com/view/7sSSWV

float seed;
float hash() {
	float p=fract((seed++)*.1031);
	p+=(p*(p+19.19))*3.;
	return fract((p+p)*p);
}

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
 	// seed the RNG (again taken from Devour)
    seed = float((int(gl_FragCoord.x)*19349663^int(gl_FragCoord.y)*83492791)%38069);

	vec2 uv = gl_FragCoord.xy/iResolution.xy;
	vec4 tex = texelFetch(iChannel0,ivec2(gl_FragCoord.xy),0);
    
    // divide by sample-count
	vec3 color = tex.rgb/tex.a;

	// vignette to darken the corners
	uv-=.5;
	color *= 1.-dot(uv,uv)*.1;

    // exposure and tonemap
    color *= 3.5;
    //color = 1.-exp(color*-2.);
    color = mix(color,1.-exp(color*-2.),.5);

    // subtle warm grade
    color = pow(color,vec3(1,1.02,1.05));
    
	// gamma correction as the final step
	color = pow(color, vec3(.45));

    // grain
    color += (vec3(hash(),hash(),hash())-.5)*.01;

    // aspect ratio
    uv*=iResolution.xy/iResolution.yx;
    color *= step(abs(uv.y),.5/(16./9.));
    color *= step(abs(uv.x),.5*(16./9.));

    // "final" color
    fragColor = vec4(vec3(color),1);
}
