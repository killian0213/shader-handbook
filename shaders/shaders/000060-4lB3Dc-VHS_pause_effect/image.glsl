//  (image) — VHS pause effect by caaaaaaarter
// https://www.shadertoy.com/view/4lB3Dc

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 texColor = vec4(0);
    // get position to sample
    vec2 samplePosition = fragCoord.xy / iResolution.xy;
    float whiteNoise = 9999.0;
    
 	// Jitter each line left and right
    samplePosition.x = samplePosition.x+(rand(vec2(iTime,fragCoord.y))-0.5)/64.0;
    // Jitter the whole picture up and down
    samplePosition.y = samplePosition.y+(rand(vec2(iTime))-0.5)/32.0;
    // Slightly add color noise to each line
    texColor = texColor + (vec4(-0.5)+vec4(rand(vec2(fragCoord.y,iTime)),rand(vec2(fragCoord.y,iTime+1.0)),rand(vec2(fragCoord.y,iTime+2.0)),0))*0.1;
   
    // Either sample the texture, or just make the pixel white (to get the staticy-bit at the bottom)
    whiteNoise = rand(vec2(floor(samplePosition.y*80.0),floor(samplePosition.x*50.0))+vec2(iTime,0));
    if (whiteNoise > 11.5-30.0*samplePosition.y || whiteNoise < 1.5-5.0*samplePosition.y) {
        // Sample the texture.
    	samplePosition.y = 1.0-samplePosition.y; //Fix for upside-down texture
    	texColor = texColor + texture(iChannel0,samplePosition);
    } else {
        // Use white. (I'm adding here so the color noise still applies)
        texColor = vec4(1);
    }
	fragColor = texColor;
}