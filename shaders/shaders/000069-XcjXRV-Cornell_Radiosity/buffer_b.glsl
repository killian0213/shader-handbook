// Buffer B (buffer) — Cornell Radiosity by Mathis
// https://www.shadertoy.com/view/XcjXRV

//Patches: sun rays

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 Output = vec4(0.);
    if (DFBox(fragCoord,vec2(256.))<0.) {
        //Shadow ray atlas
        vec2 PatchUV = floor(fragCoord*0.25)+0.5;
        vec4 PatchAttr = texture(iChannel0,PatchUV*IRES);
        if (PatchAttr.w>-0.5) {
            //Valid current patch
            vec3 PatchP = texture(iChannel0,(PatchUV+vec2(64.,0.))*IRES).xyz;
            vec3 PatchN = normalize(floatToVec3(PatchAttr.y)*2.-1.);
            vec3 PatchTan; vec3 PatchBit = TBN(PatchN,PatchTan);
            vec3 ShadowPos = PatchP+PatchN*0.0001+(PatchTan*(mod(fragCoord.x,4.)-2.)+PatchBit*(mod(fragCoord.y,4.)-2.))*0.25*I24;
            //Sun
            vec2 Mouse = texture(iChannel0,vec2(0.5,64.5)*IRES).xy;
            float MouseAngle = -(Mouse.y*IRES.y-0.5)*PI*1.75-PI;
            vec3 SunDir = normalize(vec3(sin(MouseAngle),0.85,cos(MouseAngle)));
            if (dot(PatchN,SunDir)>0. && Trace(ShadowPos,SunDir,iTime).v.x<-1.5) {
                //Visible
                Output.xyz = vec3(1.,0.8,0.6)*dot(PatchN,SunDir)*3.;
            }
        }
    }
    fragColor = Output;
}