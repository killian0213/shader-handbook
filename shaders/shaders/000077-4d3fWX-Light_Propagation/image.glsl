// Image (image) — Light Propagation by Mathis
// https://www.shadertoy.com/view/4d3fWX

//Light Propagation Volumes with anisotropic voxels

float Schlick(float R0, float COS) {
    //Schlick approximation
    return R0+(1.-R0)*pow(1.-COS,5.);
}

vec4 MIXL(vec2 f, vec2 bvt, out vec3 NC) {
    vec3 C12,C22,C32,C42;
    vec4 CC1=texture(iChannel1,bvt*ires);
    vec4 CC2=texture(iChannel1,(bvt+vec2(1.,0.))*ires);
    vec4 CC3=texture(iChannel1,(bvt+vec2(0.,1.))*ires);
    vec4 CC4=texture(iChannel1,(bvt+vec2(1.,1.))*ires);
    vec3 C11=ReadV(CC1.xyz,C12);
    vec3 C21=ReadV(CC2.xyz,C22);
    vec3 C31=ReadV(CC3.xyz,C32);
    vec3 C41=ReadV(CC4.xyz,C42);
    NC=mix(mix(C12*(1.-CC1.w),C22*(1.-CC2.w),f.x),mix(C32*(1.-CC3.w),C42*(1.-CC4.w),f.x),f.y);
    return vec4(mix(mix(C11*(1.-CC1.w),C21*(1.-CC2.w),f.x),mix(C31*(1.-CC3.w),C41*(1.-CC4.w),f.x),f.y),
        mix(mix((1.-CC1.w),(1.-CC2.w),f.x),mix((1.-CC3.w),(1.-CC4.w),f.x),f.y)+0.01);
}

vec3 MIX(vec3 f, vec2 bvt1, vec2 bvt2, out vec3 NC) {
    /*
	//Nearest
    vec3 C=ReadV(texture(iChannel1,bvt1*ires).xyz,NC);
    return C;
	//*/
    
    //*
    //Linear
	vec3 NC1,NC2;
    vec4 PC1=MIXL(f.xy,bvt1,NC1);
    vec4 PC2=MIXL(f.xy,bvt2,NC2);
    NC=mix(NC1.xyz,NC2.xyz,f.z)/mix(PC1.w,PC2.w,f.z);
    return mix(PC1.xyz,PC2.xyz,f.z)/mix(PC1.w,PC2.w,f.z);
	//*/
}

vec3 SampleLPV(vec3 P, vec3 N) {
    vec3 f=fract(P-vec3(0.5,0.5,0.5));
    vec2 pvt1=PToUV(P+vec3(-0.5,-0.5,-0.5));
    vec2 pvt2=PToUV(P+vec3(-0.5,-0.5,0.5));
    vec3 vDS=N.xyz*N.xyz;
    vec3 xC,yC,zC,CC;
    xC=MIX(f,pvt1,pvt2,CC); xC=((N.x>0.)?xC:CC);
    yC=MIX(f,pvt1+vec2(0.,64.),pvt2+vec2(0.,64.),CC); yC=((N.y>0.)?yC:CC);
    zC=MIX(f,pvt1+vec2(0.,128.),pvt2+vec2(0.,128.),CC); zC=((N.z>0.)?zC:CC);
    return xC*vDS.x+yC*vDS.y+zC*vDS.z;
}

vec3 Integral(vec3 P, vec3 N) {
    vec3 Tann,Bitt;
    Tann=NT(N,Bitt);
    return SampleLPV(P,N).xyz*SAFram+
    (SampleLPV(P,Bitt).xyz+SampleLPV(P,-Bitt).xyz+
    SampleLPV(P,Tann).xyz+SampleLPV(P,-Tann).xyz)*SASida;
}

bool SRay(vec3 pos, vec3 dir, out Hit R) {
    vec3 IDir=1./dir; vec3 fp,lfp; vec4 C;
    float FAR=boxfar(pos,1./dir,vec3(0.),vec3(32.));
    float dist=0.;
    bool OUTSIDE=Box(pos,vec3(32.))>0.;
    if (OUTSIDE) {
        vec2 B=box(pos,1./dir,vec3(0.),vec3(32.));
        if (B.x>0. && B.y>B.x) {
            dist=B.x+0.01;
        } else {
            return false;
        }
    } else {
        //Initial voxel
        fp=floor(pos);
        dist+=boxfar(pos,IDir,fp,fp+1.)+0.0001;
        lfp=fp;
    }
    //Ray tracing
    for (int i=0; i<100; i++) {
        if (dist>FAR) break;
        R.P=pos+dir*dist;
        fp=floor(R.P);
        C=texture(iChannel0,(PToUV(R.P)+vec2(0.,1.))*ires);
        if (C.w>0.) {
            R.D=dist;
            R.N=lfp-fp;
            R.C=((OUTSIDE && i==0)?vec3(0.):C.xyz);
            R.Mat=C.w-1.;
            return true;
        }
        dist+=boxfar(R.P,IDir,fp,fp+1.)+0.0001;
        lfp=fp;
    }
    return false;
}

vec3 DirectLight(vec3 P, vec3 N, vec3 LD) {
    float SunDot=dot(LD,N); Hit Shad;
    return ((SunDot<0.)?vec3(0.):SunColor*(SunDot*0.8*(1.-float(SRay(P,LD,Shad)))));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
//Light direction
    vec3 LD=texture(iChannel0,vec2(5.5,0.5)*ires).xyz;
//Camera
    vec2 uv=fragCoord.xy/iResolution.xy;
    float Rot=-(iMouse.x/iResolution.x)*3.14*3.;
	vec3 Pos=texture(iChannel0,vec2(3.5,0.5)*ires).xyz;
    mat3 MM=TBN(texture(iChannel0,vec2(2.5,0.5)*ires).xyz);
    vec3 Dir=normalize(vec3((uv*2.-1.)*(Aspect*1.1),1.)*MM);
//Trace
    vec3 Color=vec3(0.);
    Hit Pixel;
    if (SRay(Pos,Dir,Pixel)) {
        if (Pixel.Mat==1.) {
            Color=Pixel.C;
        } else {
            //Normal map
            vec2 RV=mix(texture(iChannel3,(((Pixel.P.xz+vec2(0.,floor(Pixel.P.y*10.)*71.))*10.)+0.5)/1024.).xz,
                texture(iChannel3,(((Pixel.P.xz+vec2(0.,floor(Pixel.P.y*10.+1.)*71.))*10.)+0.5)/1024.).xz,
                fract(Pixel.P.y*10.))*vec2(3.14159*2.,1.);
            vec3 NN=normalize(vec3(vec2(sin(RV.x),cos(RV.x))*RV.y,0.)*TBN(Pixel.N)*0.1+Pixel.N);
            //Direct Light
            Color=DirectLight(Pixel.P+Pixel.N*0.01,Pixel.N,LD);
            //Indirect Light
            Color+=Integral(Pixel.P+Pixel.N*0.5,-NN);
            //Reflections
            vec3 RC=vec3(0.);
            vec3 RD=reflect(Dir,NN);
            if (dot(Pixel.N,RD)<0.) RD=reflect(RD,Pixel.N);
            vec3 RP=Pixel.P+Pixel.N*0.01;
            Hit RHit;
            if (SRay(RP,RD,RHit)) {
                if (RHit.Mat==1.) {
                    RC=RHit.C;
                } else {
                    RC=DirectLight(RHit.P,RHit.N,LD);
                    //Indirect Light
                    RC+=Integral(RHit.P+RHit.N*0.5,-RHit.N);
                    RC*=RHit.C;
                }
            } else  {
                RC=SkyColor*(-RD.y*0.5+1.)+SunColor*pow(max(0.,dot(LD,RD)),24.);
            }
            Color=mix(Color,RC,Schlick(0.05,dot(-Dir,Pixel.N)));
            //Color
            Color=Color*Pixel.C;
        }
    } else {
        Color=SkyColor*(1.-Dir.y*0.5)+SunColor*pow(max(0.,dot(LD,Dir)),24.);
    }
    //Color=ReadVP(texture(iChannel1,uv).xyz);
    fragColor=vec4(pow(1.-exp(-1.3*Color),vec3(0.45)),1.0);
}