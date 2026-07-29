// Buf B (buffer) — fractal shake  by macbooktall
// https://www.shadertoy.com/view/llXBRH

// This buffer is the feedback loop

vec3 hue(vec3 color, float shift) {

    const vec3  kRGBToYPrime = vec3 (0.299, 0.587, 0.114);
    const vec3  kRGBToI     = vec3 (0.596, -0.275, -0.321);
    const vec3  kRGBToQ     = vec3 (0.212, -0.523, 0.311);

    const vec3  kYIQToR   = vec3 (1.0, 0.956, 0.621);
    const vec3  kYIQToG   = vec3 (1.0, -0.272, -0.647);
    const vec3  kYIQToB   = vec3 (1.0, -1.107, 1.704);

    // Convert to YIQ
    float   YPrime  = dot (color, kRGBToYPrime);
    float   I      = dot (color, kRGBToI);
    float   Q      = dot (color, kRGBToQ);

    // Calculate the hue and chroma
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);

    // Make the user's adjustments
    hue += shift;

    // Convert back to YIQ
    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    // Convert back to RGB
    vec3    yIQ   = vec3 (YPrime, I, Q);
    color.r = dot (yIQ, kYIQToR);
    color.g = dot (yIQ, kYIQToG);
    color.b = dot (yIQ, kYIQToB);

    return color;
}
float hash( float n )
{
    return fract(sin(n)*43758.5453123);
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*157.0;

    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+157.0), hash(n+158.0),f.x),f.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   	vec2 uv = fragCoord.xy / iResolution.xy;
    
    float time = mod(iTime, 1.570795);
    float val1 = noise(uv*2. + time)*0.0025;
    float val2 = noise(uv*2. + time - 1.570795)*0.0025;
    
	
    // Convert the uv's to polar coordinates to scale up  
    vec2 polarUv = (uv * 2.0 - 1.0);

    float angle = atan(polarUv.y, polarUv.x);
    
    // Scale up the length of the vector by a noise function feeded by the angle and length of the vector
    float llr = length(polarUv)*0.495;
    float llg = length(polarUv)*0.4965;
    float llb = length(polarUv)*0.498;
 
    vec3 base = texture(iChannel0, uv).rgb;

    vec2 offsR = vec2(cos(angle)*llr + 0.5, sin(angle)*llr + 0.5);
    vec2 offsG = vec2(cos(angle)*llg + 0.5, sin(angle)*llg + 0.5);
    vec2 offsB = vec2(cos(angle)*llb + 0.5, sin(angle)*llb + 0.5);
    
    // sample the last texture with uv's slightly scaled up
    vec3 overlayR = texture(iChannel1,offsR).rgb;
	vec3 overlayG = texture(iChannel1,offsG).rgb;
	vec3 overlayB = texture(iChannel1,offsB).rgb;
	vec3 overlay = vec3(overlayR.r, overlayG.g, overlayB.b);

    // Additively blend the colors together
    vec4 col = vec4(base + overlay*0.55, 1.0);
    
    fragColor = col;
}