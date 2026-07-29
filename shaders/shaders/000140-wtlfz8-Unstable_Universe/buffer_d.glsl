// Buffer D (buffer) — Unstable Universe by julianlumia
// https://www.shadertoy.com/view/wtlfz8

//radial blur code from jeyko: https://www.shadertoy.com/view/WlKXRR :)


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord/iResolution.xy;
	vec2 uvn = (fragCoord - 0.5*iResolution.xy)/iResolution.xy;
    

    float steps = 20.;
    float scale = 0.00 + pow(length(uv - 0.5)*1.2,3.)*0.4;
    float chromAb = pow(length(uv - 0.5),1.4)*2.1;
    vec2 offs = vec2(0);
    vec4 radial = vec4(0);
    for(float i = 0.; i < steps; i++){
    
        scale *= 0.91;
        vec2 target = uv + offs;
        offs -= normalize(uvn)*scale/steps;
    	radial.r += texture(iChannel0, target + chromAb*1./iResolution.xy).x;
    	radial.g += texture(iChannel0, target).y;
    	radial.b += texture(iChannel0, target - chromAb*1./iResolution.xy).z;
    }
    radial /= steps;
    
    
    fragColor = radial*1.; 
    
    fragColor *= 1.3;
    fragColor = mix(fragColor,smoothstep(0.,1.,fragColor), 0.2);
    
    fragColor = max(fragColor, 0.);
    fragColor.xyz = pow(fragColor.xyz, vec3(1.,1.1,1.));

    fragColor *= 1. - dot(uvn,uvn)*1.8;
}


