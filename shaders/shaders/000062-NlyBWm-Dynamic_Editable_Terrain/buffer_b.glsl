// Buffer B (buffer) — Dynamic Editable Terrain by fenix
// https://www.shadertoy.com/view/NlyBWm

// --------------------------------------------------------------------------------------------
// Render the scene via ray marching, with shadows.
// --------------------------------------------------------------------------------------------

const float LAYER_HEIGHT = 0.004;

float scene(vec3 p, float t)
{
    p.x *= iResolution.y/iResolution.x;
    float h = textureLod(iChannel0, p.xz*0.1, 0.).r + textureLod(iChannel0, p.xz*0.1, 1.).x;
    float height = p.y - max(6.,h)*LAYER_HEIGHT;
    
    return min(height, p.y + .05);
}

vec3 grad(vec3 p, float t, float d)
{
    vec2 delta = vec2(d, 0);
    return normalize(
           vec3(scene(p + delta.xyy, t) - scene(p - delta.xyy, t),
                scene(p + delta.yxy, t) - scene(p - delta.yxy, t),
                scene(p + delta.yyx, t) - scene(p - delta.yyx, t)));
}

const float MAX_T = 6.0;
const float SDF_EPSILON = 0.002;
vec3 rayMarch(vec3 pos, vec3 dir, float scale, out float t)
{
    t = 0.;
    for (int i = 0; i < 250; ++i)
    {
        float d = scene(pos, scale);
        
        if (d < SDF_EPSILON || t > MAX_T)
        {
            break;
        }
        
        float slowdown = max(d * 0.1, 0.2);
        t += d * slowdown;

        pos += dir * d * slowdown;
    }
 
    return pos;
}

vec4 render(vec3 cameraPos, vec3 rayDir, bool doShadow, out vec3 hitPos, out vec3 normal)
{
    float t;
    hitPos = rayMarch(cameraPos, rayDir, float(iFrame), t);

    normal = grad(hitPos, float(iFrame), 0.01);
    vec3 offsetPos = hitPos + normal*SDF_EPSILON;

    // Compute color
    vec3 h = hash(uvec3(100.*vec3(hitPos.x, hitPos.y, hitPos.z)));
    vec3 hGrass = hash(uvec3(100.*vec3(hitPos.x, hitPos.z, hitPos.x)));
    float splotches = (h.x * 0.5 + 0.5);
    float splotchesGrass = (hGrass.x * 0.5 + 0.5); // Use x,z splotch pattern for grass, to fix rendering artifact
    vec3 color = vec3(0.8, 0.4, 0.1) * splotches;
    if (dot(normal, vec3(0, 1, 0)) > 0.8) color = vec3(0., 1.0, 0.) * splotchesGrass;
    if (hitPos.y <= 9.*LAYER_HEIGHT) color = vec3(0.9, 0.9, 0.5) * splotches;
    if (hitPos.y <= 7.*LAYER_HEIGHT)
    {
        color = vec3(0.5, 0.5, 1.0);
    }
    
    // Apply light and shadow
    vec3 lightDir = normalize(vec3(0, 0.4, 1));
    const float AMBIENT = 0.3;

    float shadowT = MAX_T;
    
    if (doShadow)
    {
        rayMarch(offsetPos, lightDir, float(iFrame), shadowT);
    }    
    
    if (shadowT < MAX_T)
    {
        color = color * AMBIENT;
    }
    else
    {
        float dp = max(0., dot(normal, lightDir));
        color = color * (dp + AMBIENT);
    }
    
    // Fade at distance
    if (t >= MAX_T*.75)
    {
        // Pebble texture == clouds
        vec3 sky = texture(iChannel1, rayDir.xy * 0.6 + 0.5).xyz;
        //vec3 sky = mix(vec3(0.0, 0.0, 0.1), vec3(1), texture(iChannel1, rayDir.xy * 0.6 + 0.5 ).rrr);
        color = mix(color, sky, smoothstep(MAX_T*.75, MAX_T, t));
    }
    
    return vec4(color, t);
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{    
    vec4 state = texelFetch(iChannel0, ivec2(0), 0);
    float time = float(iTime);
    vec2 mouse = iMouse.xy;
    bool doShadow = state.w >= 0.;

    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(time, mouse, cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

	vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);
    
    vec3 hitPos, normal;
    vec4 colorT = render(cameraPos, rayDir, doShadow, hitPos, normal);

    // Handle reflections
    if (hitPos.y <= 7.*LAYER_HEIGHT && doShadow)
    {
        float reflectT;
        vec3 reflectHitPos, reflectNormal;
        vec4 reflectColorT = render(hitPos + normal*SDF_EPSILON, reflect(rayDir, vec3(0, 1, 0)), state.w== 0., reflectHitPos, reflectNormal);
        colorT.xyz = mix(colorT.xyz, reflectColorT.xyz, 0.4);
    }
    
    fragColor = colorT;
    
#if 0 // Debug terrain texture
    fragColor = sin(texelFetch(iChannel0, ivec2(fragCoord), 0).r + vec4(2, 3, 4, 5));
    fragColor.w = 0.;
#endif
}
