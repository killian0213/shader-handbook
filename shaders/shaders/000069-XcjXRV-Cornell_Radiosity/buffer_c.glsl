// Buffer C (buffer) — Cornell Radiosity by Mathis
// https://www.shadertoy.com/view/XcjXRV

//Patches: emissive + direct light

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    if (DFBox(fragCoord,vec2(64.))<0.) {
        vec2 LODUV = floor(fragCoord)*4.+1.;
        vec3 DirectLight = (texture(iChannel1,LODUV*IRES).xyz+
                     texture(iChannel1,(LODUV+vec2(0.,2.))*IRES).xyz+
                     texture(iChannel1,(LODUV+vec2(2.,0.))*IRES).xyz+
                     texture(iChannel1,(LODUV+2.)*IRES).xyz)*0.25;
        vec3 EmissiveLight = floatToVec3(texture(iChannel0,fragCoord*IRES).w)*8.;
        vec2 Mouse = texture(iChannel0,vec2(0.5,64.5)*IRES).xy;
        float Interp = max(0.,1.-max(0.,(Mouse.x*IRES.x-0.125)*8.));
        fragColor = vec4(EmissiveLight+DirectLight*Interp,1.);
    } else {
        discard;
    }
}