// Buffer A (buffer) — Crowdy waves by rory618
// https://www.shadertoy.com/view/ttyGWw

vec4 A(int i){
    return texture(iChannel0, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}

void mainImage( out vec4 O, in vec2 I )
{
    O = texture(iChannel0, I/R.xy);
    
    O.xy = mod(O.xy,R.xy);
    vec4 r = rand4(int(I.x) + int(I.y)*2048 + iFrame*2048*2048);
    if(iFrame<3){
        O.xy = r.xy*R.xy;
        O.zw = .25*cos(6.283*(vec2(0,.25)+r.z));
        
    }
    
    vec4 a = texture(iChannel1, (.5+floor(O.xy))/R.xy);
    
    vec2 ns = vec2(0);
    vec2 df = vec2(0);
    for(int i = 0; i < 4; i++){
        vec4 n = A(cvt(a[i]));
        ns += n.zw/4.;
        vec2 D = mod( O.xy - n.xy + R.xy/2., R.xy ) - R.xy/2.;
        if(length(D)>.005&&length(D)<10.){
        	df += normalize(D)*(1./(length(D)+.03));
        }
    }
    O.zw+=df/25.;
    O.zw = mix(O.zw,ns,.1);
    if(length(O.zw)>.001)
    	O.zw = mix(O.zw,normalize(O.zw)/4.,.05);
    O.zw += randn(r.xy)/1e2;
    if(iMouse.z>0.){
        vec2 D = O.xy-iMouse.xy;
        O.zw += normalize(D)*(1./(length(D)+.03));
    }
    O.xy += O.zw;
    
}