// Image (image) — Chromatic crystalline veneer by loicvdb
// https://www.shadertoy.com/view/wlyXzt

vec3 ACESFilm(vec3 x){
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

mat3 gaussianFilter = mat3(41, 26, 7,
                           26, 16, 4,
                           7,  4,  1) / 273.;

vec3 bloom(float scale, vec2 fragCoord){
    float logScale = log2(scale);
    vec3 bloom = vec3(0);
    for(int y = -2; y <= 2; y++)
        for(int x = -2; x <= 2; x++)
            bloom += gaussianFilter[abs(x)][abs(y)] * textureLod(iChannel0, (fragCoord+vec2(x, y)*scale)/iResolution.xy, logScale).rgb;
    
    return bloom;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    
    vec3 bloomSum = vec3(0.);
    bloomSum += bloom(.4 * iResolution.y, fragCoord) * .07;
    bloomSum += bloom(.07 * iResolution.y, fragCoord) * .07;
    
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    fragColor.rgb = ACESFilm(fragColor.rgb+bloomSum);
}