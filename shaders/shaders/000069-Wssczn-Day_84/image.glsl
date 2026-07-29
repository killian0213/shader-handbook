// Image (image) — Day 84 by jeyko
// https://www.shadertoy.com/view/Wssczn

// radial blur and chromatic abberation in this buffer
// thx iq for pallette and hg-sdf for polarMod


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord/iResolution.xy;
	vec2 uvn = (fragCoord - 0.5*iResolution.xy)/iResolution.xy;
    
    
    //float m = pow(abs(sin(p.z*0.03)),10.);

    // Radial blur
    float steps = 30.;
    float scale = 0.00 + pow(length(uv - 0.5),4.)*0.5;
    //float chromAb = smoothstep(0.,1.,pow(length(uv - 0.5), 0.3))*1.1;
    float chromAb = pow(length(uv - 0.5),1.)*3.7;
    vec2 offs = vec2(0);
    vec4 radial = vec4(0);
    for(float i = 0.; i < steps; i++){
    
        scale *= 0.97;
        vec2 target = uv + offs;
        offs -= normalize(uvn)*scale/steps;
    	radial.r += texture(iChannel0, target + chromAb*1./iResolution.xy).x;
    	radial.g += texture(iChannel0, target).y;
    	radial.b += texture(iChannel0, target - chromAb*1./iResolution.xy).z;
    }
    radial /= steps;
    
    float ss = smoothstep(0.,1.,dot(uvn,uvn)*3.);
    fragColor = radial*1.; 
    fragColor = mix(fragColor,smoothstep(0.,1.,fragColor), 0.4);
    fragColor *= 18.;
    fragColor = pow(fragColor, vec4(0.4545));
    fragColor *= 1. - dot(uvn,uvn)*2.;
}
