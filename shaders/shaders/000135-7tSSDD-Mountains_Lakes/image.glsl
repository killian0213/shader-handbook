// Image (image) — Mountains & Lakes by xjorma
// https://www.shadertoy.com/view/7tSSDD

// Created by David Gallardo - xjorma/2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0


#define AA
#define GAMMA 1

const vec3 light = vec3(0.,4.,2.);
const float boxHeight = 0.45;

/*
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 p = ivec2(fragCoord);
    float h = texelFetch(iChannel0, p, 0).x;
    float w = texelFetch(iChannel1, p, 0).x; 
    fragColor = vec4(h, w, w, 1.0);
}*/


vec2 getHeight(in vec3 p)
{
    p = (p + 1.0) * 0.5;
    vec2 p2 = p.xz * vec2(float(textureSize)) / iResolution.xy;
    p2 = min(p2, vec2(float(textureSize) - 0.5) / iResolution.xy);
    vec2 h = texture(iChannel0, p2).xy;
    h.y += h.x;
	return h - boxHeight;
} 

vec3 getNormal(in vec3 p, int comp)
{
    float d = 2.0 / float(textureSize);
    float hMid = getHeight(p)[comp];
    float hRight = getHeight(p + vec3(d, 0, 0))[comp];
    float hTop = getHeight(p + vec3(0, 0, d))[comp];
    return normalize(cross(vec3(0, hTop - hMid, d), vec3(d, hRight - hMid, 0)));
}

vec3 terrainColor(in vec3 p, in vec3 n, out float spec)
{
    spec = 0.1;
    vec3 c = vec3(0.21, 0.50, 0.07);
    float cliff = smoothstep(0.8, 0.3, n.y);
    c = mix(c, vec3(0.25), cliff);
    spec = mix(spec, 0.3, cliff);
    float snow = smoothstep(0.05, 0.25, p.y) * smoothstep(0.5, 0.7, n.y);
    c = mix(c, vec3(0.95, 0.95, 0.85), snow);
    spec = mix(spec, 0.4, snow);
    vec3 t = texture(iChannel1, p.xz * 5.0).xyz;
    return mix(c, c * t, 0.75);
}

vec3 undergroundColor(float d)
{
    vec3 color[4] = vec3[](vec3(0.5, 0.45, 0.5), vec3(0.40, 0.35, 0.25), vec3(0.55, 0.50, 0.4), vec3(0.45, 0.30, 0.20));
    d *= 6.0;
    d = min(d, 3.0 - 0.001);
    float fr = fract(d);
    float fl = floor(d);
    return mix(color[int(fl)], color[int(fl) + 1], fr);
}



vec3 Render(in vec3 ro, in vec3 rd)
{
    vec3 n;
    vec2 ret = boxIntersection(ro, rd, vec3(1, boxHeight, 1), n);
    if(ret.x > 0.0)
    {
        vec3 pi = ro + rd * ret.x;
        // Find Terrain
        vec3 tc;
        vec3 tn;
        float tt = ret.x;
        vec2 h = getHeight(pi);
        float spec;
        if(pi.y < h.x)
        {
            tn = n;
            tc = undergroundColor(h.x - pi.y);
        }
        else
        {
            for (int i = 0; i < 80; i++)
            {
                vec3 p = ro + rd * tt;
                float h = p.y - getHeight(p).x;
                if (h < 0.0002 || tt > ret.y)
                    break;
                tt += h * 0.4;
            }
            tn = getNormal(ro + rd * tt, 0);
            tc = terrainColor(ro + rd * tt, tn, spec);
        }
        
        {
            vec3 lightDir = normalize(light - (ro + rd * tt));
            tc = tc * (max( 0.0, dot(lightDir, tn)) + 0.3);
            spec *= pow(max(0., dot(lightDir, reflect(rd, tn))), 10.0);
            tc += spec;            
        }
        
        if(tt > ret.y)
        {
            tc = backgroundColor;
        }
        
        // Find Water
        float wt = ret.x;
        h = getHeight(pi);
        vec3 waterNormal;
        if(pi.y < h.y)
        {
            waterNormal = n;
        }
        else
        {
            for (int i = 0; i < 80; i++)
            {
                vec3 p = ro + rd * wt;
                float h = p.y - getHeight(p).y;
                if (h < 0.0002 || wt > min(tt, ret.y))
                    break;
                wt += h * 0.4;
            }
            waterNormal = getNormal(ro + rd * wt, 1);
        }
        
        if(wt < ret.y)
        {
            float dist = (min(tt, ret.y) - wt);
            vec3 p = waterNormal;
            vec3 lightDir = normalize(light - (ro + rd * wt));
                        
            tc = applyFog(tc, vec3(0.0, 0.0, 0.6), dist * 10.0);

            float spec = pow(max(0., dot(lightDir, reflect(rd, waterNormal))), 20.0);
            tc += 0.5 * spec * smoothstep(0.0, 0.1, dist);
        }

        
        return tc;
    }
   
    return backgroundColor;
}


mat3 setCamera( in vec3 ro, in vec3 ta )
{
	vec3 cw = normalize(ta-ro);
	vec3 up = vec3(0, 1, 0);
	vec3 cu = normalize( cross(cw,up) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


vec3 vignette(vec3 color, vec2 q, float v)
{
    color *= 0.3 + 0.8 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), v);
    return color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec3 tot = vec3(0.0);
    
    vec2 mouse = iMouse.xy;
    if(length(mouse.xy) < 10.0)
        mouse = iResolution.xy * 0.5;
        
#ifdef AA
	vec2 rook[4];
    rook[0] = vec2( 1./8., 3./8.);
    rook[1] = vec2( 3./8.,-1./8.);
    rook[2] = vec2(-1./8.,-3./8.);
    rook[3] = vec2(-3./8., 1./8.);
    for( int n=0; n<4; ++n )
    {
        // pixel coordinates
        vec2 o = rook[n];
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
#else //AA
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
#endif //AA
 
        // camera
        
        float theta	= radians(360.)*(mouse.x/iResolution.x-0.5) + iTime*.2;
        float phi	= radians(90.)*(mouse.y/iResolution.y-0.5)-1.;
        vec3 ro = 2.0 * vec3( sin(phi)*cos(theta),cos(phi),sin(phi)*sin(theta));
        //vec3 ro = vec3(0.0,.2,4.0);
        vec3 ta = vec3( 0 );
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta );
        //vec3 cd = ca[2];    
        
        vec3 rd =  ca*normalize(vec3(p,1.5));        
        
        vec3 col = Render(ro, rd);
        
        tot += col;
            
#ifdef AA
    }
    tot /= 4.;
#endif
    
    tot = vignette(tot, fragCoord / iResolution.xy, 0.6);
    #if GAMMA
    	tot = pow(tot, vec3(1. / 2.2));
    #endif

	fragColor = vec4( tot, 1.0 );
}