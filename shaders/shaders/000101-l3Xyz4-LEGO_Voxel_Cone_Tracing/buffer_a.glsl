// Buffer A (buffer) — LEGO Voxel Cone Tracing by Mathis
// https://www.shadertoy.com/view/l3Xyz4

//Storage and primary rays

vec4 textureCube(vec2 uv) {
    //Samples the cubemap
    float tcSign = -mod(floor(uv.y*I1024), 2.)*2. + 1.;
    vec3 tcD = vec3(vec2(uv.x, mod(uv.y, 1024.))*I512 - 1., tcSign);
    if (uv.y > 4096.) tcD = tcD.xzy;
    else if (uv.y > 2048.) tcD = tcD.zxy;
    return textureLod(iChannel3, tcD, 0.);
}

float vSDF(vec3 sp) {
    //Samples a volume SDF
    float SVal = sp.x*20.;
    vec2 UVmod = 0.5 + sp.zy*20.;
    vec2 UVSlice0 = vec2(floor(mod(SVal, 8.))*120., floor(SVal/8.)*128.);
    vec4 TexC = textureCube(UVmod + UVSlice0);
    return mix(TexC.x, TexC.y, fract(SVal));
}

HIT traceRay(vec3 P, vec3 D, float Time) {
    HIT OUT = HIT(1000000000., vec3(-1.), vec3(-1.), -1);
    vec3 ID = 1./D;
    
    //Ground
    if (D.y<0.) {
        float planet = -(P.y - 0.05)/D.y;
        vec3 planep = P + D*planet - vec3(-5., 0., 3.);
        if (DFBox(vec2(planep.x + planep.z, planep.x - planep.z)*0.707, vec2(16.)) < 0.) {
            OUT.D = planet;
            OUT.C = vec3(1.);
            OUT.N = vec3(0., 1., 0.);
            OUT.M = 1;
        }
    }
    
    //Car
    vec2 Carbb = ABox(P, ID, vec3(0., 0., 0.), vec3(13.95, 0.4*16. - 0.05, 5.95));
    float CarDF = DFBox(P - vec3(0., 0., 0.), vec3(13.95, 0.4*16. - 0.05, 5.95));
    if (CarDF < 0. || (Carbb.x > 0. && Carbb.y > Carbb.x && Carbb.x < OUT.D)) {
        float CarFAR = min(Carbb.y, OUT.D);
        float Cart = ((CarDF < 0.)?0.:Carbb.x + 0.05);
        vec3 sp;
        float dfs;
        for (int i = 0; i < 256; i++) {
            sp = P + D*Cart;
            float SVal = sp.x*20.;
            vec2 UVmod = 0.5 + sp.zy*20.;
            vec2 UVSlice0 = vec2(floor(mod(SVal, 8.))*120., floor(SVal/8.)*128.);
            vec4 TexC = textureCube(UVmod + UVSlice0);
            dfs = mix(TexC.x, TexC.y, fract(SVal));
            Cart += dfs;
            if (min(dfs - 0.002, CarFAR - Cart) < 0.) break;
        }
        if (dfs < 0.002) {
            //Hit
            OUT.D = Cart;
            sp = P + D*Cart;
            OUT.N = normalize(vec3(vSDF(sp + eps.xyy) - vSDF(sp - eps.xyy),
                                   vSDF(sp + eps.yxy) - vSDF(sp - eps.yxy),
                                   vSDF(sp + eps.yyx) - vSDF(sp - eps.yyx)));
            OUT.M = 1;
            return OUT;
        }
    }
    //Return
    return OUT;
}

void UpdateMouse(inout vec4 Output, vec4 Mouse) {
    //Updates the mouse
    if (Mouse.z > 0.) {
        if (Output.w == 0.) {
            Output.w = 1.;
            Output.z = iTime;
            Output.xy = Mouse.zw;
        }
    } else {
        Output.w = 0.;
    }
}

void UpdateEye(inout vec4 Output, vec4 CMouse, vec4 Mouse) {
    //Updates the eye vector
    if (CMouse.w == 0.)  {
        //Animation
        float angVel = texture(iChannel0, vec2(3.5, 0.5)*IRES).x;
        Output.y = mod(Output.y + angVel*iTimeDelta, 3.141592653*2.);
        Output.x = mix(Output.x, -0.3, angVel*iTimeDelta);
        //Copy
        Output.zw = Output.xy;
    }
    if (CMouse.w == 1.) {
        //Y led
        Output.x = Output.z + (Mouse.y - CMouse.y)*IRES.y*5.;
        Output.x = clamp(Output.x, -1.4, 0.1);
        //X led
        Output.y = Output.w - (Mouse.x - CMouse.x)*IRES.x*10.;
        Output.y = mod(Output.y, 3.141592653*2.);
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel0, fragCoord.xy*IRES);
    if (iFrame == 0) {
        //Initialization
        if (fragCoord.x < 10. && fragCoord.y < 1.) { //Store vars
            if (fragCoord.x < 1.) Output = vec4(0., 0., 0., 0.); //Mouse
            else if (fragCoord.x < 2.) Output = vec4(-0.3, -2.45, 0., 0.); //Player Eye (Angles)
            else if (fragCoord.x < 3.) Output = vec4(0., 0., 0., 1.); //Player Eye (Vector)
            else if (fragCoord.x < 4.) Output = vec4(0., 0., 0., 1.); //Camera animated movement angvel
        }
    } else {
        //Update
		if (fragCoord.x < 8. && fragCoord.y < 1.) {
            //Update vars
            if (fragCoord.x < 1.) { //Mouse
                UpdateMouse(Output, iMouse);
            } else if (fragCoord.x < 2.) {
                //Player Eye (Angles)
                vec4 CMouse = texture(iChannel0, vec2(0.5, 0.5)*IRES);
                UpdateMouse(CMouse, iMouse);
                UpdateEye(Output, CMouse, iMouse);
            } else if (fragCoord.x < 3.) {
                //Player Eye (Vector)
                vec4 A4 = texture(iChannel0, vec2(1.5, 0.5)*IRES);
                vec4 CMouse = texture(iChannel0, vec2(0.5, 0.5)*IRES);
                UpdateMouse(CMouse, iMouse);
                UpdateEye(A4, CMouse, iMouse);
                Output.xyz = normalize(vec3(cos(A4.x)*sin(A4.y), sin(A4.x), cos(A4.x)*cos(A4.y)));
            } else if (fragCoord.x < 4.) {
                //Player Eye animation angvel
                vec4 CMouse = texture(iChannel0, vec2(0.5, 0.5)*IRES);
                UpdateMouse(CMouse, iMouse);
                if (CMouse.w == 0.) {
                    //No input -> accelerate angvel
                    Output.x = 0.5*(1. - exp(-(iTime - CMouse.z)));
                } else {
                    //Input -> no angvel
                    Output.x = 0.;
                } 
            } else if (fragCoord.x < 5.) {
                //Player Eye last frame
                Output = texture(iChannel0, vec2(2.5, 0.5)*IRES);
            }
        }
    }
    if (DFBox(fragCoord - 1., RES - 2.) < 0.) {
        Output = vec4(0.);
        if (iFrame > 8) {
            //G-Buffer
            vec2 SSOffset = fract(vec2(0.61803398875, 0.38196601125)*float(iFrame % 16))*0.8 - 0.5;
            vec3 SunDir = texture(iChannel0, vec2(5.5, 0.5)*IRES).xyz;
            //Compensate for 1 frame lag
            vec4 CMouse = texture(iChannel0, vec2(0.5, 0.5)*IRES);
            UpdateMouse(CMouse, iMouse);
            vec4 Eye4 = texture(iChannel0, vec2(1.5, 0.5)*IRES);
            vec3 PriorEye = normalize(vec3(cos(Eye4.x)*sin(Eye4.y), sin(Eye4.x), cos(Eye4.x)*cos(Eye4.y)));
            UpdateEye(Eye4, CMouse, iMouse);
            vec3 Eye = normalize(vec3(cos(Eye4.x)*sin(Eye4.y), sin(Eye4.x), cos(Eye4.x)*cos(Eye4.y)));
            vec3 Pos = vec3(7. - Eye.x*2., 2., 3.) - Eye*13.;
            mat3 EyeMat = TBN(Eye);
            vec3 Dir = normalize(vec3(((fragCoord+SSOffset)*IRES*2. - 1.)*(ASPECT*CFOV), 1.)*EyeMat);
            //Render scene
            HIT Pixel = traceRay(Pos, Dir, iTime);
            if (Pixel.M == 0) {
                //Emissive
                Output = vec4(Vec3ToFloat(Pixel.C*ILightCoeff), 0., texture(iChannel0,fragCoord*IRES).w, -2.);
            } else if (Pixel.M > 0) {
                //Geometry
                Output = vec4(Vec3ToFloat(Pixel.C),
                              Vec3ToFloat(Pixel.N*0.49 + 0.5),
                              texture(iChannel0, fragCoord*IRES).w,
                              Pixel.D);
            } else {
                //Sky
                Output = vec4(0., 0., texture(iChannel0, fragCoord*IRES).w, -1.);
            }
        }
    }
    fragColor = Output;
}