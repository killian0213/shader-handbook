// Buffer A (buffer) — Space Rainbow Road by rcargou
// https://www.shadertoy.com/view/csf3D4

float c1() {
    return (1. + clamp(-.2, .2, sin(iTime / 5.) ));
}

float c2() {
    return 0.;
    return .1*clamp(.0, 1., clamp(-.2, .2, sin(iTime / 3. + .7) ));
}

float hash31(vec3 p) {
   	float h = dot(p,vec3(127.1,311.7, 21.));	
    return fract(sin(h)*43758.5453123);
}

float hash21( vec2 p ) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
    
}
 
vec3 HUEtoRGB(in float hue)
{
    vec3 rgb = abs(hue * 6. - vec3(3, 2, 4)) * vec3(1, -1, -1) + vec3(-1, 2, 2);
    return clamp(rgb, 0., 1.);
}

float path(float t) {
    return 0.1;
}

float multiwave(float path) {
    path /= 3.;
    return 10.*(2. * sin(path / 20.) + 
            1./4. * sin(path / 4.) +
            1./4. * sin(path / 4.));
}
float dmultiwave(float path) {
    path /= 3.;
    return (2. * cos(path / 20.) + 
            1./4. * cos(path / 4.) +
            1./4. * cos(path / 4.));
}

float opS( in float d1, in float d2 )
{
    d1 *= -1.0;
    return (d1 > d2) ? d1 : d2;
}


vec3 archCOL(vec3 p ) {
    float rep = 52.;
    float size = 11.;
    float in_size = 7.8;
    float l = 25.5;
    p.y += multiwave(p.z);
    float id = floor(p.z / rep);
    p.z = mod(p.z, rep) - rep / 2.;
    p.z-=20.;
    float outer = length(p.xy) - size;
    float iner = length(p.xy) - size + .5;
    float d = opS(iner, outer);
    
    float dist = max(d, abs( p.z - l) );
    vec3 c =  HUEtoRGB(hash31(vec3(id)));
    c /= 4.;
    c+= .3;
    return c;
}
 
float mapStarField(vec3 p, out vec2 id) {

    float r = c1();
    vec3 rep = vec3(20.);
    float scale = 1.;
    p.yz = rotate2d(3.14 / -2.) * p.yz;
    float t = iTime * 150.;
    p /= scale;
    p.y += t;
    float d = p.z;
    vec3 pm = mod(p, rep) - rep / 2.;
    id.x = hash31(floor(p / rep));
 
    if (id.x * r < 1.1) {
        return rep.z / 2.;
    }
    pm.xz = rotate2d( 42.*iTime *id.x) * pm.xz;
    id.x = fract(id.x *112.131);
    id.y = 1.;
   // id.x = .2;
    return opExtrusion(pm  / 2., .05);
}

float mapArch(vec3 p) {
    float rep = 52.;
    float size = 11.;
    float in_size = 7.8;
    float l = -25.5;
    p.y += multiwave(p.z);
    p.z = mod(p.z, rep) - rep / 2.;
    p.z-=20.;
    float outer = length(p.xy) - size;
    float iner = length(p.xy) - size + .5;
    float d = opS(iner, outer);
    
    return max(d, abs( p.z - l) );
}

float mapFence(vec3 p) {
    float rep = 2.;
    float height = .4;// + (1.+ sin(p.z / 4.)) / 1.;
    float size = .1 ;
    
    p.y += multiwave(p.z);
    p.z = mod(p.z, rep) - rep / 2.;
    p.x = abs(p.x) - 8.;
    float dt = length(vec2(p.x, p.y -.76 - height + 4.0*size)) - size / 2.;
        
    vec3 pstar = vec3(p.z, p.y, p.x);
    float dstar = opExtrusion(pstar, .01);
    float df = abs(max(length( p.xz - size), -.1+abs(p.y +.8) - height));
    return min(dt, dstar);
    
}

float mapRoad(vec3 p, out vec2 id) {
 
    
    vec2 rep = vec2(1, 1.);
    
    vec2 mp = mod(p.xz, rep) - rep / 2.;
    
    float s = .35;
    id.x = fract( ((+ p.z/rep.y)*0.323 + (p.x / rep.x )) *.0379523 );
   
    id.y = hash21( floor(p.xz / rep.xy ) * 10. );
    if (id.y < 0.02)
     id.x = fract( (floor(+ p.z/rep.y) *0.323+ floor(p.x / rep.x )) *0.0379523 );
    float l = iTime* 2. * hash21( floor(p.xz / rep)  );
    
     p.y -= .3 + sin(l ) * .0;
     float h =  p.y + 2. + multiwave(p.z) + cos(sin(p.z *c2()*.02  + iTime * c2() * .5) + p.x / 3.);
   
    return max( max(max(mp.x -s , mp.y - s ) , abs(p.x) - 8. ), abs( h )  - .05);
}

vec2 map(vec3 p, out vec2 id) {
    vec2 id2;
    vec3 ps = p;
    p.x+=sin(p.z / 15.)*2. + cos(p.z / 20.) + sin(p.z / 200.) * 200.;
    vec2 res =  vec2(mapRoad(p, id), 1.);
    
    vec2 resFence = vec2(mapFence(p), 2. );
    if (resFence.x < res.x) {
        res = resFence;
    }
    vec2 resArch = vec2(mapArch(p), 3.);
    if (resArch.x < res.x) {
        res = resArch;
    }
    vec2 resStar = vec2(mapStarField(ps, id2), 4.);
    if (resStar.x < res.x) {
        res = resStar;
        id = id2;
    }
    return res;
}

vec2 castRay(vec3 ro, vec3 rd, out vec2 id) {
    vec2 res = vec2(1e10, 0.);
    vec3 pos = ro;

    const float NEAR = 0.;
    const float FAR = 220.;

    float t = NEAR;
    
    for (int i = 0; i < 300 && t < FAR; ++i) {
    
        pos = ro + rd * t;
        vec2 h = map(pos, id);
        if (abs(h.x) < 0.001 * t) {
            res = vec2(t, h.y);
            break ;
        }
        t += t < 10. ? h.x * .5: h.x;
    }
    
    return res;
}


vec3 normal (in vec3 p)
{
    vec2 e = vec2(.0001, .0);
    vec2 id;
    float d = map (p,id).x;
    vec3 n = vec3 (map (p + e.xyy,id).x - d,
                   map (p + e.yxy,id).x - d,
                   map (p + e.yyx,id).x - d);
    return normalize(n);
}

vec3 raymarch_arch(vec3 ro, vec3 rd) {
    float t = 0.;
    vec3 acc = vec3(0.);

    for (int i = 0; i < 40; ++i) {
        vec3 pos = ro + rd * t;
         float dLight = .03+21.5/(10.+ length(mod(pos.zzz, 52.) -20.))*0.5;
        acc += dLight * archCOL(pos) / 50.;
    }
    return vec3(acc);
}

float stars(vec2 uv) {

    float acc = 0.;
    float s = 0.1;
    float scale = 100.;
    for (float i = 0.; i < 3.; i = i + 1.) {
        for (float j = 0.; j < 3.; j = j + 1.) {
            vec2 off = vec2( (j - 2.) * s, (i - 2.) * s);  
            acc += ( smoothstep( .92, 1.0, pow( noise(vec3( uv.x * scale + off.x, uv.y * scale + off.y, 0.)),3. )));
        }
    }
    return acc / 20.;
}

vec3 render(vec3 ro, vec3 rd, vec2 uv) {

    vec2 id;
    vec2 res = castRay(ro, rd, id);
    vec3 pos = ro + rd * res.x;
    float mat = res.y;
    float depth = length(pos - ro);
    vec3 albedo = vec3(20.);
    vec3 nor = normal(pos);
    vec3 lightDir = normalize( vec3(-2., 1., -0.));
    float ndotl = max(.4, dot(nor, lightDir));
   // vec3 stars = vec3( smoothstep( .9, 1.0, pow( noise(vec3( uv.x * 100., rd.y * 100., 0.)),3. )));
        vec3 stars = vec3(stars(vec2(uv.x, rd.y)));
    float dLight = .03+21.5/(5.+ length(mod(pos.zzz, 52.) -20.))*0.5;
     vec3 dLightCol = archCOL(pos);
    if (mat == 0.) {
        return stars;
    }
    if (mat == 1. || mat == 4.) {
        albedo = 4.* HUEtoRGB(id.x);// * (texture(iChannel1, pos.xz * 11.).x * 3. + .1);
        if (id.y < 0.02)
        albedo *= 32.;
        if (mat == 4.)
        albedo *= 12.;
     }
    if (mat == 2.) {
        albedo = vec3(0.5, 0.5, 0.2) * 20.;
    }
    float f = 1. / (1. +pow(depth * .0015 , 2.));

    vec3 r = raymarch_arch(ro, rd);
    float m = clamp(0., 1., 1.7 - f);
    return vec3(mix(dLightCol*dLight*albedo *ndotl + albedo / 30., stars  * 4., .8));
}

void camera(out vec3 ro, out vec3 rd, vec2 uv) {
    vec2 mouse = (-iResolution.xy + 2.0*iMouse.xy)/iResolution.y;
    float speed = iTime * 15.;
    ro = vec3( + sin(speed / 200.) * 200., 3.0 + multiwave(speed), -speed);
    mouse = vec2(0.);
    mouse.y += 3.;
    vec3 lookAt = vec3(sin(speed / 200. - 0.5 / 200.) * 200. + mouse.x + uv.x, mouse.y + -uv.y + multiwave(speed)- dmultiwave(speed)*.2, 1.-speed - c1() * 0.);
    
    rd = normalize(ro - lookAt);
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
    vec3 ro, rd;
    camera(ro, rd, uv);
    vec3 col = pow( render(ro, rd, uv)*1.6, vec3(1.0));
    fragColor = vec4(col * 1.,1.0);
}