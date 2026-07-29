// Image (image) — gears ball  2 mouse by shadertoyjiang
// https://www.shadertoy.com/view/McKSD3


// 2024年05月16日 
// 齿球


bool reflectingScene = true;


#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define PI    3.14159265358979
#define PI2   6.28318530717957
float mclr, rshl=.9;
int obj;

mat3 rot3(vec3 n, float a)
{
        n = normalize(n);
        float s = sin(a), c=cos(a), e=1.-c,
              x = n.x, y = n.y, z = n.z;
        return mat3( e*x*x+c,   e*y*x-z*s, e*z*x+y*s,
                     e*x*y+z*s, e*y*y+c,   e*z*y-x*s,
                     e*x*z-y*s, e*y*z+x*s, e*z*z+c );
}

// 光滑
float smin(float a, float b, float k){float h = clamp(.5+.5*(a-b)/k, 0., 1.);return mix(a, b, h) - k * h*(1.-h);}
float smax(float a, float b, float k){return smin(a, b, -k);}

float d12g(vec3 p, vec3 a)
{
        vec3 q = p, e = vec3(1), n = normalize(cross(e,a));
        float mx,vnu,x,y,d1,d2,d3;
        for(int i;i++<3;q=q.yzx)
        {
                vnu = dot(q, a);
                if(vnu>mx)mx=vnu, p = q;
        }
        y = dot(p,n);
        x = length(p-y*n)-rshl;
        vec2 rct = vec2(x,y), f = vec2(.052,.03);
        d1 = length(max(abs(rct)-f, 0.))-.01;
        e=normalize(e);
        y = dot(p,e);
        x = length(p-y*e)-.1;
        d3=abs(length(p)-rshl-.02)-.05;
        d2=smax(x, d3,.01);
        return smin(d1,d2,.05);
}


float chi(vec3 p)
{
        mclr=0.;
        if(length(p)>1.15)return length(p)-1.1;
        int num, num2;
        
        obj=0;
        
        
        float av, af,
              df = sqrt(5.)*.5+.5,
              xf = sqrt(5.)*.5-.5;
        vec3 e = vec3(1),
             a = vec3(0, xf, df),
             b = vec3(xf, df, 0),
             nv = normalize(e),
             ne = normalize(a+e),
             nf = normalize(cross(e-b,e-a)),
             n = normalize(e-a);
        
        vec3 vx = nf-nv, 
             vz = normalize(cross(vx, nv)),
             fx = nv-nf,
             fz = normalize(cross(fx, nf));
             vx = normalize(cross(nv, vz));
             fx = normalize(cross(nf, fz));
     
        float dpz=dot(p, vec3(nv.xy,nv.z)  );
        vec3 tq=p;
        for(int i;i++<9;n=n.yzx){
                if(dot(p, n)<0.)p=reflect(p, n),num++;}
                
        float shl = d12g(p,a);
        
        vec3 tv = vec3(dot(p, vx), dot(p, nv), dot(p, vz)),tf;
        av =  atan(tv.z, tv.x);
        
        float mi=-1e8,md,mv,mf=-1e8; vec3 mp;
        
        for(float i;i<3.;i++)
        {
                md = dot(p, nf);
                if(mf<md)
                {
                        mf=md;
                        mi=i;
                        mp = p;
                }
                p=p.zxy;
        }
        p = mp;
        tf = vec3(dot(p, fx), dot(p, nf), dot(p, fz));
        af = -atan(tf.z, tf.x);
        float nu = float(num%2); 
        if(nu>.5)
        {
              av=PI2/3.*0.-av, 
              af=PI2/5.*0.-af;
        }
        else
        {
              //av-=0.*PI2/3.;
        }
        
        av-=(float(num))* PI2/3.;
        af+=float(num)*PI2/5. ;
        
        // 求解齿轮半径
        float rp = 1., avf, r;
        avf = acos(dot(nv, nf));
        r = rp * tan(avf/2.);
        
        vec2 rvf = vec2(length(tv.xz), length(tf.xz))-r+.08;  
        vec2 hvf = vec2(tv.y, tf.y)-rp;
        vec2 mvf = vec2(length(vec2(rvf.x,hvf.x)),length(vec2(rvf.y,hvf.y))) -.05;
        mvf -= .05*(.5-.5*sin(30.*(vec2(av,af)+iTime*.9))*vec2(1,-1));// 15 30 45 60 75 90
        
        mvf = max(mvf, abs(hvf)-.02); // 压扁
        mvf = max(mvf, max(-rvf, 0.)-.03); // 挖轮心
        mvf = min(mvf, max( //轴套
                  abs(hvf)-.04 ,
                  rvf +.2
              ));
               
        vec2 dgan=max(rvf+r-.12,   length(p)-rp-.05);
        if(dgan.y<mvf.y || dgan.x<mvf.x)obj=4;
        mvf = min(mvf, dgan);
        // 不连心
        mvf.x=max(mvf.x, (rshl+.0-length(p))+.0);
                             
        // 球
        float knr = smin(  max(rvf.y+r-.15,   length(p)-.6) , length(p)-.3,.3);
        if(knr<mvf.y)obj=2;
        mvf.y = min(mvf.y,  knr );
        
        float aa = 5.*(af+iTime*.9); // 5 10 15 20
        
        float r1=length(tf.xz)-r+.08;
        float d1=length(vec2(tf.y-rp, (.5+.5*sin(aa))*(.2+rvf.y)))-.0315; // 1736  .1 .05
        
        float lf = max(r1,d1); // 五辐条
        
        float ab = 6.*(av+iTime*.9);  // 设置成15不会碎裂，角度折叠规律还没理解  3 6 9 12 15         .2+rvf.x   -.003
        
        float r2=length(tv.xz)-r+.08;
        float d2=length(vec2(tv.y-rp, .0+(.5+.5*cos(ab))*(.1-abs(rvf.x))))-.008; // 1736  .1 .05
        float lv= max(d2,r2); // 六福条
               
        float ln = min(lf,lv);
        
        ln = smin( min(mvf.x, mvf.y) , ln, .01);
        ln=max(ln,length(p)-rp-.06);// 倒角
        if(shl<ln)obj=1;
        return min(ln,shl);
}

float map(vec3 p)
{
        float t ; 
        float d=   p.y+1.3,d2;
        obj=0;
        if(length(iMouse)<10. || mod(iMouse.x/iResolution.x*4.,2.)<1. )t=iTime*.3;
        d= 99.3-length(p-vec3(0, 98,8));
        
        p=rot3(vec3(1,0,0),(length(iMouse)>2.?iMouse.y/iResolution.y-.5:0.)*3.5)*p;
        p=rot3(vec3(0,1,0), t*.2)*p;
        p=rot3(vec3(1,0,0),PI/4.)*p;
        p=rot3(vec3(0,1,0),-PI/4.)*p;
        
        d2=chi(p);
        
        if(d<d2)obj=3;
        return min(d2, d);
}

float softshadow(vec3 ro, vec3 rd)
{
   float res = 1., k= 8.;
   float t;
   for(int i =0;i<256 && t<2.;i++)
   {
               float h = map(ro + rd * t);
               if(h<.001)return 0.;
               res = min(res, k*h/t);
               t += h;
   }
   return res +.5;
}



void mainImage(out vec4 O, vec2 U)
{
        O = vec4(.5);
        vec2 R = iResolution.xy,
             u = (U+U - R) / R.y;
        vec3 eye = vec3(0, 0, -2),
             dir = normalize(vec3(u, 1.5)),
             sun = 5. * ( .2*cos(iTime*0.+12.6+vec3(7,11,13)) + vec3(-1,2,-3)/3.74 ),
             eps = vec3(0, .0001, 0),
             nor, p;
        float d , t;
        float ref;
        vec3 nrm;
        for(int i; i++<228 && t< 12.;)
        {
                p = eye + dir * t;
                d = map(p);
                if( d<.003 )
                {       // phong 光照模型
                        float shd = .05+.95*softshadow(p-dir*.1, normalize(sun-p));
                        nor = nrm = normalize(vec3(map(p+eps.yxx), map(p+eps), map(p+eps.xxy))-d); 
                        vec3  sp = normalize(sun-p), ep=normalize(eye-p);
                        float ln = max(0., dot(nor,sp)),               // light norm
                              er =ref= max(0., dot(ep, reflect(-sp,nor))); // eye ray
                        float ambt=.3, difu=.6, spec=88.;
                        
                        vec4  Clr=vec4(1);
                        if(iMouse.x < iResolution.x/2.)
                        {
                                if(iMouse.y<iResolution.y/2.){
                                Clr = vec4(2,.5,0,1)* .8;//,.6,.5,1);
                                if(obj==1)Clr=vec4(0,.5,1,1);
                                if(obj==2)Clr=vec4(.15,.6,.1,1);
                                if(obj==4)Clr = vec4(2);
                                if(obj==3)Clr = vec4(4,6,9,0)*.1+shd*.4;//地面  .03 .4
                                }else{
                                Clr =(iMouse.y/iResolution.y>1.-.1 ? 6.*p.xyyy:O*0.)+ .3/vec4(.15, .1, 1.8, 1)* .8;//,.6,.5,1);
                                if(obj==1)Clr=vec4(0,.5,1,1);
                                if(obj==2)Clr=vec4(5.15,.6,.1,1);
                                if(obj==4)Clr = vec4(2);
                                if(obj==3)Clr = vec4(.4,6,9,0).zxxx*.1+shd*.8;//地面
                                }
                        
                        
                        }
                        O = Clr * (ambt*.05 + difu*ln*.3 +pow(er, 4.) + pow(er, spec));
                        // 大绿
                        O += vec4(-mclr, mclr*.0002, 0, 0);
                        
                        
                        
                        
  if(reflectingScene==true && iMouse.x/R.x> .05     && iMouse.y/R.y<.25){                    
      //if(obj!=1)O = O * .4 -.0+ 2. *pow(texture(iChannel0, reflect(-ep, nor))  *  pow(max(dot((ep+normalize(sun-p))/2.,nor) ,0.), 1.) ,vec4(4.))       +.01,                    
      O*=clamp(3. +.8* Clr,0.,2.);         
      
      //O = O*.4+texture(iChannel0,    reflect(-ep, nor))* dot((ep+normalize(sun-p))/2.,nor) ;           
      //if(obj==3)O= sqrt(O.wxxw)-.01; // xxx green
      O*=O+.2;
      if(obj==3)O= sqrt(O);
  }                      
                        O *= shd;//+pow(1.-shd,2.);               
                        
                        O=sqrt(O);       
                        break;
                }
                t += d * .6 ;
        }
        if(length(U-iMouse.xy)/iResolution.y<.1){
        if(abs(U.y-iMouse.y)<2.)O=vec4(0,0,1,1);
        if(abs(U.x-iMouse.x)<2.)O=vec4(0,0,1,1);}
        if(obj==3)  O.rgb *= exp( .2 *  length(eye-p)),O=min(O ,1.)*.5;// * .8;

//if(length(iMouse.xy)<5. && 
if(obj != 3)
{
         float spec = length(sin(ref * 9.)*cos(ref*ref*2.) * .5 + .5);
         spec *= .2+smoothstep(.85, .8, dot( (p+sin(nrm*8.)),cos(nrm.yzx*8.)));
         //Elsio
         O *= .2+1.8*pow(   (vec4(1)  * spec * .6 + pow(spec * .4, 5.) * 5.),// * AO(p, ref * 2.),
                      vec4(.8)
              );     
     
}
}

















