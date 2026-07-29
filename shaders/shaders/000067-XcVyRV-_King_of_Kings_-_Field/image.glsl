// Image (image) — [♪]King of Kings - Field by Catzpaw
// https://www.shadertoy.com/view/XcVyRV

//==================================================
// King of Kings - Field
// Image:post effects

//TEXTURE
vec4 tx0(vec2 uv){
    vec4 c=texture(iChannel0,uv);
    c.g=texture(iChannel0,.993*(uv-.5)+.5).g;
    c.r=texture(iChannel0,.986*(uv-.5)+.5).r;
    return c;
}

//MAIN
void mainImage(out vec4 fragColor,in vec2 fragCoord){

    vec2 uv=fragCoord/iResolution.xy;

    //DOF filter
    mat2 vel=rot(1.43);
    vec2 mul=vec2(0,iResolution.x/iResolution.y),ang=vec2(0,1)*mul;
    vec4 acc=vec4(0,0,0,1),tgt=vec4(1),c=tx0(uv);
    float fp=1.;
    fp=min(tx0(vec2(.55,.5)).w,fp);
    fp=min(tx0(vec2(.55,.45)).w,fp);
    fp=min(tx0(vec2(.5,.5)).w,fp);
    fp=min(tx0(vec2(.45,.45)).w,fp);
    fp=min(tx0(vec2(.44,.5)).w,fp);
    float foc=min(.3,fp),bok,rad=0.,dis=0.;
    bok=c.w<foc?1.-c.w/foc:(c.w-foc)/(1.-foc);
    bok=pow(bok,1.+foc);
    for(int j=ZERO;j<30;j++){
        rad+=.006;
        tgt=tx0(uv+ang*rad*.05);dis=tgt.w;tgt.w=.97;
        acc+=(((dis<c.w)&&(abs(dis-foc)>=rad))||(bok>=rad))?tgt:vec4(0);
        ang*=vel;
    }
    c.rgb+=acc.rgb;c.rgb/=acc.w;
    
    //vignette
    uv-=.5;
    c.rgb-=dot(uv,uv)*.8;

    //output
    c.w=1.;
    fragColor=c;
}
