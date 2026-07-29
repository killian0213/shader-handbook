// Buffer A (buffer) — Dynamic Delaunay 4 by rory618
// https://www.shadertoy.com/view/WtcXz4

vec4 A(int i){
    return texture(iChannel0, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}

void mainImage( out vec4 O, in vec2 I )
{
    O = texture(iChannel0, I/R.xy);
    O.xy = clamp(O.xy,vec2(0),vec2(R.xy));
    //O.xy = mod(O.xy,R.xy);
    vec4 r = rand4(int(I.x) + int(I.y)*2048 + iFrame*2048*2048);
    if(iFrame<3){
        O.xy = (.5+(r.xy-.5)/10.)*R.xy;
        O.zw = .25*cos(6.283*(vec2(0,.25)+r.z));
        
    }
    
    vec4 a = texture(iChannel1, (O.xy)/R.xy);
    
    vec2 ns = vec2(0);
    vec2 df = vec2(0);
    for(int i = 0; i < 4; i++){
        vec4 n = A(cvt(a[i]));
        ns += n.zw/4.;
        vec2 D = O.xy-n.xy;
        if(length(D)>.005&&length(D)<10.){
        	df += normalize(D);//*(1./(length(D)+.03));
        }
    }
    O.zw+=df*3.;
    O.zw = mix(O.zw,ns,.3);
    O.zw += randn(r.xy)/1e2;
    if(iMouse.z>0.){
        vec2 D = O.xy-iMouse.xy;
        O.zw -= normalize(D)*(100./(length(D)+.03));
    }
    //O.zw *= .92;
    O.xy += O.zw/4.;
    
}