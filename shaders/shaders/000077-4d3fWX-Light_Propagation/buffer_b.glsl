// Buffer B (buffer) — Light Propagation by Mathis
// https://www.shadertoy.com/view/4d3fWX

//Indirect Light LPV

float ShadowRay(vec3 pos, vec3 dir) {
    vec3 IDir=1./dir; vec3 cp,fp; vec4 C;
    float dist=0.;
    float FAR=boxfar(pos,1./dir,vec3(0.),vec3(32.));
    for (int i=0; i<48; i++) {
        if (dist>FAR) break;
        cp=pos+dir*dist;
        fp=floor(cp);
        C=texture(iChannel0,(PToUV(cp)+vec2(0.,1.))*ires);
        if (C.w>0.) return 0.;
        dist+=boxfar(cp,IDir,fp,fp+1.)+0.001;
    }
    return 1.;
}

vec3 PropagateAXIS(vec3 P, vec4 N, vec4 Tan, vec4 Bit, out vec3 LightN) {
    vec2 CUV; vec3 LightP=vec3(0.); vec3 CYN,CXN,CYP,CXP; vec4 CC; vec3 BCN=vec3(0.);
    //Negative
    if (Box(P+N.xyz,vec3(32.))<0.) {
        CUV=PToUV(P+N.xyz);
        CC=texture(iChannel1,(CUV+vec2(0.,N.w))*ires);
        LightN+=ReadVN(CC.xyz)*(CC.w*(1.-SAFram)+SAFram);
        CYP=ReadV(texture(iChannel1,(CUV+vec2(0.,Tan.w))*ires).xyz,CYN);
        CXP=ReadV(texture(iChannel1,(CUV+vec2(0.,Bit.w))*ires).xyz,CXN);
        LightN+=(CYP+CYN+CXP+CXN)*SASida;
    	BCN=texture(iChannel0,(CUV+vec2(0.,1.))*ires).xyz;
    } else
        LightN=vec3(0.);
    //Positive
    if (Box(P-N.xyz,vec3(32.))<0.) {
        CUV=PToUV(P-N.xyz);
        CC=texture(iChannel1,(CUV+vec2(0.,N.w))*ires);
        LightP+=ReadVP(CC.xyz)*(CC.w*(1.-SAFram)+SAFram);
        CYP=ReadV(texture(iChannel1,(CUV+vec2(0.,Tan.w))*ires).xyz,CYN);
        CXP=ReadV(texture(iChannel1,(CUV+vec2(0.,Bit.w))*ires).xyz,CXN);
        LightP+=(CYP+CYN+CXP+CXN)*SASida;
    } else
        LightP=vec3(0.);
    //Add bounce light
    	LightN+=LightP*BCN*0.99;
    	LightP+=LightN*texture(iChannel0,(CUV+vec2(0.,1.))*ires).xyz*0.99;
    //Return
    return LightP;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Color=vec4(0.);
    float Occ=0.;
    vec3 CCN=vec3(0.); vec3 CCP=vec3(0.);
    if (fragCoord.x<512. && fragCoord.y<32.*6.) { //Voxelisering
        vec2 FUV=floor(fragCoord);
        vec2 uv=vec2(FUV.x+0.5,mod(FUV.y,64.)+0.5)*ires;
        //Voxel position
        float AddZ=((fract(FUV.y*i32*0.5)<0.5)?0.:16.);
        vec3 Pos=vec3(floor(fract(FUV.x*i32)*32.),floor(mod(FUV.y,32.))
                      ,floor(FUV.x*i32)+AddZ)+0.5;
        //Voxelisation
        	//One-point isotropic voxelisation
        DF VoxelColor=SDF(Pos,iTime);
        if (VoxelColor.d<VoxelisationDist) {
            Occ=(VoxelisationDist-max(0.,VoxelColor.d))/VoxelisationDist;
            //Inject direct light
            if (VoxelColor.Mat==1.) {
                 //Emissive
                Color=vec4(StoreV(VoxelColor.c,VoxelColor.c),Occ);
            } else if (VoxelColor.Mat==0.) {
                //Är väggvoxel
                
                /*
                //Binary sun-occlusion
                vec3 Normal=Offsets[int(floor(fragCoord.y/64.))];
                vec3 SunDir=texture(iChannel0,vec2(5.5,0.5)*ires).xyz;
                float SunDot=dot(SunDir,Normal);
                if (SunDot>0.)
                    CCP=SunColor*(SunDot*ShadowRay(Pos+Normal,SunDir));
               	else
                    CCN=SunColor*(-SunDot*ShadowRay(Pos-Normal,SunDir));
                Color=vec4(StoreV(CCP*VoxelColor.c,CCN*VoxelColor.c),Occ);
				//*/
                
                //*
                //Temporal sun-occlusion
                vec3 Normal=Offsets[int(floor(fragCoord.y/64.))];
                vec3 Bit; vec3 Tan=NT(Normal,Bit);
                vec2 TOffset2=Offsets2[int(mod(float(iFrame),9.))];
                vec3 TOffset3=TOffset2.x*Tan+TOffset2.y*Bit;
                vec3 SunDir=texture(iChannel0,vec2(5.5,0.5)*ires).xyz;
                float SunDot=dot(SunDir,Normal);
                if (SunDot>0.)
                    CCP=SunColor*(SunDot*ShadowRay(Pos+Normal+TOffset3,SunDir));
               	else
                    CCN=SunColor*(-SunDot*ShadowRay(Pos-Normal+TOffset3,SunDir));
                vec3 LCCN; vec3 LCCP=ReadV(texture(iChannel1,fragCoord.xy*ires).xyz,LCCN);
                Color=vec4(StoreV((CCP*VoxelColor.c+LCCP*9.)/10.,(CCN*VoxelColor.c+LCCN*9.)/10.),Occ);
				//*/
            }
        } else {
            //Propagate light
            if (fragCoord.y<64.) { //X-sidor
                CCP=PropagateAXIS(Pos,vec4(1.,0.,0.,0.),
                	vec4(0.,1.,0.,64.),vec4(0.,0.,1.,128.),CCN);
            } else if (fragCoord.y<128.) { //Y-sidor
                CCP=PropagateAXIS(Pos,vec4(0.,1.,0.,64.),
                	vec4(1.,0.,0.,0.),vec4(0.,0.,1.,128.),CCN);
        		//Injicering av skylight
            	CCP+=SkyColor*ShadowRay(Pos+vec3(0.,0.55,0.),vec3(0.,1.,0.))*0.075;
            } else { //Z-sidor
                CCP=PropagateAXIS(Pos,vec4(0.,0.,1.,128.),
                	vec4(0.,1.,0.,64.),vec4(1.,0.,0.,0.),CCN);
            }
            Color=vec4(StoreV(CCP,CCN),Occ);
        }
        fragColor=Color;
    } else fragColor=vec4(0.,0.,0.,1.);
}