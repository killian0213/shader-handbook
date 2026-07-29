// Buf A (buffer) — Jump Flooding by paniq
// https://www.shadertoy.com/view/4syGWK

// channel 1: JFA steps

vec4 load0(ivec2 p) {
    vec2 uv = (vec2(p)-0.5) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);
}

void store(out vec4 t, vec4 v) {
    t = v;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float iter = mod(float(iFrame),13.0);
    if (iter < 0.5) {
        // init
        vec2 uv = fragCoord / iResolution.xy;
        uv.x = clamp(uv.x * iResolution.x / iResolution.y - 0.3, 0.0, 1.0);
        float ww = 40.0/256.0;
        vec4 color = texture(iChannel1, 
			floor(mod(iTime * 5.0,6.0)) * vec2(ww,0.0) + vec2(ww,1.0) * uv);
        float lum = dot(color.rgb,vec3(0.299,0.587,0.114));
        if (lum < 0.4) {
            store(fragColor, vec4(fragCoord,0.0,0.0));
        } else {
            store(fragColor, vec4(0.0));
        }
    } else {
        // JFA step (for up to 4096x4096)
        float level = clamp(iter-1.0,0.0,11.0);
        int stepwidth = int(exp2(11.0 - level)+0.5);
        
        ivec2 tc = ivec2(fragCoord + 0.5);
        
        float best_dist = 999999.0;
        vec2 best_coord = vec2(0.0);
        vec2 center = vec2(tc);
        for (int y = -1; y <= 1; ++y) {
            for (int x = -1; x <= 1; ++x) {
                ivec2 fc = tc + ivec2(x,y)*stepwidth;
		        vec2 ntc = load0(fc).xy;
                float d = length(ntc - center);
                if ((ntc.x != 0.0) && (ntc.y != 0.0) && (d < best_dist)) {
                    best_dist = d;
                    best_coord = ntc;
                }
            }
        }        
        store(fragColor,vec4(best_coord,0.0,0.0));
    }
}