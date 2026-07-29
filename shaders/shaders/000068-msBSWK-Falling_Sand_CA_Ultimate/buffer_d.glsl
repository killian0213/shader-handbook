// Buffer D (buffer) — Falling Sand CA Ultimate by gelami
// https://www.shadertoy.com/view/msBSWK



// Cheap mipmap blur from Michael Moroz
// https://www.shadertoy.com/view/WsVGWV
float weight(float t, float log2radius, float gamma)
{
    return exp(-gamma*pow(log2radius-t,2.));
}

vec4 sampleBlurred(sampler2D ch, vec2 uv, float radius, float gamma)
{
    vec4 pix = vec4(0.);
    float norm = 0.;
    // Weighted integration over mipmap levels
    for(float i = 0.; i < 10.; i += 1.0)
    {
        float k = weight(i, log2(radius), gamma);
        pix += k*texture(ch, uv, i); 
        norm += k;
    }
    
    return pix / norm;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    initState(fragCoord, iFrame+3);
    vec4 scene = texelFetch(iChannel0, IRES-1, 0);
    float scale = scene.x;
    vec2 center = scene.zw;
    
    // Culling
    /*
    vec2 bl = center - RES * 0.5 / scale - 1.0;
    vec2 tr = center + RES * 0.5 / scale + 1.0;
    
    if (fragCoord.x < bl.x || fragCoord.x >= tr.x ||
        fragCoord.y < bl.y || fragCoord.y >= tr.y)
    {
        fragColor = vec4(0);
        return;
    }*/

    vec4 data = sampleTex0(fragCoord);
    float id = data.x;
    
    vec4 rand = hash42(uvec2(fragCoord));
    
    vec2 uv = fragCoord / RES;
    
    if (id == WATER || id == LAVA)
    {
        float a = (texture(iChannel2, uv * 4.0).r + iTime * 0.5) * TAU;
        uv += 1.2 * vec2(cos(a), sin(a)) / RES * vec2(RES.y / RES.x, 1.0);
    }
    vec3 bg = texture(iChannel1, uv * 2.0, 2.0).rgb * 0.25;//vec3(26, 29, 33) / 255.0;
    bg = round(bg * 64.0) / 64.0;
    
    vec3 col;
    
    if (id == SMOKE)
        col = vec3(0.5);
    else if (id == FIRE)
        col = vec3(1.0, 0.25, 0);
    else if (id == LAVA)
        col = vec3(1.0, 0.4, 0);
    else if (id == WATER)
        col = vec3(0.2, 0.3, 0.9);
    else if (id == SAND)
        col = vec3(225, 177, 89) / 255.0;
    else if (id == STONE)
        col = vec3(0.25);
    else if (id == WOOD)
        col = vec3(0.196,0.129,0.102);
    else if (id == PLANT)
        col = vec3(0.4, 0.65, 0.1);
    else if (id == WALL)
        col = vec3(0.09, 0.08, 0.13);
    else
        col = vec3(bg);
    
    vec3 hsl = RGBtoHSL(col);
    
    if (id != WATER)
    {
        vec3 r2 = rand.xyz;
        if (id == LAVA)
            r2 = 0.5 + 0.5 * sin((r2 + iTime * 0.4) * TAU);
        
        hsl.x = hsl.x + (r2.z - 0.5) * 8.0 / 255.0;
        hsl.y = hsl.y + (r2.x - 0.5) * 20.0 / 255.0;
        hsl.z = hsl.z + (r2.y - 0.5) * 16.0 / 255.0;

        vec3 rgb = HSLtoRGB(hsl);
        col = rgb;
    }
    
#ifdef RAINBOW_MODE
    hsl = vec3(fract(data.z * 4.0 + data.x * 1.2232), 0.5 + 0.5 * fract(data.w * 4.0), 0.5);
    col = mix(col, HSLtoRGB(hsl), 0.5);
#endif

    float r = rand.w;
    if (id == LAVA)
        r = 0.5 + 0.5 * sin((r - iTime * 0.4) * TAU);
    col *= 0.9 + 0.1 * r;
    
    bg *= 0.9 + 0.1 * rand.z;
    
    /*
    vec2 ldir = normalize(vec2(0, 1));
    
    vec2 n = vec2(0);
    for (int x = -1; x <= 1; x++)
    {
        for (int y = -1; y <= 1; y++)
        {
            if (x == 0 && y == 0)
                continue;
            float b = float(sampleTex0(fragCoord + vec2(x, y)).x != AIR);
            
            n += vec2(x, y) * (1.0 - b) * (abs(x) + abs(y) < 2 ? 1.0 : sqrt(2.0) / 2.0);
        }
    }
    
    n = normalize(n);
    */
    
    //float dif = max(dot(n, ldir), 0.0);
    //float sha = max(dot(n, -ldir), 0.0);
    
    float up = sampleTex0(fragCoord + vec2(0, 1)).x;
    float down = sampleTex0(fragCoord - vec2(0, 1)).x;
    float dif = float(up < id);
    float sha = float(down < id);// * float(!(down >= SAND && id >= SAND));
    
    float occ = sampleBlurred(iChannel0, fragCoord / RES, 16.0, 0.5).y;
    occ = saturate((1.0 - occ) / 0.25);
    
    col *= 0.2 + 0.8 * occ;
    col *= 0.6 + 0.4 * max(dif, 1.0 - sha);
    col += col * 0.3 * dif;
    
    float op = getOpacity(id);
    
    col = mix(bg, col, op);
    
    //col = vec3(bg);
    
    fragColor = vec4(col, occ);
}