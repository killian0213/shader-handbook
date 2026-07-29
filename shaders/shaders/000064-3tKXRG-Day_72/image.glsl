// Image (image) — Day 72 by jeyko
// https://www.shadertoy.com/view/3tKXRG



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord/iResolution.xy;
	vec2 uvn = (fragCoord - 0.5*iResolution.xy)/iResolution.xy;
    
    
    //float m = pow(abs(sin(p.z*0.03)),10.);

    // Radial blur
    float steps = 20.;
    float scale = 0.00 + pow(length(uv - 0.5)*1.2,2.7)*0.2;
    //float chromAb = smoothstep(0.,1.,pow(length(uv - 0.5), 0.3))*1.1;
    float chromAb = pow(length(uv - 0.5),1.4)*5.1;
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
    
    
    fragColor = radial*3.; 
    //fragColor = mix(fragColor,smoothstep(0.,1.,fragColor), 0.8);
    //1fragColor *= 18.;
    fragColor = max(fragColor, 0.);
    fragColor = pow(fragColor, vec4(0.4545 + dot(uvn,uvn)*1.7));
    fragColor *= 1. - dot(uvn,uvn)*1.2;
}


