// Buffer D (buffer) — Quadtree ReSTIR GI by Mathis
// https://www.shadertoy.com/view/DslSDM

//Temporal accumulation

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel3,fragCoord*IRES)*((iFrame<1)?0.:1.);
    //Current reservoir
    vec4 CRT = texture(iChannel1,fragCoord*IRES);
    if (CRT.w<-0.5) {
        Output = vec4(0.,0.,0.,-1.);
    } else {
        if (Output.w<-0.5) Output = vec4(0.,0.,0.,0.);
        vec2 CMA = FloatToMAngle(CRT.z);
        vec4 CRS = texture(iChannel2,fragCoord*IRES);
        vec3 NLight = FloatToVec3(CRS.x,ReservoirScale)*CRS.w;
        //3x3 clamping
        vec3 Min = vec3(10000.);
        vec3 Max = vec3(0.);
        for (float x=-1.; x<1.5; x++) {
            for (float y=-1.; y<1.5; y++) {
                vec4 CRS = texture(iChannel2,(fragCoord+vec2(x,y))*IRES);
                vec3 SLight = FloatToVec3(CRS.x,ReservoirScale)*CRS.w;
                Min = min(Min,SLight);
                Max = max(Max,SLight);
            }
        }
        Output.xyz = clamp(Output.xyz,Min,Max);
        //Accumulation
        Output = vec4((Output.xyz*Output.w+NLight)/(Output.w+1.),min(8.,Output.w+1.));
    }
    fragColor = Output;
}