// Image (image) — Day 74 by jeyko
// https://www.shadertoy.com/view/3tGSR3


// I fixed up the shader a bit, compared to the original and added tome color toning

// It is basically just two perpendicular planes which are rotated depending on the position of the viewer.
// Materials are reflective
// Then some glowy lines are added on top



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord/iResolution.xy;
	vec2 uvn = (fragCoord - 0.5*iResolution.xy)/iResolution.xy;
    
    // Radial blur and chromatic abberation
    float steps = 40.;
    float scale = 0.00 + pow(length(uv - 0.5),3.4)*0.1;
    float chromAb = pow(length(uv - 0.5),1.)*1.5;
    vec2 offs = vec2(0);
    vec4 radial = vec4(0);
    for(float i = 0.; i < steps; i++){
    
        scale *= 0.98;
        vec2 target = uv + offs;
        offs -= normalize(uvn)*scale/steps;
    	radial.r += texture(iChannel0, target + chromAb*1./iResolution.xy).x;
    	radial.g += texture(iChannel0, target).y;
    	radial.b += texture(iChannel0, target - chromAb*1./iResolution.xy).z;
    }
    radial /= steps;
    
    fragColor = radial*1.5; 
    
    // mimap glow
    //fragColor += texture(iChannel0,uv, 6.)*0.1;
    
    // color correction
    fragColor = mix(fragColor,smoothstep(0.,1.,fragColor), 0.14); 
    
    fragColor *= 1.;
    fragColor.g *= 1.1;
    fragColor.r *= 0.95 + uvn.x*0.7;
    fragColor.g *= 0.95 + uvn.y*0.3;
    fragColor = max(fragColor, 0.);
    // vignette
    fragColor = pow(fragColor, vec4(0.545 + dot(uvn,uvn)*2.)); 
	
}
