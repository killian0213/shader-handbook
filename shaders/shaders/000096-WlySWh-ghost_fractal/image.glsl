// Image (image) — ghost fractal by loicvdb
// https://www.shadertoy.com/view/WlySWh

#define Log2BlurRadius 1.5
#define NoiseStrength .4

vec3 ACESFilm(vec3 x){
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    
    fragColor = texture(iChannel0, fragCoord/iResolution.xy, Log2BlurRadius);
    
    // yes the noise is added afterwards
    float random = texture(iChannel1, (fragCoord+vec2(iFrame*50))/iChannelResolution[1].xy).x;
    float noise = exp((random*.5-.5)*NoiseStrength);
    fragColor = vec4(ACESFilm(fragColor.rgb*noise), 1.);
}