// Image (image) — Power City by fizzer
// https://www.shadertoy.com/view/ltfyD7

float box(vec3 p,vec3 o,vec3 s)
{
    p=abs(p-o)-s;
    return max(p.x,max(p.y,p.z));
}

float hash(float n)
{
    return fract(sin(n)*43758.5453);
}

float noise(vec3 p)
{
    return hash(p.x + p.y*57.0 + p.z*117.);
}

float noise(vec2 p)
{
    return hash(p.x + p.y*57.0);
}

float valnoise(vec2 p)
{
    vec2 c=floor(p);
    vec2 f=smoothstep(0.,1.,fract(p));
    return mix (mix(noise(c+vec2(0,0)), noise(c+vec2(1,0)), f.x),
                mix(noise(c+vec2(0,1)), noise(c+vec2(1,1)), f.x), f.y);
}

float dist(vec3 p)
{
    float d=1e3;

    vec3 p2=p;
    float s=1.;
    for(int i=0;i<4;++i)
    {
        p2.xz=abs(p2.xz);   
        float cl=max(max(p2.x,p2.z),dot(p2.xz,normalize(vec2(1))));
        float r=20.;
        cl=min(cl-r+1.,max(box(vec3(p2.x,mod(p2.y,10.)-5.,p2.z),vec3(0),vec3(r,6.,r)),cl-r));
        cl=max(cl,p2.y-50.+float(i)*80.);
        if(i==3)cl=max(cl,p.y+25.);
        cl/=s;
        if(i==2)cl=max(cl,dot(p.yz-vec2(0,25),normalize(vec2(1))));
        d=min(d,cl);
        p2*=2.;
        p2.xz=mod(p2.xz,100.)-50.;
        s*=2.;
    }

    p2=abs(p-vec3(74,0,-35));
    float cl=max(max(p2.x,p2.z),dot(p2.xz,normalize(vec2(1))))-6.;
    d=min(d,cl);

    p2=p;

    d=min(d,distance(p,vec3(0,50,0))-14.);

    {
        vec3 p2=p;
        p2.xz=mod(p2.xz,10.)-5.;
        p2.xz=abs(p2.xz);
        d=min(d,p.y+52.+max(p2.x,p2.z));
    }

    {
        vec3 p2=p;
        p2.xz=mod(p2.xz,80.)-40.;
        p2.xz=abs(p2.xz);
        d=min(d,p.y+41.+max(p2.x,p2.z));
    }

    d=min(d,max(p.y+15.,p.z+60.));

    d=min(d,max(box(p,vec3(0,-70,0),vec3(31)), -box(p,vec3(0,-25,0),vec3(20))));

    d=min(d,box(p,vec3(0,30,19),vec3(15,9,2)));

    d=max(d,box(p,vec3(0),vec3(85,64,67)));


    p2=p;
    for(int i=0;i<4;++i)
    {
        vec3 p3=p2;
        p2.y-=cos(float(i)*9.)*23.;
        p3.xz=min(p3.xz,1.);
        float rr=distance(p3.xz,normalize(p3.xz)*27.)-5.;
        d=min(d,max(rr,abs(p3.y)-2.));
        p2.xz=p2.zx*vec2(1,-1);
    }

    d=max(d,box(p,vec3(0),vec3(85,64,67)+40.));


    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 t = fragCoord.xy / iResolution.xy-.5;
	t.x*=iResolution.x/iResolution.y;
    t*=1.4;
    
    vec3 fog=vec3(.5,.5,1);

    vec2 p=t.xy;
    vec2 ot=t;

    vec3 backg=vec3(0.75,1,.75)/3.*exp(-length(ot.xy)/2.);

    vec3 ro=vec3(0,-20,380.);
    vec3 rd=vec3(p,-3.);


    {
        float ang=0.3-iMouse.y/iResolution.y*.5;
        ro.yz*=mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
        rd.yz*=mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
    }


    {
        float ang=0.6-iMouse.x/iResolution.x*.5;
        ro.xz*=mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
        rd.xz*=mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
    }

    ro+=rd*90.;

    vec3 co=ro;
    rd=normalize(rd);
    vec3 ord=rd;

    vec3 f=vec3(1.),a=vec3(0.);
    float s=1.;
    vec3 n;
    for(int j=0;j<6;++j)
    {
        vec3 oro=ro;

        float t=0.;
        for(int i=0;i<20;++i)
        {
            ro=oro+rd*t;
            float d=dist(ro);
            if(d<1.-4.)
            {
                break;
            }
            t+=d;
        }
        if(t>200.)
        {
            fragColor.rgb=backg;
            fragColor.rgb+=noise(gl_FragCoord.xy)/200.;

            return;
        }



        oro=ro;
        vec3 c=floor(ro);
        vec3 ts=(c+max(vec3(0.),sign(rd))-ro)/rd;

        for(int i=0;i<25;++i)
        {
            n=step(ts,ts.yzx)*step(ts,ts.zxy);
            c+=sign(rd)*n;
            float d=dist(c);
            vec3 dd=sign(rd)/rd*n;
            if(d<-1.7)
            {
                ro=oro+rd*min(ts.x,min(ts.y,ts.z));
                break;
            }
            ts+=dd;
        }
        ro=oro+rd*min(ts.x,min(ts.y,ts.z));
    }

    float fogstrength=.0001;
    vec3 ld=normalize(vec3(6,-2,1.4));
    float sh=1.;
    {
        ro-=rd*1e-5;
        vec3 oro=ro;
        vec3 rd=ld;
        vec3 c=floor(ro);
        vec3 ts=(c+max(vec3(0.),sign(rd))-ro)/rd,n;

        for(int i=0;i<4;++i)
        {
            n=step(ts,ts.yzx)*step(ts,ts.zxy);
            c+=sign(rd)*n;
            float d=dist(c);
            vec3 dd=sign(rd)/rd*n;
            if(d<-1.7)
            {
                sh=0.;
                break;
            }
            ts+=dd;
        }
    }

    vec3 rp=floor(ro);
    fragColor.rgb=exp(-(rp.y+68.)/8.)*vec3(.5,1.,1.)*2.*mix(.8,1.,.5+.5*cos(iTime*17.));

    fragColor.rgb+=((.75+.25*dot(n*-sign(rd),ld)))*mix(.5,1.,sh)*.01;

    fragColor.rgb+=smoothstep(.96,.97,abs(cos(rp.x)*cos(rp.y+5.)*cos(rp.z)));
    fragColor.rgb+=.1*smoothstep(.96,.97,abs(cos(rp.x*8.)*cos(rp.y+5.)*cos(rp.z*9.)));

    float g=mod(rp.x+floor(rp.y/20.)*4.,40.);
    fragColor.rgb+=.01*step(abs(mod(rp.y,20.)-clamp(min(g,40.-g),10.,15.)),.5);

    if(length(rp.xz)<18.5)
        fragColor.rgb+=.003;

    fragColor.rgb+=(1.-smoothstep(0.,10.,distance(rp,vec3(0.,50.,0.))-14.))*vec3(.5,1,1)*.03;
    fragColor.rgb+=(1.-smoothstep(0.,1.,distance(rp,vec3(0.,50.,0.))-14.))*vec3(.5,1,1)*.5*clamp((rp.y-50.)/50.,0.,1.);

    if(rp.y>60.)
        fragColor.rgb+=.2;

    if(rp.y<-45.)
        fragColor.rgb+=step(.9,noise(rp))*.1;

    {
        float sd=box(rp,vec3(0,30,19),vec3(15,8,2));
        if(sd<0.)
            fragColor.rgb*=.1;
    }

    vec3 screencolor=vec3(1,1,.7);
    {
        float sd=box(rp,vec3(0,30,19),vec3(12,6,2));
        vec3 rp2=rp-vec3(0,30,19);
        if(sd<0.)
            fragColor.rgb+=.5*step(1.,abs(mod(rp2.y-cos(rp2.x/1.5+iTime)*2.,5.)))*screencolor;
    }

    fragColor.rgb+=mix(.8,1.,.5+.5*cos(iTime*7.))*screencolor*10./pow(distance(rp,vec3(0,30,15)),2.)*smoothstep(0.,16.,rp.z-17.);


    float fogamount=exp(-distance(ro,co)*fogstrength/3.);
    fragColor.rgb=mix(vec3(.5,1,.5),fragColor.rgb,fogamount);

    fragColor.rgb=sqrt(fragColor.rgb)*1.5;

    fragColor.rgb=mix(fragColor.rgb,backg,smoothstep(105.,125.,length(rp.xz)));

    fragColor.rgb+=noise(gl_FragCoord.xy)/200.;

}