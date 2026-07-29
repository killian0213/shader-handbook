// Buffer A (buffer) — Falling Sand CA Ultimate by gelami
// https://www.shadertoy.com/view/msBSWK


#define BUFFER_OFFSET 0

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    initState(fragCoord, iFrame);
    ivec2 p = ivec2(floor(fragCoord));
    
    // Keyboard functions
    if (p == IRES-1)
    {
        if (iFrame < 2)
        {
            fragColor = vec4(SCALE, 0, ZOOM_POINT);
            return;
        }
        
        vec4 prev = texelFetch(iChannel0, p, 0);
    
        float up = texelFetch(iChannel3, ivec2(KEY_UP, 0), 0).r;
        float down = texelFetch(iChannel3, ivec2(KEY_DOWN, 0), 0).r;
        float left = texelFetch(iChannel3, ivec2(KEY_LEFT, 0), 0).r;
        float right = texelFetch(iChannel3, ivec2(KEY_RIGHT, 0), 0).r;
    
        float zoomin = texelFetch(iChannel3, ivec2(KEY_PLUS, 0), 0).r;
        float zoomout = texelFetch(iChannel3, ivec2(KEY_MINUS, 0), 0).r;

        vec2 speed = vec2(15.0 / prev.x);
        float zoom = log2(prev.x + 1.0) * 0.08;
        
        if (zoomin > 0.0)
            prev.x += zoom;
        if (zoomout > 0.0)
            prev.x -= zoom;
        
        prev.x = max(prev.x, 1.0);
    
        prev.w += up * speed.y;
        prev.w -= down * speed.y;
        prev.z -= left * speed.x;
        prev.z += right * speed.x;
        
        prev.zw = clamp(prev.zw, RES * 0.5 / prev.x, RES - RES * 0.5 / prev.x);
        
        fragColor = prev;
        return;
        
    } else if (p == IRES - ivec2(2, 1))
    {
        if (iFrame < 2)
        {
            fragColor = vec4(MOUSE_RADIUS, SAND, 0, 0);
            return;
        }
        
        vec4 prev = texelFetch(iChannel0, p, 0);
                
        for (int i = 0; i < 10; i++)
        {
            if (texelFetch(iChannel3, ivec2(KEY_0 + i, 0), 0).r > 0.0)
                prev.y = float(i);
        }
        
        float bleft = texelFetch(iChannel3, ivec2(KEY_BRACKET_LEFT, 0), 0).r;
        float bright = texelFetch(iChannel3, ivec2(KEY_BRACKET_RIGHT, 0), 0).r;
        
        float radiusChange = 0.2;
        prev.x -= bleft * radiusChange;
        prev.x += bright * radiusChange;
        
        prev.x = max(prev.x, 1.0);
        
        if (iMouse.z > 0.0)
        {
            prev.zw = iMouse.xy;
        } else {
            prev.zw = vec2(0);
        }
        
        fragColor = prev;
        return;
    }
    
    float space = texelFetch(iChannel3, ivec2(KEY_SPACE, 0), 0).r;
    float reset = texelFetch(iChannel3, ivec2(KEY_R, 0), 0).r;
    
    if (space > 0.0)
    {
    
        fragColor = vec4(AIR, 0, fragCoord / RES);
        return;
    }
    
    if (iFrame < 2 || reset > 0.0)
    {
        if (fragCoord.y == 0.5)
        {
            fragColor = vec4(WALL, 0, fragCoord / RES);
            return;
        }
        
        vec4 tex = texture(iChannel1, fragCoord / RES);
        float id = mod(round(tex.x * WALL * 3.0 - 1.0), WALL+1.0);
        
        if (id == LAVA && tex.y < 0.2)
            id = SMOKE;
        if (id == STONE && tex.z < 0.3)
            id = SAND;
        if (id == PLANT && hash(state) < 0.8)
            id = WATER;
        
        //float id = hash(state) < 0.05 ? SAND : AIR;
        fragColor = vec4(id, 0, fragCoord / RES);
        return;
    }

    vec2 mousePos = vec2(0);
    // Mouse interaction
    if (iMouse.z > 0.0)
    {
        mousePos = iMouse.xy;   
    } else {
        //mp = vec2(sin(iTime * 0.9) * 0.4 * RES.x + RES.x * 0.5, RES.y * 0.8);
    }
    
    if (mousePos != vec2(0))
    {
        vec4 scene = texelFetch(iChannel0, IRES-1, 0);
        vec4 mouse = texelFetch(iChannel0, IRES-ivec2(2, 1), 0);
        float scale = scene.x;
        vec2 center = scene.zw;
        float radius = mouse.x;
        float id = mouse.y;
        vec2 prevMousePos = mouse.zw;
        
        if (prevMousePos != vec2(0))
        {
            vec2 m = (mousePos - RES * 0.5) / scale + center;
            vec2 mp = (prevMousePos - RES * 0.5) / scale + center;
            float d = sdSegment(fragCoord, m, mp);
            //float d = length(fragCoord - m);

            if (d < radius && hash(state) < MOUSE_STRENGTH)
            {
                fragColor = vec4(id, 0, fragCoord / RES + iTime * 0.1);
                return;
            }
        }
    }
    
    fragColor = simulate(iChannel0, p, IRES, iFrame, BUFFER_OFFSET);
    fragColor.y = getOpacity(fragColor.x);
    if (fragColor.x == FIRE || fragColor.x == LAVA)
        fragColor.y = 0.0;
    //fragColor.y = float(fragColor.x != AIR);
}