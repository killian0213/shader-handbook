// Image (image) — MotionCube by Jaenam
// https://www.shadertoy.com/view/WcGfzm

/*================================
=          MotionCube™           =
=         Author: Jaenam         =
================================*/
// Date:    2026-05-12
// License: Creative Commons (CC BY-NC-SA 4.0)

#define R(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define BOX(p,b) length(max(abs(p)-b,0.))
#define PI 3.14159

uvec3 hash3u(uvec3 s) {
    s = s * 1145141919u + 1919810u;
    s.x += s.y * s.z;
    s.y += s.z * s.x;
    s.z += s.x * s.y;
    s ^= s >> 16;
    s.x += s.y * s.z;
    s.y += s.z * s.x;
    s.z += s.x * s.y;
    return s;
}

vec3 hash3f(vec3 f) {
    return vec3(hash3u(floatBitsToUint(f))) / float(-1u);
}

vec3 texPos;

float cubeUnfold(vec3 p, float a) {
    // Isometric view rotation
    p.yz *= R(.2 * PI);
    p.xz *= R(-.25 * PI);
    
    float d = 1e9, sz = 4., th = .2;
    float sx = sign(p.x);  
    vec3 q;
    float fd;
    
    // Bottom face
    fd = BOX(p - vec3(0,-sz,0), vec3(sz,th,sz));
    if(fd < d) { d = fd; texPos = p; }
    
    // Top face
    q = p;
    q.y += sz; q.z += sz;
    q.yz *= R(-a);
    q.y -= sz; q.z -= sz;
    q.y -= sz; q.z += sz;
    q.yz *= R(-a);
    q.y += sz; q.z -= sz;
    fd = BOX(q - vec3(0,sz,0), vec3(sz,th,sz));
    if(fd < d) { d = fd; texPos = q; }
    
    // Front face
    q = p; 
    q.y += sz; q.z += sz;
    q.yz *= R(-a);
    q.y -= sz; q.z -= sz;
    fd = BOX(q - vec3(0,0,-sz), vec3(sz,sz,th));
    if(fd < d) { d = fd; texPos = q; }
    
    // Back face 
    q = p; 
    q.y += sz; q.z -= sz;
    q.yz *= R(a);
    q.y -= sz; q.z += sz;
    fd = BOX(q - vec3(0,0,sz), vec3(sz,sz,th));
    if(fd < d) { d = fd; texPos = q; }
    
    // Left & Right faces
    q = vec3(abs(p.x), p.yz);  // Mirror X
    q.y += sz; q.x -= sz;
    q.xy *= R(-a);             
    q.y -= sz; q.x += sz;
    fd = BOX(q - vec3(sz,0,0), vec3(th,sz,sz));
    if(fd < d) { d = fd; texPos = vec3(sx * q.x, q.yz); }  // Restore X sign
    
    return d;
}

void mainImage(out vec4 O, vec2 I) {   

    vec3 r = iResolution;
    float t = iTime;
    
    float e = sin(t) * .5;
    float a = clamp(e, 0., 1.) * 1.57;
    
    mat2 Rx = R(sin(t - PI/2.));
    mat2 Ry = R(sin(t + PI/2.));
    
    O *= 0.;
    
    for (float i, d, s, n; i++ < 1e2;) {
        
        vec2 uv = (I + I - r.xy) / r.y;
        float ji = i;
        float fl = 20.;
        
        vec3 ro = vec3(0, 0, 9.5 * fl);
        vec3 rd = normalize(vec3(uv * 1.2, -fl));
        vec3 p = ro + rd * d;
        
        //Rotations
        p.xy *= Rx;
        p.yz *= Ry;
        
        // Zoom 
        float z = -tanh(e * 8. - i * .005);
        float zoom = .9 + .3 * z;
        p *= zoom;
        
        // Map cube
        float cube = cubeUnfold(p, a);
        vec3 tex = texPos * .8;
        
        // Holographic Texturing
        vec3 g = floor(tex * 2.); 
        vec3 f = fract(tex * 2.) - .5; 
        vec3 rnd = hash3f(g); 
        float ang = rnd.y * 6.28; 
        float shine = dot(rd.xy, normalize(tex.xy + .001)) * 4.;
        float h = smoothstep(.08, .0, abs(length(f) - (rnd.x * .3 + .1)));
        
        // Tribulence Texturing
        for (n = .0; n++ < 3.;)
            tex += (abs(mod(tex.zyx * n / 6.28 + .75, 1.) - .5) * 4. - 1.) * 1.57 / n;
            
        // Step
        d += s = (.005 + .1 * abs(dot(abs(fract(tex)-.5), vec3(.6)) - cube*2. - i /3e2)) / zoom;
        
        // Early Exit
        if (d > 3e2 || s < .0001) break;
        
        // Holographic Texture Mask
        float sf = smoothstep(.02, .01, s);
        
        // Accumulate Base Color + Texture
        O.rgb += ((.5 + .5 * sin(i*.3 + vec3(-1., 0., 1.) * 5.)) / s 
                    + sf * 4. * h * (.5 + .5 * sin(ang + i*.1 + vec3(1,2,3))) / s) / zoom;
    }
    
    O = tanh(O * O / 1e7);
}