// Buffer C (buffer) — Crowdy waves by rory618
// https://www.shadertoy.com/view/ttyGWw

vec4 A(int i){
    return texture(iChannel0, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}

void mainImage( out vec4 O, in vec2 I )
{
    O = vec4(0);
    vec4 a = texture(iChannel1, I/R.xy);
    for(int i = 0; i < 4; i++){
        O += .4*exp(-.5*dot2(I-A(cvt(a[i]) ).xy));
    }
    O = mix(O, texture(iChannel2, I/R.xy),.9);
}