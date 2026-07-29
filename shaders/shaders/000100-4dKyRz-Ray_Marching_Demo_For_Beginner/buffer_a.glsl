// Buf A (buffer) — Ray Marching Demo For Beginner by Trashe725
// https://www.shadertoy.com/view/4dKyRz


float asp;
vec4 bufA;
vec4 bufB;
vec4 bufC;
vec4 bufD;


vec4 gui_check_box(vec4 col, vec2 uv, vec2 pos, float scale, bool check)
{
    
    float unit = asp * 0.01 * scale;
    float h = box(uv, pos, vec2(1.8*unit));
    col = mix(col, vec4(vec3(0.9, 0.9, 1.), 1.), smoothstep(0.01, 0., h));
    col = mix(col, vec4(vec3(0., 0., 0.5), 1.), smoothstep(0.01, 0., abs(h)));
    
    
    if(check)
    {
        const vec2 dir1 = normalize(vec2(-1., 1.2));
        const vec2 dir2 = normalize(vec2(1., 1.));
    	h = line(uv, pos+vec2(0., unit*-0.5), pos+dir1*unit*2.1);
        col = mix(col, vec4(1., 0., 0., 1.), smoothstep(0.01, 0., abs(h)));
        h = line(uv, pos+vec2(0., unit*-0.5), pos+dir2*unit*4.2);
        col = mix(col, vec4(1., 0., 0., 1.), smoothstep(0.01, 0., abs(h)));
    }
    
    return col;
}

vec4 gui_arrow_left(vec4 col, vec2 uv, vec2 pos, float scale, bool check)
{
    float unit = asp * 0.01 * scale;
    float h;
    
    h = triangle(uv, pos+vec2(unit*1.8, -unit*2.), pos+vec2(unit*1.8, unit*2.), pos+vec2(-unit*1.8, 0.));
    if(!check) h = abs(h);
    col = mix(col, vec4(vec3(0.5), 1.), smoothstep(0.01, 0., h));
    
    
    return col;
}

vec4 gui_arrow_right(vec4 col, vec2 uv, vec2 pos, float scale, bool check)
{
	float unit = asp * 0.01 * scale;
    float h;
    
    h = triangle(uv, pos+vec2(-unit*1.8, -unit*2.), pos+vec2(-unit*1.8, unit*2.), pos+vec2(unit*1.8, 0.));
    if(!check) h = abs(h);
    col = mix(col, vec4(vec3(0.5), 1.), smoothstep(0.01, 0., h));
    
    
    return col;
}

float word_map(vec2 uv, vec2 pos, int ascii, vec2 unit)
{
    return get_text(uv, pos, ascii, unit, iChannel1);
}

vec4 put_text_drawmap(vec4 col, vec2 uv, vec2 pos, float scale)
{
	float unit = asp * scale * 0.1;
    float h = 0.;
    vec2 sc = vec2(unit, unit*0.8);
    
    // S
    h = max(h, word_map(uv, pos, 83, sc));
    // h
    h = max(h, word_map(uv, pos+vec2(unit*0.4, 0.), 104, sc));
    // o
    h = max(h, word_map(uv, pos+vec2(unit*0.8, 0.), 111, sc));
    // w
    h = max(h, word_map(uv, pos+vec2(unit*1.2, 0.), 119, sc));
    // M
    h = max(h, word_map(uv, pos+vec2(unit*2.0, 0.), 77, sc));
    // a
    h = max(h, word_map(uv, pos+vec2(unit*2.4, 0.), 97, sc));
    // p
    h = max(h, word_map(uv, pos+vec2(unit*2.8, 0.), 112, sc));
    
    
    col = mix(col, vec4(1.-vec3(h), 1.), h);
    
    return col;
}

vec4 put_text_drawstart(vec4 col, vec2 uv, vec2 pos, float scale)
{
	float unit = asp * scale * 0.1;
    float h = 0.;
    vec2 sc = vec2(unit, unit*0.8);
    
    // M
    h = max(h, word_map(uv, pos, 77, sc));
    // a
    h = max(h, word_map(uv, pos+vec2(unit*0.4, 0.), 97, sc));
    // r
    h = max(h, word_map(uv, pos+vec2(unit*0.8, 0.), 114, sc));
    // c
    h = max(h, word_map(uv, pos+vec2(unit*1.15, 0.), 99, sc));
    // h
    h = max(h, word_map(uv, pos+vec2(unit*1.5, 0.), 104, sc));
    
    col = mix(col, vec4(1.-vec3(h), 1.), h);
    
    return col;
}

vec4 put_text_target(vec4 col, vec2 uv, vec2 pos, float scale)
{
	float unit = asp * scale * 0.1;
    float h = 0.;
    vec2 sc = vec2(unit, unit*0.8);
    
    // S
    h = max(h, word_map(uv, pos, 83, sc));
    // h
    h = max(h, word_map(uv, pos+vec2(unit*0.4, 0.), 104, sc));
    // o
    h = max(h, word_map(uv, pos+vec2(unit*0.8, 0.), 111, sc));
    // w
    h = max(h, word_map(uv, pos+vec2(unit*1.2, 0.), 119, sc));
    
    // T
    h = max(h, word_map(uv, pos+vec2(unit*2.0, 0.), 84, sc));
    // a
    h = max(h, word_map(uv, pos+vec2(unit*2.35, 0.), 97, sc));
    // r
    h = max(h, word_map(uv, pos+vec2(unit*2.8, 0.), 114, sc));
    // g
    h = max(h, word_map(uv, pos+vec2(unit*3.15, 0.), 103, sc));
    // e
    h = max(h, word_map(uv, pos+vec2(unit*3.5, 0.), 101, sc));
    // t
    h = max(h, word_map(uv, pos+vec2(unit*3.95, 0.), 116, sc));
    
    col = mix(col, vec4(1.-vec3(h), 1.), h);
    
    return col;
}

vec4 put_text_fixed(vec4 col, vec2 uv, vec2 pos, float scale, bool p)
{
	float unit = asp * scale * 0.1;
    float h = 0.;
    vec2 sc = vec2(unit, unit*0.8);
    
    // F
    h = max(h, word_map(uv, pos, 70, sc));
    // i
    h = max(h, word_map(uv, pos+vec2(unit*0.35, 0.), 105, sc));
    // x
    h = max(h, word_map(uv, pos+vec2(unit*0.7, 0.), 120, sc));
    // e
    h = max(h, word_map(uv, pos+vec2(unit*1.05, 0.), 101, sc));
    // d
    h = max(h, word_map(uv, pos+vec2(unit*1.4, 0.), 100, sc));
    
    if(p){
        //o
    	h = max(h, word_map(uv, pos+vec2(unit*2.1, 0.), 111, sc));
        //r
        h = max(h, word_map(uv, pos+vec2(unit*2.45, 0.), 114, sc));
        //i
        h = max(h, word_map(uv, pos+vec2(unit*2.8, 0.), 105, sc));
        //g
        h = max(h, word_map(uv, pos+vec2(unit*3.15, 0.), 103, sc));
        //i
        h = max(h, word_map(uv, pos+vec2(unit*3.5, 0.), 105, sc));
        //n
        h = max(h, word_map(uv, pos+vec2(unit*3.85, 0.), 110, sc));
    }
    else{
        //t
    	h = max(h, word_map(uv, pos+vec2(unit*2.1, 0.), 116, sc));
        //a
        h = max(h, word_map(uv, pos+vec2(unit*2.45, 0.), 97, sc));
        //r
        h = max(h, word_map(uv, pos+vec2(unit*2.8, 0.), 114, sc));
        //g
        h = max(h, word_map(uv, pos+vec2(unit*3.15, 0.), 103, sc));
        //e
        h = max(h, word_map(uv, pos+vec2(unit*3.5, 0.), 101, sc));
        //t
        h = max(h, word_map(uv, pos+vec2(unit*3.85, 0.), 116, sc));
    }
    
    col = mix(col, vec4(1.-vec3(h), 1.), h);
    
    return col;
}

vec4 put_text_step_count(vec4 col, vec2 uv, vec2 pos, float scale, int count)
{
	float unit = asp * scale * 0.1;
    float h = 0.;
    vec2 sc = vec2(unit, unit*0.8);
    
    int d = count % 10;
    int t = count / 10;
    
    h = max(h, word_map(uv, pos+vec2(unit*0.35, 0.), 48+d, sc));
    
    if(t > 0)
    {
    	h = max(h, word_map(uv, pos, 48+t, sc));
    }
    
    col = mix(col, vec4(1.-vec3(h), 1.), h);
    
    return col;
}

vec4 put_text_step(vec4 col, vec2 uv, vec2 pos, float scale)
{
	float unit = asp * scale * 0.1;
    float h = 0.;
    vec2 sc = vec2(unit, unit*0.8);
    
    // S
    h = max(h, word_map(uv, pos, 83, sc));
    // t
    h = max(h, word_map(uv, pos+vec2(unit*0.35, 0.), 116, sc));
    // e
    h = max(h, word_map(uv, pos+vec2(unit*0.7, 0.), 101, sc));
    // p
    h = max(h, word_map(uv, pos+vec2(unit*1.05, 0.), 112, sc));
    
    col = mix(col, vec4(1.-vec3(h), 1.), h);
    
    return col;
}

vec4 put_text_map(vec4 col, vec2 uv, vec2 pos, float scale)
{
	float unit = asp * scale * 0.1;
    float h = 0.;
    vec2 sc = vec2(unit, unit*0.8);
    
    // M
    h = max(h, word_map(uv, pos, 77, sc));
    // a
    h = max(h, word_map(uv, pos+vec2(unit*0.35, 0.), 97, sc));
    // p
    h = max(h, word_map(uv, pos+vec2(unit*0.7, 0.), 112, sc));
    
    col = mix(col, vec4(1.-vec3(h), 1.), h);
    
    return col;
}

void initBuffer()
{
	bufA = texture(iChannel0, vec2(0.0, 0.0));
    bufB = texture(iChannel0, vec2(1.0, 0.0));
    bufC = texture(iChannel0, vec2(0.0, 1.0));
    bufD = texture(iChannel0, vec2(1.0, 1.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    asp = iResolution.x/iResolution.y;
    vec2 uv = (-iResolution.xy + 2.*fragCoord.xy)/iResolution.y;
    vec4 col = vec4(vec3(1.), 0.);
    
    initBuffer();
    
    col = gui_check_box(col, uv, vec2(-asp*0.9, 0.9), 0.8, is(GET_DRAW_MAP));    //draw map
    col = put_text_drawmap(col, uv, vec2(-asp*0.84, 0.9), 0.7);
    
    col = gui_check_box(col, uv, vec2(-asp*0.9, 0.78), 0.8, is(GET_DRAW_START));  //draw start
    col = put_text_drawstart(col, uv, vec2(-asp*0.84, 0.78), 0.7);
    
    col = gui_check_box(col, uv, vec2(-asp*0.9, 0.66), 0.8, is(GET_SHOW_TAR));   //show target point
    col = put_text_target(col, uv, vec2(-asp*0.84, 0.66), 0.7);
    
    col = gui_check_box(col, uv, vec2(-asp*0.9, 0.54), 0.8, is(FIX_ORI));   //fix origin point
    col = put_text_fixed(col, uv, vec2(-asp*0.84, 0.54), 0.7, true);
    
    col = gui_check_box(col, uv, vec2(-asp*0.9, 0.42), 0.8, is(FIX_TAR));   //fix target point
    col = put_text_fixed(col, uv, vec2(-asp*0.84, 0.42), 0.7, false);
    
    col = gui_arrow_left(col, uv, vec2(-asp*0.9, 0.30), 0.8, GET_STEP_COUNT!=MAX_STEP_COUNT);  //step count
    col = put_text_step_count(col, uv, vec2(-asp*0.84, 0.30), 0.7, int(GET_STEP_COUNT));
    col = gui_arrow_right(col, uv, vec2(-asp*0.77, 0.30), 0.8, GET_STEP_COUNT!=MIN_STEP_COUNT);
    col = put_text_step(col, uv, vec2(-asp*0.72, 0.3), 0.7);
    
    col = gui_arrow_left(col, uv, vec2(-asp*0.9, 0.18), 0.8, GET_MAP_NUM!=MAX_MAP_COUNT);  //map count
    col = put_text_step_count(col, uv, vec2(-asp*0.84, 0.18), 0.7, int(GET_MAP_NUM)+1);
    col = gui_arrow_right(col, uv, vec2(-asp*0.77, 0.18), 0.8, GET_MAP_NUM!=MIN_MAP_COUNT);
    col = put_text_map(col, uv, vec2(-asp*0.72, 0.18), 0.7);
    
    fragColor = col;
}