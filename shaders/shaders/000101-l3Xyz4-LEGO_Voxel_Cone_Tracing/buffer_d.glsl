// Buffer D (buffer) — LEGO Voxel Cone Tracing by Mathis
// https://www.shadertoy.com/view/l3Xyz4

//Shadow map

vec4 textureCube(vec2 uv) {
    //Samples the cubemap
    float tcSign = -mod(floor(uv.y*I1024), 2.)*2. + 1.;
    vec3 tcD = vec3(vec2(uv.x, mod(uv.y, 1024.))*I512 - 1., tcSign);
    if (uv.y > 4096.) tcD = tcD.xzy;
    else if (uv.y > 2048.) tcD = tcD.zxy;
    return texture(iChannel3, tcD, 0.);
}

float vSDF(vec3 sp) {
    //Samples a volume SDF
    float SVal = sp.x*20.;
    vec2 UVmod = 0.5 + sp.zy*20.;
    vec2 UVSlice0 = vec2(floor(mod(SVal, 8.))*120., floor(SVal/8.)*128.);
    vec4 TexC = textureCube(UVmod + UVSlice0);
    return mix(TexC.x, TexC.y, fract(SVal));
}

float traceRay(vec3 P, vec3 D) {
    vec3 ID = 1./D;
    //Car
    vec2 Carbb = ABox(P, ID, vec3(0., 0., 0.), vec3(13.95, 0.4*16. - 0.05, 5.95));
    float CarDF = DFBox(P - vec3(0., 0., 0.), vec3(13.95, 0.4*16. - 0.05, 5.95));
    if (CarDF < 0. || (Carbb.x > 0. && Carbb.y > Carbb.x)) {
        float CarFAR = Carbb.y;
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
            return Cart;
        }
    }
    //Return
    return 10000.;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 sunStartPos = SUN_TARGET + SUN_DIR*32. +
                       ((fragCoord.x*IRES.x*2. - 1.)*SUN_SM_SIZE*ASPECT.x)*SUN_TAN +
                       ((fragCoord.y*IRES.y*2. - 1.)*SUN_SM_SIZE)*SUN_BIT;
    fragColor = vec4(traceRay(sunStartPos, -SUN_DIR));
}