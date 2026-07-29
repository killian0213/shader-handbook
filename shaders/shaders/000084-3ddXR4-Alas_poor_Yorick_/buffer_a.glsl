// Buffer A (buffer) — Alas, poor Yorick! by shau
// https://www.shadertoy.com/view/3ddXR4

// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

float saturate(float x) {return clamp(x, 0.0, 1.0);}
vec3 saturate(vec3 x) {return clamp(x, vec3(0.0), vec3(1.0));}

//Shane IQ
float n3D(vec3 p) {    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); 
    p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p * p * (3. - 2. * p);
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

//Distance functions - IQ
//https://iquilezles.org/articles/distfunctions
float sdSphere(vec3 p, float r) {
    return length(p) -  r;    
}

float sdEllipsoid(vec3 p, vec3 r) {
    return (length(p / r) - 1.) * min(min(r.x, r.y), r.z);
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdCappedCylinder(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdRoundBox(vec3 p, vec3 b, float r) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdTriPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.y-h.y,max(q.x*0.866025+p.z*0.5,-p.z)-h.x*0.5);
}

float sdLink(in vec3 p, in float le, in float r1, in float r2) {
    vec3 q = vec3( p.y, max(abs(p.x)-le,0.0), p.z );
    return length(vec2(length(q.yx)-r1,q.z)) - r2;
}

float sdEqTriangle(vec2 p) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0 / k;
    if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, - k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0, 0.0);
    return -length(p) * sign(p.y);
}

//mercury
float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.0 * PI / repetitions,
          a = atan(p.y, p.x) + angle / 2.0,
          r = length(p),
          c = floor(a / angle);
    a = mod(a, angle) - angle / 2.0;
    p = vec2(cos(a), sin(a)) * r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions / 2.0)) c = abs(c);
    return c;
}

float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
	return mix(b, a, h) - k * h * (1. - h);
}

float smax(float a, float b, float k) {
	float h = clamp( 0.5 + 0.5 * (b - a) / k, 0.0, 1.0 );
	return mix(a, b, h) + k * h * (1.0 - h);
}

float pattern(vec2 uv, float size) {
    
    for(int i=0; i<5; ++i) {
		uv *= rot(float(i)+1.7);
        uv = abs(fract(uv/30. + .5) - .5)*30.; //NuSan
		uv -= size;
		size *= 0.5;
	}
    
    float t = length(uv+vec2(0.0, -1.5)) - 0.4;
    t = max(t, -(length(uv+vec2(0.0, -1.5)) - 0.3));
    t = min(t, length(uv+vec2(0.0, -1.5)) - 0.2);
    t = min(t, sign(sdEqTriangle((uv+vec2(0.0,-0.5)) * 1.0)) * sign(sdEqTriangle((uv+vec2(0.0,-0.5)) * 1.3)));
    return step(0.0, t);
}

vec2 nearest(vec2 a, vec2 b) {
    float s = step(a.x, b.x);
    return s*a + (1.0-s)*b;
}

vec2 dfSkull(vec3 p) {
    
    p.yz *= rot(0.2);
    vec3 q = p;
  
    float nz = (n3D(p*2.0) - 0.5) * 0.06;
    //teeth
    q.xz *= rot(0.0981);
    pModPolar(q.xz, 32.0);
    float teeth = sdEllipsoid(q - vec3(0.7, 0.0, 0.0), vec3(0.04, 0.18, 0.06));
    teeth = min(smax(teeth, -sdBox(q - vec3(0.0, -1.0, 0.0), vec3(2.0, 1.0, 2.0)), 0.04), 
                smax(teeth, -sdBox(q - vec3(0.0, 1.0, 0.0), vec3(2.0, 1.0, 2.0)), 0.04));
    teeth = max(teeth, p.z);    

    //symetry
    p.x = abs(p.x);
    
    //skull
    q = p;
    float skull = sdCapsule(p, vec3(0.0, 1.5, 0.6), vec3(0.0, 1.5, 1.0), 1.36+nz);
    skull = smin(skull, sdSphere(p - vec3(0.0, 1.5, 1.0), 1.46), 0.2+nz);
    //roof of mouth
    skull = smin(skull, sdEllipsoid(q - vec3(0.0, 0.2, 0.0), vec3(0.72, 0.8, 0.72)), 0.3);
    skull = max(skull, -sdEllipsoid(q - vec3(0.0, 0.2, 0.0), vec3(0.52, 0.6, 0.52)));
    skull = smax(skull, -sdBox(q - vec3(0.0, -0.9, 0.0), vec3(2.0, 1.0, 2.0)), 0.02);
    
    //jaw socket
    skull = smax(skull, -sdCappedCylinder(p.yxz - vec3(0.0, 0.0, 0.7), 0.5, 2.0), 0.2);
    
    //jaw
    float jaw = sdEllipsoid(q - vec3(0.0, -0.2, 0.0), vec3(0.72, 0.5, 0.7)+nz);
    jaw = max(jaw, -sdEllipsoid(q - vec3(0.0, -0.2, 0.0), vec3(0.65, 0.52, 0.65)));
    jaw = smax(jaw, -sdBox(q - vec3(0.0, 0.9, 0.0), vec3(2.0, 1.0, 2.0)), 0.02);
    q.yz *= rot(-0.2);
    jaw = smin(jaw, sdTorus(q - vec3(0.0, -0.38, -0.2), vec2(0.5, 0.08+nz)), 0.14);
	q.x = abs(q.x);
    jaw = smin(jaw, sdEllipsoid(q - vec3(0.58, -0.36, 0.3), vec3(0.3, 0.14, 0.6)+nz), 0.1);
    jaw = smax(jaw, -sdBox(q - vec3(0.0, 0.0, 1.7), vec3(0.5, 2.0, 2.0)), 0.02);
    jaw = smax(jaw, -sdBox(q - vec3(0.0, 0.0, 2.5), vec3(2.0, 1.0, 2.0)), 0.08);
    q = p;
    q.yz *= rot(-0.2);
    q.xy *= rot(-0.2);
    jaw = smin(jaw, sdEllipsoid(q - vec3(0.8, 0.3, 0.36), vec3(0.1, 0.40, 0.14)+nz), 0.2);
    jaw = smin(jaw, sdCapsule(p, vec3(0.9,0.2,0.3), vec3(1.1,0.5,0.6), 0.08+nz), 0.08);
    skull = min(skull, jaw);
    
    //eyebrow
    skull = smax(skull, -sdCapsule(p, vec3(0.8,0.8,-0.9), vec3(-0.8,0.8,-0.9), 0.3), 0.16);
    //eye socket
    skull = smax(skull, -sdEllipsoid(vec3(abs(p.x),p.y,p.z) - vec3(0.4,0.8,-0.26), vec3(0.4,0.3,0.3)), 0.1);

    //temple
    q = p;
    q.xz *= rot(-0.4);
    q.xy *= rot(-0.3);
    skull = smax(skull, -sdEllipsoid(q - vec3(0.64,1.2,0.8), vec3(0.1+nz,0.6,0.7)), 0.1);
    
    //eye socket
    nz = n3D(p*5.0) * 0.03;
    
    q = p;
    q += vec3(-0.4, -0.8, 0.50);
    q.y *= 1.0 - abs(p.x)*0.3;
    q.z -= abs(q.x*q.x*0.8);
    q.z += q.y*0.2;
    float brow = sdLink(q, 0.34, 0.24+nz, 0.08+nz);
    skull = smin(skull, brow, 0.1);
    q = p;
    q += vec3(-1.14, -0.9, -0.44);
    q.y += q.z*q.z*0.4;
    q.x += q.z*q.z*0.6;
    q.yz *= rot(-0.2);
    skull = smin(skull, sdCapsule(q, vec3(0.0,0.0,-0.66),  vec3(0.0,0.0,0.66), 0.1+nz), 0.1); 
    
    //nose
    skull = smin(skull, sdEllipsoid(p - vec3(0.0, 0.5, -0.3), vec3(0.4,0.3,0.44)), 0.1);    
    float nose = sdCapsule(p, vec3(0.0,0.62,-0.78), vec3(0.0,1.2,-0.5), 0.18 - p.y*0.08 + nz);
    skull = smin(skull, nose, 0.14);
    nz = n3D(p*19.0)*0.05;
    skull = smax(skull, -sdEllipsoid(p - vec3(0.0,0.56,-0.98), vec3(0.34,0.2,0.34)+nz), 0.02);
    
    //nostril
    q = p;
    q += vec3(-0.08, -0.55, 0.7);
    q.yz *= rot(1.4);
    q.xz *= rot(0.523);
    skull = smax(skull, -sdTriPrism(q, vec2(0.14, 0.3)), 0.03);
    
    //cutout teeth
    skull = smax(skull, -teeth, 0.02);
    
    return nearest(vec2(skull, SKULL), vec2(teeth, TEETH));       
}

vec3 dfHalo(vec3 p) {
    
    vec3 q = p.xzy;
    float stoneO = sdCappedCylinder(q, 50.0, 0.2);
    stoneO = max(stoneO, -sdCappedCylinder(q, 3.5, 1.0));
    float stoneI = sdCappedCylinder(q, 3.0, 0.2);
    stoneI = max(stoneI, -sdCappedCylinder(q, 2.0, 1.0));
    
    float glow = sdTorus(p.xzy, vec2(1.9, 0.01));
    glow = min(glow, sdTorus(p.xzy, vec2(3.3, 0.01)));
    
    //ughhh!!!
    /*
    q = p;
    float black = sdCapsule(q, vec3(-3.0,-1.0,-0.5), vec3(3.0,-1.0,-0.5), 0.08);
    q.xy *= rot(PI*2.0/5.0);
    black = min(black, sdCapsule(q, vec3(-3.0,-1.0,-0.5), vec3(3.0,-1.0,-0.5), 0.08));
    q.xy *= rot(PI*2.0/5.0);
    black = min(black, sdCapsule(q, vec3(-3.0,-1.0,-0.5), vec3(3.0,-1.0,-0.5), 0.08));
    q.xy *= rot(PI*2.0/5.0);
    black = min(black, sdCapsule(q, vec3(-3.0,-1.0,-0.5), vec3(3.0,-1.0,-0.5), 0.08));
    q.xy *= rot(PI*2.0/5.0);
    black = min(black, sdCapsule(q, vec3(-3.0,-1.0,-0.5), vec3(3.0,-1.0,-0.5), 0.08));
    //*/
    
    vec2 near = nearest(vec2(stoneI, STONE_I), vec2(stoneO, STONE_O));
    near = nearest(near, vec2(glow, GLOW));
    //near = nearest(near, vec2(black, BLACK));
    
    return vec3(near, glow);
}

vec3 map(vec3 p) {

    vec2 skull = dfSkull(p);
    vec3 halo = dfHalo(p + vec3(0.0,-0.9,-0.4));
    
    return vec3(nearest(skull, halo.xy), halo.z);
}

vec3 normal(vec3 p) {
    vec2 e = vec2(EPS, 0);
    float d1 = map(p + e.xyy).x, d2 = map(p - e.xyy).x;
    float d3 = map(p + e.yxy).x, d4 = map(p - e.yxy).x;
    float d5 = map(p + e.yyx).x, d6 = map(p - e.yyx).x;
    float d = map(p).x * 2.0;
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

//IQ - https://iquilezles.org/articles/raymarchingdf
float AO(vec3 p, vec3 n) {
    float ra = 0., w = 1., d = 0.;
    for (float i = 1.; i < 12.; i += 1.){
        d = i / 5.;
        ra += w * (d - map(p + n * d).x);
        w *= .5;
    }
    return 1. - clamp(ra, 0., 1.);
}

//IQ - https://www.shadertoy.com/view/lsKcDD
float shadow(vec3 ro, vec3 rd, float mint, float tmax) {
	float res = 1.0;
    float t = mint;
    float ph = 1e10;
    
    for (int i = ZERO; i < 32; i++) {
		float h = map(ro + rd * t).x;
        float y = h * h / (2.0 * ph);
        float d = sqrt(h * h - y * y);
        res = min(res, 10.0 * d / max(0.0, t-y));
        ph = h;        
        t += h;
        if (res < 0.0001 || t > tmax) break;
    }
    
    return clamp(res, 0.0, 1.0);
}

vec3 bump(vec3 p, vec3 n, float ba) {
    vec2 e = vec2(EPS, 0.0);
    float nz = n3D(p);
    vec3 d = vec3(n3D(p + e.xyy) - nz, n3D(p + e.yxy) - nz, n3D(p + e.yyx) - nz) / e.x;
    n = normalize(n - d * ba / sqrt(0.1));
    return n;
}
   
//Knarkowicz
//https://www.shadertoy.com/view/4sSfzK
vec3 fresnelSchlick(float vdoth, vec3 specularColour) {
    return specularColour + (1.0 - specularColour) * pow(1.0 - vdoth, 5.0);
} 

float distributionTerm(float roughness, float ndoth) {
	float r2 = roughness * roughness;
	float d	 = (ndoth * r2 - ndoth) * ndoth + 1.0;
	return r2 / (d * d * PI);
}

float geometrySchlickGGX(float ndot, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    float nom = ndot;
    float denom = ndot * (1.0 - k) + k;
    return nom / denom;
}

float geometrySmith(float roughness, float ndotv, float ndotl) {
    float ggx2  = geometrySchlickGGX(ndotv, roughness);
    float ggx1  = geometrySchlickGGX(ndotl, roughness);
    return ggx1 * ggx2;
}

vec3 envBRDFApprox(vec3 specularColor, float roughness, float ndotv) {
    const vec4 c0 = vec4(-1, -0.0275, -0.572, 0.022);
    const vec4 c1 = vec4(1, 0.0425, 1.04, -0.04);
    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * ndotv)) * r.x + r.y;
    vec2 AB = vec2(-1.04, 1.04) * a004 + r.zw;
    return specularColor * AB.x + AB.y;  
}

// St. Peter's Basilica SH
// https://www.shadertoy.com/view/lt2GRD
struct SHCoefficients {
    vec3 l00, l1m1, l10, l11, l2m2, l2m1, l20, l21, l22;
};

const SHCoefficients SH_STPETER = SHCoefficients(
    vec3( 0.3623915,  0.2624130,  0.2326261 ),
    vec3( 0.1759131,  0.1436266,  0.1260569 ),
    vec3(-0.0247311, -0.0101254, -0.0010745 ),
    vec3( 0.0346500,  0.0223184,  0.0101350 ),
    vec3( 0.0198140,  0.0144073,  0.0043987 ),
    vec3(-0.0469596, -0.0254485, -0.0117786 ),
    vec3(-0.0898667, -0.0760911, -0.0740964 ),
    vec3( 0.0050194,  0.0038841,  0.0001374 ),
    vec3(-0.0818750, -0.0321501,  0.0033399 )
);

vec3 SHIrradiance(vec3 nrm) {
    const SHCoefficients c = SH_STPETER;
    const float c1 = 0.429043;
    const float c2 = 0.511664;
    const float c3 = 0.743125;
    const float c4 = 0.886227;
    const float c5 = 0.247708;
    return (
        c1 * c.l22 * ( nrm.x * nrm.x - nrm.y * nrm.y ) +
        c3 * c.l20 * nrm.z * nrm.z +
        c4 * c.l00 -
        c5 * c.l20 +
        2.0 * c1 * c.l2m2 * nrm.x * nrm.y +
        2.0 * c1 * c.l21  * nrm.x * nrm.z +
        2.0 * c1 * c.l2m1 * nrm.y * nrm.z +
        2.0 * c2 * c.l11  * nrm.x +
        2.0 * c2 * c.l1m1 * nrm.y +
        2.0 * c2 * c.l10  * nrm.z
    );
}

vec3 envRemap(vec3 c) {
    return pow(2.0 * c, vec3(2.2));
}

vec2 march(vec3 ro, vec3 rd, inout vec3 gc) {
    float t = 0.0, id = 0.0;
    for (int i=ZERO; i<200; i++) {
    	vec3 ns = map(ro + rd*t);
        if (abs(ns.x)<EPS || t>FAR) {
            id = ns.y;
            break;
        }
        
        gc += vec3(0.1,0.0,0.0) / (1.0 + ns.z*ns.z*60.);
        t += ns.x*0.7;
    }
    return vec2(t, id);
}

vec3 camera(vec2 U, vec3 ro, vec3 la, float fl) {
    vec2 uv = (U - R*.5) / R.y;
    vec3 fwd = normalize(la-ro),
         rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    return normalize(fwd + fl*uv.x*rgt + fl*uv.y*cross(fwd, rgt));
}

void mainImage(out vec4 C, in vec2 U) {
    
    vec3 pc = vec3(0),
         gc = vec3(0),
         ro = vec3(0.0, 1.0 + sin(T*0.04)*0.6, -3.0),
         la = vec3(0.0, 1.0, 0.0),
         lp = vec3(3.0, 8.0, -4.0),
         lc = vec3(0.6, 0.4, 0.1);
         
    ro.xz *= rot(sin(T*-0.1)*0.6);
    /*
    ro.xz *= rot((iMouse.x/R.x-0.5)*2.0);
    ro.yz *= rot((iMouse.y/R.y-0.5)*2.0);
    //*/
    
    vec3 rd = camera(U, ro, la, 1.4);
    
    float dof = 0.0, mint = FAR;
    vec2 si = march(ro, rd, gc);
    if (si.x>0.0 && si.x<mint) {
        
        vec3 p = ro +rd*si.x,
             n = normal(p),
             sc = vec3(0.0);
        
        dof = length(la - p);
        mint = si.x;
        
        float rG = 0.0, //roughness
              metallic = 0.0; 
        
        vec3 q = p - vec3(0.0, 0.9, 0.0);
        
        if (si.y==SKULL) {
            
            n = bump(vec3(p.x*20.0,p.y,p.z*20.0), n, 0.02);
            n = bump(p*30.0, n, 0.02);
            
            if (pattern(q.xy*2.0, 2.0) == 0.0) {
                sc = vec3(1.0,0.8,0.3)*0.4;
                rG = 0.7;
                metallic = 1.0;
            } else {
                sc = vec3(1.0,0.9,0.7);
                rG = 0.9;
            }
        } else if (si.y==TEETH) {
            n = bump(vec3(p.x,p.y*0.1,p.z)*40.0, n, 0.06);
            sc = vec3(1.0,0.9,0.7);
            rG = 0.7;
        } else if (si.y==STONE_O) {
            q.xy *= rot(T*-0.2);
            if (pattern(q.xy, 6.0) == 0.0) {
                sc = vec3(1.0,0.8,0.3)*0.4;
                rG = 0.7;
                metallic = 1.0;
            } else {
                n = bump(q*20.0, n, 0.08);
                sc = vec3(0.04);
                rG = 1.0;
            }
        } else if (si.y==STONE_I) {
            q.xy *= rot(T*0.2);
            if (pattern(q.xy, 6.0) == 0.0) {
                sc = vec3(1.0,0.8,0.3)*0.4;
                rG = 0.7;
                metallic = 1.0;
            } else {
                n = bump(q*20.0, n, 0.08);
                sc = vec3(0.04);
                rG = 1.0;
            }
        } else if (si.y==BLACK) {
            sc = vec3(0.0);
            rG = 0.0;
            metallic = 1.0;
        }
        
        sc += vec3(0.1,0.0,0.4)*0.8 * max(0.0, n.y);
        
        vec3 ld = normalize(lp-p),
             rrd = reflect(rd, n);
        float ao = AO(p, n),
              sh = shadow(p+n*EPS, ld, 0.0, FAR);
        
        vec3 h = normalize(-rd + ld);
        float rL = max(.01, rG*rG), //linear roughness
              vdoth = clamp(dot(-rd, h), 0., 1.),
              ndoth	= clamp(dot(n, h), 0., 1.),
              ndotv = clamp(dot(n, -rd), 0., 1.),
              ndotl = clamp(dot(n, ld), 0., 1.);
        
        vec3 diffuseColour = metallic == 1.0 ? vec3(0) : sc,
             specularColour = metallic == 1.0 ? sc : vec3(0.02),
             diffuse = diffuseColour * envRemap(SHIrradiance(n));
        diffuse += diffuseColour * saturate(dot(n, ld));
        diffuse *= ao;
        
        vec3 envSpecularColour = envBRDFApprox(specularColour, rG*rG, ndotv),
             env1 = envRemap(texture(iChannel1, rrd).xyz),
             env2 = envRemap(texture(iChannel0, rrd).xyz),       
             env3 = envRemap(SHIrradiance(rrd)),       
             env  = mix(env1, env2, saturate(rG*rG * 4.));
        env = mix(env, env3, saturate((rG*rG - 0.25) / 0.75));
        
        vec3 specular = envSpecularColour * env;
        vec3 lightF = fresnelSchlick(vdoth, specularColour);
        float lightD = distributionTerm(rL, ndoth);
        float lightV = geometrySmith(rL, ndotv, ndotl);
        specular += vec3(1.) * lightF * (lightD * lightV * PI * ndotl);
        specular *= saturate(pow(ndotv + ao, rG*rG) - 1.0 + ao);
        
        pc = diffuse + specular;
        pc *= sh;
        pc = pow(pc * .4, vec3(1. / 2.4));        

        if (si.y==GLOW) {
            pc = vec3(1.0,0.0, 0.0);
        }
    }
    
    pc = mix(pc, vec3(0), mint/FAR);
    pc += gc;
    
    C = vec4(pc, dof/10.0);
}