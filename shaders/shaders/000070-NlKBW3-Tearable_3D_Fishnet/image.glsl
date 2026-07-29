// Image (image) — Tearable 3D Fishnet by fenix
// https://www.shadertoy.com/view/NlKBW3

// ---------------------------------------------------------------------------------------
//	Created by fenix in 2022
//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//  Verlet cloth sim with point tearing. Hopefully you'll find it more "tearable" than
//  "terrible". If you were expecting not to suffer any bad puns you've come to the wrong
//  shader...
// 
//  The stability of this, such as it is, comes from essentially an absurd number of
//  edges. Not only is each particle connected via the visible lines to each neighbor,
//  but to the next particle, and the next particle, and so on. I'm surely not the first
//  person to come up with this appoach, so I don't think you can say I made this "out
//  of whole cloth". Ahem.
//  
//  If the wind is a bit much, you can tone it down with WIND_SPEED. I could tell you
//  more about the making of this shader, and it would be quite the yarn. But you might
//  accuse me of fabrication.
//
//  OK, I'll stop.
//
//  Buffer A computes the particle positions
//  Buffer B computes nearest particles to each screen pixel
//
// ---------------------------------------------------------------------------------------

void drawLine(vec3 from, vec3 to, vec2 p, mat4 w2c, inout vec4 fragColor)
{
    // convert to camera space
    vec3 fromCamera = (w2c * vec4(from,1.0)).xyz;
    fromCamera.xy = fromCamera.xy / fromCamera.z;
    vec3 toCamera = (w2c * vec4(to,1.0)).xyz;
    toCamera.xy = toCamera.xy / toCamera.z;

    // if in front of clipping plane
    if(fromCamera.z > 0.01 && toCamera.z > 0.01) 
    {
        float dist2 = fxLinePointDist2(fromCamera.xy, toCamera.xy, p);
        float dist = sqrt(dist2);

        float PARTICLE_SIZE = 2. / iResolution.y;
        float particleTemp = max(0.0, PARTICLE_SIZE - dist) / PARTICLE_SIZE;

        if (dist < PARTICLE_SIZE)
        {
            fragColor = min(fragColor, 1. - vec4(vec3(particleTemp), 0));
        }
    }
}

void drawLineToNeighbor(int nid, vec3 pos, vec2 p, mat4 w2c, inout vec4 fragColor)
{
    if (nid >= 0)
    {
        fxParticle nData = fxGetParticle(nid);

        if (!nData.disabled) drawLine(pos, nData.pos, p, w2c, fragColor);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    computeClothSide(iResolution);
    
    // pixel
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    // camera-to-world and world-to-camera transform
    mat4 c2w = fxCalcCameraMat(iResolution, cameraLeft, cameraUp, cameraFwd, cameraPos);
    mat4 w2c = inverse(c2w);

	const vec3 reverseLightDir = normalize(vec3(1.0,2.0,3.0));
	const vec3 lightColor = vec3(0.5,0.5,0.5);	
	const vec3 ambientColor = vec3(0.05,0.05,0.05);
   
    fragColor = vec4(.7);
    //return;
    ivec4 old = fxGetClosest( ivec2(fragCoord) );      

    for(int j=0; j<1; j++)
    {
        int particle = old[j];
        if (particle < 0 || particle >= MAX_PARTICLES) continue;
        fxParticle data = fxGetParticle(particle);
        if (!data.disabled)
        {
            drawLineToNeighbor(above(particle), data.pos, p, w2c, fragColor);
            drawLineToNeighbor(below(particle), data.pos, p, w2c, fragColor);
            drawLineToNeighbor(left(particle), data.pos, p, w2c, fragColor);
            drawLineToNeighbor(right(particle), data.pos, p, w2c, fragColor);
        }
    }
}
