// Buffer C (buffer) — Moominhouse by ytt
// https://www.shadertoy.com/view/dlSSDd

// MIT License

// Buffer C - Compose materials and outline
// Inputs: Buffer B

const vec3 skyColor = vec3(0.64, 0.9, 1.0);
const vec3 fogColor = vec3(1.0, 0.96, 1.0);
const vec3 grassColor1 = vec3(0.84, 1.0, 0.52);
const vec3 grassColor2 = vec3(0.11, 0.72, 0.49);
const vec3 groundColor = vec3(0.68, 0.34, 0.02);

#define colorScreen(color1, color2) (1.0 - (1.0 - (color1)) * (1.0 - (color2)))

float getMaterialTextureMask(vec3 pos)
{
    pos.x += 10.0 * fbm(pos);
    float x = 1.5 * fbm(pos * vec3(1.0, 0.8, 1.2) * 0.4);
    x = x * x;
    x = x * (3.0 - x);
    return x;
}

vec3 getMaterialColor(float index, vec2 uv, vec3 pos, vec3 n)
{
    if (index < 1.0)
    {
        return vec3(1.0, 1.0, 0.0); // missing
    }

    if (index < MATERIAL_SKY + 1.0)
    {
        float sunMask = dot(normalize(SUN_DIRECTION), normalize(pos - state.origin));
        const float f1 = 0.00012;
        const float f2 = 0.1;
        sunMask = max(0.0, (sunMask - 1.0 + f1) / f1) + // sun
            0.1 * pow(max(0.0, (sunMask - 1.0 + f2) / f2), 4.0); // halo
        return mix(skyColor, vec3(2.0), sunMask);
    }

    if (index < MATERIAL_GRASS + 1.0)
    {
        vec3 grassColor = mix(grassColor1, grassColor2, uv.x).rgb;
        return mix(groundColor, grassColor, 0.8 + 0.2 * uv.y);
    }

    if (index < MATERIAL_GRASS_FLOWER1 + 1.0)
    {
        return mix(vec3(1.0), vec3(1.0, 0.99, 0.1), uv.y);
    }

    if (index < MATERIAL_GRASS_FLOWER2 + 1.0)
    {
        return vec3(1.0, 1.0, 0.1);
    }

    if (index < MATERIAL_MOUNTAIN + 1.0)
    {
        vec3 pos1 = pos;
        pos1.xz -= state.origin.xz;
        float t = getMaterialTextureMask(0.1 * pos1);

        vec3 viewZ = normalize(state.origin - pos);
        vec3 viewX = normalize(cross(viewZ, vec3(pos1.x, 0.0, pos1.z)));

        float fresnel = dot(n, viewZ);
        fresnel = pow(clamp(fresnel * 1.2, 0.0, 1.0), 4.0);

        float sky = dot(n, cross(viewZ, viewX));
        sky = pow(clamp(sky * 1.1, 0.0, 1.0), 8.0);

        vec3 color = mix(vec3(0.19, 0.73, 0.6), vec3(0.89, 1.0, 0.81), 0.7 * fresnel + 0.3 * t);
        color = mix(color, skyColor, 0.8 * sky + 0.2 * t);

        return color;
    }

    if (index < MATERIAL_CLOUD + 1.0)
    {
        return 1.4 * vec3(1.0, 0.83, 1.0); // over saturate
    }

    if (index < MATERIAL_OUTER_WALL + 1.0)
    {
        pos.y *= 0.05;

        vec3 color = mix(vec3(0.6, 0.82, 1.0), vec3(0.28, 0.63, 0.89), uv.x);

        float textureMask = map01_11(getMaterialTextureMask(10.0 * pos + 10.0 * uv.xyx));
        vec3 textureColor = 0.1 * textureMask * vec3(1.0, 0.8, 0.1);

        color = colorScreen(color, textureColor);
        return color;
    }

    if (index < MATERIAL_INNER_WALL + 1.0)
    {
        return uv.x < 0.5 ? vec3(0.92, 0.93, 0.75) : vec3(0.85, 0.87, 0.66);
    }

    if (index < MATERIAL_PAINTED_WOOD + 1.0)
    {
        pos *= 15.0;
        float textureMask = getMaterialTextureMask(pos);
        return mix(vec3(0.88, 0.94, 0.92), vec3(0.86, 0.92, 0.9), textureMask);
    }

    if (index < MATERIAL_WOOD1 + 1.0)
    {
        return mix(vec3(0.83, 0.72, 0.58), vec3(0.71, 0.63, 0.45), uv.x);
    }

    if (index < MATERIAL_WOOD2 + 1.0)
    {
        return vec3(0.83, 0.72, 0.58);
    }

    if (index < MATERIAL_WOOD3 + 1.0)
    {
        vec3 p = 400.0 * vec3(uv, 0.0);
        float textureMask = getMaterialTextureMask(p);
        vec3 color = mix(vec3(0.76, 0.65, 0.53), vec3(0.71, 0.57, 0.42), textureMask);
        return color;
    }

    if (index < MATERIAL_WOOD4 + 1.0)
    {
        vec3 p = 400.0 * vec3(uv, 0.0);
        float textureMask = getMaterialTextureMask(p);
        vec3 color = mix(vec3(0.64, 0.57, 0.49), vec3(0.58, 0.48, 0.38), textureMask);
        return color;
    }

    if (index < MATERIAL_TILE + 1.0)
    {
        float textureMask = getMaterialTextureMask(pos * 8.0);
        textureMask = 0.15 * (2.0 * textureMask - 1.0);
        return mix(vec3(0.9, 0.64, 0.56), vec3(0.75, 0.4, 0.34), uv.x + textureMask);
    }

    if (index < MATERIAL_BRICK + 1.0)
    {
        float textureMask = getMaterialTextureMask(pos * 20.0);
        textureMask = 0.1 * (2.0 * textureMask - 1.0);
        return mix(vec3(0.49, 0.27, 0.18), vec3(0.77, 0.58, 0.50), uv.x + textureMask);
    }

    if (index < MATERIAL_METAL1 + 1.0)
    {
        vec3 r = reflect(state.viewZ, n);
        float f = dot(r, SUN_DIRECTION);
        return mix(vec3(0.88, 0.94, 0.92), vec3(1.0), f < 0.8 ? 0.0 : 0.5);
    }

    if (index < MATERIAL_METAL2 + 1.0)
    {
        vec3 r = reflect(state.viewZ, n);
        float f = dot(r, SUN_DIRECTION);
        return mix(vec3(0.55, 0.34, 0.2), vec3(1.0), f < 0.8 ? 0.0 : 0.5);
    }

    if (index < MATERIAL_METAL3 + 1.0)
    {
        vec3 r = reflect(state.viewZ, n);
        float f = dot(r, SUN_DIRECTION);
        return mix(vec3(0.64, 0.72, 0.76), vec3(1.0), f < 0.8 ? 0.0 : 0.5);
    }

    if (index < MATERIAL_METAL4 + 1.0)
    {
        vec3 r = reflect(state.viewZ, n);
        float f = dot(r, SUN_DIRECTION);
        return mix(vec3(0.86, 0.8, 0.37), vec3(1.0), f < 0.8 ? 0.0 : 0.5);
    }

    if (index < MATERIAL_BASE_ROCK + 1.0)
    {
        float textureMask = getMaterialTextureMask(pos * 4.0);
        textureMask = 0.08 * (2.0 * textureMask - 1.0);
        return mix(vec3(0.82, 0.85, 0.89), vec3(0.47, 0.49, 0.51), uv.x + textureMask);
    }

    if (index < MATERIAL_ROPE + 1.0)
    {
        return mix(vec3(0.54, 0.38, 0.02), vec3(0.71, 0.6, 0.34), uv.x);
    }

    if (index < MATERIAL_RIVERBED + 1.0)
    {
        pos *= 1.5;
        return mix(vec3(0.93, 0.91, 0.76), vec3(0.84, 0.8, 0.57), getMaterialTextureMask(pos));
    }

    if (index < MATERIAL_SOIL + 1.0)
    {
        pos *= 100.0;
        float textureMask = getMaterialTextureMask(pos);
        return mix(vec3(0.37, 0.21, 0.15), vec3(0.46, 0.3, 0.24), textureMask);
    }

    if (index < MATERIAL_PATHWAY + 1.0)
    {
        pos *= 4.0;
        return mix(vec3(0.83, 0.78, 0.47), vec3(0.88, 0.83, 0.6), getMaterialTextureMask(pos));
    }

    if (index < MATERIAL_PATHWAY_ROCK + 1.0)
    {
        pos *= 7.0;
        return mix(vec3(0.8, 0.87, 0.89), vec3(0.76, 0.75, 0.74), getMaterialTextureMask(pos));
    }

    if (index < MATERIAL_TREE_BRANCH + 1.0)
    {
        return vec3(0.46, 0.54, 0.4);
    }

    if (index < MATERIAL_TREE_BARK + 1.0)
    {
        return vec3(0.45, 0.35, 0.3);
    }

    if (index < MATERIAL_STEM + 1.0)
    {
        return vec3(0.6, 0.89, 0.32);
    }

    if (index < MATERIAL_FLOWER1 + 1.0)
    {
        return mix(vec3(1.0), vec3(1.0, 0.5, 1.0), uv.y);
    }

    if (index < MATERIAL_FLOWER2 + 1.0)
    {
        return vec3(1.0, 0.9, 0.1);
    }

    if (index < MATERIAL_HAT + 1.0)
    {
        return vec3(0.4, 0.3, 0.56);
    }

    if (index < MATERIAL_HAT_RIBBON + 1.0)
    {
        return vec3(0.78, 0.51, 0.94);
    }

    if (index < MATERIAL_SKIN + 1.0)
    {
        return mix(vec3(0.85, 0.98, 0.99), vec3(1.0, 0.86, 0.85), uv.y);
    }

    if (index < MATERIAL_EYE + 1.0)
    {
        return vec3(1.0);
    }

    if (index < MATERIAL_PUPIL + 1.0)
    {
        return vec3(0.16, 0.85, 1.0);
    }

    if (index < MATERIAL_MOUTH + 1.0)
    {
        return vec3(1.0, 0.8, 0.75);
    }

    if (index < MATERIAL_SCARF + 1.0)
    {
        return mix(vec3(0.28, 0.74, 0.28), vec3(0.86, 0.48, 0.2), uv.x);
    }

    if (index < MATERIAL_PORCELIN + 1.0)
    {
        return vec3(0.9, 0.95, 0.98);
    }

    if (index < MATERIAL_CAKE1 + 1.0)
    {
        return vec3(1.0, 0.99, 0.73);
    }

    if (index < MATERIAL_CAKE2 + 1.0)
    {
        return vec3(0.62, 0.31, 0.1);
    }

    if (index < MATERIAL_JUICE + 1.0)
    {
        return vec3(0.92, 0.22, 0.75);
    }

    return vec3(1.0, 1.0, 0.0); // missing
}

vec4 getMaterialTintColor(float index, vec3 pos, vec3 n)
{
    if (index < 1.0)
    {
        return vec4(0.0);
    }

    if (index < MATERIAL_WINDOW_GLASS)
    {
        return vec4(getMaterialColor(index, vec2(0.5), pos, n), 0.5);
    }

    if (index < MATERIAL_WINDOW_GLASS + 2.0)
    {
        float ref = index >= MATERIAL_WINDOW_GLASS + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(0.6, 0.8, 0.84), vec3(1.0), ref), 0.5);
    }

    if (index < MATERIAL_DOOR_GLASS1 + 2.0)
    {
        float ref = index >= MATERIAL_DOOR_GLASS1 + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(0.1, 0.5, 1.0), vec3(1.0), ref), 0.5);
    }

    if (index < MATERIAL_DOOR_GLASS2 + 2.0)
    {
        float ref = index >= MATERIAL_DOOR_GLASS2 + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(1.0, 0.1, 0.0), vec3(1.0), ref), 0.5);
    }

    if (index < MATERIAL_DOOR_GLASS3 + 2.0)
    {
        float ref = index >= MATERIAL_DOOR_GLASS3 + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(1.0, 0.8, 0.0), vec3(1.0), ref), 0.4);
    }

    if (index < MATERIAL_GLASS1 + 2.0)
    {
        float ref = index >= MATERIAL_GLASS1 + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(0.6, 0.8, 0.84), vec3(1.0), ref), 0.5);
    }

    if (index < MATERIAL_GLASS2 + 2.0)
    {
        float ref = index >= MATERIAL_GLASS2 + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(0.6, 0.8, 0.84), vec3(1.0), ref), 0.5);
    }

    if (index < MATERIAL_GLASS3 + 2.0)
    {
        float ref = index >= MATERIAL_GLASS3 + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(0.6, 0.8, 0.84), vec3(1.0), ref), 0.5);
    }

    if (index < MATERIAL_GLASS4 + 2.0)
    {
        float ref = index >= MATERIAL_GLASS4 + 1.0 ? 0.6 : 0.0; // reflection
        return vec4(mix(vec3(0.6, 0.8, 0.84), vec3(1.0), ref), 0.5);
    }

    if (index < MATERIAL_CLOUD + 2.0)
    {
        return vec4(1.3 * (n.y > -0.3 ? vec3(1.0, 1.0, 1.0) : vec3(1.0, 0.7, 0.8)), 0.6);
    }

    if (index < MATERIAL_WATER + 2.0)
    {
        return index < MATERIAL_WATER + 1.0 ?
            vec4(0.57, 0.88, 1.0, 0.6) :
            vec4(0.7, 0.7, 0.75, 0.5); // reflection
    }

    if (index < MATERIAL_JUICE + 2.0)
    {
        return vec4(0.92, 0.22, 0.75, 0.6);
    }
}

vec2 getOutline(vec2 fragCoord)
{
    float f = 0.0;
    float minDepth = 1.0;
    float maxDepth = 0.0;
    float minIndex1 = 100.0;
    float maxIndex1 = 0.0;
    float minIndex2 = 100.0;
    float maxIndex2 = 0.0;

    float outlineIndex1 = 0.0; // selected outline material index
    float outlineIndex2 = 0.0; // selected outline tint index
    float outlineDepth = MAX_DIST; // selected outline material distance

    for (int i = 0; i < 9; i++)
    {
        vec2 offset = vec2(float(i % 3), float(i / 3)) + vec2(-1.0);
        vec4 t = inputTexture(fragCoord + offset);

        float depth = min(deserializeDepth(getDepthComponent(t)) / 200.0, 1.0); // MAX_DIST
        minDepth = min(minDepth, depth);
        maxDepth = max(maxDepth, depth);

        float index1 = getMaterialIndexComponent(t);
        minIndex1 = min(minIndex1, index1);
        maxIndex1 = max(maxIndex1, index1);

        float index2 = getTintIndexComponent(t);
        minIndex2 = min(minIndex2, index2);
        maxIndex2 = max(maxIndex2, index2);

        outlineIndex1 = outlineDepth < depth ? outlineIndex1 : index1;
        outlineIndex2 = outlineDepth < depth ? outlineIndex2 : index2;
        outlineDepth = min(outlineDepth, depth);

        bool isOutline = getOutlineComponent(t) > 0.0;
        f += isOutline ? (3.0 - abs(offset.x) - abs(offset.y)) / 3.0 : 0.0;
    }

    float isEdge = (abs(maxDepth - minDepth) + abs(maxIndex1 - minIndex1) + abs(maxIndex2 - minIndex2)) * 150.0; // keep edge outlines

    float depth1 = pow(1.0 - minDepth, 5.0); // fade inner outlines
    depth1 = materialFadeInnerLines(maxIndex1) ? depth1 : 1.0;; // keep mountains inner lines
    minDepth = materialFadeOutlines(minIndex1) && materialFadeOutlines(maxIndex1) ? 40.0 * minDepth : minDepth; // fade grass flowers outlines
    float opacity = clamp(1.0 - minDepth * 0.5, 0.0, 1.0); // fade far outlines
    return vec2(opacity * clamp(f / 3.0, 0.0, 1.0) * clamp(isEdge + depth1, 0.0, 1.0), outlineIndex1);
}

vec3 getPosition(vec2 coord, vec4 t)
{
    vec2 uv = map01_11(coord / iResolution.xy);
    uv.x *= iResolution.x / iResolution.y;

    float depth = deserializeDepth(getDepthComponent(t));
    vec3 rd = normalize(uv.x * state.viewX + uv.y * state.viewY + FIELD_OF_VIEW * state.viewZ * state.renderScale);

    vec3 pos = state.viewOrigin + depth * rd; // point in scene

    return pos;
}

vec3 getPosition(vec2 coord)
{
    return getPosition(coord, inputTexture(coord));
}

vec3 getNormal(vec2 coord, vec4 t)
{
    vec3 pos = getPosition(coord, t);
    vec3 nx0 = pos - getPosition(coord - vec2(1.0, 0.0));
    vec3 ny0 = pos - getPosition(coord - vec2(0.0, 1.0));
    vec3 nx1 = pos - getPosition(coord + vec2(1.0, 0.0));
    vec3 ny1 = pos - getPosition(coord + vec2(0.0, 1.0));
    vec3 nx = length(nx0) < length(nx1) ? -nx0 : nx1;
    vec3 ny = length(ny0) < length(ny1) ? -ny0 : ny1;
    return normalize(cross(nx, ny));
}

vec3 getDepthColor(float depth)
{
    const float depth1 = 0.5;
    const float depth2 = 4.0;
    depth = deserializeDepth(depth);
    depth = log(depth + depth1) / log(depth1 + depth2);
    return vec3(1.0 - depth);
}

// iq - shadertoy/ll2GD3
vec3 getGroupColor(float group)
{
    return group > 0.0 ? vec3(0.7 + 0.3 * sin((group * 0.27 + vec3(0.66, 0.0, 0.33)) * PI2)) : vec3(0.9);
}

float getTargetMask(vec2 pos)
{
    const float thickness = 2.0;
    const float opening = 5.0;
    const float size = 15.0;

    pos.xy = abs(pos.xy);
    pos = vec2(max(pos.x, pos.y), min(pos.x, pos.y));

    return ((pos.x > opening && pos.x < size && pos.x > thickness && pos.y < thickness)) ? 1.0 : 0.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 t = inputTexture(fragCoord);

    if (fragCoord.x < STATE_SIZE && fragCoord.y < 1.0)
    {
        fragColor = t;
        return;
    }

    deserializeState(iChannel0, iResolution.xy);

    vec3 color;

    if (state.renderMode > 6.0)
    {
        // uv
        color = vec3(getMaterialUvComponent(t), 0.0);
    }
    else if (state.renderMode > 5.0)
    {
        // outline + edge group
        color = getGroupColor(getEdgeGroupComponent(t)) * (1.0 - getOutlineComponent(t));
    }
    else if (state.renderMode > 4.0)
    {
        // outline
        color = vec3(1.0 - getOutlineComponent(t));
    }
    else if (state.renderMode > 3.0)
    {
        // shadow
        color = vec3(1.0 - getShadowComponent(t));
    }
    else if (state.renderMode > 2.0)
    {
        // depth
        color = getDepthColor(getDepthComponent(t));
    }
    else if (state.renderMode > 1.0)
    {
        // normal
        color = getNormal(fragCoord, t);
    }
    else if (state.renderMode > 0.0)
    {
        // steps
        color = mix(vec3(getMaterialUvComponent(t).y), vec3(0.6, 0.9, 1.0), getOutlineComponent(t));
    }
    else
    {
        float materialIndex = getMaterialIndexComponent(t);
        float tintIndex = getTintIndexComponent(t);
        float depth = deserializeDepth(getDepthComponent(t));
        vec2 uv = getMaterialUvComponent(t);
        vec3 pos = getPosition(fragCoord, t);
        vec3 n = getNormal(fragCoord, t);

        color = getMaterialColor(materialIndex, uv, pos, n);

        // mix with grass color for down facing surfaces
        color = mix(color, color + groundColor - vec3(1.0), materialHasGroundBounceLight(materialIndex) ? 0.3 * smoothstep(-0.2, -0.6, dot(n, vec3(0.0, 1.0, 0.0))) : 0.0);

        // outline
        vec2 outline = getOutline(fragCoord);
        vec3 outlineColor = getMaterialColor(outline.y, uv, pos, n);
        outlineColor = min(outlineColor, 1.0); // clamp over staturated materials
        outlineColor = vec3(pow(outlineColor.r, 4.0), pow(outlineColor.g, 4.0), pow(outlineColor.b, 4.0));
        outlineColor = mix(outlineColor, vec3(0.28, 0.15, 0.04), 0.5);

        color = mix(color, outlineColor, outline.x);

        // shadow
        bool isGround = abs(materialIndex - MATERIAL_GRASS) == 0.0;
        float shadow = getShadowComponent(t);
        shadow = isGround ? shadow : (1.0 - (1.0 - shadow) * smoothstep(0.1, 0.2, dot(SUN_DIRECTION, n)));

        shadow = materialReceivesShadow(materialIndex) ? shadow : 0.0;
        shadow *= 0.3;
        color = mix(color, color + vec3(0.6, 0.1, 0.0) - vec3(1.0), shadow);

        // tint
        vec4 tintColor = getMaterialTintColor(tintIndex, pos, n);
        color = mix(color, tintColor.rgb, tintColor.a);

        // fog
        float fog1 = 50.0 + 2.0 * max(pos.y, 0.0); // start
        float fog2 = 200.0 + 10.0 * max(pos.y, 0.0); // end
        float fog = min(pow(max(depth - fog1, 0.0) / (fog2 - fog1), 0.5), 1.0);
        color = mix(color, fogColor, fog);
    }

    fragColor = vec4(color, 1.0);
}
