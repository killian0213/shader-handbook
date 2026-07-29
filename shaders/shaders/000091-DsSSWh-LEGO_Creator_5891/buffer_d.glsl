// Buffer D (buffer) — LEGO Creator 5891 by Mathis
// https://www.shadertoy.com/view/DsSSWh

//Accumulation

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = texture(iChannel2,fragCoord*IRES);
    vec4 Sample = texture(iChannel1,fragCoord*IRES);
    vec2 RMoved = texture(iChannel0,vec2(8.5,0.5)*IRES).xy;
    bool Accumulate = (RMoved.x<0.5 && RMoved.y>0.5);
    if (!Accumulate) {
        //Reset accumulation
        Output = vec4(Sample.xyz,0.);
    } else {
        //Continue accumulation
        Output = vec4((Sample.xyz+Output.xyz*Output.w)/(Output.w+1.),min(1024.,Output.w+1.)); //Remove 32 later
    }
    fragColor = Output;
}