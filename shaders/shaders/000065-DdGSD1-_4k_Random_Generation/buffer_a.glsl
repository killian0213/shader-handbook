// Buffer A (buffer) — [4k] Random Generation by Kali
// https://www.shadertoy.com/view/DdGSD1

#define iD iMouse.x
#define rot(a) mat2(cos(a+vec4(0,11,33,0)))   

float curhash, nexthash, h1, h2, tt = 0., id, it, cab = 100., sph = 100., pis, time;
vec3 pos, pobj;

float hash(float p) {
    p = p * 1230.123 + iD;
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(2. * p * p);
}

vec2 rand2(vec2 co) {
    return
        vec2(fract(sin(dot(co.xy, vec2(12.98, 78.23))) * 43758.54),
            fract(cos(dot(co.xy, vec2(4.89, 7.23))) * 23421.63));
}

float rnd()
{
    h1++;
    h2++;
    return mix(hash(h1), hash(h2), fract(tt));
}

float cables(vec3 p) {
    it = 0.;
    p.xz *= rot(iTime);
    float area = length(p), sc = 1., m = 1000.;
    p *= .15;
    for (float i = 0.; i < 8.; i++) {
        p.xy = sin(p.xy);
        p.xy *= rot(1.);
        p.xz *= rot(1.5);
        p = p * 2.;
        float l2 = length(p) * .5 - .2;
        float l = length(p.xy);
        l = mix(l, l2, smoothstep(113., 120., iTime));
        m = min(m, l);
        if (m == l) it = i;

    }
    float d = m;
    area += it * 2.;
    d = max(d, area - smoothstep(100., 110., iTime) * 20.);
    d = min(d, m + smoothstep(1., 20., area) * 2. + smoothstep(6.5, 5., iTime) * 30.);
    return d;
}



float obj(vec3 p)
{
    float bo=length(p) - 15.;
    if (bo > 0.) return bo + 1.;
    vec3 p2 = p;
    float s = sin(time * 3.);
    p.xy *= rot((rnd() - .5) * 1.);
    p.xz *= rot(time - p.y * (.12 + rnd() * .5));
    p.xy *= rot(time - p.z * (.12 + rnd() * .6));
    sph = length(p) - 2.3 - length(sin(p * 7.)) * .5 - rnd();
    sph = min(sph, length(p.xy + 5.) + .1 + smoothstep(53., 51., iTime));
    sph = min(sph, abs(p.x + 10.) + .1 + smoothstep(69., 67., iTime));
    sph = max(sph, length(p) - 13.);
    pos = p;
    float d;
    d = length(p) - 1. - rnd() * 2.;
    d = max(d, -length(p.xy) + 2.5 + rnd());
    d = max(d, -length(p.xz) + 2.5 + rnd());
    d = max(d, -length(p.yz) + 2.5 + rnd());
    float desp = (rnd() - .5) * 10.;
    float rem = length(p.yz + vec2(desp, 0.)) * (.5 + rnd() * .5) + rnd() * .9;
    rem = length(p.xz + vec2(desp, 0.)) * (.5 + rnd() * .5) + rnd() * .9;
    d = min(d, rem);
    d -= length(sin(p * (rnd() * 2. + 2.))) * (.8 + rnd() * .5);
    d = max(d, length(p2) - 15.);
    d = min(d + 2. * (smoothstep(15., 12., iTime) + smoothstep(93., 105., iTime)), sph);
    pobj = p;
    return d * .2;
}

float de(vec3 p) {
    p.yz*=rot(smoothstep(80.,100.,iTime)*6.3);
    vec3 p2 = p;
    p2.y += 10. - smoothstep(0., 2., time) * 10.;
    if (length(p) < 30.) cab = cables(p2);
    p.xz *= rot(rnd() * 3.);
    id = 0.;
    h1 = curhash;
    h2 = nexthash;
    float d1 = obj(p2);
    float d1b = length(p2) - 2.7;
    float l = smoothstep(min(30., time * 10.), 0., length(p.xz));
    float d2 = p.y + 4.5 + sin(length(p) * 5. - time * 20.) * .02 * l + smoothstep(50., 55., iTime) * 20.;
    float d3 = max(abs(p.y + 2.), abs(length(p.xz) - 8.));
    pis = d2;
    d2 = min(d1b, d2);
    return min(sph,min(cab, min(d1, d2)));
}

// normal hack to reduce webgl compilation time, not in the original version
vec3 normal(vec3 pos) {
    vec2 e=vec2(0.,.01);
    vec3[4] ev = vec3[4](e.yxx, e.xyx, e.xxy, e.xxx-.000001);
    vec3 nn = vec3(0);
    for(int i = 0; i<4; i++){
        nn += sign(ev[i])*de(pos + ev[i]);
        if(nn.x<-1e8) break; // Fake break.
    } 
    return normalize(nn);
}

vec3 march(vec3 from, vec3 dir)
{
    vec3 gcol = normalize(.3 + vec3(rnd(), rnd() * .5, rnd()));
    gcol.rb *= rot(dir.y * 1.5);
    gcol = abs(gcol);
    float td = 0., d, maxdist = 70., g = 0., ref = 0.;
    vec3 p = from + dir, col = vec3(.0);
    float h = rand2(dir.xy + mod(time, 10.)).x - .5;
    float savepis = 0.;
    float glow = smoothstep(13., 14., iTime) - smoothstep(94., 96., iTime) + smoothstep(103., 103.5, iTime);
    for (int i = 0; i < 200; i++)
    {
        p += dir * d * (1. - h * .2);
        d = de(p);
        if (td > maxdist) break;
        if (d < .01 && ref < 1.)
        {
            savepis = pis;
            ref++;
            vec3 n = normal(p);
            dir = reflect(dir, n);
            p += .01 * dir;
            continue;
        }
        if (d < .01) break;
        td += d;
        g = max(g, (.3 + glow * .35) / (.1 + sph * 3.)) * step(fract(iTime * 2.5), .4 + step(iTime, 40.) + step(66., iTime) + length(p) * .1);
        float fl = .1 / (.1 + pis * .5) * .015;
        fl *= 1. + step(fract(iTime * 2.5), .4) * step(40., iTime);
        g += fl;
        g += .1 / (.1 + cab * 2.) * step(.7, fract(length(p) * .2 - iTime * 1.25 + it * .2));
    }
    if (d < .01)
    {
        vec3 n = normal(p);
        vec3 refr = reflect(dir, n);
        col = normalize((fract(.5 * pobj * rnd()))) * 5. * pow(max(0., dot(normalize(-p), n)), 3.) * 1.
            + pow(max(0., dot(normalize(-p), refr)), 5.) * 1.5 * gcol
            + smoothstep(.5, 0., abs(length(pobj.xy) - 7.)) * 5.;
        col *= gcol;;
        if (savepis < 0.1) col *= .5;
    } else {
        col = gcol * gl_FragCoord.x/iResolution.x * (.5+step(.5,fract(iTime*2.5))*.5) * step(40.,iTime) * step(iTime,123.5);
    }
    col = clamp(col, vec3(0.), vec3(1.));
    col += g * gcol * (.7 + step(.5, savepis) * .3);
    return col;
}

vec2 uniformDisc(vec2 co) {
    vec2 r = rand2(co);
    return sqrt(r.y) * vec2(cos(r.x * 6.28), sin(r.x * 6.28));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    time = (iTime * (.25 + step(26.5, iTime) * .2 + step(40., iTime) * .2 + step(66.5, iTime) * .1) + 0.);
    vec2 uv = fragCoord.xy / iResolution.xy - .5;
    tt = smoothstep(0., 1., fract(iTime * .15625));
    float n = floor(iTime * .15625) + step(26.5, iTime) + step(40., iTime) + step(80., iTime),
        split = sign(uv.x + smoothstep(67.5, 66.5, iTime) * .5 * -sign(uv.x) - .15 * smoothstep(66.5, 80., iTime));
    if (iTime > 66.5 && iTime < 80.) {
        uv.x -= split * .25 + smoothstep(66.5, 80., iTime) * .07;
        uv *= 1.4 * -split - (iTime - 66.5) * .06;
        n += split * 10.;
        split = 10.;
    }
    curhash = n;
    nexthash = n + 1.;
    h1 = curhash;
    h2 = nexthash;
    uv.x += (rnd() - .5) * .4 * smoothstep(115., 110., iTime) * step(split, 9.);
    uv.x *= iResolution.x / iResolution.y;
    uv += uniformDisc(uv + iTime) * .05
        * (smoothstep(2., 0., min(abs(iTime - 39.5), abs(iTime - 66.))) + 2. * smoothstep(122.5, 130., iTime));
    vec3 dir = normalize(vec3(uv, .6 + rnd()*.9)),
        from = vec3(0., -4. + 15. * rnd(), -20);
    from.y -= step(40., iTime) * 5.;
    from.y += step(66.5, iTime) * 15.;
    from.y = max(-4., from.y);
    from.y -= step(53.3, iTime) * 15.;
    if (iTime < 26.5) from.y *= .5;
    from.xz *= rot(-time + smoothstep(120.5, 124., iTime) * 5.);
    if (iTime > 53.3 && iTime < 66.5) dir = normalize(vec3(uv, 1.7));
    dir.xy *= 1. + smoothstep(118., 120., iTime) * .6;
    vec3 fr = normalize(-from);
    vec3 rt = normalize(cross(fr, vec3(0., 1., 0.)));
    dir = mat3(rt, cross(rt, fr), fr) * dir;
    vec3 col = march(from, dir);
    vec3 fb = texture(iChannel0, vec2(fragCoord.xy / iResolution.xy)).rgb;
    if (time > .01) {
        col = mix(col, fb, .93);
    }
    col += step(abs(iTime - 26.5), .02) * .3;
    col += step(abs(iTime - 53.3), .02) * .3;
    col += step(abs(iTime - 80.), .02) * .3;
    col.rgb = mix(length(col.rgb) * vec3(.5, .4, .3), col.rgb, .8);
    col *= smoothstep(130., 127., iTime) * smoothstep(0., .5, iTime);
    if (split > 9.) col *= exp(-.2 * abs(uv.x));
    fragColor = vec4(col, 1.);
}
