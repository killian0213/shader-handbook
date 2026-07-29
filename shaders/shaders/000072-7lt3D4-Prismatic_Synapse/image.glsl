// Image (image) — Prismatic Synapse by Hyeve
// https://www.shadertoy.com/view/7lt3D4

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))



//NOTE: this style of very compact, hard-to-read code makes
//things easier for shaders, especially in the view of
//livecoding compos where you have very limited time to
//write them, but it would be absolutely awful anywhere else,
//and I definitely don't recommend doing it outside of shaders like this



vec3 glw; //glow

float bx(vec3 p, vec3 s) //box
{
  vec3 q=abs(p)-s;
  return min(max(q.x,max(q.y,q.z)),0.) + length(max(q,0.));
}

vec2 mp(vec3 p) //scene
{
 
  float scl=0.8;
  for(int i=0;i<3;i++)
  {
    p.yz*=rot(scl-0.3);
    p.y=abs(p.y)-scl;
    p.x+=p.y*scl;
    scl-=abs(p.y)*0.2;
    p.xz*=rot(iTime*0.4);
  }
  float s = length(p-vec3(0,0,2));
  float b = bx(p,vec3(scl)) - 0.1;
  b*=0.5;b=min(s,b);
  s*=8.;glw += 0.01/(0.01*s*s)*normalize(p*p);
  return vec2(b,1);
}

vec2 tr(vec3 ro, vec3 rd, float z) //raymarch
{
  vec2 d=vec2(0);
  for(int i=0;i<256;i++)
  {
    vec2 s=mp(ro+rd*d.x);
    s.x*=z;d.x+=s.x;d.y=s.y;
    if(s.x<0.0001||d.x>64.)break;
  }
  return d;
}

vec3 nm(vec3 p) //get normal
{
  vec2 e=vec2(0.001,0); return normalize(mp(p).x - vec3(mp(p-e.xyy).x,mp(p-e.yxy).x,mp(p-e.yyx).x));
}

vec4 px(vec2 h, vec3 p, vec3 n, vec3 r) //shade pixel
{
  vec4 bg = vec4(0.1,0.1,0.8,0) + length(r*r)*0.5;
  if(h.x>64.) return bg; 
  vec4 fc = vec4(0.4,0.4,01,1);
  vec3 ld = normalize(vec3(0.6,0.4,0.8));
  float diff = length(n*ld);
  float fres = abs(1.-length(n*r))*0.2;
  float spec = pow(max(dot(reflect(ld,n)*ld,-r),0.),6.);
  float ao = clamp(1.-mp(p+n*0.1).x*10.,0.,1.)*0.1;
  float sss = smoothstep(0.,1.,mp(p*ld*3.).x)*0.6;
  fc.rgb+=fc.rgb*sss;
  fc*=diff;
  fc+=spec;
  fc+=fres;
  fc-=ao;
  return fc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
  uv -= 0.5;
  uv /= vec2(iResolution.y / iResolution.x, 1);
  vec3 ro = vec3(0,0,-5),rd=normalize(vec3(uv,1));
  vec3 cp,cn,cr,h=vec3(1);
  vec4 cc,fc=vec4(1);
  
  //adjust this value for different amounts of refraction
  //higher = more refraction; lower = less refraction (1.0 is none)
  //below 1.0 makes them.. inverted i think? kinda interesting
  float io = 1.4; 
 
  for(int i=0;i<4*2;i++) //more efficient transparency loop
  {
     h.xy=tr(ro,rd,h.z);cp=ro+rd*h.x;
     cn=nm(cp);cr=rd;ro=cp-cn*(0.01*h.z);
     rd=refract(cr,cn*h.z,h.z>0.?1./io:io);
     if(dot(rd,rd)==0.)rd=reflect(cr,cn*h.z);
     cc=px(h.xy,cp,cn,cr);h.z*=-1.;
     if(h.z<0.)fc.rgb=mix(fc.rgb,cc.rgb,fc.a);
     fc.a*=cc.a;if(fc.a<=0.||h.x>64.)break;
  }
  
  //various interesting effects to try
  fragColor = vec4(fc+glw.rgbb);
  //fragColor = vec4(fc+sqrt(glw.rgbb*0.6));
  //fragColor = vec4(fc+sqrt(glw.rgbb-0.005));
  //fragColor = vec4(fc*sqrt(glw.rgbb-0.005));
}
