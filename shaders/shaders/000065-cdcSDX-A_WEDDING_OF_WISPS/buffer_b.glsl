// Buffer B (buffer) — A WEDDING OF WISPS by alro
// https://www.shadertoy.com/view/cdcSDX

/*
    Store and update particle positions using curl noise
    
    Based on:
        https://atyuwen.github.io/posts/bitangent-noise/
        https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph2007-curlnoise.pdf
*/

const float speed = 3.0;
const float scale = 0.15;

// How many positions are computed regardless of how many are displayed in Buffer C
const float particleCount = 2048.0;

// Particles beyond this distance are reset to the centre
const float boundingRadius = 10.0;

// Radius where reset particles are placed
const float spawnRadius = 4.0;

//---------------------------- Noise ----------------------------

// 5th order polynomial interpolation
vec3 fade(vec3 t){
    return (t * t * t) * (t * (t * 6.0 - 15.0) + 10.0);
}

// https://www.shadertoy.com/view/4djSRW
vec3 hash(vec3 p3){
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return 2.0 * fract((p3.xxy + p3.yxx) * p3.zyx) - 1.0;
}

vec3 hash32(vec2 p){
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

float noise(vec3 p){

    // Offset to vary look slowly over time
    p += 1e-4 * iTime;

    vec3 i = floor(p);
    vec3 f = fract(p);
	
	vec3 u = fade(f);
    
    /*
    * For 1D, the gradient of slope g at vertex u has the form h(x) = g * (x - u), where u 
    * is an integer and g is in [-1, 1]. This is the equation for a line with slope g which 
    * intersects the x-axis at u.
    * For N dimensional noise, use dot product instead of multiplication, and do 
    * component-wise interpolation (for 3D, trilinear)
    */
    return mix( mix( mix( dot( hash(i + vec3(0.0,0.0,0.0)), f - vec3(0.0,0.0,0.0)), 
              dot( hash(i + vec3(1.0,0.0,0.0)), f - vec3(1.0,0.0,0.0)), u.x),
         mix( dot( hash(i + vec3(0.0,1.0,0.0)), f - vec3(0.0,1.0,0.0)), 
              dot( hash(i + vec3(1.0,1.0,0.0)), f - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( hash(i + vec3(0.0,0.0,1.0)), f - vec3(0.0,0.0,1.0)), 
              dot( hash(i + vec3(1.0,0.0,1.0)), f - vec3(1.0,0.0,1.0)), u.x),
         mix( dot( hash(i + vec3(0.0,1.0,1.0)), f - vec3(0.0,1.0,1.0)), 
              dot( hash(i + vec3(1.0,1.0,1.0)), f - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

//---------------------------- Curl ----------------------------

// https://atyuwen.github.io/posts/bitangent-noise/
vec3 computeCurl(vec3 p){

    const float eps = 1e-4;

    float dx = noise(p + vec3(eps, 0, 0)) - noise(p - vec3(eps, 0, 0));
    float dy = noise(p + vec3(0, eps, 0)) - noise(p - vec3(0, eps, 0));
    float dz = noise(p + vec3(0, 0, eps)) - noise(p - vec3(0, 0, eps));

    vec3 noiseGrad0 = vec3(dx, dy, dz)/(2.0 * eps);

    // Offset position for second noise read
    p += 1000.5;

    dx = noise(p + vec3(eps, 0, 0)) - noise(p - vec3(eps, 0, 0));
    dy = noise(p + vec3(0, eps, 0)) - noise(p - vec3(0, eps, 0));
    dz = noise(p + vec3(0, 0, eps)) - noise(p - vec3(0, 0, eps));

    vec3 noiseGrad1 = vec3(dx, dy, dz)/(2.0 * eps);

    vec3 curl = cross(noiseGrad0, noiseGrad1);

    return normalize(curl);
}


//---------------------------- Position ----------------------------

vec4 getInitialPosition(vec2 fragCoord){
    return vec4(spawnRadius * (2.0 * hash32(fragCoord) - 1.0), 0.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord){
    if((floor(fragCoord.y) * iResolution.x + floor(fragCoord.x)) < particleCount){
        if(iFrame == 0){
            fragColor = getInitialPosition(fragCoord);
        }else{
            // Determine how much time has passed since last frame
            // iTimeDelta is not 0 when interacting with a paused shader
            float iTimeLastFrame = texelFetch(iChannel0, ivec2(0.5, 0.5), 0).x;
            float dT = iTime - iTimeLastFrame;
            
            vec4 oldData = texelFetch(iChannel0, ivec2(fragCoord), 0);
            vec3 oldPos = oldData.rgb;

            oldPos += speed * dT * computeCurl(scale * oldPos);

            // Store how long a particle has existed since a reset in the fourth channel
            vec4 newPos = vec4(oldPos, oldData.w + dT);
            
            if(length(newPos) > boundingRadius){
                newPos = getInitialPosition(fragCoord + iTime);
            }

            fragColor = newPos;
        }
    }else{
        fragColor = vec4(vec3(0), 1.0);
    }

    // Store iTime in the first pixel of Buffer B
    if(fragCoord == vec2(0.5, 0.5)){
        fragColor = vec4(iTime);  
    }
}