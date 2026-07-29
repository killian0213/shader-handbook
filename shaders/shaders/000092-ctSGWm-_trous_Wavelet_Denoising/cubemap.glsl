// Cube A (cubemap) — Àtrous Wavelet Denoising by Mathis
// https://www.shadertoy.com/view/ctSGWm

//TAA
    //Catmull-rom by hornet: https://www.shadertoy.com/view/MtVGWz

vec4 textureCube(vec2 UV) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return texture(iChannel3,D);
}

vec3 sampleLevel0(vec2 PriorUV) {
    float YOffset = floor(PriorUV.x*I1024)*1024.+floor(PriorUV.y*I1024)*3072.;
    return textureCube(mod(PriorUV,1024.)+vec2(0.,YOffset)).xyz;
}

vec3 SampleTextureCatmullRom(vec2 uv) {
    vec2 samplePos = uv;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;
    vec2 f = samplePos - texPos1;
    vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
    vec2 w3 = f * f * (-0.5 + 0.5 * f);
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / w12;
    vec2 texPos0 = texPos1 - vec2(1.0);
    vec2 texPos3 = texPos1 + vec2(2.0);
    vec2 texPos12 = texPos1 + offset12;
    vec3 result = vec3(0.);
    result += sampleLevel0( vec2(texPos0.x,  texPos0.y)) * w0.x * w0.y;
    result += sampleLevel0( vec2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos0.y)) * w3.x * w0.y;
    result += sampleLevel0( vec2(texPos0.x,  texPos12.y)) * w0.x * w12.y;
    result += sampleLevel0( vec2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos12.y)) * w3.x * w12.y;
    result += sampleLevel0( vec2(texPos0.x,  texPos3.y)) * w0.x * w3.y;
    result += sampleLevel0( vec2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos3.y)) * w3.x * w3.y;
    return max(vec3(0.),result);
}

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir) {
    vec4 Output = vec4(0.,0.,0.,0.);
    vec2 UV; vec3 aDir = abs(rayDir);
    if (aDir.z>max(aDir.x,aDir.y)) {
        //Z-side
        UV = floor(((rayDir.xy/aDir.z)*0.5+0.5)*1024.)+0.5;
        if (rayDir.z<0.) UV.y += 1024.;
    } else if (aDir.x>aDir.y) {
        //X-side
        UV = floor(((rayDir.yz/aDir.x)*0.5+0.5)*1024.)+0.5;
        if (rayDir.x>0.) UV.y += 2048.;
        else UV.y += 3072.;
    } else {
        //Y-side
        UV = floor(((rayDir.xz/aDir.y)*0.5+0.5)*1024.)+0.5;
        if (rayDir.y>0.) UV.y += 4096.;
        else UV.y += 5120.;
    }
    vec2 RESOffset = vec2((mod(floor(UV.y*I1024)+0.5,3.)-0.5)*1024.,floor(UV.y*I1024*I3)*1024.);
    vec2 CUV = mod(UV,1024.)+RESOffset;
    if (DFBox(CUV-3.,RES-6.)<0.) {
        //Inside the screen
        vec2 BCRef = texture(iChannel0,CUV*IRES).xy;
        vec3 FinalColor = vec3(FloatToVec2(BCRef.x),FloatToVec2(BCRef.y).x)*ReflConst;
        //Reprojection
        float CurrentFrame = float(iFrame-1);
        vec2 SSOffset = SSOffsets[(iFrame-1)%16];
        float CurrentTime = texture(iChannel1,vec2(0.5,0.5)*IRES).y;
        vec4 CurrentMouse = texture(iChannel1,vec2(2.5,0.5)*IRES);
        vec3 Pos = Position(CurrentMouse,CurrentTime,IRES);
        vec3 Eye = normalize(CameraCenter(CurrentMouse,CurrentTime)-Pos);
        vec3 Tan; vec3 Bit = TBN(Eye,Tan);
        mat3 EyeMat = TBN(Eye);
        vec3 Dir = normalize(vec3(((CUV+SSOffset)*IRES*2.-1.)*CFOV*ASPECT,1.)*EyeMat);
        float Distance = texture(iChannel1,CUV*IRES).w;
        if (Distance<-0.5) Distance = 100000.; //Sky pixel
        HIT Pixel = Trace(Pos+Dir*(Distance-0.01),Dir,CurrentTime);
        vec3 Normal = normalize(FloatToVec3(texture(iChannel1,CUV*IRES).x)*2.-1.);
        vec3 PPos = Pos+Dir*Distance;
        float PriorTime = texture(iChannel1,vec2(0.5,0.5)*IRES).z;
        vec4 PriorMouse = texture(iChannel1,vec2(3.5,0.5)*IRES);
        vec3 PriorPos = Position(PriorMouse,PriorTime,IRES);
        vec3 PriorEye = normalize(CameraCenter(PriorMouse,PriorTime)-PriorPos);
        vec3 PriorTan; vec3 PriorBit = TBN(PriorEye,PriorTan);
        vec3 PriorVPos = vec3(dot(PPos-PriorPos,PriorTan),dot(PPos-PriorPos,PriorBit),dot(PPos-PriorPos,PriorEye));
        vec2 PriorUV = ((PriorVPos.xy/PriorVPos.z)*0.5/(ASPECT*CFOV)+0.5)*RES;
        if (DFBox(PriorUV-3.,RES-6.)<0.) {
            //Valid reprojection
            vec3 LFinalColor;
            if (length(PriorUV-CUV-SSOffset)>0.02) {
                //Catmull-rom sampling
                PriorUV -= SSOffsets[(iFrame-2)%16];
                LFinalColor = SampleTextureCatmullRom(PriorUV);
            } else {
                //Nearest neighbour sampling
                PriorUV = floor(PriorUV)+0.5;
                float YOffset = floor(PriorUV.x*I1024)*1024.+floor(PriorUV.y*I1024)*3072.;
                LFinalColor = textureCube(mod(PriorUV,1024.)+vec2(0.,YOffset)).xyz;
            }            
            //Clamping
            vec3 FMIN = vec3(1000.);
            vec3 FMAX = vec3(0.);
            for (float x=-1.; x<1.5; x+=1.) {
                for (float y=-1.; y<1.5; y+=1.) {
                    BCRef = texture(iChannel0,(CUV+vec2(x,y))*IRES).xy;
                    vec3 Sample = vec3(FloatToVec2(BCRef.x),FloatToVec2(BCRef.y).x)*ReflConst;
                    FMIN = min(FMIN,Sample);
                    FMAX = max(FMAX,Sample);
                }
            }
            LFinalColor = clamp(LFinalColor,FMIN,FMAX);
            //Output
            Output = vec4((FinalColor+LFinalColor*15.)/16.,0.);
        } else {
            //Invalid reprojection
            Output.xyz = FinalColor;
        }
    }
    //Output
    fragColor = Output;
}