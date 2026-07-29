// Buffer C (buffer) — LEGO Voxel Cone Tracing by Mathis
// https://www.shadertoy.com/view/l3Xyz4

//TAA

vec4 sampleLevel0(vec2 PriorUV) {
    return texture(iChannel2, PriorUV*IRES);
}

vec4 SampleTextureCatmullRom(vec2 uv) {
    vec2 samplePos = uv;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;
    vec2 f = samplePos - texPos1;
    vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f));
    vec2 w3 = f * f * (-0.5 + 0.5 * f);
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / w12;
    vec2 texPos0 = texPos1 - vec2(1.);
    vec2 texPos3 = texPos1 + vec2(2.);
    vec2 texPos12 = texPos1 + offset12;
    vec4 result = vec4(0.);
    result += sampleLevel0( vec2(texPos0.x,  texPos0.y)) * w0.x * w0.y;
    result += sampleLevel0( vec2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos0.y)) * w3.x * w0.y;
    result += sampleLevel0( vec2(texPos0.x,  texPos12.y)) * w0.x * w12.y;
    result += sampleLevel0( vec2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos12.y)) * w3.x * w12.y;
    result += sampleLevel0( vec2(texPos0.x,  texPos3.y)) * w0.x * w3.y;
    result += sampleLevel0( vec2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += sampleLevel0( vec2(texPos3.x,  texPos3.y)) * w3.x * w3.y;
    return max(vec4(0., 0., 0., 1.),result);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0., 0., 0., 1.);
    if (iFrame > 1 && DFBox(fragCoord - 1., RES - 2.) < 0.) {
        //Inside the screen
        vec3 BCRef = texture(iChannel1, fragCoord*IRES).xyz;
        vec3 FinalColor = vec3(BCRef.xyz);
        //Reprojection
        vec3 Eye = texture(iChannel0, vec2(2.5, 0.5)*IRES).xyz;
        vec3 Pos = vec3(7. - Eye.x*2., 2., 3.) - Eye*13.;
        mat3 EyeMat = TBN(Eye);
        vec3 PriorEye = texture(iChannel0, vec2(4.5, 0.5)*IRES).xyz;
        vec3 PriorPos = vec3(7. - PriorEye.x*2., 2., 3.) - PriorEye*13.;
        vec3 PriorTan; vec3 PriorBit = TBN(PriorEye, PriorTan);
        mat3 PriorEyeMat = TBN(PriorEye);
        vec3 Dir = normalize(vec3((fragCoord*IRES*2. - 1.)*CFOV*ASPECT, 1.)*EyeMat);
        vec4 CAttr = texture(iChannel0, fragCoord*IRES);
        float Distance = CAttr.w;
        if (Distance < -0.5) Distance = 100000.; //Sky pixel
        vec3 PPos = Pos + Dir*Distance;
        //Prior position
        vec3 PriorVPos = vec3(dot(PPos - PriorPos, PriorTan), dot(PPos - PriorPos, PriorBit), dot(PPos - PriorPos, PriorEye));
        vec2 PriorUV = ((PriorVPos.xy/PriorVPos.z)*0.5/(ASPECT*CFOV) + 0.5)*RES;
        if (DFBox(PriorUV - 1., RES - 2.) < 0.) {
            //Geometric validation
            vec4 LFinalColor;
            if (length(PriorUV - fragCoord) > 0.02) {
                //Catmull-rom sampling
                LFinalColor = SampleTextureCatmullRom(PriorUV);
            } else {
                //Nearest neighbour sampling
                PriorUV = floor(PriorUV) + 0.5;
                LFinalColor = texture(iChannel2, PriorUV*IRES);
            }
            //Clamping
            vec3 FMIN = vec3(1000.);
            vec3 FMAX = vec3(0.);
            for (float x = -1.; x < 1.5; x += 1.) {
                for (float y = -1.; y < 1.5; y += 1.) {
                    vec3 Sample = texture(iChannel1, (fragCoord + vec2(x, y))*IRES).xyz;
                    //Clamp
                    FMIN = min(FMIN, Sample);
                    FMAX = max(FMAX, Sample);
                }
            }
            LFinalColor.xyz = clamp(LFinalColor.xyz, FMIN, FMAX);
            //Output
            Output = vec4((FinalColor + LFinalColor.xyz*LFinalColor.w)/(LFinalColor.w + 1.), min(31., LFinalColor.w + 1.));
        } else {
            //Invalid geometry
            Output = vec4(FinalColor, 1.);
        }
    }
    fragColor = Output;
}