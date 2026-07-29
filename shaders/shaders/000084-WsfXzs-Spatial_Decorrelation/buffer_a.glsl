// Buffer A (buffer) — Spatial Decorrelation by rory618
// https://www.shadertoy.com/view/WsfXzs

//Simple newtonian particles
//Use O.w for render pass

//Uncomment to see the decorrelated image that is getting rendered
//#define show_decorrelated

//Drawing a particle
//Need another pass or bigger output pass to draw bigger particles
//For now just light up the pixel it lands in


void splat(inout float O, vec2 I, vec2 ip, vec2 p){
    
    //O = min(O,vec4(length(p-I))/3.);
    //float d2 = dot2(I-p);
    //O += exp(-d2*.01);
#ifdef show_decorrelated
    if(floor(I)==floor(p)) O += (.055);
#else
    if(floor(ip)==floor(p)) O += (.055);
#endif
}

void mainImage( out vec4 O, in vec2 I )
{
    vec2 uv = I/R.xy;
    vec2 r = rand2(IHash3(iFrame,I.x,I.y));
    O = texture(iChannel0,uv);
    float Owp = O.w;
    O.w=0.;
    vec2 p = O.xy;
    vec2 v = umpackVec2(O.z);
    if(iFrame<3 || texelFetch(iChannel3,ivec2(32,1),0).x>.5){
        p = I;
        v=vec2(0);
    }
    v /= 1.003;
    
    //Add some brownian motion to seperate the particles when they all get stuck together
    p += randn(r)/1e4;
    p += v/2.;
    
    //also add an interesting force
    vec2 k = vec2(cos(10.*float(iFrame)/60.),sin(10.*float(iFrame)/60.))*R.y/7.+R.xy/2.;
    vec2 d = (k-p);
    v += sin(-float(iFrame)/60.*6.5+.6*pow(dot2(d),.6)/9.)*3.*d/(pow(length(d),1.7));
    v *= 1.-exp(-.1*length(d));
    
    if(iMouse.z > 1.){
        vec2 d = (iMouse.xy-p);
        v += 4.*d/(pow(length(d),1.7));
        v *= 1.-exp(-.1*length(d));
    }
    //bounce off the walls
    if(p.x<0.)  {v.x =  abs(v.x); p.x=-p.x;}
    if(p.y<0.)  {v.y =  abs(v.y); p.y=-p.y;}
    if(p.x>R.x) {v.x = -abs(v.x); p.x=R.x*2.-p.x;}
    if(p.y>R.y) {v.y = -abs(v.y); p.y=R.y*2.-p.y;}
    
    O.xy = p;
    O.z = packVec2(v);
    
#ifdef show_decorrelated
    vec2 ip = I;
#else
    vec2 ip = forward_mapping(I,iR.x,iR.y,iFrame/2-1);
#endif
    for(int i = 0; i < 9; i++){
        vec4 t = texelFetch(iChannel1,ivec2(ip-1.)+ivec2(i/3,i%3),0);
        
        splat(O.w,I,ip,t.xy);
        splat(O.w,I,ip,t.zw);
    }
    O.w=pow(O.w,.7);
    int stage = iFrame%2;
    if(stage==1) O.w=Owp;
    else O.w = mix(O.w,Owp,0.3);
    //Smooth over time
}