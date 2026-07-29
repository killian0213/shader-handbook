// Image (image) — Android Runtime by shau
// https://www.shadertoy.com/view/DltBRM

// Created by SHAU - 2023
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

/*
    Trying to create a passable android/humanoid with as little geometry 
    as possible and is reasonably performant.
    For the motion I used this as a basis but it's still a bit stiff and uniform 
    https://www.shadertoy.com/view/mtd3zM
    
    Some human animation shadertoys that I like
    
    Human Document by Reinder
    https://www.shadertoy.com/view/XtcyW4
    
    The Olypian by Klems
    hadertoy.com/view/XltyRf
    
    The Walking Raymarcher by XorXor
    https://www.shadertoy.com/view/Mt3XWH
    
    On the Salt Lake by Iapafoto
    https://www.shadertoy.com/view/fsXcR8
*/


#define ZERO (min(iFrame,0))
#define EPS 0.005
#define FAR 140.0
//jeyko
#define AObruh(p,n,a) smoothstep(0.,1.,map(p + n*a).x/a)

//Shane IQ?
float noise(vec3 rp) {
    vec3 ip = floor(rp);
    rp -= ip; 
    vec3 s = vec3(7,157,113);
    vec4 h = vec4(0.0,s.yz,s.y + s.z) + dot(ip,s);
    rp = rp*rp*(3.0 - 2.0*rp); 
    h = mix(fract(sin(h)*43758.5),fract(sin(h + s.x)*43758.5),rp.x);
    h.xy = mix(h.xz,h.yw,rp.y);
    return mix(h.x,h.y,rp.z); 
}

//IQ
//https://iquilezles.org/articles/
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdEllipsoid(vec3 p, vec3 r)
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float plaIntersect( vec3 ro, vec3 rd, vec4 p )
{
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

float sphIntersect( vec3 ro, vec3 rd, vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd ),
          c = dot( oc, oc ) - sph.w*sph.w,
          h = b*b - c;
    if( h<0.0 ) return -1.0;
    h = sqrt( h );
    return -b - h;
}

float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
	return mix(b, a, h) - k * h * (1. - h);
}

float bone(vec3 p, 
           vec3 a, 
           vec3 b, 
           float r1, 
           float r2, 
           float r3, 
           float ma, 
           float s)
{
    float la = length(a-p)/length(a-b),
          lt = min(sdSphere(p - a,r1),sdSphere(p - b,r2)),
          x = (1.0 - la)*s+S(0.0,0.4,la)*S(1.0,0.4,la)*ma;
    return smin(lt,sdCapsule(p,a,b,r3 + x),0.3);
}

float torso(vec3 p, 
            vec3 base, 
            vec3 lHip,
            vec3 rHip,
            vec3 top,
            vec3 lShoulder,
            vec3 rShoulder)
{
    //bottom of torso
    vec3 q = p - base;
    q.xy *= rot((base.x - top.x)/(top.y - base.y));
    q.xz *= rot((lHip.x - rHip.x)/(rHip.z - lHip.z));
    q.yz *= rot((lHip.y - rHip.y)/(rHip.z - lHip.z));
    float hips = min(sdEllipsoid(q,vec3(1.4,1.6,rHip.z)),
                  max(-q.y,sdEllipsoid(q,vec3(1.4,3.0,rHip.z))));
    //shoulders and chest
    q = p - top;
    float tt2 = S(-1.8,-0.9,q.y)*S(1.4,-0.8,q.y)*0.6*max(0.0,sign(q.x)) - //chest
                S(0.4,0.0,abs(q.z))*S(-0.6,-2.2,q.y)*0.3*max(0.0,sign(q.x)) - //groove front
                S(0.6,0.0,abs(q.z))*S(1.4,-1.2,q.y)*0.6*max(0.0,sign(-q.x)); //groove back
    
    q.xy *= rot((base.x - top.x)/(top.y - base.y));
    q.xz *= rot((lShoulder.x - rShoulder.x)/(rShoulder.z - lShoulder.z));
    q.yz *= rot((lShoulder.y - rShoulder.y)/(rShoulder.z - lShoulder.z));
    float shoulders = min(sdEllipsoid(q,vec3(1.2+tt2,1.5,rShoulder.z)),
                          max(q.y,sdEllipsoid(q,vec3(1.2+tt2,5.0,rShoulder.z))));
    q.z = abs(q.z);
    shoulders = smin(shoulders,sdSphere(q-vec3(0.0,0.0,2.4),1.0),0.3);
    return smin(hips,shoulders,0.8);
}

float leg(vec3 p, 
          vec4 hip, 
          vec4 knee, 
          vec4 ankle, 
          vec4 joint, 
          vec4 toe, 
          float side)
{
    //thigh and bum
    float t = smin(bone(p,
                       hip.xyz,
                       knee.xyz,
                       1.0,
                       0.8,
                       0.7,
                       hip.w,
                       0.2),
            sdEllipsoid(p-hip.xyz-vec3(-0.4,0.0,0.5*side),vec3(1.5,1.8,1.5)),
            0.5);
    //shin - move ankle bone up a bit
    t = min(t,bone(p,
                   knee.xyz,
                   ankle.xyz + normalize(knee.xyz - ankle.xyz) * 0.7,
                   0.8,
                   0.5,
                   0.45,
                   knee.w,
                   0.1));
    //foot - new shoes. waddle waddle
    vec3 q = p - joint.xyz;
    float a = tan((joint.x - ankle.x)/length(ankle-joint));
    q.xy *= rot(a);
    float foot = max(-q.y,sdEllipsoid(q,vec3(0.4,1.6,0.9)));
    q.xy *= rot(tan((toe.x - joint.x)/length(joint-toe))-a);
    foot = min(foot,max(q.y,sdEllipsoid(q,vec3(0.4,1.0,0.9)))); //toes
    foot = min(foot,sdEllipsoid(q,vec3(0.4,0.4,0.9))); //joint
    foot = smin(foot,
                sdCapsule(p,
                          joint.xyz,
                          ankle.xyz + normalize(ankle.xyz - joint.xyz)*0.6,
                          0.4),
                0.2);
    
    return smin(t,foot,0.3);
}

float arm(vec3 p, 
          vec4 shoulder, 
          vec4 elbow, 
          vec4 wrist, 
          vec4 knuckle, 
          vec4 finger, 
          float side)
{
    float t = min(bone(p,shoulder.xyz,elbow.xyz,0.7,0.6,0.5,shoulder.w,0.1),
                  bone(p,elbow.xyz,wrist.xyz,0.6,0.4,0.4,elbow.w,0.05));
    
    //hand
    vec3 q = p - knuckle.xyz;
    float a = (finger.y - wrist.y)/length(finger.xy - wrist.xy);
    q.xy *= rot(tan(a));
    q.xz *= rot(-0.4*side);    
    float hnd = min(sdEllipsoid(q,vec3(0.3,0.7,0.3)), 
                    max(q.x,sdEllipsoid(q,vec3(1.6,0.7,0.3))));
    q.xz *= rot(0.6*side);
    hnd = min(hnd,max(-q.x,sdEllipsoid(q,vec3(1.6,0.7,0.3))));
    return smin(t,hnd,0.4);
}

vec2 near(vec2 a, vec2 b){ 
    float s = step(a.x, b.x);
    return s * a + (1. - s) * b;
}

vec3 map(vec3 p)
{
    vec4 bSpine =    texture(iChannel0,B_SPINE/R),
         rHip =      texture(iChannel0,R_HIP/R),
         lHip =      texture(iChannel0,L_HIP/R),
         rKnee =     texture(iChannel0,R_KNEE/R),
         rAnkle =    texture(iChannel0,R_ANKLE/R),
         rFoot =     texture(iChannel0,R_FOOT/R),
         rToe =      texture(iChannel0,R_TOE/R),
         lKnee =     texture(iChannel0,L_KNEE/R),
         lAnkle =    texture(iChannel0,L_ANKLE/R),
         lFoot =     texture(iChannel0,L_FOOT/R),
         lToe =      texture(iChannel0,L_TOE/R),
         tSpine =    texture(iChannel0,T_SPINE/R),
         rShoulder = texture(iChannel0,R_SHOULDER/R),
         lShoulder = texture(iChannel0,L_SHOULDER/R),
         rElbow =    texture(iChannel0,R_ELBOW/R),
         rWrist =    texture(iChannel0,R_WRIST/R),
         rKnuckle =  texture(iChannel0,R_KNUCKLE/R),
         rFinger =   texture(iChannel0,R_FINGER/R),
         lElbow =    texture(iChannel0,L_ELBOW/R),
         lWrist =    texture(iChannel0,L_WRIST/R),
         lKnuckle =  texture(iChannel0,L_KNUCKLE/R),
         lFinger =   texture(iChannel0,L_FINGER/R),
         head =      texture(iChannel0,HEAD/R);

    float t = torso(p,
                    bSpine.xyz,
                    rHip.xyz,
                    lHip.xyz,
                    tSpine.xyz,
                    rShoulder.xyz,
                    lShoulder.xyz),    
          legs = min(leg(p,rHip,rKnee,rAnkle,rFoot,rToe,RIGHT),
                     leg(p,lHip,lKnee,lAnkle,lFoot,lToe,LEFT)),
          arms = min(arm(p,rShoulder,rElbow,rWrist,rKnuckle,rFinger,RIGHT),
                     arm(p,lShoulder,lElbow,lWrist,lKnuckle,lFinger,LEFT));

    t = smin(t,legs,0.3);
    t = smin(t,arms,0.2);

    //head
    vec3 q = p - head.xyz;
    q.xy *= rot(-0.1);
    float fa = S(-0.7,-0.3,q.y)*0.4,
          fb = S(-1.0,-2.3,q.y)*0.4,
          f = sdEllipsoid(q - vec3(1.4,-0.6,0.0),vec3(0.9+fa,1.9,1.3-fb));
    q.xy *= rot(-0.2);
    f = smin(f,sdEllipsoid(q - vec3(0.4,0.4,0.0),vec3(2.0,1.4,1.7)),0.4);     
    //nose
    f = smin(f, sdCapsule(q,vec3(2.5,-0.8,0.0),vec3(1.9,1.0,0.0),0.2),0.15);
    //neck
    f = smin(f, sdCapsule(p,tSpine.xyz,head.xyz,0.8),0.4);
    t = smin(t,f,0.5);
    //eyes and ears
    q.z = abs(q.z);
    float eyes = sdEllipsoid(q - vec3(1.7,-0.2,0.5),vec3(0.7,0.5,0.6)); 
    eyes = min(eyes,sdEllipsoid(q - vec3(0.0,0.4,1.5),vec3(0.6,0.4,0.4)));
    return vec3(near(vec2(t,1.0),vec2(eyes,2.0)),eyes);
}

vec3 normal(vec3 p) 
{  
    vec4 n = vec4(0.0);
    for (int i=ZERO; i<4; i++) 
    {
        vec4 s = vec4(p, 0.0);
        s[i] += EPS;
        n[i] = map(s.xyz).x;
    }
    return normalize(n.xyz-n.w);
}

//Shane - Perspex Web Lattice - one of my favourite shaders
//https://www.shadertoy.com/view/Mld3Rn
//Standard hue rotation formula... compacted down a bit.
vec3 rotHue(vec3 p, float a)
{
    vec2 cs = sin(vec2(1.570796, 0) + a);
    mat3 hr = mat3(0.299,  0.587,  0.114,  0.299,  0.587,  0.114,  0.299,  0.587,  0.114) +
        	  mat3(0.701, -0.587, -0.114, -0.299,  0.413, -0.114, -0.300, -0.588,  0.886) * cs.x +
        	  mat3(0.168,  0.330, -0.497, -0.328,  0.035,  0.292,  1.250, -1.050, -0.203) * cs.y;
							 
    return clamp(p*hr, 0., 1.);
}


float surfCol(vec3 p)
{
    vec3 rHip =      texture(iChannel0,R_HIP/R).xyz,
         lHip =      texture(iChannel0,L_HIP/R).xyz,
         rKnee =     texture(iChannel0,R_KNEE/R).xyz,
         rAnkle =    texture(iChannel0,R_ANKLE/R).xyz,
         lKnee =     texture(iChannel0,L_KNEE/R).xyz,
         lAnkle =    texture(iChannel0,L_ANKLE/R).xyz,
         rShoulder = texture(iChannel0,R_SHOULDER/R).xyz,
         lShoulder = texture(iChannel0,L_SHOULDER/R).xyz,
         rElbow =    texture(iChannel0,R_ELBOW/R).xyz,
         rWrist =    texture(iChannel0,R_WRIST/R).xyz,
         lElbow =    texture(iChannel0,L_ELBOW/R).xyz,
         lWrist =    texture(iChannel0,L_WRIST/R).xyz,
         head =      texture(iChannel0,HEAD/R).xyz,
         la = lAnkle + normalize(lKnee - lAnkle) * 0.7,
         ra = rAnkle + normalize(rKnee - rAnkle) * 0.7;
    
    float t = min(length(p-lHip) - 1.6,length(p-rHip) - 1.6);
    t = min(t,length(p-lKnee) - 1.0);
    t = min(t,length(p-la) - 0.7);
    t = min(t,length(p-ra) - 0.7);
    t = min(t,length(p-rKnee) - 1.0);
    t = min(t,length(p-lShoulder) - 1.2);
    t = min(t,length(p-rShoulder) - 1.1);
    t = min(t,length(p-lElbow) - 0.8);
    t = min(t,length(p-rElbow) - 0.8);
    t = min(t,length(p-lWrist) - 0.6);
    t = min(t,length(p-rWrist) - 0.6);
    t = min(t,length(p.xy-head.xy) - 1.4);
    t = min(t,abs(p.z) - 0.2);
    
    return t;
}

float fbm(vec3 x) {
    float r = 0.0,
          w = 1.0,
          s = 1.0;
    for (int i = 0; i < 5; i++) {
        w *= 0.5;
        s *= 2.0;
        r += w*noise(s*x);
    }
    return r;
}

//Patu
//https://www.shadertoy.com/view/4tVXRV
vec3 clouds(vec3 rd) 
{
    float CT = iTime/8.0,
          nz = fbm(vec3((rd.xz/(rd.y + 0.4))*1.4 + vec2(CT*2.0,0.0),CT))*1.5;
    return clamp(pow(vec3(nz),vec3(6.0))*rd.y,0.0,1.0);
}

vec3 bump(vec3 p, vec3 n) {
    vec4 d = vec4(0.0);
    for (int i=ZERO; i<4; i++) 
    {
        vec4 s = vec4(p,0.0);
        s[i] += EPS;
        d[i] = S(0.08,0.0,surfCol(s.xyz));
    }
    return normalize(n - d.xyz*0.4);
}

mat3 camera(vec3 la, vec3 ro, float cr)
{
	vec3 cw = normalize(la - ro),
	     cp = vec3(sin(cr),cos(cr),0.),
	     cu = normalize(cross(cw,cp)),
	     cv =          (cross(cu,cw));
    return mat3(cu,cv,cw); 
}

void mainImage(out vec4 C, vec2 U)
{
    vec4 ro = texture(iChannel0,CAM/R),
         la = texture(iChannel0,LA/R),
         rFoot = texture(iChannel0,R_FOOT/R),
         lFoot = texture(iChannel0,L_FOOT/R);
         
    vec2 uv = (2.0*(U) - R.xy)/R.y;
    vec3 rd = camera(la.xyz,ro.xyz,0.0) * normalize(vec3(uv,ro.w)), 
         bg = rotHue(vec3(1.0,0.0,0.0),iTime*0.1)*2.0,
         col = bg*clouds(rd)*3.0,
         lp = vec3(7.0,25.0,-17.0);
    
    float ft = plaIntersect(ro.xyz,rd,vec4(0,1,0,6.0)), //floor
          st = sphIntersect(ro.xyz,rd,vec4(0.0,4.0,0.0,12.0)), //bounding sphere
          t = 0.0, maxt = FAR, sid = 0.0, gc = 0.0;

    if (ft>0.0)
    {
        //floor
        maxt = ft;
        vec3 p = ro.xyz + rd*ft,
             q = vec3(p.x+mod(iTime*32.0,32.0),p.yz),
             fl = floor(q*0.5) - 0.5,
             fr = fract(q*0.5) - 0.5;
        
        col = vec3(0.01);
        
        //glow
        float lft = length(lFoot.xz - floor(p.xz*0.5) - vec2(0.5)),
              rft = length(rFoot.xz - floor(p.xz*0.5) - vec2(0.5)),
              ct = length(fr.xz);
        col += 3.0*(2.0*bg*S(0.5,0.1,ct)+mix(bg,vec3(1.0),0.8)*S(0.3,0.0,ct)) *
                S(2.6,0.0,lft)*S(-5.0,-6.0,lFoot.y);
        col += 3.0*(2.0*bg*S(0.5,0.1,ct)+mix(bg,vec3(1.0),0.8)*S(0.3,0.0,ct)) *
                S(2.6,0.0,rft)*S(-5.0,-6.0,rFoot.y);
        
        col += clouds(reflect(rd,vec3(0.0,1.0,0.0)))*bg*0.5;
        //mask
        col *= S(-0.4,-0.35,fr.x)*S(0.4,0.35,fr.x) *
               S(-0.4,-0.35,fr.z)*S(0.4,0.35,fr.z);
        
        float fog = length(p);
        col /= (1.0 + fog*fog*0.01);
    }
    
    if (st>0.0)
    {
        t = st;
        for (int i=ZERO; i<100; i++)
        {
            vec3 p = ro.xyz + rd*t;
            vec3 ns = map(p);
            if (ns.x<EPS) 
            {
                sid = ns.y;
                break;
            }
            t += ns.x*0.8;
            gc += 0.016/(1.0 + ns.z*ns.z*32.0);
            if (t>maxt) {
                t = -1.;
                break;
            }
        }
    }
    
    if (t>0.0) { 
       vec3 p = ro.xyz + rd*t,
            n = bump(p,normal(p)),
            ld = normalize(lp-p);
       float spec = pow(max(dot(reflect(-ld,n),-rd),0.0),16.0),
             fres = pow(clamp(dot(n,rd) + 1.0,0.0,1.0),4.0),
             ao = AObruh(p,n,0.4)*AObruh(p,n,0.1),
             jc = surfCol(p);
       
       if (sid==1.0)
       {
           if (jc<0.0)
           {
               //joints
               col = vec3(0.006)*max(0.0,dot(ld,n)) + max(0.0,n.y)*bg*0.08;
               col *= ao;
           }
           else
           {
               //body
               col = vec3(0.01)*max(0.001,dot(ld,n)); 
               col += bg*clouds(reflect(rd,n))*4.0*max(0.2,dot(ld,n));
               col *= ao;
               col += vec3(1.0)*spec;
               col += vec3(1.0)*clouds(reflect(rd,n))*4.0*fres;
           }

       }
       if (sid==2.0)
       {
           //eyes and ears
           col = bg;
       }
    }

    col += gc*bg;    
    col = pow(col,vec3(0.4545));
    
    C = vec4(col,1.0);
}