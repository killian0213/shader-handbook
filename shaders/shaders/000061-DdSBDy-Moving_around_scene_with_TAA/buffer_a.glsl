// Buffer A (buffer) — Moving around scene with TAA by morimea
// https://www.shadertoy.com/view/DdSBDy


// this exist just because Shadertoy has only 4 buffers

// r is OBJ_ID
// g is current depth
// b is last depth

// camera control use 1 alpha pixel per value

// also in alpha saved noise
// noise everywhere except MEMORY_BOUNDARY and top right pixel

#define keyboard_texture iChannel3

#ifdef move_rounds
const vec3 start_pos = vec3(-49., 6.5, 0.); //do not edit this
const vec3 start_pos_edit = vec3(1.7, .1, 0.); //edit this
#else
const vec3 start_pos = vec3(-49., 6.5, 0.1); //edit this
#endif
const vec2 start_mouse = vec2(-0.05, -0.25);

const float speed = 2.5;
#define iTimeDelta min(iTimeDelta,1./10.)

void store(ivec2 P, ivec2 ipx, float V, inout vec4 fc){ if(ipx==P) fc.a = V;}

float key(int K, sampler2D kb){return step(0.5, texelFetch(kb, ivec2(K, 0), 0).x);}



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
    return i * (n + (1.0 - n)*0.707106);
}

vec3 CameraDirInput(vec2 vm, sampler2D kb) {
    vec2 m = vm;
    m.y = -m.y;
    
    mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(m.y), sin(m.y), 0.0, -sin(m.y), cos(m.y));
    mat3 rotY = mat3(cos(m.x), 0.0, -sin(m.x), 0.0, 1.0, 0.0, sin(m.x), 0.0, cos(m.x));
    
    return (rotY * rotX) * vec3(KeyboardInput(kb), 0.0).xzy;
}

void Collision_floor(vec3 prev, inout vec3 p) {
    //return;
    if(length(p.xz-vec2(49.,0.))>49.8){
        float a = angle2d(prev.xz-vec2(49.,0.),vec2(0.,0.));
        vec2 ta = -(vec2(min(length(prev.xz-vec2(49.,0.)),50.),0.)*MD(a)-vec2(49.,0.));
        p.xz=ta;
        p.y=prev.y;
    }
    if(length(p.xz-vec2(49.,0.))<44.3){
        float a = angle2d(prev.xz-vec2(49.,0.),vec2(0.,0.));
        vec2 ta = -(vec2(max(length(prev.xz-vec2(49.,0.)),44.3),0.)*MD(a)-vec2(49.,0.));
        p.xz=ta;
        p.y=prev.y;
    }
    
    if (p.y < -1.05) p = vec3(prev.xz, max(-1.05, prev.y)).xzy;
    if (p.y > 2.85) p = vec3(prev.xz, min(2.85, prev.y)).xzy;
}

vec2 render_new_minDist(in vec2 fragCoord, vec2 halton_px_shift, vec3 ro, vec2 m) {

    vec2 fc=fragCoord.xy;
    fragCoord.xy += halton_px_shift;
    
    vec2 uv = fragCoord/iResolution.xy * 2.0 - 1.0;
    uv.y *= iResolution.y/iResolution.x;
    vec3 rd;
    SetCamera_m(uv, m, rd, iResolution.xy);
    
    HitInfo hit;
	bool rayHit = minDist(ro, rd, hit);
    
    return vec2(float(hit.obj_type)+0.5,hit.t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   

    float l_t = load(LOCAL_T,iChannel0);
    float l_t_last = load(LOCAL_T_last,iChannel0);
    float llmc = load(LMC,iChannel0);
    
#ifdef move_rounds
    if (iMouse.z>0.0){llmc+=-2.5*iTimeDelta*llmc-0.001;}else{llmc+=1.25*iTimeDelta*llmc+0.001;}
    llmc=clamp(llmc,0.,1.);
    l_t_last = l_t;
    rtimer_last = l_t_last;
    l_t+=iTimeDelta*llmc;
    rtimer = l_t;
#ifdef move_SUN_circle_inf
    lightDir.xz=lightDir.xz*MD(-rtimer*rspd);
#endif
#endif

    ivec2 ipx = ivec2(fragCoord);
    
    vec2 res_l = vec2(load(RES_LAST0,iChannel0),load(RES_LAST1,iChannel0));
    bool input_registered = false;
    bool res_ch = ivec2(res_l)!=ivec2(iResolution.xy);
    input_registered = res_ch;
    // resolution control
    input_registered = input_registered||(load(ivec2(iResolution.xy)-1, iChannel0))<0.5;
    //input_registered=true;
    bool input_registered_TMP = input_registered;
    
    
    vec3 target      = vec3(load(TARGET0, iChannel0),load(TARGET1, iChannel0),load(TARGET2, iChannel0));   
#ifdef move_rounds
    vec3 htarget     = vec3(load(HTARGET0, iChannel0),load(HTARGET1, iChannel0),load(HTARGET2, iChannel0));   
#endif
    vec3 position    = vec3(load(POSITION0, iChannel0),load(POSITION1, iChannel0),load(POSITION2, iChannel0));
    vec3 position_l = position;
    
    vec2 pm          = vec2(load(PMOUSE0, iChannel0),load(PMOUSE1, iChannel0));
    vec3 vm          = vec3(load(VMOUSE0, iChannel0),load(VMOUSE1, iChannel0),load(VMOUSE2, iChannel0));
    
    bool is_init = load(INIT0, iChannel0)<1.;
    if (iFrame == 0 || is_init) 
    {
        target = start_pos;
#ifdef move_rounds
        htarget = start_pos_edit;
        position = start_pos+start_pos_edit;
        position_l = start_pos+start_pos_edit;
#else
        position = start_pos;
        position_l = start_pos;
#endif
        pm = start_mouse;
        vm.xy = start_mouse.xy;
    }
#ifdef move_rounds
    vec3 ptarget = htarget;
    htarget += CameraDirInput(vm.xy, keyboard_texture) * min(iTimeDelta,1./10.) * speed;
    Collision_floor(ptarget, htarget);
#else
    vec3 ptarget = target;
    target += CameraDirInput(vm.xy, keyboard_texture) * min(iTimeDelta,1./10.) * speed;
    //Collision_floor(ptarget, target);
#endif
    
    vec3 lp = position;
#ifdef move_rounds
    target.xz = vec2(-49.,0.)*MD(-rtimer*rspd);
    target.y = 6.5+htarget.y;
    target.xz+=htarget.xz*MD(-rtimer*rspd);
#endif
    position += (target - position) * min(iTimeDelta,1./10.) * 5.0;

    
    
    if(length(abs(position)-abs(lp))>0.0001)input_registered=true;
    
    vec3 ro = position;
    vec2 im = vec2(0.);
    
    if (iMouse.z>0.0) {
        vec2 tpm = pm + (abs(iMouse.zw) - iMouse.xy)/iResolution.y;
        input_registered=input_registered||(abs(tpm.x-vm.x)>.5/iResolution.y||abs(tpm.y-vm.y)>.5/iResolution.y);
    	im = tpm;
    }
    else {
    	im = vm.xy;
    }

#ifdef use_dynamic_TAA
    vec2 halton = (halton(iFrame % 360 + 1) - 0.5f);
#else
    vec2 halton = input_registered?vec2(0.):halton(iFrame % 360 + 1) - 0.5f;
#endif
    
    fragColor.rg = render_new_minDist(fragCoord, halton, ro, im);
    fragColor.b = texelFetch(iChannel0,ipx,0).y;
    fragColor.a = texelFetch(iChannel0,ipx,0).a;
    
    if(ipx==ivec2(iResolution.xy)-1){
        fragColor.a=2.; // resolution control for pause case
        return;
    }
//--------------------
    
    
    float bnoise=fragColor.a;
    if(input_registered_TMP||iFrame==0)
    if (any(greaterThan(ipx, MEMORY_BOUNDARY))){bnoise=Bnoise(fragCoord+iDate.w*0.01);fragColor.a=bnoise;}
    
    if (any(greaterThan(ipx, MEMORY_BOUNDARY))) return;
    
    vec2 vm_l = vec2(load(VMOUSE0, iChannel0),load(VMOUSE1, iChannel0));
    
    if (iFrame == 0 || is_init) {
        vm_l=start_mouse;
#ifdef move_rounds
        vec3 position_l = start_pos+start_pos_edit;
        vec3 start_pos_t = start_pos+start_pos_edit;
#else
        vec3 position_l = start_pos;
        vec3 start_pos_t = start_pos;
#endif
        store(POSITION0, ipx, start_pos_t.x, fragColor); // ro
        store(POSITION1, ipx, start_pos_t.y, fragColor);
        store(POSITION2, ipx, start_pos_t.z, fragColor);
        store(POSITION_last0, ipx, position_l.x, fragColor); // last_ro
        store(POSITION_last1, ipx, position_l.y, fragColor);
        store(POSITION_last2, ipx, position_l.z, fragColor);
        store(TARGET0, ipx, start_pos_t.x, fragColor); // mouse look
        store(TARGET1, ipx, start_pos_t.y, fragColor);
        store(TARGET2, ipx, start_pos_t.z, fragColor);
#ifdef move_rounds
        store(HTARGET0, ipx, start_pos_edit.x, fragColor); // mouse look
        store(HTARGET1, ipx, start_pos_edit.y, fragColor);
        store(HTARGET2, ipx, start_pos_edit.z, fragColor);
#endif
        store(VMOUSE0, ipx, start_mouse.x, fragColor); // virtual mouse (rotation_mat)
        store(VMOUSE1, ipx, start_mouse.y, fragColor);

        store(VMOUSE_last0, ipx, vm_l.x, fragColor); // last virtual mouse
        store(VMOUSE_last1, ipx, vm_l.y, fragColor);
        store(PMOUSE0, ipx, start_mouse.x, fragColor); // real mouse pos
        store(PMOUSE1, ipx, start_mouse.y, fragColor);
        store(INIT0, ipx, 2., fragColor); // is_init(0 false, 2 true)
        store(RES_CHANGE, ipx, 0., fragColor); // 0 true 1 false
        store(INPUT0, ipx, 2., fragColor); // key_pressed(0 false, 2 true) 
        store(INPUT0_timer, ipx, 0., fragColor);
        store(RES_LAST0, ipx, iResolution.x, fragColor); // xy = last_resolution
        store(RES_LAST1, ipx, iResolution.y, fragColor);
        store(HALTON0, ipx, halton.x, fragColor);
        store(HALTON1, ipx, halton.y, fragColor);
        store(HALTON_last0, ipx, 0., fragColor);
        store(HALTON_last1, ipx, 0., fragColor);
        store(LOCAL_T, ipx, 0., fragColor);
        store(LOCAL_T_last, ipx, 0., fragColor);
        store(LMC, ipx, 0., fragColor);
        return;
    }
    
    store(LMC, ipx, llmc, fragColor);
    store(LOCAL_T, ipx, l_t, fragColor);
    store(LOCAL_T_last, ipx, l_t_last, fragColor);
    store(TARGET0, ipx, target.x, fragColor);
    store(TARGET1, ipx, target.y, fragColor);
    store(TARGET2, ipx, target.z, fragColor);
#ifdef move_rounds
    store(HTARGET0, ipx, htarget.x, fragColor);
    store(HTARGET1, ipx, htarget.y, fragColor);
    store(HTARGET2, ipx, htarget.z, fragColor);
#endif
    store(POSITION0, ipx, position.x, fragColor);
    store(POSITION1, ipx, position.y, fragColor);
    store(POSITION2, ipx, position.z, fragColor);
    
    if (iMouse.z>0.0) {
        vec2 tpm = pm + (abs(iMouse.zw) - iMouse.xy)/iResolution.y;
        input_registered=input_registered||(abs(tpm.x-vm.x)>.5/iResolution.y||abs(tpm.y-vm.y)>.5/iResolution.y);
    	store(VMOUSE0, ipx, tpm.x, fragColor);
        store(VMOUSE1, ipx, tpm.y, fragColor);
        store(VMOUSE2, ipx, 1., fragColor);
    }
    else if (vm.z > 0.5) {
    	store(PMOUSE0, ipx, vm.x, fragColor);
        store(PMOUSE1, ipx, vm.y, fragColor);
        store(VMOUSE2, ipx, 0., fragColor);
    }
    store(POSITION_last0, ipx, position_l.x, fragColor);
    store(POSITION_last1, ipx, position_l.y, fragColor);
    store(POSITION_last2, ipx, position_l.z, fragColor);
    store(VMOUSE_last0, ipx, vm_l.x, fragColor);
    store(VMOUSE_last1, ipx, vm_l.y, fragColor);
    
    store(INPUT0, ipx, input_registered?2.:0., fragColor);
    float iot = load(INPUT0_timer, iChannel0);
    store(INPUT0_timer, ipx, input_registered?0.:iot+iTimeDelta, fragColor);
    
    
    store(HALTON0, ipx, halton.x, fragColor);
    store(HALTON1, ipx, halton.y, fragColor);
    
    vec2 halton_last = vec2(load(HALTON0,iChannel0),load(HALTON1,iChannel0));
    store(HALTON_last0, ipx, halton_last.x, fragColor);
    store(HALTON_last1, ipx, halton_last.y, fragColor);
    
    store(RES_LAST0, ipx, iResolution.x, fragColor);
    store(RES_LAST1, ipx, iResolution.y, fragColor);
    
    store(RES_CHANGE, ipx, res_ch?0.:1., fragColor);
    

}