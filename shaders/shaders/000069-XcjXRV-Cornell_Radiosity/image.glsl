// Image (image) — Cornell Radiosity by Mathis
// https://www.shadertoy.com/view/XcjXRV

/*
Cornell box with some spheres and radiosity
    Bilinear interpolation with first order extrapolation to improve texture boundaries
    Radiosity with proper formfactors and binary visibility test
    

Some cool notes:
    Scene can be completely dynamic, but temporal multibounce flickers a lot when patches move
    Temporal multibounce is cool but introduces ghosting as usual
        Both these problems can be reduced by removing temporal history based on
        movement, light or other changes
    No flag for invalid patches
        When patches partially intersects geometry the sampling position might land inside geometry
        leading to artifacts, both for interpolation and for light transport
            Can be fixed but not implemented here

Controls:
    iMouse.x interpolates between classic cornell lightsource, two emissive walls and sunlight
    iMouse.y controls the sunlight angle
*/



vec3 acesFilm(vec3 x) {
    return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.,1.);
}

vec4 textureCube(vec2 UV, float LOD) {
    //Samples the cubemap
    float Sign = -mod(floor(UV.y*I1024),2.)*2.+1.;
    vec3 D = vec3(vec2(UV.x,mod(UV.y,1024.))*I512-1.,Sign);
    if (UV.y>4096.) D = D.xzy;
    else if (UV.y>2048.) D = D.zxy;
    return textureLod(iChannel3,D,LOD);
}

vec3 SamplePatch(vec2 UV, vec4 mm) {
    if (UV.x<mm.x) {
        float PixelIndex = floor(UV.x+1.)+floor(UV.y)*64.;
        vec3 tmpc = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        PixelIndex = floor(UV.x+2.)+floor(UV.y)*64.;
        return max(vec3(0.),2.*tmpc-
               textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz);
    }
    if (UV.x>mm.x+mm.z) {
        float PixelIndex = floor(UV.x-1.)+floor(UV.y)*64.;
        vec3 tmpc = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        PixelIndex = floor(UV.x-2.)+floor(UV.y)*64.;
        return max(vec3(0.),2.*tmpc-
               textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz);
    }
    if (UV.y<mm.y) {
        float PixelIndex = floor(UV.x)+floor(UV.y)*64.+64.;
        vec3 tmpc = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        PixelIndex = floor(UV.x)+floor(UV.y)*64.+128.;
        return max(vec3(0.),2.*tmpc-
               textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz);
    }
    if (UV.y>mm.y+mm.w) {
        float PixelIndex = floor(UV.x)+floor(UV.y)*64.-64.;
        vec3 tmpc = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        PixelIndex = floor(UV.x)+floor(UV.y)*64.-128.;
        return max(vec3(0.),2.*tmpc-
               textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz);
    }
    float PixelIndex = floor(UV.x)+floor(UV.y)*64.;
    return textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
}

vec3 InterpolatePatches(vec2 UV, vec4 MinMax) {
    //Interpolates patches
    vec3 OUT = vec3(0.);
    
    //Nearest
    /*
    float PixelIndex = floor(UV.x)+floor(UV.y)*64.;
    OUT = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
    //*/
    
    //Bilinear
    //*
    if (DFBox(UV-vec2(48.,24.),vec2(16.,31.))<0.) {
        //Spherical surface
        float theta = UV.x-48.;
        float thetaf = floor(theta);
        float thetar = 1.+ceil(30.*sin(thetaf/15.*PI));
        float uvy = 24.+(UV.y-24.)*thetar-0.5;
        if (uvy<24.) uvy += thetar;
        float PixelIndex = floor(UV.x)+floor(uvy)*64.;
        vec3 C00 = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        uvy = 24.+(UV.y-24.)*thetar+0.5;
        if (uvy>24.+thetar) uvy -= thetar;
        PixelIndex = floor(UV.x)+floor(uvy)*64.;
        vec3 C01 = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        vec3 C0 = mix(C00,C01,fract(uvy));
        //Mext theta
        thetar = 1.+ceil(30.*sin((thetaf+1.)/15.*PI));
        uvy = 24.+(UV.y-24.)*thetar-0.5;
        if (uvy<24.) uvy += thetar;
        PixelIndex = floor(UV.x)+1.+floor(uvy)*64.;
        C00 = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        uvy = 24.+(UV.y-24.)*thetar+0.5;
        if (uvy>24.+thetar) uvy -= thetar;
        PixelIndex = floor(UV.x)+1.+floor(uvy)*64.;
        C01 = textureCube(vec2(floor(mod(PixelIndex+0.5,32.))*32.,floor((PixelIndex+0.5)*I32)*32.)+16.,5.).xyz;
        vec3 C1 = mix(C00,C01,fract(uvy));
        //Output
        return mix(C0,C1,fract(UV.x));
    } else {
        //Quad surface
        vec2 buv = UV-0.5;
        vec2 fuv = fract(buv);
        vec3 C0 = SamplePatch(buv,MinMax);
        vec3 C1 = SamplePatch(buv+vec2(1.,0.),MinMax);
        vec3 C2 = SamplePatch(buv+vec2(0.,1.),MinMax);
        vec3 C3 = SamplePatch(buv+vec2(1.),MinMax);
        return mix(mix(C0,C1,fuv.x),mix(C2,C3,fuv.x),fuv.y);
    }
    //*/
    
    //Output
    return OUT;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 Output = vec3(0.);
    //Sunlight
    vec2 Mouse = texture(iChannel0,vec2(0.5,64.5)*IRES).xy;
    float Interp = max(0.,1.-max(0.,(Mouse.x*IRES.x-0.125)*8.));
    float MouseAngle = -(Mouse.y*IRES.y-0.5)*PI*1.75-PI;
    vec3 SunDir = normalize(vec3(sin(MouseAngle),0.85,cos(MouseAngle)));
    //Primary ray
    vec3 Dir = normalize(vec3((fragCoord*IRES*2.-1.)*(ASPECT*CFOV),1.))*vec3(-1.,1.,1.);
    HIT Pixel = Trace(CameraPos,Dir,iTime);
    if (Pixel.v.x>-0.5) {
        //Geometry
        if (Pixel.v.x<64.) {
            //Diffuse
            vec4 PixelAttr = texture(iChannel0,Pixel.v.xy*IRES);
            //Direct light
            Output += floatToVec3(PixelAttr.w)*8.;
            vec3 PPos = CameraPos+Dir*Pixel.v.z;
            vec3 PatchN = normalize(floatToVec3(PixelAttr.y)*2.-1.);
            if (DFBox(Pixel.v.xy-vec2(48.,24.),vec2(16.,31.))<0.) PatchN = normalize(PPos-DSP);
            if (dot(PatchN,SunDir)>0. && Trace(PPos,SunDir,iTime).v.x<-1.5) {
                Output += vec3(1.,0.8,0.6)*dot(PatchN,SunDir)*3.*Interp;
            }
            //Indirect light
            Output.xyz += InterpolatePatches(Pixel.v.xy,Pixel.m);
            //Color
            Output *= floatToVec3(PixelAttr.z);
        } else {
            //Specular
            Output.xyz = vec3(0.);
            vec3 PPos = CameraPos+Dir*Pixel.v.z;
            vec3 PixelN = normalize(PPos-vec3(0.75,0.225,0.7));
            vec3 RDir = reflect(Dir,PixelN);
            HIT RHit = Trace(PPos,RDir,iTime);
            if (RHit.v.x>-0.5) {
                vec4 RAttr = texture(iChannel0,RHit.v.xy*IRES);
                //Direct light
                Output += floatToVec3(RAttr.w)*8.;
                vec3 RPPos = PPos+RDir*RHit.v.z;
                vec3 RPatchN = normalize(floatToVec3(RAttr.y)*2.-1.);
                if (DFBox(RHit.v.xy-vec2(48.,24.),vec2(16.,31.))<0.) RPatchN = normalize(RPPos-DSP);
                if (dot(RPatchN,SunDir)>0. && Trace(RPPos,SunDir,iTime).v.x<-1.5) {
                    Output += vec3(1.,0.8,0.6)*dot(RPatchN,SunDir)*3.*Interp;
                }
                //Indirect light
                Output.xyz += InterpolatePatches(RHit.v.xy,RHit.m);
                //Color
                Output *= floatToVec3(RAttr.z);
            }
        }
    }
    //Output
    fragColor = vec4(pow(acesFilm(max(vec3(0.),Output)),vec3(0.45)),1.);
}