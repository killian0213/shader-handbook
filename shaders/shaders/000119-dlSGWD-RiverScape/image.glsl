// Image (image) — RiverScape by XT95
// https://www.shadertoy.com/view/dlSGWD

// ----------------------------------------------------------------
// RiverScape
//
// Article -> http://www.aduprat.com/portfolio/?page=articles/riverscape
// ----------------------------------------------------------------

vec3 ACES(const vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes * RESOLUTION * invRes;
    vec3 col = texture(iChannel0, uv).rgb / float(iFrame+1);
    
    col = ACES(col*8.5 + pow(col,vec3(1.5))*0.0);
    col = pow(col, vec3(1.0,1.035,1.115));
    
    // vignetting
    col *= vec3(1.) * smoothstep(1.8,.5, length(uv*2.-1.))*.25+.75;
    
    fragColor = vec4(pow(col, vec3(1./2.2)),1.0);
}