// Image (image) — volumetric fractal pathtrace by public_int_i
// https://www.shadertoy.com/view/Xtc3RS

//Ethan Alexander Shulman 2016

/*
Controls:
look - mouse
move - arrow keys
*/


//display montecarlo path trace result


#define devrender 0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    #if devrender == 0
    vec4 csamp = texture(iChannel0, 0.5/iResolution.xy);
    vec4 samp = texture(iChannel0, fragCoord/iResolution.xy);
    fragColor = pow(samp/samp.w/*/(float(iFrame-int(csamp.x*4096.)))*/, vec4(1./2.2));
    
    //used for exporting image in the format of r=lighting, g=opacity
	//fragColor = texture(iChannel0, fragCoord/iResolution.xy)/(float(iFrame-120));
    //fragColor.x = pow(fragColor.x, 1./2.2);
    
	#else
    fragColor = pow(texture(iChannel0, fragCoord/iResolution.xy), vec4(1./2.2));
    #endif
}