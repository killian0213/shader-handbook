// Image (image) — Morning glare by loicvdb
// https://www.shadertoy.com/view/wd33zl

//lens flares

float lodFlares;

vec3 ghostFlare(vec2 uv, float scale){
    uv /= scale;
    float threshold = .75;
    return vec3(max(texture(iChannel0, uv*0.95+.5, lodFlares).r - threshold, 0.0),
                max(texture(iChannel0, uv*1.00+.5, lodFlares).g - threshold, 0.0),
                max(texture(iChannel0, uv*1.05+.5, lodFlares).b - threshold, 0.0));
}

vec3 haloFlare(vec2 uv, float scale){
    float weight = 1.0-smoothstep(0.0, .05, abs(.5-length(uv)));
    uv -= scale*normalize(uv);
    float threshold = .6;
    return weight * max(texture(iChannel0, vec2(.5) + uv*1.00, lodFlares).rgb - threshold, vec3(0));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    lodFlares = log2(iResolution.y*.15);
    float lodLargeBloom = log2(iResolution.y*.15);
    float lodSmallBloom = log2(iResolution.y*.05);
    
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = texture(iChannel0, uv);
    
    vec3 bloom = max(texture(iChannel0, uv, lodLargeBloom).rgb - .3, vec3(0.0))*.65
               + max(texture(iChannel0, uv, lodSmallBloom).rgb - .6, vec3(0.0))*.3;
    
    uv -= .5;
    vec2 radialUV = vec2(atan(uv.x, uv.y), 0.5);
    float flareStrength = texture(iChannel1, radialUV).r * texture(iChannel1, uv).r;
    
    float l = length(uv);
    vec3 flareTint = 4.0*flareStrength * (vec3(sin(l*20.0), cos(l*10.0+2.0), sin(l*15.0))*.3+.5);
    
    vec3 lensFlare = flareTint * (ghostFlare(uv, -.75) + haloFlare(uv, -.5));
    
    fragColor.rgb += lensFlare + bloom;
}