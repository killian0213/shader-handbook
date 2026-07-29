// Buffer B (buffer) — TV Scene, wall of TV by morimea
// https://www.shadertoy.com/view/4fffR7


// do not use this - this is junk made only for this case
// if you look for camera control in buffer:
// look my template shaders, BufA there
// https://www.shadertoy.com/view/DljGzy
// or
// https://danilw.github.io/blog/my_shader_templates_list/

#define keyboard_texture iChannel3
#define self_texture iChannel1

const vec3 start_pos = vec3(3.35, 8., -7.);
const vec2 start_mouse = vec2(-0.5*3.1415926+0.001, -0.0+0.001);
const float mouse_dir_ms = 0.4*0.75*1.;
const vec2 mouse_dir_st = vec2(-1.,0.);

#define iTimeDelta min(iTimeDelta,1./10.)

void store(ivec2 P, ivec2 ipx, vec4 V, inout vec4 fc){ if(ipx==P) fc = V;}

vec4 load(ivec2 P, sampler2D self){return texelFetch(self, ivec2(P), 0);}
float key(int K, sampler2D kb){return step(0.5, texelFetch(kb, ivec2(K, 0), 0).x);}
float key_t(int K, sampler2D kb){return step(0.5, texelFetch(kb, ivec2(K, 2), 0).x);}

const ivec2 MEMORY_BOUNDARY = ivec2(5, 3);
const ivec2 RES_LAST = ivec2(0, 0);
const ivec2 INIT = ivec2(0, 1);
const ivec2 TARGET = ivec2(0, 2);

const ivec2 POSITION = ivec2(1, 0);
const ivec2 POSITION_last = ivec2(1, 1);
const ivec2 tt_st = ivec2(1, 2);

const ivec2 last_iMouse = ivec2(2, 0);
const ivec2 mouse_dir = ivec2(2, 1);
const ivec2 t_ha = ivec2(2, 2);
const ivec2 t_ha2 = ivec2(4, 2);

const ivec2 INPUT = ivec2(3, 0);
const ivec2 PMOUSE = ivec2(3, 1);

const ivec2 RES_LAST_LAST = ivec2(3, 2);


const int Key_Backspace = 8, Key_Tab = 9, Key_Enter = 13, Key_Shift = 16, Key_Ctrl = 17, 
Key_Alt = 18, Key_Pause = 19, Key_Caps = 20, Key_Escape = 27, Key_Space = 32, 
Key_PageUp = 33, Key_PageDown = 34, Key_End = 35,Key_Home = 36, Key_LeftArrow = 37, 
Key_UpArrow = 38, Key_RightArrow = 39, Key_DownArrow = 40, Key_Insert = 45, 
Key_Delete = 46, Key_0 = 48, Key_1 = 49, Key_2 = 50, Key_3 = 51, Key_4 = 52,
Key_5 = 53, Key_6 = 54, Key_7 = 55, Key_8 = 56, Key_9 = 57, Key_A = 65, Key_B = 66, 
Key_C = 67, Key_D = 68, Key_E = 69, Key_F = 70, Key_G = 71, Key_H = 72,Key_I = 73, 
Key_J = 74, Key_K = 75, Key_L = 76, Key_M = 77, Key_N = 78, Key_O = 79, Key_P = 80,
Key_Q = 81, Key_R = 82, Key_S = 83, Key_T = 84, Key_U = 85,Key_V = 86, Key_W = 87, 
Key_X = 88, Key_Y = 89, Key_Z = 90, Key_LeftWindow = 91, Key_RightWindows = 92, 
Key_Select = 93, Key_Numpad0 = 96, Key_Numpad1 = 97, Key_Numpad2 = 98, Key_Numpad3 = 99,
Key_Numpad4 = 100, Key_Numpad5 = 101, Key_Numpad6 = 102, Key_Numpad7 = 103, 
Key_Numpad8 = 104, Key_Numpad9 = 105, Key_NumpadMultiply = 106, Key_NumpadAdd = 107,
Key_NumpadSubtract = 109, Key_NumpadPeriod = 110, Key_NumpadDivide = 111, Key_F1 = 112,
Key_F2 = 113, Key_F3 = 114, Key_F4 = 115, Key_F5 = 116, Key_F6 = 117, Key_F7 = 118,
Key_F8 = 119, Key_F9 = 120, Key_F10 = 121, Key_F11 = 122, Key_F12 = 123, 
Key_NumLock = 144, Key_ScrollLock = 145,Key_SemiColon = 186, Key_Equal = 187, 
Key_Comma = 188, Key_Dash = 189, Key_Period = 190, Key_ForwardSlash = 191, 
Key_GraveAccent = 192, Key_OpenBracket = 219, Key_BackSlash = 220, 
Key_CloseBraket = 221, Key_SingleQuote = 222;

vec2 KeyboardInput(sampler2D kb) {
    ivec4 inputs1 = ivec4(Key_UpArrow, Key_DownArrow, Key_RightArrow, Key_LeftArrow); //ARROWS
    ivec4 inputs2 = ivec4(Key_W, Key_S, Key_D, Key_A);//WASD
    //ivec4 inputs2 = ivec4(Key_E, Key_D, Key_F, Key_S);//ESDF
    
	vec2 i = vec2(max(key(inputs1.z,kb),key(inputs2.z,kb))   - max(key(inputs1.w,kb),key(inputs2.w,kb)), 
                  max(key(inputs1.x,kb),key(inputs2.x,kb)) - max(key(inputs1.y,kb),key(inputs2.y,kb)));
    
    float n = abs(abs(i.x) - abs(i.y));
    return clamp(i * (n + (1.0 - n)),-1.,1.);
}

vec3 CameraDirInput(sampler2D kb, vec2 op, out vec2 tdx, float ltz) {
    vec2 td = load(mouse_dir, self_texture).xy;
    vec2 m = vec2(-0.5*3.1415926+0.001, -0.0+0.001);
    m.y = -m.y;
    
    mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(m.y), sin(m.y), 0.0, -sin(m.y), cos(m.y));
    mat3 rotY = mat3(cos(m.x), 0.0, -sin(m.x), 0.0, 1.0, 0.0, sin(m.x), 0.0, cos(m.x));
    
    float ty = 0.;
    vec3 last_imc = vec3(load(last_iMouse, self_texture).xy,ltz);
    vec3 position_l = load(POSITION, self_texture).xyz;
    if(last_imc.x>0.)ty = (max(position_l.x-(start_pos.x-1.55),0.));
    else ty = min(position_l.x-(start_pos.x-0.25),0.);
    float tb = smoothstep(0.,1.75-0.5*sign(ty)-1.05*max(sign(ty),0.),iTime-last_imc.z+min(sign(ty),0.)*1.25);
    ty*=tb*tb;
    vec2 im = iMouse.xy/iResolution.y-0.5*iResolution.xy/iResolution.y;
    vec2 tix = vec2(step(vec2(0.47,0.4),abs(im)));
    float tx = 1.-min(dot(tix,vec2(1.)),1.);
    ty*=tx;
    
    float tva = (1.-smoothstep(0.,.75,start_pos.x-(position_l.x+ty)));
    op+=mouse_dir_ms*td.yx;
    tdx = -step(abs(td),vec2(0.5))*(abs(td) - (1.-smoothstep(0.025+0.125*tva,0.05+0.125*tva,abs(op.yx))));
    
    return (rotY * rotX) * vec3(mouse_dir_ms*td*(0.25+0.75*tva), ty).xyz;
}


void build_mip( out vec4 fragColor, ivec2 ipx )
{
    fragColor = vec4(0.);
    const float mscale = 10.;
    vec2 sc_res = (mscl/iResolution.xy)*(iResolution.xy/2.)/mscale;
    
    vec2 suv = (vec2(ipx)+0.5)/sc_res;
    ivec2 six = ivec2(suv);
    bool yx = true;
    if(any(greaterThan(six, ivec2(1,3))))return;
    yx = six.y>1;
    if(yx){
        six.y=six.y-2;
    }
    
    vec4 col = vec4(0.);
    const int lp = 10;
    float stp = .5*float(mscale)/float(lp);
    for(int i = 0; i<lp; i++){
        for(int j = 0; j<lp; j++){
            vec2 lsuv = (vec2(ipx)+0.5+(float(lp)/2.-vec2(i,j))*stp)/sc_res;
            lsuv = fract(lsuv*0.5)*2.;
            lsuv = clamp(lsuv,vec2(six),vec2(six)+1.);
            if(yx)col += textureLod(iChannel1, lsuv*0.5, 0.);
            else col += textureLod(iChannel0, lsuv*0.5, 0.);
        }
    }
    col = col/float(lp*lp);
    
    fragColor = col;
    return;
}

const vec3 tm = vec3(2.73,4.3,3.23);
void set_frame( out vec4 fragColor, vec2 fragCoord ){
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = clamp(textureLod(iChannel1, uv, 0.),0.,2.);
    vec2 tid = floor(2.*uv);
    int ti = int(tid.x)+2*int(tid.y);
    if(tid==vec2(1.,1.))uv+=-0.5;

    bool res_ch = ivec2(load(RES_LAST_LAST, self_texture))!=ivec2(iResolution.xy);
    float h0 = load(t_ha2, self_texture)[ti-1];
    
    if(h0<-0.5)fragColor = textureLod(iChannel0, uv, 0.).bgra;
    if(res_ch)fragColor = textureLod(iChannel0, uv, 0.).bgra;
    vec4 tcc = textureLod(iChannel0, uv, 0.).bgra;
    
    
    vec2 tuv = fragCoord.xy / iResolution.xy;
    tuv=fract(tuv*2.);
    float tft = iTime*0.75+float(ti)*15.3;
    
	float d = 0.5+0.5*noise(tuv*vec2(0.05,100.)+tft*vec2(0.5,1.5));
    d*= 0.5+0.5*noise(tuv*vec2(0.05,30.)+vec2(0.,tft*8.5));
    d*= 0.5+0.5*noise(tuv*vec2(0.05,10.5)+vec2(0.,tft*5.5));
    d *= hash12(300.*floor(tuv*100.)/100.+tft*0.1);
    d*=2.;
    float tt = abs(20.-mod(iTime*1.85+float(ti)*15.3,40.));
    d*=1.-smoothstep(0.5-0.001-2.*smoothstep(8.,10.,tt),0.5-.5*smoothstep(8.,10.,tt),abs(tuv.y-0.5));
    d*=d;
    d*=float((iFrame%3)<1);
    float d1 = d;
    
    tft = iTime+float(ti+4)*18.3;
	d = 0.5+0.5*noise(tuv*vec2(0.05,100.)+tft*vec2(0.5,1.5));
    d*= 0.5+0.5*noise(tuv*vec2(0.05,30.)+vec2(0.,tft*8.5));
    d*= 0.5+0.5*noise(tuv*vec2(0.05,10.5)+vec2(0.,tft*5.5));
    d *= hash12(300.*floor(tuv*100.)/100.+tft*0.1);
    d*=2.;
    tt = abs(20.-mod(iTime*1.25+float(ti+4)*18.3,40.));
    d*=1.-smoothstep(0.5-0.001-2.*smoothstep(11.,15.,tt),0.5-.5*smoothstep(11.,15.,tt),abs(tuv.y-0.5));
    d*=d;
    d*=float((iFrame%8)<1);
    
    fragColor.rgb=d1*tcc.rgb+fragColor.rgb*(1.-d1)+d*0.;
    fragColor.a=d*tcc.a+fragColor.a*(1.-d)+d1*0.25;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    ivec2 ipx = ivec2(fragCoord);
    fragColor=vec4(0.);
    if (any(greaterThan(ipx, MEMORY_BOUNDARY))){
        if(ipx.y>MEMORY_BOUNDARY.y+10-1)build_mip(fragColor, ipx- ivec2(0., MEMORY_BOUNDARY.y+10));
        ivec2 tid = ivec2(2.*fragCoord/iResolution.xy);
        if(tid!=ivec2(0,0))set_frame(fragColor, fragCoord);
        return;
    }
    
    fragColor = load(ipx, self_texture);
    
    vec3 position_l = load(POSITION, self_texture).xyz;
    bool is_init = load(INIT, self_texture).x>1.;
    
    if (iFrame == 0 || !is_init) 
    {
        position_l=start_pos;
        store(POSITION, ipx, vec4(start_pos, 0.), fragColor);
        store(POSITION_last, ipx, vec4(position_l, 0.), fragColor);
        store(TARGET, ipx, vec4(start_pos, 0.), fragColor);
        store(mouse_dir, ipx, vec4(mouse_dir_st,0.,0.), fragColor);
        store(tt_st, ipx, vec4(0.), fragColor);
        store(last_iMouse, ipx, vec4(iMouse.zw,0.,0.), fragColor);
        store(INIT, ipx, vec4(2.,0.,0.,0.), fragColor);
        store(INPUT, ipx, vec4(2.,0.,0.,0.), fragColor);
        store(RES_LAST, ipx, vec4(iResolution.xy,0.,0.), fragColor);
        store(RES_LAST_LAST, ipx, vec4(vec2(1.),0.,0.), fragColor);
        store(t_ha, ipx, vec4(0.), fragColor);
        store(t_ha2, ipx, vec4(0.), fragColor);
        return;
    }
    

    vec3 target      = load(TARGET, self_texture).xyz;   
    vec3 position    = load(POSITION, self_texture).xyz;
    vec2 res_l       = load(RES_LAST, self_texture).xy;
    
    vec3 ptarget = target;
    vec2 tdx;
    
    vec3 last_imc = load(last_iMouse, self_texture).xyz;
    if(sign(last_imc.x)!=sign(iMouse.z))last_imc=vec3(iMouse.zw,iTime);
    
    vec3 mdl = CameraDirInput(keyboard_texture,target.yz-position.yz, tdx, last_imc.z);
    vec3 mvl = mdl;
    
    float ltd = iTimeDelta * 1.75*smoothstep(2.75,7.5,iTime);
    target += mvl*vec3(1.*iTimeDelta*1.75,tdx*ltd*(1.-key_t(Key_Space,keyboard_texture)));
    ltd*=smoothstep(1.5,8.5,iTime);
    
    vec3 lp = position;
    position += (target - position) * iTimeDelta * 1.75;
    
    bool input_registered = false;
    input_registered = ivec2(res_l)!=ivec2(iResolution.xy);
    if(length(abs(position)-abs(lp))>0.0001)input_registered=true;
    
    store(TARGET, ipx, vec4(target, 0.0), fragColor);
    store(POSITION, ipx, vec4(position, 0.0), fragColor);
    
    if (iMouse.z>0.0) {
        vec2 im = iMouse.xy/iResolution.y-0.5*iResolution.xy/iResolution.y;
        vec2 tix = vec2(step(vec2(0.47,0.4),abs(im)));
        float tx = min(dot(tix,vec2(1.)),1.);
        tix.x*=step(0.5,abs(tix.x-tix.y));
        im = tix*sign(im);
        
        im = tx*im+(1.-tx)*load(mouse_dir, self_texture).xy;
        store(mouse_dir, ipx, vec4(im,0.,0.), fragColor);
    }else{
        vec2 tixn = KeyboardInput(keyboard_texture);
        vec2 tix = abs(tixn);
        float tx = min(dot(tix,vec2(1.)),1.);
        tixn.x*=step(0.5,abs(tix.x-tix.y));
        if(tx>0.5){
            store(mouse_dir, ipx, vec4(tixn,0.,0.), fragColor);
        }
    }
    
    float ltt = clamp(load(tt_st, self_texture).x,-1.,1.);
    float nlt = clamp(ltt+clamp(iTime-load(last_iMouse, self_texture).z,0.,1.)*(((1.-float(sign(load(mouse_dir, self_texture).x)==sign(ltt)))+(float(sign(load(mouse_dir, self_texture).x)==sign(ltt)))*min(1.-abs(ltt),1.))*ltd/1.75*load(mouse_dir, self_texture).x-sign(ltt)*min(sqrt(abs(ltt))*1.5,1.)*ltd/1.75*abs(load(mouse_dir, self_texture).y)),-1.,1.);
    if(abs(sign(load(mouse_dir, self_texture).y))>0.5)if(sign(nlt)!=sign(ltt)&&abs(nlt)<0.1)nlt=0.;
    store(tt_st, ipx, vec4(nlt,ltt,0.,0.), fragColor);

    store(last_iMouse, ipx, vec4(last_imc,0.), fragColor);
    store(POSITION_last, ipx, vec4(position_l, 0.), fragColor);

    
    store(INPUT, ipx, vec4(input_registered?2.:0.,0.,0.,0.), fragColor);
    
    store(RES_LAST, ipx, vec4(iResolution.xy,0.,0.), fragColor);
    store(RES_LAST_LAST, ipx, vec4(res_l,0.,0.), fragColor);
    
    
    vec2 tid = vec2(1.,0.);
    int ti = int(tid.x)+2*int(tid.y);
    vec3 h0 = load(t_ha, self_texture).rgb;
    float h1 = hash12(tid*33.3+3.133+3.*vec2(floor((iTime)/tm[ti-1])));
    tid = vec2(0.,1.);
    ti = int(tid.x)+2*int(tid.y);
    float h2 = hash12(tid*33.3+3.133+3.*vec2(floor(iTime/tm[ti-1])));
    tid = vec2(1.,1.);
    ti = int(tid.x)+2*int(tid.y);
    float h3 = hash12(tid*33.3+3.133+3.*vec2(floor(iTime/tm[ti-1])));
    vec3 hn = floor(vec3(h1,h2,h3)*1000.)/1000.;
    
    vec3 tt = mod(vec3(iTime),tm)/tm;
    
    
    vec3 h02o = load(t_ha2, self_texture).rgb;
    vec3 h02 = (1.-vec3(equal(ivec3(hn*100.),ivec3(h0*100.))));
    vec3 thh2 = vec3(greaterThan(h02o,vec3(0.5)));
    vec3 tsh2 = sign(max(tt-max(h0,vec3(0.35)),vec3(0.)));
    h02o=h02+(1.-h02)*(thh2*(-tsh2+(1.-tsh2)*h02o));
    
    
    store(t_ha, ipx, vec4(hn,0.), fragColor);
    store(t_ha2, ipx, vec4(h02o,0.), fragColor);
    
}









