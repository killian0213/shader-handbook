// Image (image) — Cubemap Pathtracing by fizzer
// https://www.shadertoy.com/view/Wss3Ds

// This is an example of how the new cubemap feature of Shadertoy can be used to cache
// and accumulate non-view-dependent illumination.
//
// Surface textures for two cubes are both stored in one cubemap, by using a 2-channel
// colour system. So two colours can be stored in an RGBA pixel.
//
// Click and drag with the mouse to move the camera around.
//
// This cached-cube-illumation idea was partially inspired by the 4-kilobyte demo
// "Think Outside the Box" by slerpy: https://www.pouet.net/prod.php?which=79661

#define AA 3

// Sample the illumunation at a given position, in a given direction.
// This version of the function (compared to the one in Cube A) uses the cubemap
// for shading the diffuse boxes, and only traces mirror reflection rays.
vec2 sampleRay(vec3 ro, vec3 rd)
{
    vec2 energy = vec2(0);
    vec2 spectrum = vec2(1.);
    vec2 mats = vec2(.9, .5) * .99;
    vec3 lo = vec3(.7, .8, .1), ls = vec3(1, 0, 0) * .2, lt = vec3(0, 0, 1) * .2;
    vec3 ln = normalize(cross(ls, lt));
    float lightArea = length(ls) * length(lt);
    float lightRadiance = 50.0;

    for(int i = 0; i < 3; ++i)
    {
        vec3 n, p0, p1, uvw;
        vec2 res = traceScene(ro, rd, n, uvw);
        vec3 rp = ro + rd * res.x;
        if(res.x < 0. || res.x > 1e3)
            break;

        float t = dot(lo - ro, ln) / dot(rd, ln);
        if(t > 0. && t < res.x && dot(rd, ln) < 0.)
        {
            vec3 rp = ro + rd * t;
            vec2 uv = vec2(dot(rp - lo, ls) / dot(ls, ls), dot(rp - lo, lt) / dot(lt, lt));
            if(abs(uv.x) < 1. && abs(uv.y) < 1.)
            {
                energy += spectrum * lightRadiance;
            }
        }

        float fr = mix(0.001, 1.0, pow(1. - clamp(dot(-rd, n), 0., 1.), 3.));

        vec3 absuvw = abs(uvw);
        vec2 uv = absuvw.x > absuvw.y ? (absuvw.x > absuvw.z ? uvw.yz : uvw.xy) : (absuvw.y > absuvw.z ? uvw.xz : uvw.xy);

            if(res.y < .5)
            {
                // No intersection.
                break;
            }
        else if(res.y < 1.5)
        {
            // Diffuse box 1.
            if(rp.y > .99)
                spectrum *= .5;
            else
                spectrum *= mats;
            vec2 dc = texture(iChannel0,uvw).rg/float(iFrame)*12.;
            dc *= mix(.3, 1., textureLod(iChannel2, uv / 2., 1.).r);
            if(rp.y > .999 && abs(rp.x - -.3) < .6 && abs(rp.z - .1) < .8)
            {
                energy += spectrum * vec2(1.3, 1.).yx * mix(.7, 1., textureLod(iChannel1, rd, 2.).r);
                fr = 1.;
            }
            else
            {
                energy += spectrum * dc * (1. - fr);
            }
        }
        else if(res.y < 2.5)
        {
            // Diffuse box 2.
            spectrum *= mats.yx;
            vec2 dc = texture(iChannel0,uvw).ba / float(iFrame) * 12.;
            dc *= mix(.3, 1., textureLod(iChannel3, uv / 2., 1.).b);
            energy += spectrum * dc * (1. - fr);
        }
        else if(res.y < 3.5)
        {
            // Mirror box.
            fr = 1.;
        	fr *= mix(1., .25, pow(textureLod(iChannel2, rp.zx, 1.).r, 3.));
        }
        spectrum *= .9 * fr;
        ro = rp + n * 5e-3;
        rd = reflect(rd, n);
        
        if(max(spectrum.x, spectrum.y) < 1e-4)
            break;
    }
    return energy;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy * 2. - 1.;
    uv.x *= iResolution.x / iResolution.y;

    vec3 c = vec3(0);

    // Set up primary ray direction and differentials.
    vec3 ord = vec3(uv, -2.);
    vec3 rdx = dFdx(ord) / 1.;
    vec3 rdy = dFdy(ord) / 1.;

    // Camera positioning.
    float ax, ay;
    mat2 mx, my;

    ax = iMouse.z > 0. ? (iMouse.y / iResolution.y * 2. - 1.) * .7 : 0.;
    mx = mat2(cos(ax), sin(ax), -sin(ax), cos(ax));   

    ay = iMouse.z > 0. ? (iMouse.x / iResolution.x * 2. - 1.) * 1.5 : iTime / 4.;
    my = mat2(cos(ay), sin(ay), -sin(ay), cos(ay));   

    // AA loops.
    for(int iy = 0; iy < AA; ++iy)
        for(int ix = 0; ix < AA; ++ix)
        {
            vec3 ro = vec3(0, 0, 3.5);
            vec3 rd = ord + float(ix) / float(AA) * rdx + float(iy) / float(AA) * rdy;

            float a;
            mat2 m;

            ro.yz *= mx;
            rd.yz *= mx;

            ro.xz *= my;
            rd.xz *= my;

            vec3 n, uvw;
            vec2 res = traceScene(ro, rd, n, uvw);

            // Accumulate.
            if(res.y > .5)
            {
                vec2 energy = sampleRay(ro,rd);
                vec3 c2 = min(energy.x * vec3(.8, .6, .1) + energy.y * vec3(.1, .1, 1), 1.);
                c += c2;
            }
            else
            {
                c += vec3(.03);
            }
        }

    fragColor.rgb = c / float(AA * AA);

	// Gamma correction.
    fragColor.rgb = pow(fragColor.rgb, vec3(1. / 2.2));
}

