// Image (image) — Hutger Rauer (4k Intro port) by spolsh
// https://www.shadertoy.com/view/WscGRM

/*
''''''''''''''''''''''''''''''''''''''''''''        Xenium 2019
'''@@@@''''''''''@@@'''''@@@@@@@@@@@@@@@@'''
'''@@@@'''''''''@@@@@'''@@@@@@@@@@@@@@@@@@''
''@@@@@@''''''''@@@@@'''@@@@@@@@@@@@@@@@@@''  code  klos
''@@@@@@''''''''@@@@@'''@@@@@@@@@@@@@@@@@@''        shx
''@@@@@@''''''''@@@@@'''@@@@@@@@@@@@@@@@@@''        
''@@@@@@''''''''@@@@@''''''''''''''''@@@@@''
''@@@@@@''''''''@@@@@''''''''''''''''@@@@@''  music shx
''@@@@@@''''''''@@@@@''''''''''''''''@@@@@''  
''@@@@@@'''@@@@@@@@@@''''@@@@@@@@@@@@@@@@@''
''@@@@@@'''@@@@@@@@@@'''@@@@@@@@@@@@@@@@@@''  gfx   klos
''@@@@@@''@@@@@@@@@@@'''@@@@@@@@@@@@@@@@@@''  
''@@@@@@''@@@@@@@@@@@'''@@@@@@@@@@@@@@@@@@''
'''@@@@''''@@@@@@@@@''''@@@@@@@@@@@@@@@@@@''  >>> Hutger Rauer <<<
''''''''''''''''''''''''''''''''''''''''''''  
''''''''''''''''''''''''''''''''''''''''''''
'''@@@@''''@@@@@@@@@'''''@@@@@@@@@@@@@@@@'''
'''@@@@''''@@@@@@@@@@'''@@@@@@@@@@@@@@@@@@''  tools .crinkler
''@@@@@@''@@@@@@@@@@@'''@@@@@@@@@@@@@@@@@@''        .4klang
''@@@@@@''@@@@@@@@@@@'''@@@@@@@@@@@@@@@@@@''        .opengl
''@@@@@@'''@@@@@@@@@@'''@@@@@@@@@@@@@@@@@@''        .k2yasm
''@@@@@@''''''''@@@@@'''@@@@@'''''''''''''''
''@@@@@@''''''''@@@@@'''@@@@@'''''''''''''''  greets
''@@@@@@''''''''@@@@@'''@@@@@'''''''''''''''    Aberration Creations,
''@@@@@@''''''''@@@@@'''@@@@@@@@@@@@@@@@@'''    Abyss, Adapt, Alcatraz,
''@@@@@@''''''''@@@@@'''@@@@@@@@@@@@@@@@@@''    Altair, Brain Control,
''@@@@@@''''''''@@@@@'''@@@@@@@@@@@@@@@@@@''    Dekadence, Desire, FHI,
''@@@@@@''''''''@@@@@'''@@@@@@@@@@@@@@@@@@''    Fulcrum, Hprg, LJ, Nuance,
'''@@@@'''''''''@@@@''''@@@@@@@@@@@@@@@@@@''    PVM, Rabenauge, Skyrunner,
''''''''''''''''''''''''''''''''''''''''''''	Titan & everybody we forgot!
*/

#define USE_MINIMIZED

// #define v iChannelTime[0]
// #define v (mod(iTime, 109.0)) // Spotet compilation issues recently
#define v iTime
#define l iResolution

#define PI 3.1415
#define F gl_FragCoord
#define O (min(iFrame,0))
#define N normalize
#define M(v)smoothstep(0.,1.,v)
#define C(v)clamp(v,0.,1.)

#ifdef USE_MINIMIZED

    #define S float
    #define W vec2
    #define V vec3
    #define I int[]
    #define J S[]


    int m=-1;

    S i=1.,
      x=0.,
      y=0.,
      z=1e+09;

    V a=V(1,-1,0),
      s=V(0,.9,0),
      r=V(60,2,2.5),
      e=V(1.2,.3,.1);

    W // l=W(1920,1080),
      p=W(1e+09);

    mat2 n(S m)
    {
      S y=sin(m),
        x=cos(m);
      return mat2(x,y,-y,x);
    }
    S t(S x)
    {
      return x*exp(1.-x);
    }
    S h(W x)
    {
      return fract(sin(dot(x,W(12.9898,78.233)))*43758.5);
    }
    S w(W m)
    {
      W x=floor(m),
        z=fract(m),
         p=z*z*(3.-2.*z);

      S y=h(x),
        e=h(x+a.xz),
        i=h(x+a.zx),
        s=h(x+a.xx);

      return mix(y,e,p.x)+(i-y)*p.y*(1.-p.x)+(s-e)*p.x*p.y;
    }
    S d(W x)
    {
      return.5*w(x)+.25*w(2.*x)+.125*w(4.*x);
    }
    S d(S x,S m,S z)
    {
      S y=C(.5+.5*(m-x)/z);
      return mix(m,x,y)-z*y*(1.-y);
    }
    S h(V x,V m,V y)
    {
      V p=step(m-y,x)-step(m+y,x);
      return p.x*p.y*p.z;
    }
    S d(V x,V y)
    {
      V m=abs(x)-y;
      return length(max(m,0.))+min(max(m.x,max(m.y,m.z)),0.);
    }
    S h(V m,V x)
    {
      S y=length(m/x);
      return y*(y-1.)/length(m/(x*x));
    }
    W n(W y,W x)
    {
      return y.x<x.x?y:x;
    }
    V t(V x,S m)
    {
      return x.xy*=n(m),x;
    }
    W P(V m)
    {
      V i=m;
      i.z=abs(abs(i.z)-.3);
      p.x=min(p.x,length(i-V(.87,.28,.05))-.045);
      W y=W(p.x,5);
      V e=m;
      if(x<9.)
        e.x=mod(e.x+4.,8.)-4.,e.z=mod(e.z+1.,2.)-1.,y=n(y,vec2(h(e,vec3(1.2,.6,.6)),4));
      else
        {
          if(h(m,V(0,.5,0),V(2.4,1.,1.5))>.5)
            {
              V r=e;
              r.xz=abs(r.xz);
              r-=V(.6,.15,.4);
              p.y=min(p.y,d(e-V(-.9,.3,0),V(.1,.02,.3))-.03);
              S z=d(max(h(abs(e-V(-.2,.2,0)),V(1.3,.3,1.)),d(e-V(0,.2,0),V(1.3,.08,.34))-.1),mix(h(t(e,.2)-V(-.45,.3,0),V(.6,.2,.35)),d(t(e,.2)-V(-.45,.3,0),V(.6,.3,.35))-.1,.3)-.05,.04),s=max(length(r.xy)-.16,abs(r.z)-.11);
              y=n(y,n(W(max(-length(r-.1*a.zzx)+.12,s),3),W(max(max(max(max(-s+.02,max(z-.04,d(s,z,.17))),-t(e,.1*PI).x-.85),-e.y+.05),-d(e-vec3(1,.28,0),vec3(.15,.04,.4))),4)));
            }
          V r=m-V(-12.*x+666.48,1,0);
          r.xz*=n(8.*x);
          mat2 z=n(.25*PI);
          r.yz*=z;
          r.xy*=z;
          S s=d(r,V(.5));
          p.y=min(p.y,s);
          V l=m-V(-.9,-.45,0);
          l.z=abs(l.z);
          l-=V(-.02,0,.3-.01*cos(2.*l.x+28.*x));
          p.y=min(p.y,d(l-V(-20,.75,-.05),V(20,.01,.06)));
          y=n(y,W(p.y,4));
        }
      m.x+=12.*x;
      V r=m;
      r.z=abs(r.z);
      r.x=mod(r.x+1.5,3.)-1.5;
      y=n(y,W(min(d(r-V(0,-.095,.7),V(.5,.1,.06)),d(r-V(0,-.095,2.1),V(1.5,.1,.06))),6));
      if(abs(m.z)>2.)
        y=n(y,W(m.y-d(m.xz)*.2*M((abs(m.z)-2.2)/.4)-d(m.xz*.1)*4.*M((abs(m.z)-2.6)/7.4)*M((x-18.)/10.),2));
      return y;
    }
    W P(V x,V y,V z)
    {
      V m=1./y,e=m*x,
        s=abs(m)*z,
        p=-e-s,
        r=-e+s;
      return W(max(max(p.x,p.y),p.z),min(min(r.x,r.y),r.z));
    }
    W P(V m,V x)
    {
      if(i>.5)
        r.yz=W(4,30);
      W y=W(1e+09,-1),
        p=P(m-s,x,r),
        e;
      S z=.1,
        a=90.,
        l=-m.y/x.y,
        d;

      if(l>0.)
        a=min(a,l),
        y=W(l,0);

      if(p.x<p.y&&p.y>0.&&p.x<a)
        {
          d=z=max(p.x,z);
          if(i<.5)
            y=n(y,W(p.y,1));
          for(int o=O;o<128&&d<min(p.y,a);o++)
            {
              e=P(m+x*d);
              if(e.x<.0001*d)
                {
                  y=W(d,e.y);
                  break;
                }
              d+=e.x;
            }
        }
      return y;
    }
    V g(V x)
    {
      W m=W(1,-1)*.002;
      return N(m.xyy*P(x+m.xyy).x+m.yyx*P(x+m.yyx).x+m.yxy*P(x+m.yxy).x+m.xxx*P(x+m.xxx).x);
    }
    V g(V m,V x)
    {
      S y=1.-abs(atan(m.z,m.x)/2.*PI);
      return mix(mix(.1*a.zzx*max(5.*m.y+.3,0.)+(.2*M((y-.9)/.1)*(e-.2)+2.*M((y-.99)/.01)*e)*(10.*max(0.,m.y)),V(0),step(m.y,.03*d(-20.*m.xz)))+.5*pow(max(0.,m.y),8.)*e,.01*e,step(m.y,.07*d(-10.*m.xz)));
    }
    I c=I(12,-1,13,-1,0,1,2,3,4,5,6,7,8,0,10,11,9,4,3,14,5,6,4,3,7,-1);
    J o=J(3.,5.,6.,7.,9.,11.,16.,21.85,26.,27.,27.9,32.,40.,54.,54.5,55.,55.5,66.,67.,74.,82.,83.,90.,91.,96.,106.),
      u=J(2.,4.,1.2,-2.,20.,20.,2.5,0.,-7.,4.,12.,20.,30.,40.,-2.),
      b=J(.1,.2,1.,1.2,.2,2.2,1.5,30.,1.5,1.2,.2,1.,1.,5.,1.2),
      k=J(-.3,-.1,-8.,-1.5,-1.5,.7,3.,2.,1.5,-3.5,-.1,-6.,-4.,-.3,0.),
      Z=J(20.,0.,1.7,1.,0.,0.,.7,4.,5.,0.,0.,0.,30.,43.,1.),
      Y=J(0.,-.2,-.2,-.5,-50.,-50.,-.1,-8.,-.5,-.05,-25.,-50.,-25.,-30.,-.3),
      X=J(-5.,0.,-.3,-.2,0.,0.,-.1,-1.,.5,-.05,0.,0.,-25.,-30.2,-.1);

    void mainImage(out vec4 f, in vec2 fragCoord)
    {   
      f = a.zzzx;

      W r=(-l.xy+2.*F.xy)/l.y,
        w=F.xy/l.xy,
        U;

      if(abs(r.y)>.74) return;

      // x=S(v)/44100.+h(F.xy)*.04;  
      x=v+h(F.xy)*.04; 

      if (iMouse.xy==vec2(0) && iFrame==0) // miniature
        x=88.+h(F.xy)*.04;

      i=x>55.5&&x<91.?0.:1.;  
      V T=V(0.,.1,0),R,Q,L,K,H,G,E,D;
      R=Q=L=K=H=G=E=D=V(0);
      for(int B=O;B<o.length();++B)
        {
          if(x>=o[B])
            {
              y=x-o[B];
              m=c[B];
              if(m>=0)
                R=V(u[m],b[m],k[m]),T.x=Z[m],Q.x=Y[m],L.x=X[m];
            }
        }
      if(m==-1)
        return;
      R+=Q*y;
      T+=L*y;
      R.y+=.01*h(a.xx*100.*x);
      r+=4.*dot(r,r)*h(F.xy+x)/l.xy;
      V B=N(T-R),
        A=N(cross(B,a.zxz)),
        q=cross(A,B),
        j=mat3(A,q,B)*N(V(r,4)),
        ab=g(j,R),
        ac=V(1),
        ad=V(2,.5,0);

      p=a.xx*1e+09;
      for(int ae=O;ae<3;++ae)
        {
          U=P(R,j);
          if(ae==0)
            z=U.x;
          if(U.y<0.)
            {
              K+=g(j,R)*ac;
              break;
            }
          H=R+U.x*j;
          G=U.y<1.5?U.y<.5?a.zxz:V(0,N(s.yz-H.yz)):g(H);
          W af=M((abs(fract(1.5*H.yz+.5)*2.-1.)-.1)/.02),
            ag=M((abs(fract(1.5*H.yz+.5)*2.-1.)-.05)/.05);
          S ah=pow(dot(G,j)+1.,.2),
            ai=exp2(min(0.,P(H+G*.07).x/.07-1.))*exp2(min(0.,P(H+G*.15).x/.15-1.))*exp2(min(0.,P(H+G*.3).x/.3-1.)),
            aj=pow(t(10.*fract(.92*x)),8.),ak=1.-C(floor(2.*fract(.1*(H.x+12.*x)))),
            al=1.-min(af.x,af.y),am=1.-min(ag.x,ag.y);		
          E=V(.1);
          if(U.y==0.)
            E*=.1*d((H.xz+12.*a.xz*x)*W(4,80)),ah*=.1;
          D=(ai+80.*V(0,.5,1)/pow(length(ad-H),.1)*M(dot(N(ad-H),-N(V(1,-5,0)))-.1/1.5))*E;
          if(U.y==1.)
            H.yz*=n(.2*floor(5.*x)*step(60.,x)),D+=2.-2.*C(floor(10.*fract(.05*(H.x+12.*x))))+5.*ak*(aj*al*step(60.,x)+am*step(70.,x))*mix(V(1),
            am*mix(e.zyx,a.xzz,ak),M((x-75.)/5.));
          if(U.y==4.)
            D+=e*pow(max(0.,G.y),3.)*M(d(600.*H.xz)*4.-2.);
          K+=(1.-ah)*D*ac;
          ac*=ah;
          j=reflect(j,G);
          R=H+.001*j;
        }
      p=.5*exp(-p*10.);
      w*=1.-w.yx;
      f=vec4(pow((mix(mix(ab,K+e.zyx*p.x+e*p.y,exp(-.001*z*z)),e,.02*(1.-exp(-.001*z*z)))+V(t(max(0.,10.*(x-55.5))))+V(t(max(0.,10.*(x-91.)))))*pow(w.x*w.y*15.,.5),V(.4545)),1.);
    }

#else // USE_MINIMIZED

    int tid = -1;

    float gOpen	= 1.,
          gTime	= 0.,
          tdiff = 0.,
          tt	= 10e8;

    vec3  r			  	= vec3(  1, -1, 0  ),
          gBoundsPos  	= vec3(  0, .9, 0  ),
          gBoundsSize 	= vec3( 60,  2, 2.5),
          LINE_COLOR  	= vec3( 1.2, .3, .1);

    vec2 // R			= vec2(1920, 1080),
         gBloom		= vec2(10e8);

    mat2 rot(float a)
    {
        float s = sin(a),
          c = cos(a);
        return mat2(c, s, -s, c);
    }

    float impulse(float k)
    {
        return k * exp(1. - k);
    }

    float hash(vec2 p)
    {
        return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
    }

    float noise(vec2 p)
    {
        vec2 i = floor(p),
             f = fract(p), 
             u = f * f * (3. - 2. * f);

        float a = hash(i), 
              b = hash(i + r.xz),
              c = hash(i + r.zx),
              d = hash(i + r.xx);  

        return mix(a, b, u.x) +
                (c - a) * u.y * (1. - u.x) +
                (d - b) * u.x * u.y;
    }

    float fbm(vec2 x)
    {
        return + .5   * noise(     x)
               + .25  * noise(2. * x)
               + .125 * noise(4. * x);
    }

    float smin(float a, float b, float k)
    {
        float h = C(.5+.5*(b - a) / k);
        return mix(b, a, h) - k * h * (1. - h);
    }

    float insideBox3D(vec3 p, vec3 center, vec3 size)
    {
        vec3 s = step(center - size, p) - step(center + size, p);
        return s.x * s.y * s.z;
    }

    float sdBox(vec3 p, vec3 b)
    {
        vec3 d = abs(p) - b;
        return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.);
    }

    float sdEll(vec3 p, vec3 r)
    {
        float k0 = length(p / r);
        return k0 * (k0 - 1.) / length(p / (r * r));
    }

    vec2 opU(vec2 d1, vec2 d2)
    {
        return d1.x < d2.x ? d1 : d2;
    }

    vec3 rotXY(vec3 p, float a)
    {
        p.xy *= rot(a);
        return p;
    }

    vec2 map(vec3 pos)
    {
        // car light
        vec3 pR = pos;
        pR.z = abs(abs(pR.z) - 0.3);
        gBloom.x = min(gBloom.x, length(pR - vec3(.87, 0.28, 0.05)) - .045);
        vec2 res = vec2(gBloom.x, 5);

        vec3 pC = pos;
        if (gTime < 9.) // gTStart
        {
            pC.x = mod(pC.x + 4.0, 8.0) - 4.0;
            pC.z = mod(pC.z + 1.0, 2.0) - 1.0;
            res = opU(res, vec2(sdEll(pC, vec3(1.2, .6, .6)), 4));
        }
        else
        {
            if (insideBox3D(pos, vec3(0, .5, 0), vec3(2.4, 1., 1.5)) > .5)
            {
                vec3 pW = pC;

                pW.xz = abs(pW.xz);
                pW -= vec3(.6, .15, .4);

                gBloom.y = min(gBloom.y, sdBox(pC - vec3(-0.9, 0.3, 0), vec3(0.1, 0.02, 0.3)) - 0.03);

                float sBody0 = smin(
                                max(
                                    sdEll(abs(pC - vec3(-0.2, 0.2, 0)), vec3(1.3, 0.3, 1.)),
                                    sdBox(pC - vec3(0, 0.2, 0), vec3(1.3, 0.08, 0.34)) - .1
                                ), mix(
                                    sdEll(rotXY(pC, 0.2) - vec3(-0.45, 0.3, 0), vec3(0.6, 0.2, 0.35)),
                                    sdBox(rotXY(pC, 0.2) - vec3(-0.45, 0.3, 0), vec3(0.6, 0.3, 0.35)) - .1,
                                    0.3) - 0.05,
                            0.04),
                    sWheels0 = max(length(pW.xy) - 0.16, abs(pW.z) - 0.11);

                res = opU( 
                        res,
                        opU(
                            vec2( max(-length(pW - .1 * r.zzx) + .12, sWheels0), 3),
                            vec2( max(
                                    max(
                                        max(
                                            max(
                                                -sWheels0 + .02,
                                                max(
                                                    sBody0 - .04, 
                                                    smin(sWheels0, sBody0, .17)
                                                )
                                            ),
                                        -rotXY(pC, .1 * PI).x - .85),
                                        -pC.y + .05
                                    ),
                                    -sdBox(pC -vec3(1, .28, 0), vec3(.15, .04, .4))
                                ),
                                4
                            )
                        )
                    );
            }

            // orb
            vec3 pB = pos - vec3(-12. * gTime + 666.48, 1, 0); // gTTunel
            pB.xz *= rot(8. * gTime);
            mat2 r2 = rot(.25 * PI);
            pB.yz *= r2;
            pB.xy *= r2;
            float box0 = sdBox(pB, vec3(.5));
            gBloom.y = min(gBloom.y, box0);

            // trail
            vec3 pT = pos - vec3(-.9, -.45, 0);
            pT.z = abs(pT.z);
            pT -= vec3(-.02, 0, .3 -.01 * cos( 2.*pT.x+28.*gTime ));
            gBloom.y = min(gBloom.y, sdBox(pT - vec3(-20, .75, -.05), vec3(20, .01, .06)));
            res = opU(res, vec2(gBloom.y, 4));
        }

        pos.x += 12. * gTime;
        // lanes
        vec3 pL = pos;
        pL.z = abs(pL.z);
        pL.x = mod(pL.x + 1.5, 3.) - 1.5;
        res = opU(res, vec2(
                min(sdBox(pL - vec3(0, -.095,  .7), vec3( .5, .1, .06)),
                    sdBox(pL - vec3(0, -.095, 2.1), vec3(1.5, .1, .06))),
                 6));

        // ground
        if (abs(pos.z) > 2.)
        {
            res = opU(res, vec2(
                        pos.y
                        - fbm(pos.xz     ) *  .2 * M((abs(pos.z) - 2.2) /  .4)
                        - fbm(pos.xz * .1) * 4.  * M((abs(pos.z) - 2.6) / 7.4) * M((gTime - 18.)/10.),
                        2));
        }

        return res;
    }

    vec2 iBox(vec3 ro, vec3 rd, vec3 rad)
    {
        vec3 m = 1. / rd,
          n = m * ro,
          k = abs(m) * rad,
          t1 = -n - k,
          t2 = -n + k;
        return vec2(max(max(t1.x, t1.y), t1.z),
                 min(min(t2.x, t2.y), t2.z));
    }

    vec2 castRay(vec3 ro, vec3 rd)
    {
        if (gOpen > .5)
            gBoundsSize.yz = vec2(4, 30);

        vec2 res = vec2(10e8, -1),
             tb = iBox(ro - gBoundsPos, rd, gBoundsSize),
             h;

        float tmin =  .1,
              tmax = 90.,
              tp1 = -ro.y / rd.y,
              t;

        // raytrace floor plane
        if (tp1 > 0.)
        {
            tmax = min(tmax, tp1);
            res = vec2(tp1, 0);
        }    

        // raymarch primitives   
        if (tb.x < tb.y && tb.y > 0. && tb.x < tmax)
        {
            t = tmin = max(tb.x, tmin);
            if (gOpen < .5)
                res = opU(res, vec2(tb.y, 1));

            for (int i = O; i < 128 && t < min(tb.y, tmax); i++)
            {
                h = map(ro + rd * t);
                if (h.x < (.0001 * t))
                {
                    res = vec2(t, h.y);
                    break;
                }
                t += h.x;
            }
        }

        return res;
    }

    vec3 calcNormal(vec3 pos)
    { // https://iquilezles.org/articles/normalsSDF
       vec2 e = vec2(1, -1) * .002;
       return N(e.xyy * map(pos + e.xyy).x +
                e.yyx * map(pos + e.yyx).x +
                e.yxy * map(pos + e.yxy).x +
                e.xxx * map(pos + e.xxx).x);
    }

    vec3 sky(vec3 rd, vec3 ro)
    {    
        float angle = 1. - abs(atan(rd.z, rd.x) / 2. * PI);
        return mix(
                mix(
                        .1 * r.zzx * max(5. * rd.y + .3, 0.)								// bg
                            + (    .2 * M((angle - .9 )/.1 ) * (LINE_COLOR - .2)			// line glow
                                + 2.  * M((angle - .99)/.01) *  LINE_COLOR      )			// line
                                * (10. * max(0., rd.y)),									// line scale and bottom up gradient
                        vec3(0),															// distant mountains shape color
                        step(rd.y, .03 * fbm(-20. * rd.xz))								    // distant mountains shape
                    ) 
                    + .5 * pow(max(0., rd.y), 8.) * LINE_COLOR,								// dome light
                .01 * LINE_COLOR,
                step(rd.y, .07*fbm(-10.*rd.xz))
            );
    }

    //             		       0,    1,    2,    3,    4,    5,    6,    7,    8,    9,    10,   11,   12,   13,    14,   15,   16,   17,   18,   19,   20,   21,   22,	  23,   24,    25
    int[] 	tids = int[](     12,   -1,   13,   -1,    0,    1,    2,    3,    4,    5,     6,    7,    8,    0,    10,   11,    9,    4,    3,   14,    5,    6,    4,    3,    7,   -1);
    float[] time = float[](  3.0,  5.0,  6.0,  7.0,  9.0, 11.0, 16.0, 21.85, 26.0, 27.0,  27.9, 32.0, 40.0, 54.0,  54.5, 55.0, 55.5, 66.0, 67.0, 74.0, 82.0, 83.0, 90.0, 91.0, 96.0, 106.), // 100.0
            rox  = float[](  2.0,  4.0,  1.2, -2.0, 20.0, 20.0,  2.5,  0.0, -7.0,  4.0,  12.0, 20.0, 30.0, 40.0, -2.0),
            roy  = float[](  0.1,  0.2,  1.0,  1.2,  0.2,  2.2,  1.5, 30.0,  1.5,  1.2,   0.2,  1.0,  1.0,  5.0,  1.2),
            roz  = float[]( -0.3, -0.1, -8.0, -1.5, -1.5,  0.7,  3.0,  2.0,  1.5, -3.5,  -0.1, -6.0, -4.0, -0.3,  0.0),
            tax  = float[]( 20.0,  0.0,  1.7,  1.0,  0.0,  0.0,  0.7,  4.0,  5.0,  0.0,   0.0,  0.0, 30.0, 43.0,  1.0),
            roxm = float[](  0.0, -0.2, -0.2, -0.5,-50.0,-50.0, -0.1, -8.0, -0.5, -0.05,-25.0,-50.0,-25.0,-30.0, -0.3),
            taxm = float[]( -5.0,  0.0, -0.3, -0.2,  0.0,  0.0, -0.1, -1.0,  0.5, -0.05,  0.0,  0.0,-25.0,-30.2, -0.1);
    //                         0,    1,    2,    3,    4,    5,    6,    7,    8,    9,    10,   11,   12,   13,    14,   15,   16,   17,   18,   19,   20,   21,   22,	  23,   24,    25

    // void main()
    void mainImage(out vec4 f, in vec2 fragCoord)
    {
        vec2 p = (-l.xy + 2. * F.xy) / l.y;
        vec2 q = F.xy / l.xy;
        vec2 res;

        if (abs(p.y) > 0.74) return;

        gTime = v + (hash(F.xy)*.04);
        gOpen = gTime > 55.5 && gTime < 91. ? 0.0 : 1.0; // gTTunel, gTEnd

        vec3 ta = vec3(0.,.1,0),
          ro, rom, tam,  col,  pos,  nor,  alb,  rad;
        ro = rom = tam = col = pos = nor = alb = rad = vec3(0);

        for (int ti = O; ti < time.length(); ++ti)
        {
            if (gTime >= time[ti])
            {
                tdiff = gTime - time[ti];
                tid = tids[ti];
                if (tid >= 0)
                {
                    ro = vec3(rox[tid], roy[tid], roz[tid]);
                    ta.x = tax[tid];
                    rom.x = roxm[tid];
                    tam.x = taxm[tid];
                }
            }
        }
        if (tid == -1) return;
        ro += rom * tdiff;
        ta += tam * tdiff;
        ro.y += 0.01 * hash(r.xx * 100. * gTime);
        p += 4.*dot(p,p)*(hash(F.xy+gTime))/l.xy;

        vec3 cw = N(ta - ro);
        vec3 cu = N(cross(cw, r.zxz));
        vec3 cv = cross(cu, cw);
        vec3 rd = mat3(cu, cv, cw) * N(vec3(p, 4));
        vec3 bg = sky(rd, ro);
        vec3 tint = vec3(1);
        vec3 pSpot = vec3(2, .5, 0);

        gBloom = r.xx*10e8;
        for (int bi = O; bi < 3; ++bi)
        {
            res = castRay(ro, rd);

            if (bi == 0)
            {
                tt = res.x;
            }

            if (res.y < .0)
            {
                col += sky(rd, ro) * tint;
                break;
            }

            pos = ro + res.x * rd;
            nor = (res.y < 1.5)
                ? (res.y < 0.5)
                    ? r.zxz
                    : vec3(0, N(gBoundsPos.yz - pos.yz))
                : calcNormal(pos);

            vec2 str0 = M( ( abs(fract(1.5*pos.yz+0.5)*2.-1.) -.1 ) /.02 );
            vec2 str1 = M( ( abs(fract(1.5*pos.yz+0.5)*2.-1.) -.05) /.05 );

            float fre = pow(dot(nor, rd) + 1., .2),
              ao = 1. 
                * exp2(min(0., map(pos + nor * .07).x / .07 - 1.))
                * exp2(min(0., map(pos + nor * .15).x / .15 - 1.))
                * exp2(min(0., map(pos + nor * .3 ).x / .3  - 1.)),
              imp = pow( impulse(10.*fract(.92*gTime)), 8.),
              frames1 = 1. - C( floor(2. * fract(.1 *(pos.x + 12.*gTime)) ) ),		// frames
              stripes0 = 1. - min(str0.x, str0.y),									// blinking stripes
              stripes1 = 1. - min(str1.x, str1.y);									// blinking stripes              

            alb = vec3(.1);
            if (res.y == 0.)
            {
                alb *= .1 * fbm((pos.xz + 12. * r.xz * gTime) * vec2(4, 80));
                fre *= .1;
            }

            rad = (ao
                 + 80.
                    * vec3(0, .5, 1)
                    * 1. / pow( length(pSpot - pos), 0.1)
                    * M( dot( N(pSpot - pos), -N(vec3(1, -5, 0)) ) -.1 / 1.5)
                  ) * alb;

            if (res.y == 1.0)
            {
                pos.yz *= rot(0.2*floor(5.0*gTime) * step(60.0, gTime));

                rad +=  2. -2.*C( floor(10.* fract(.05*(pos.x + 12.*gTime)) ) )
                        + 5. * frames1 * (  imp * stripes0 * step(60., gTime)
                                +                 stripes1 * step(70., gTime))
                        * mix(vec3(1), stripes1 * mix(LINE_COLOR.bgr, r.xzz, frames1), M( (gTime-75.) / 5.) );
            }

            if (res.y == 4.)        
                rad += LINE_COLOR * pow(max(0.,nor.y), 3.) * M( fbm(600.*pos.xz)*4.-2. );

            col += (1. - fre) * rad * tint;
            tint *= fre;

            rd = reflect(rd, nor);
            ro = pos + .001 * rd;
        }

        gBloom = .5 * exp(-gBloom * 10.);
        q *= 1. - q.yx;

        f = vec4(pow(												// gamma start
            (	
                mix(												// air red fog
                    mix(											// horizon blend blue fog
                        bg,
                        col
                        + LINE_COLOR.bgr * gBloom.x					// bloom red
                        + LINE_COLOR     * gBloom.y,				// bloom blue
                        exp(-.001 * tt * tt)
                    ),
                    LINE_COLOR,
                    .02 * (1. - exp(-.001 * tt * tt))
                )										
                + vec3(impulse(max(0., 10. * (gTime - 55.5) )))		// collision flash
                + vec3(impulse(max(0., 10. * (gTime - 91. ) )))		// tunnel leave flash
            )
             * pow(q.x * q.y * 15., .5),							// vignette
            vec3(.4545)), 1.);										// gamma end
    }

#endif // USE_MINIMIZED