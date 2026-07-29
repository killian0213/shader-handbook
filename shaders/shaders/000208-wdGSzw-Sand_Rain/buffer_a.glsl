// Buffer A (buffer) — Sand Rain by Kali
// https://www.shadertoy.com/view/wdGSzw

#define A 6

float hash(vec2 p)
{
   return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// check if there is an arriving particle at this pixel in next frame
float arrivingParticle(vec2 coord, out vec4 partData) {
	// scan area from -D to D
    for (int i=-A; i<A; i++) {
        for (int j=-A; j<A; j++) {
            // position to check
            vec2 arrCoord = coord + vec2(i,j);
            vec4 data = texture(iChannel0, arrCoord/iResolution.xy);
            
            // no particles here
            if (dot(data,data)<.1) continue;

            // get next position of particle
            vec2 nextCoord = data.xy + data.zw;

            // distance between next position and current pixel
            vec2 offset = abs(coord - nextCoord);
            // if the distance is within half a pixel pick this particle
            // (other arriving particles are dismissed)
            if (offset.x<.5 && offset.y<.5) {
                partData = data;
                return 1.;
            }
        }
    }
    // no particles arriving here
	return 0.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord/iResolution.xy;
 	// random particles at the top, xy is position, zw velocity
    if (fragCoord.y>iResolution.y-3.) {
        fragColor = vec4(fragCoord.xy,(hash(uv+iTime)-.8)*4.,-6.+hash(uv)); 
        return;
    }
   
    // get the data of a particle arriving at this pixel 
    vec4 partData;
    float p = arrivingParticle(fragCoord, partData);

    // no particles, empty pixel
    if (p<1.) {
    	fragColor = vec4(0.);
        return;
    }
    
    // update position with current velocity altered by channels r & b in the video
    float vel=max(0.,1.-length(texture(iChannel2,fragCoord/iResolution.xy).rb)*.95);
    partData.xy+=partData.zw*vel;

    //set particle data
    fragColor = partData;
}