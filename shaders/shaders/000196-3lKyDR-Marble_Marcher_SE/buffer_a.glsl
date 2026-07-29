// Buffer A (buffer) — Marble Marcher: SE by michael0884
// https://www.shadertoy.com/view/3lKyDR

//Controller

#define CAMERA_SPEED 5./60.
#define MOUSE_SENSITIVITY 0.2/60.

bool KeyPressEvent(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,1), 0 ).x > 0.5;
}

bool isKeyPressed(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,0), 0 ).x > 0.5;
}

struct Level
{
    float FracScale, FracAng1, FracAng2;
    vec3 FracShift, FracCol; 
    vec4 MarblePos, FlagPos;
    bool isPlanet;
};

const int levelnum = 11;
const Level[] Levels = Level[]( 
//Jump the crater
Level(1.8, -0.12, 0.5,vec3(-2.12, -2.75, 0.49),vec3(0.42, 0.38, 0.19),
      vec4(-2.95862, 2.68825, -1.11868, 0.035),vec4(2.95227, 2.65057, 1.11848, 0.035),false),
//Too many trees
Level(1.9073f, -9.83f, -1.16f, vec3(-3.508, -3.593, 3.295),vec3(-0.34, 0.12, -0.08),
      vec4(-3.40191, 4.14347, -3.48312, 0.04),vec4(3.40191, 4.065, 3.48312, 0.04),false),
//Hole in one
Level(2.02f, -1.57f, 1.62f, vec3(-3.31f, 6.19f, 1.53f),vec3(0.12f, -0.09f, -0.09f),
      vec4(3.18387f, 5.99466f, 0.0f, 0.009f),vec4(0.0f, -6.25f, 0.0f, 0.009f),false),
////Around the world
//Level(1.65f, 0.37f, 5.26f, vec3(-1.41f, -0.22f, -0.77f),vec3(0.14f, -1.71f, 0.31f),
//      vec4(0.0f, 2.29418f, 0.0f, 0.01f),vec4(0.0f, -2.25f, 0.0f, 0.01f),true),
//Beware Of Bumps     
Level(1.66f, 1.52f, 0.19f,vec3(-3.83f, -1.94f, -1.09f),vec3(0.42f, 0.38f, 0.19f),
      vec4(0.68147f, 2.80038f, 2.52778f,0.02f),vec4(0.0f, 2.84448f, -2.71705f, 0.02f),false),
//Mountain Climbing
Level(1.58f, -1.45f, 3.95f,vec3(-1.55f, -0.13f, -2.52f),vec3(-1.17f, -0.4f, -1.0f),
      vec4(0.0f, 3.36453f, 2.28284f, 0.02f),vec4(0.0f, 3.68893f, -0.604513f, 0.02f),false),
//Mind the gap                        
Level(1.81,-4.84,-2.99,vec3(-2.905, 0.765, -4.165),vec3(0.251,0.337,0.161),
      vec4(-4.63064f, 3.8365f, 0.0f, 0.022f),vec4(4.63f, 3.61f, 0.0f, 0.022f),false),
//The Sponge
Level(1.88f, 1.52f, 4.91f,vec3(-4.54f, -1.26f, 0.1f),vec3(-1.0f, 0.3f, -0.43f),
      vec4(-2.8896f, 3.76526f, 0.0f, 0.03f),vec4(2.88924f, 3.73f, 0.0f, 0.03f),false),
//Build Up Speed
Level(2.08f, -4.79f, 3.16f,vec3(-7.43f, 5.96f, -6.23f),vec3(0.16f, 0.38f, 0.15f),
      vec4(6.06325f, 6.32712f, 0.0f, 0.023f),vec4(0.0f, 6.72f, 0.0f, 0.023f),false),
//Around The Citadel
Level(2.0773f, -9.66f, -1.34f,vec3(-1.238f, -1.533f, 1.085f),vec3(0.42f, 0.38f, 0.19f),
      vec4(1.03543f, 1.06432f, 1.22698f, 0.01f),vec4(-1.39536f, 0.641835f, 0.0f, 0.01f),false),
//Top Of The Citadel
Level(2.0773f, -9.66f, -1.34f,vec3(-1.238f, -1.533f, 1.085f),vec3(0.42f, 0.38f, 0.19f),
      vec4(1.04172f, 1.41944f, 1.09742f, 0.005f),vec4(-1.04172f, 1.414f, -1.09742f, 0.005f),false),
//Mega Citadel
Level(1.4731, 0.0f, 0.0f, vec3(-10.27, 3.28, -1.90),vec3(1.17, 0.07, 1.27),
      vec4(-0.05, 14.69, 0.02, 0.009),vec4(-14.76, 0.01, -0.00, 0.009),false)
 );

int GMODE, curLVL;

void LoadLevel(Level LVL)
{
    iFracScale = LVL.FracScale;
    iFracAng1 = LVL.FracAng1;
    iFracAng2 = LVL.FracAng2;
    iFracShift = LVL.FracShift;
    iFracCol = LVL.FracCol;
    iMarblePos = LVL.MarblePos;
    iMarbleVel = vec3(0.);
    iFlagPos = LVL.FlagPos;
    isPlanet = float(LVL.isPlanet);
    
    //set cemera to point to the flag
    vec3 m2f = normalize(iFlagPos.xyz - iMarblePos.xyz);
    float phi = atan(m2f.z, m2f.x);
    float theta = acos(m2f.y);
    ang.xy = vec2(phi - PI,PI - theta);
    //camera distance from marble
    radius = 10.;
}


int checkMenuClick(vec2 p, vec2 pos, float sizescale, ivec2 range)
{
    for(int i = range.x; i<=range.y; i++)
    {
        vec2 dx = vec2(pos.x - p.x, iResolution.y - pos.y - p.y);
        vec2 size = sizescale*Buttons[i].size;
        
        if(step(dx.y - size.x, 0.0)*step(0.0, dx.y)*step(0.0, dx.x + size.y)*step(dx.x, 0.0) > 0.5) 
            return i;
            
        pos.y +=1.2*size.x;
    }
    return -1;
}

void PhysicsIteration(float dt, vec3 marble_force, float frictionm)
{
    vec3 closest_fractal_point = closestPoint(iMarblePos.xyz);
    vec3 dx = closest_fractal_point - iMarblePos.xyz;
    float dist = length(dx);
    dx = normalize(dx);
    float onGround = step(dist, iMarblePos.w);
    float force = ((dist < iMarblePos.w*1.14)?ground_force:air_force)*iMarblePos.w;
    float friction =((dist < iMarblePos.w*1.14)?ground_friction:air_friction);
    vec3 Gvec = (isPlanet==1.0)?normalize(iMarblePos.xyz):vec3(0.,1.,0);
    //unintersect
    iMarblePos.xyz += 0.3*onGround*dx*(dist - iMarblePos.w);
    //momentum update
    iMarbleVel += -marble_bounce*onGround*max(0.,dot(iMarbleVel, dx))*dx;

    //update velocity
    iMarbleVel += (-iMarblePos.w*gravity*Gvec +  frictionm*(friction - 1.0)*iMarbleVel + force*marble_force)*dt;
    //update position
    iMarblePos.xyz += iMarbleVel*dt;
}

void START(int levelid)
{
    levelid = levelid%levelnum;
    timers = vec3(-3.*60., 0., iTimeDelta);
    GMODE = 3;
    curLVL = levelid;
    LoadLevel(Levels[levelid]);
}

void mainImage( out vec4 c, in vec2 p )
{
    ivec2 pi = ivec2(p);
    if(pi.x >= NUM && pi.y >= 1) discard;
    
    ///Loading Data
    c = GET_DATA(iChannel2, pi.x);

    vec4 mouse = GET_DATA(iChannel2,MOUSE_);
    vec2 mousespeed = mouse.xy;

    load_scene(iChannel2, iTime, iResolution.xy);

    GMODE = int(MODE/64.0);
    curLVL = int(MODE)%64;     

    //Initialization
    if(iFrame < 5)
    {
        LoadLevel(Levels[1]);
        GMODE = 0;
        //START(10);
    }

    if(GMODE < GAMEMODE_GAME) //Menus
    {
        pang = ang;
        ang.xy = vec2(0.2*iTime, PI*0.35);         
        ang.y = clamp(ang.y, PI*0.01, PI*0.99);

        //////////update matrix
        cam = get_cam(ang.xy);

        pcampos = campos;
        campos = cam*vec3(-12.0, 0, 0) + vec3(0, 2, 0);

        bool MB = (iMouse.w > 1.0);
        vec2 MP = iMouse.xy;
        
        float font_size = FONT_SCALE;
        if(MB)
        {
            if(GMODE == 0)//Main menu
            {
                int button = checkMenuClick(MP, MAIN_POS, font_size, ivec2(0,1));
                if(button == 0)
                {
                    START(0);
                }
                if(button == 1) //level menu
                {
                    GMODE = 1;
                }
            }
            else if(GMODE == 1)//Level menu
            {   
                int button = checkMenuClick(MP, LEVELS_POS, font_size, ivec2(2,13));
                if(button == 2)
                {
                    GMODE = 0;
                }
                else if(button>2)
                {
                    START(button - 3);
                }
            }
       } 
    }
    else //Gameplay
    {
        //Go into free camera mode
        if(KeyPressEvent(KEY_F))
        {
            GMODE = (GMODE == GAMEMODE_FREE)?GAMEMODE_GAME:GAMEMODE_FREE;
        }
        if(KeyPressEvent(KEY_BSPACE))
        {
            GMODE = 0;
        }
        if(KeyPressEvent(KEY_R) || iMarblePos.y < -15.0)
        {
            START(curLVL);
        }
        if((KeyPressEvent(KEY_SPACE) && GMODE == GAMEMODE_FINISH) || KeyPressEvent(KEY_P))
        {
            START(curLVL+1);
        }
        if(KeyPressEvent(KEY_O))
        {
            START(abs(curLVL-1));
        }

        /////////cam update
        pang = ang;
        ang.xy = ang.xy + ang.zw*MOUSE_SENSITIVITY; // angle delta
        ang.y = clamp(ang.y, PI*0.01, PI*0.99);
        ang.zw += vec2(-1.0, 1.0)*mouse.xy; //velocity
        ang.zw *= 0.76;

        //////////update matrix
        cam = get_cam(ang.xy);

        //marble update
        vec3 marble_force = vec3(0.);
        float frictionm = 1.0; //friction multiplier

        if(isKeyPressed(KEY_UP) || isKeyPressed(KEY_W))
        {
            marble_force += cam[0];
        }
        if(isKeyPressed(KEY_DOWN) || isKeyPressed(KEY_S))
        {
            marble_force -= cam[0];
        }
        if(isKeyPressed(KEY_RIGHT) || isKeyPressed(KEY_D))
        {
            marble_force += cam[1];
        }
        if(isKeyPressed(KEY_LEFT) || isKeyPressed(KEY_A))
        {
            marble_force -= cam[1];
        }

        if(GMODE == GAMEMODE_GAME)
        {
            #ifndef FORCE_ALONG_CAMERA
                marble_force = vec3(marble_force.x, 0., marble_force.z);
                marble_force = marble_force/(length(marble_force)+1e-4);
            #endif

            marble_force = marble_force/max(length(marble_force), 1.);       
        }

        if(GMODE == GAMEMODE_FINISH)
        {
            vec3 flagmarble = (iFlagPos.xyz + vec3(0,8.*iFlagPos.w,0) - iMarblePos.xyz)/iFlagPos.w;
            marble_force = 2.5*normalize(flagmarble)*min(length(flagmarble), 3.); 
            frictionm = 12.;
        }

        //PHYSICS
        #ifdef ADAPTIVE_PHYSICS_ITERATIONS
            float iterations = clamp(10.*timers.z*60.0, 4., 32.);
        #else
            float iterations = 10.;
        #endif
        float dt = 0.1;
        vec4 pMarblePos = iMarblePos;
        if(GMODE == GAMEMODE_GAME || GMODE == GAMEMODE_FINISH)
        for(float i = 0.0; i<iterations; i++)
            PhysicsIteration((timers.x >= 0.)?dt:0.0, marble_force, frictionm);
        

        dMarblePos = iMarblePos - pMarblePos;

        //update camera position
        pcampos = campos;

        if(isKeyPressed(KEY_Q))
        {
            radius *= 1.0 - iterations*0.002;
        }
        if(isKeyPressed(KEY_E))
        {
            radius *= 1.01 + iterations*0.002;
        }

        if(GMODE == GAMEMODE_GAME || GMODE == GAMEMODE_FINISH)
        {
            //camera unintersection
            vec3 rd = -cam[0];
            float camd =iMarblePos.w*radius;
            vec4 ro = vec4(iMarblePos.xyz + rd*iMarblePos.w*1.03,1e8);
            if(scene(iMarblePos.xyz + cam*vec3(-camd,0,0)).x <= iMarblePos.w*0.2)
            { ro.w = 0.;  trace(ro,rd); camd = ro.w; }  
            campos = iMarblePos.xyz + cam*vec3(-camd, 0, 0);
        }
        else
        {
            //reuse radius as the speed regulator
            camvel += - camvel*0.1 + CAMERA_SPEED*iMarblePos.w*marble_force*radius/10.; 
            campos += camvel;
        }

        //Win condition
        if(GMODE == 3 && distance(iMarblePos.xyz, iFlagPos.xyz) < iFlagPos.w*4.0) GMODE = 4;

        timers = vec3(timers.x + ((GMODE == 3)?dt*iterations:0.0), 0., mix(timers.z,iTimeDelta,0.03)); 

    }

    //////////mouse update
    if(length(iMouse.zw - iMouse.xy) > 10.)
    {
        mouse.xy = iMouse.xy - c.zw; // mouse delta
        if(iFrame < 1)
        {
            mouse.xy = vec2(0.);
        }
    }
    else
    {
        mouse.xy = vec2(0.); // mouse delta
    }
    mouse.zw = iMouse.xy; // mouse pos

    switch(pi.x)
    {
    case MOUSE_: 
        c = mouse;
        break;
    case CAM_ANGLE_:  
        c = ang;
        break;
    case CAM_POS_:  
        c.xyz = campos;
        break;
    case CAM_VEL_:  
        c = vec4(camvel, 0.);
        break;
    case LIGHT_POS_:
        c.xyz = vec3(0.2, 2.0, 1.5);
        break;
    case PCAM_ANGLE_:
        c = pang;
        break;
    case PCAM_POS_:
        c.xyz = pcampos;
        break;
    case PRESOLUTION_:
        c.xy = pResolution.zw;
        c.zw = iResolution.xy;
        break;
    case MARBLE_POS_:  
        c = iMarblePos;
        break;
    case DMARBLE_POS_:  
        c = dMarblePos;
        break;      
    case MARBLE_VEL_:  
        c = vec4(iMarbleVel, radius);
        break;
    case TIMER_MODE_:  
        c = vec4(timers, float(GMODE*64 + curLVL));
        break;
    case FLAG_POS_:
        c = iFlagPos;
        break;
    case FRAC_PARAM1_:
        c = vec4(iFracScale, iFracAng1, iFracAng2, isPlanet);
        break;
    case FRAC_PARAM2_:
        c = vec4(iFracShift, 0.);
        break;
    case FRAC_PARAM3_:
        c = vec4(iFracCol, 0.);
        break;  
    }   
}