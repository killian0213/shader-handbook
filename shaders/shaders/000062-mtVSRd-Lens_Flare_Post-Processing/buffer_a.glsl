// Buffer A (buffer) — Lens Flare Post-Processing by gelami
// https://www.shadertoy.com/view/mtVSRd


// Skybox pass

// Formula found from
// Inverse Aces Tonemap Operator - Chrisy
// https://www.shadertoy.com/view/wlfyWr
vec3 inverseReinhard(vec3 color, float exposure)
{
    return color / (exposure * max((1.0 - color) / exposure, 1e-3));
}

vec3 getSky(vec3 rd)
{
    vec3 sky = sRGBToLinear(texture(iChannel0, rd).rgb);
    
    sky = inverseReinhard(sky, ENV_MAP_WHITE_POINT);
    sky /= vec3(1, 0.5, 0.4);
    
    vec3 dir = normalize(vec3(1, 0.5, -1));
    
    //sky += vec3(1) * smoothstep(0.995, 1.0, dot(rd, dir)) * 20.0;
    
    return sky;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pv = (2. * (fragCoord) - iResolution.xy) / iResolution.y;
    vec2 uv = fragCoord / iResolution.xy;
    
    vec3 ro = getCameraPos(iMouse, iResolution.xy, iTime);
    vec3 lo = getLookAtPos();

    mat3 cmat = getCameraMatrix(ro, lo);

    const float invTanFov = 1.25;
    
    vec3 rd = normalize(cmat * vec3(pv, invTanFov));

    vec3 col = getSky(rd);
    
    fragColor = vec4(col, 1);
}