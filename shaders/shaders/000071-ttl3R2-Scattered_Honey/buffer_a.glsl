// Buffer A (buffer) — Scattered Honey by fizzer
// https://www.shadertoy.com/view/ttl3R2

const float pi = acos(-1.);

// Signed distance field
float map(vec3 p)
{
    float d = 0.;
    
    p.x += 11.5;

    p += (smoothSample(iChannel2, p * 2., 0).rgb - .5) * .001;
    p += (smoothSample(iChannel2, p / 18. - 10. / 205. * vec3(0, 0, 1), 0).rgb - .5) * 1.5;
    d += length(p.yz) - .6;

    d = max(d - .2, -(length(mod(p, .2) - .1) - .015));
    
    d = min(d, length(abs(p.yz) - 1.5) - .05);
    d = min(d, length(p.yz - 1.2) - .05);
    
    return d;
}

vec3 mapNormal(vec3 p)
{
    vec3 e = vec3(1e-3, 0., 0.);
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
                          map(p + e.yxy) - map(p - e.yxy),
                          map(p + e.yyx) - map(p - e.yyx)));
}

vec4 render(vec2 fragCoord)
{    
    // Set up primary ray

    vec2 p = fragCoord / iResolution.xy * 2. - 1.;
    p.x *= iResolution.x / iResolution.y;

    vec3 ro = vec3(0, 0, 3.5);
    vec3 rd = normalize(vec3(p, -2.8));

    // Camera rotation
    
    mat3 m = rotY(.6) * rotZ(-.3);

    rd = m * rd;

    vec4 fragColor = vec4(0);

    // When flip is positive, the march is outside of the glass.
    // When it's negative, the march is inside of the glass.
    float flip = +1.;
    
    vec3 transfer = vec3(1);

    vec3 rp = ro + rd * 2., prevhitrp = rp;

    for(int i = 0; i < 400; ++i)
    {
        float d = map(rp) * flip;

        // Test for surface hit
        if(abs(d) < 1e-4)
        {
            // Get the surface normal here
            vec3 n = mapNormal(rp), on = n;
            
            // Put the normal and ray direction on the same side of the plane
            n *= -sign(dot(rd, n));
            
            // Fresnel term
            float fr = mix(.01, .4, pow(clamp(1. - dot(-rd, n), 0., 1.), 5.));
            
            // Refract ray direction, or reflect if there is no solution (as per Snell's law).
            // This accounts for total internal reflection.
            float ior = 1.25;
            vec3 refr = normalize(refract(normalize(rd), normalize(n), flip < 0. ? ior : 1. / ior));
            rd = dot(refr, refr) > 0. ? refr : reflect(rd, n);

            float dist = distance(rp, prevhitrp);

            // If the ray is just leaving a solid volume then aborb some energy
            // according to Beer's law.
            if(flip < 0.)
                transfer *= exp(-abs(dist) * vec3(.3, .5, .7) * 2.2);

            // Just directly add a reflection here, to avoid the need for a branch path.
            // This isn't correct, but a reflection is needed somehow to get any kind of
            // convincing material appearance.
            fragColor.rgb += textureLod(iChannel1, reflect(rd, n), 2.).rgb * transfer * fr;
            

            prevhitrp = rp;

            flip = -flip;
            d = 2e-4;
            
            // Push the ray position through the surface along the normal.
            // This is more robust than pushing it along the ray's direction.
            rp += -n * 1e-3;
            
            transfer *= (1. - fr);
        }

        rp += rd * d * .3;

        // Test for far plane escape
        if(distance(rp, ro) > 15.)
            break;
    }

    vec3 refc = vec3(0);

    float wsum = 0.;
    
    // Filtered environment map lookup
    for(int z = -2; z < 2; ++z)
        for(int y = -2; y < 2; ++y)
            for(int x = -2; x < 2; ++x)
            {
                float w = 1. - float(max(abs(x), max(abs(y), abs(z)))) / 3.;
                refc.rgb += textureLod(iChannel1, rd + vec3(x, y, z) * .1, 3.).rgb * w;
                wsum += w;
            }
    
    fragColor.rgb += refc * transfer / wsum;

    // Vignet
    fragColor.rgb *= 1. - (pow(abs(p.x)/2.2,4.) + pow(abs(p.y)/1.4,4.)) * .7;

    fragColor.a = 1.;

    return fragColor;
}

// Halton sequence (radical inverse)
float halton(const uint b, uint j)
{
   float h = 0.0, f = 1.0 / float(b), fct = f;

   while(j > 0U)
   {
      h += float(j % b) * fct;
      j /= b;
      fct *= f;
   }

   return h;
}

// Sample unit disc
vec2 disc(vec2 uv)
{
   float a = uv.x * pi * 2.;
   float r = sqrt(uv.y);
   return vec2(cos(a), sin(a)) * r;
}

// Sample cone PDF (for tent filtering)
vec2 cone(vec2 v)
{
	return disc(vec2(v.x, 1. - sqrt(1. - v.y)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0);

    vec4 oldColor = texelFetch(iChannel3, ivec2(fragCoord), 0);

    if(iMouse.z > .5)
        oldColor = vec4(0);

    vec2 uv = vec2(halton(2U, uint(oldColor.w) & 2047U), halton(3U, uint(oldColor.w) & 2047U));
    
    vec2 aaOffset = cone(uv) * 1.2;
        
	fragColor = oldColor + vec4(clamp(render(fragCoord + aaOffset).rgb, 0., 1.), 1.);
}

