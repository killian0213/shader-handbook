// Image (image) — One-Pass Fire by Xor
// https://www.shadertoy.com/view/tf2SWc

/*
    "One-Pass Fire" by @XorDev
    
    Here's the continuation of my experiments with fire effects
    
    Also see Turbulent Flame:
    https://www.shadertoy.com/view/wffXDr
*/
//Fire ring radius
#define COLOR vec3(0.21, 0.06, 0.03)
//Scroll speed
#define SCROLL 1.2

//Number of turbulence waves
#define FIRE_NUM 8.0
//Turbulence wave amplitude
#define FIRE_AMP 0.4
//Turbulence wave speed
#define FIRE_SPEED 6.0
//Turbulence frequency (inverse of scale)
#define FIRE_FREQ 12.0
//Turbulence frequency multiplier
#define FIRE_EXP 1.2

//Bicubic noise texture sample
vec4 noise(vec2 p)
{
    vec2 f = floor(p);
    vec2 s = p-f;
    s *= s * (3.0 - 2.0*s);
    
    return texture(iChannel0, (f+s+.5) / 256.0);
}

//https://mini.gmshaders.com/p/turbulence
vec2 turbulence(vec2 p, float F, float N, float S, float A, float E)
{
    //Turbulence starting scale
    float freq = F;
    
    //Turbulence rotation matrix
    mat2 rot = mat2(0.6, -0.8, 0.8, 0.6);
    
    //Loop through turbulence octaves
    for(float i=0.0; i<N; i++)
    {
        //Scroll along the rotated y coordinate
        float phase = freq * (p * rot).y + S*iTime + i;
        //Add a perpendicular sine wave offset
        p += A * rot[0] * sin(phase) / freq;
        
        //Rotate for the next octave
        rot *= mat2(0.6, -0.8, 0.8, 0.6);
        //Scale down for the next octave
        freq *= E;
    }
    
    return p;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Screen coordinates, centered and aspect corrected
    vec2 p = (fragCoord.xy*2.0-iResolution.xy) / iResolution.y;
    
    //Expand vertically
    float xstretch = 2.0 - 1.5*smoothstep(-2.0,2.0,p.y);
    //Decelerate horizontally
    float ystretch = 1.0 - 0.5 / (1.0+p.x*p.x);
    //Combine
    vec2 stretch = vec2(xstretch, ystretch);
    //Stretch coordinates
    p *= stretch;
    
    //Scroll upward
    float scroll = SCROLL*iTime;
    p.y -= scroll;
    
    //Apply turbulence
    p = turbulence(p, FIRE_FREQ, FIRE_NUM, FIRE_SPEED, FIRE_AMP, FIRE_EXP);
    
    //Scrolling coordinates
    vec2 sp = p;
   
    //Reverse the scrolling offset
    p.y += scroll + 0.5;
    
    //Set radius with noise
    float radius = 0.1 + 0.5*noise(sp/0.1).x;
    //Distance to fire
    float dist = length(p) - radius;
    
    //Scrolling texture uvs
    vec2 uv = sp * FIRE_FREQ*1.5;
    //Sample noise
    float n = noise(uv).x + noise(uv*0.3).y + noise(uv*0.1).z;
    //Glow brightness
    float light = smoothstep(0.3, 0.1, dist) / (0.1 - 0.03*n + dist*dist);
    
    //Spark highlights
    float spec = 1.0 / noise(sp*3e1).a;
    //Blend color, intensity and fad edges
    vec3 sparks = 0.02 * spec * spec * COLOR / (1.0+20.0*p.x*p.x);
    
    //Combine ambient light and fire
    vec3 col = n * light * COLOR + sparks;
    
    //Exponential tonemap
    //https://mini.gmshaders.com/p/tonemaps
    col = 1.0 - exp(-col);
    fragColor = vec4(col,1);
}