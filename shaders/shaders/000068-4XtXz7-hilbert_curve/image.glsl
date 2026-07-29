// Image (image) — hilbert curve by shadertoyjiang
// https://www.shadertoy.com/view/4XtXz7

// 2024年6月20日                                 
// hilbert curve
// 参照 https://www.shadertoy.com/view/MljyRd

int iter=3;

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float dln(in vec3 a, in vec3 b, in vec3 p){b-=a; p-=a;float h = clamp(dot(p,b)/dot(b,b), 0., 1.);return length(p - b * h);}


vec4 clr=vec4(0);

void cclr(vec3 p, float sid, float fan)
{
        float alp = atan(p.y,p.x)/(3.1415926535*.5)+1.;
        alp =(alp-.5)*fan+.5;
        sid += alp;
        float spd = 25.,
              nt = pow(8.,float(iter)) ,
              t1= (mod(iTime*1., 1.+ nt/spd)-1.)*spd,
              t2= (mod(iTime+nt/2./spd, 1.+ nt/spd)-1.)*spd;
        clr *= 0.;
        clr += 1.*exp(- .5 *abs(sid-t1) )*vec4(-5,5,2,1);//* .5;
        clr += 1.*exp(- .5 *abs(sid-t2) )*vec4(5,2,-5,1);
}

float sdcubeedge(vec3 p)
{
        vec3 a = abs(p) ,
             m = 1.-step(a,a.yzx )*step(a,a.zxy );
        return length( max(abs(a-2.)-.02, 0.)*m );
}

vec2 hrbt(vec3 p)
{// 皮亚诺曲线（希尔伯特 hilbert curve） 
        //p = p*1./dot(p,p);
        float d1 = length(max(abs(p)-2., 0.));
       // if(d1>.3)return vec2(d1,999.);
        float k = 1.;
        float d3 = sdcubeedge(p);
        #define fx vec3(1,0,0)
        #define fy vec3(0,1,0)
        #define fz vec3(0,0,1) 
        vec3 f[9]=vec3[9](fx, fz, -fy,-fz, fx, fz, fy, -fz, fy);
        int  t[8]=int[](3,4,0,7,2,5,1,6);
        int ind;
        float sid=0.,fan=1.;
        
        //iter= 3  ;
        
        for(int i=0;i < iter; i++)       
        {        
                ind = int( .5+dot(vec3(1,2,4), sign(p)*.5+.5)  );
                vec3 rx = f[t[ind]  ],
                     ry = f[t[ind]+1],
                     rz = cross(rx,ry),
                     tx;
                sid = sid * 8. + (float(t[ind])-3.5)*fan+3.5;// 就是反号倒序
                if((ind<4)&&(ind!=2)) rz=-rz;
                if((ind==0)||(ind==2)||(ind==5)||(ind==6)){tx=-rx, rx=-ry, ry=tx; fan=-fan;}
                
                
                p = (p - sign(p))*2.;
                k = k * 2.;
                p = p*mat3(rx,ry,rz);
        }
        
        vec3 q=min(abs(p+2.),abs(2.-p));
        float d4 = min(q.x, min(q.y, q.z))/k;
        if(d1>0.6)d4=1e3;
        p-=vec3(-2,2,0);
        cclr(p, sid, fan);
        float d2= length(vec2(length(p.xy)-2.,p.z))- 1. ;
        
        if((sid==0.)||(int(sid+.5)==(1<<iter*3)-1)){
               p+=vec3(-2,2,0); //p+=fx*1.;;    
               d2 = min(length(p)-1.2, dln(p*0., -fx*5., p)-1.);
        }
        d2 = d2/k;
        if(d3<d2)d2=d3,clr=vec4(8, 1.8,.0,.4)*.2;
        return vec2(d2,d4);
        //return max(d1, d2/k);
}

vec2 map(vec3 p)
{
        float t = (iTime-10.)*.2;
        vec2 ms = iMouse.xy/iResolution.xy*6.28;
        p.xy *= rot(t *1.2);p.yz *= rot(-t *.7);p.xz *= rot(t *.5);
        p.xz *= rot(ms.x);
        p.yz *= rot(ms.y);
        return hrbt(p);
        //return h2(p);
}


float softshadow(vec3 ro, vec3 rd )
{
   float res = 1.;
   float t = .01, k= 1.8 ;
   for(int i =0;i<25 && t<1.5;i++)
   {              
               float h = map(ro + rd * t).x;
               if(h<.001)return 0.;               
               res = min(res, k*h/t);
               t += h;
   }
   return res * .5 + .5;
}


void mainImage(out vec4 O, vec2 U)
{
        O = vec4(.4);
        vec2 R = iResolution.xy,
             u = (U+U +.1- R) / R.y;
        vec3 eye = vec3(0, 0, -7),
             dir = normalize(vec3(u, 2)),
             sun = 5. * ( .0*cos(iTime+vec3(7,11,13)) + vec3(-1,2,-5)/3.74 ),
             eps = vec3(0, .0001, 0),
             nor, p;
        float  t=0.;
        vec2 e;
        for(int i=0; i<148 ;i++)
        {
                if(t>13.)break;
                p = eye + dir * t;
                e = map(p);
                //e.x=min(e.x,e.y);
                vec4 clrf=clr;
                if( e.x<.01 )
                {       // phong 光照模型
                        nor = normalize(vec3(map(p+eps.yxx).x, map(p+eps).x, map(p+eps.xxy).x)-e.x); 
                        vec3  sp = normalize(sun-p), ep=normalize(eye-p);
                        float ln = max(0., dot(nor,sp)),               // light norm
                              er = max(0., dot(ep, reflect(-sp,nor))); // eye ray
                        float ambt=.3, difu=.6, spec=80.;
                        float shd=softshadow(p-dir*e.x,normalize(sun-p));
                        //vec4  lightClr = vec4(1,.6,0,1).yyxw*.8+.3; O = clrf+lightClr * (ambt - er*.3 + difu*ln + pow(er, spec))*shd;
                        vec4  lightClr = vec4(1.4,1.9,0,1)/*vec4(1.2,1.5,0,1).zyxz*/*.6+.1; O = clrf.xwww *5. +.5*lightClr * (ambt - er*.3 + difu*ln + pow(er, spec));
                        O*=shd;
                        O *= exp(-.1*(t+eye.z+2.));
                        break;
                }
                t += min(e.x, max(e.y,.1)); // safe
                //t += e.x * .5;// fast
        }
}




