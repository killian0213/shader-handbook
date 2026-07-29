// Image (image) — Rain on camera or window by omgs
// https://www.shadertoy.com/view/4l3Gz2

//OMGS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec2 uv = fragCoord.xy / iResolution.xy;
 
	vec3 bufB = texture(iChannel0,uv).xyz;
   
    vec3 rain = texture(iChannel1,reflect(bufB,vec3(uv,1.)) ).xyz;
    
    fragColor = vec4(rain, 1.0 );
}