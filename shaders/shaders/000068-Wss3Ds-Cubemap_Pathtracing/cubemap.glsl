// Cube A (cubemap) — Cubemap Pathtracing by fizzer
// https://www.shadertoy.com/view/Wss3Ds

// Light properties
vec3 lo = vec3(.7, .8, .1), ls = vec3(1, 0, 0) * .2, lt = vec3(0, 0, 1) * .2;
float lightRadiance = 18.0;

uvec2 rstate;

// Tiny Encryption Algorithm for random numbers: 
uvec2 encrypt(uvec2 v)
{
    uint k[4], sum = 0U, delta = 0x9e3779b9U;
    k[0] = 0xA341316CU;
    k[1] = 0xC8013EA4U;
    k[2] = 0xAD90777DU;
    k[3] = 0x7E95761EU;
    for(uint i = 0U; i < 4U; ++i)
    {
        sum += delta;
        v.x += ((v.y << 4) + k[0]) ^ (v.y + sum) ^ ((v.y >> 5) + k[1]);
        v.y += ((v.x << 4) + k[2]) ^ (v.x + sum) ^ ((v.x >> 5) + k[3]);
    }

    return v;
}

float rand()
{
    rstate = encrypt(rstate);
    return float(rstate.x & 0xfffffU) / float(1U << 20U);
}

// Sample the lightsources directly, including shadowing.
vec2 sampleLight(vec3 rp, vec3 n)
{
    vec2 energy = vec2(0);
    vec3 lightdir = normalize(normalize(vec3(.2, 4., 1.)) +
                              (vec3(rand(), rand(), rand()) * 2. - 1.) * .015);
    vec3 n2, uvw;
    float t = traceScene(rp, lightdir, n2, uvw).x;

    vec3 lrp = rp + lightdir * t;

    // Directional 'sky' lighting.
    if((lrp.y > .999 && abs(lrp.x- -.3) < .6 && abs(lrp.z - .1) < .8))
        energy += vec2(1.5, .8).yx * max(0., dot(n, lightdir)) * 2.;

    vec3 lo = vec3(.7, .8, .1), ls = vec3(1, 0, 0) * .2, lt = vec3(0, 0, 1) * .2;
    vec3 ln = normalize(cross(ls, lt));
    
    int light_sample_count = 2;
    
    // Parallelogram local lightsource.
    for(int j = 0; j < light_sample_count; ++j)
    {
        float lu = rand() * 2. - 1., lv = rand() * 2. - 1.;
        vec3 lp = lo + ls * lu + lt * lv, n2;
        float ld = dot(normalize(lp - rp), n), ld2 = dot(normalize(rp - lp), ln);
        if(ld > 0. && ld2 > 0. && traceSceneShadow(rp + n * 1e-4, lp - rp))
            energy += vec2(1.5, .5) *
            	(1. / dot(rp - lp, rp - lp) * ld * ld2) / float(light_sample_count);
    }

    return energy;
}

// Sample the illumunation at a given position, in a given direction.
vec2 sampleRay(vec3 ro, vec3 rd)
{
    vec2 energy = vec2(0);
    vec2 spectrum = vec2(1.);

    vec3 ln = normalize(cross(ls, lt));
    float lightArea = length(ls) * length(lt);

    for(int i = 0; i < 3; ++i)
    {
        vec3 n, p0, p1, uvw;
        vec2 res = traceScene(ro, rd, n, uvw);
        vec3 rp = ro + rd * res.x;
        
        if(res.x < 0. || res.x > 1e3)
            break;
        
        vec3 lrd = lambertNoTangent(n, vec2(rand(), rand()));
        
        if(res.y < .5)
        {
            // No intersection.
            break;
        }
        else if(res.y < 1.5)
        {
            // Diffuse box 1.
            if(rp.y > .999)
                spectrum *= .5;
            else
                spectrum *= mats;
            ro = rp + n * 1e-4;
            rd = lrd;
        }
        else if(res.y < 2.5)
        {
            // Diffuse box 2.
            spectrum *= mats.yx;
            ro = rp + n * 1e-4;
            rd = lrd;
        }
        else if(res.y < 3.5)
        {
            // Mirror box.
            spectrum *= .9;
            ro = rp + n * 1e-4;
            rd = reflect(rd, n);
        }
        
        
        if(res.y < 2.5)
        {
            // For diffuse materials, sample lights directly.
            energy += spectrum * sampleLight(rp, n) * lightRadiance * lightArea;
        }
        else
        {
            // Test for intersection with the parallelogram lightsource.
            float t = dot(lo - ro, ln) / dot(rd, ln);
            if(t > 0.)
            {
                vec3 rp = ro + rd * t;
                vec2 uv = vec2(dot(rp - lo, ls) / dot(ls, ls), dot(rp - lo, lt) / dot(lt, lt));
                if(abs(uv.x) < 1. && abs(uv.y) < 1.)
                {
                    energy += spectrum * lightRadiance;
                }
            }
        }
    }
    return energy;
}

vec2 sampleScene(vec3 p, vec3 n)
{
    vec2 energy = vec2(0);

    vec3 ln = normalize(cross(ls, lt));
    float lightArea = length(ls) * length(lt);
    int count = 1;
    for(int i = 0; i < count; ++i)
    {
        vec3 ro = p + n * 1e-4;
        vec3 rd = lambertNoTangent(n, vec2(rand(), rand()));

        energy += sampleRay(ro, rd);
        energy += sampleLight(ro, n) * lightRadiance * lightArea;
    }

    energy /= float(count);
    return energy;
}

void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    rstate = uvec2(fragCoord.xy) + uint(iFrame) / 6U * 4096U;

    // Project ray direction on to the unit cube.
    vec3 absRayDir = abs(rayDir);
    rayDir /= max(absRayDir.x, max(absRayDir.y, absRayDir.z));

    // Get the index of the current face being rendered.
    int faceIndex = 0;

    if(absRayDir.y > absRayDir.x && absRayDir.y > absRayDir.z)
    {
        faceIndex = 2;
    }
    else if(absRayDir.z > absRayDir.x && absRayDir.z > absRayDir.y)
    {
        faceIndex = 4;
    }

    if(rayDir[faceIndex / 2] > 0.)
        faceIndex |= 1;

    // Sample previous result.
    fragColor = textureLod(iChannel0, rayDir,0.);

    // Skip this face if it's not the one chosen for this frame.
    if(faceIndex != (iFrame % 6))
        return;

    // Render for only one of the boxes per frame, as an extra speedup.
    if((iFrame / 12 & 1) == 0)
    {
        vec3 p = vec3(-1), q = vec3(1);
        vec3 samplePoint = (p + q) / 2. + (q - p) * rayDir / 2.;
        vec3 sampleNormal = boxNormal(samplePoint, p, q);
        fragColor.rg += sampleScene(samplePoint, -sampleNormal);
    }
    else
    {
        vec3 p = vec3(-.5, -.9, -.5), q = vec3(.5, -.5, .5);
        vec3 samplePoint = (p + q) / 2. + (q - p) * rayDir / 2.;
        vec3 sampleNormal = boxNormal(samplePoint, p, q);
        fragColor.ba += sampleScene(samplePoint, sampleNormal);
    }

}