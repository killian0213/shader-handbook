// Buffer A (buffer) —  Water Surface Simulation by TinyTexel
// https://www.shadertoy.com/view/wl3cDj

// License: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

/* Simulation */

float ReadKey(int keyCode) {return texelFetch(iChannel1, ivec2(keyCode, 0), 0).x;}
float ReadKeyToggle(int keyCode) {return texelFetch(iChannel1, ivec2(keyCode, 2), 0).x;}

#define FETCH(uv) texelFetch(iChannel0, clamp(uv, ivec2(0), ivec2(GridSize-1.0)), 0).r
#define FETCH2(uv) texelFetch(iChannel2, clamp(uv, ivec2(0), ivec2(GridSize-1.0)), 0).r
#define FETCH3(uv) texelFetch(iChannel2, clamp(uv, ivec2(0), ivec2(GridSize-1.0)), 0)

void mainImage( out vec4 col, in vec2 uv0 )
{

    // =================================================================================== //
    // program state
    bool isGrid = uv0.x < GridSize && uv0.y < GridSize;
    bool isStateColumn = uv0.x == iResolution.x - 0.5;
    
    if(!isGrid && !isStateColumn) { discard; }

    ivec2 uv = ivec2(uv0 - 0.5);
    int stateColumnX = int(iResolution.x - 1.0);
    
    float iFrameTest     = texelFetch(iChannel0, ivec2(stateColumnX, 0), 0).x;
    vec4  iMouseLast     = texelFetch(iChannel0, ivec2(stateColumnX, 1), 0);
    float iTimeDeltaLast = texelFetch(iChannel0, ivec2(stateColumnX, 2), 0).x;

    bool isInit = float(iFrame) == iFrameTest;
    if( !isInit)
    {
        iTimeDeltaLast = iTimeDelta;
    }
    
    if(isStateColumn)
    {
        if(uv.y == 0) col = vec4(float(iFrame) + 1.0, 0.0, 0.0, 0.0);
        if(uv.y == 1) col = iMouse;
        if(uv.y == 2) col = vec4(iTimeDelta, 0.0, 0.0, 0.0);
        
        return;
    }
    
    if(!isGrid) return;
    // =================================================================================== //

    col = vec4(0.0);
    
    vec2 h12 = texelFetch(iChannel0, uv, 0).xy;

    bool isTerrainAnimated = ReadKeyToggle(KEY_N1) == 0.0;
    
    float terrH = EvalTerrainHeight(uv0, isTerrainAnimated ? iTime : 0.0);
    float mask = smoothstep(0.0, -0.05, terrH);
    float D = clamp01(-terrH);
    float lD2 = clamp01(-terrH-1.0);
    
   
#ifdef USE_HQ_KERNEL

    // 30 tabs version (vertical pass; horizontal pass in Buffer B)
    float lowp3[4] = float[4](5.0/16.0, 15.0/64.0, 3.0/32.0, 1.0/64.0);   
    float lowp7[8] = float[8](429.0/2048.0, 3003.0/16384.0, 1001.0/8192.0, 1001.0/16384.0, 91.0/4096.0, 91.0/16384.0, 7.0/8192.0, 1.0/16384.0);   
    float lapl7[8] = float[8](3.22, -1.9335988099476562, 0.4384577800334821, -0.1637450351359609, 0.07015324480535713, -0.02963974593026339, 0.010609595665007715, -0.0022370294899667453);   

    float lowpass3  = 0.0;
    float lowpass7  = 0.0;
    float laplacian = 0.0;
    
    for(int y = -7; y <= 7; ++y)
    {
        vec3 f = FETCH3(uv + ivec2(0, y)).xyz;
    
        int i = abs(y);

        lowpass3  += f.x * (i < 4 ? lowp3[i] : 0.0);
        lowpass7  += f.y * lowp7[i];
        laplacian += f.z * lapl7[i];
    }

    vec4 f0 = FETCH3(uv);
    
    laplacian += f0.w;
    
    float highpass = f0.z - mix(lowpass3, lowpass7, 0.772 * lD2);
    float halfLaplacian =   mix(highpass, laplacian, 0.19)*1.255;

    float Aa = laplacian;
    float Ab = halfLaplacian;
   
#else

   #if 0
    // 21 tabs version
    const int r  = 4;
    const int r1 = r + 1;

    float kernA[r1] = float[r1](3.14, -1.8488262937460072, 0.3538769077873216, -0.0913000638886917, 0.016249449847377015);

    float kernB[r1*r1] = float[r1*r1](2.269921105564736    , -0.4505893247500618, 0.01789846106075618, -0.01027660288590306, 0.0034772145111404747, 
                                     -0.4505893247500618   , -0.1279900243271159, 0.                 ,  0.                 , 0.                   , 
                                      0.01789846106075618  ,  0.                , 0.                 ,  0.                 , 0.                   , 
                                     -0.01027660288590306  ,  0.                , 0.                 ,  0.                 , 0.                   , 
                                      0.0034772145111404747,  0.                , 0.                 ,  0.                 , 0.                   );  
   #else
    // 13 tabs version
    const int r  = 2;
    const int r1 = r + 1;
 
    float kernA[r1] = float[r1](2.85, -1.5792207792207793, 0.15422077922077923);
 
    float kernB[r1*r1] = float[r1*r1](2.0933782605117255  , -0.32987120049780483, -0.026408964879028916, 
                                     -0.32987120049780483 , -0.1670643997510976 ,  0.0                 ,
                                     -0.026408964879028916,  0.0                ,  0.0                 );
   #endif
     
      
    float Aa = 0.0;
    float Ab = 0.0;

    for(int y = -r; y <= r; ++y)
    for(int x = -r; x <= r; ++x)
    {
        float w = (kernB[abs(x) + abs(y) * r1]);

        if(w == 0.0) continue;

        float f = FETCH(uv + ivec2(x, y));

        Ab += f * w;

        if(y == 0) Aa += f * kernA[abs(x)];                
        if(x == 0) Aa += f * kernA[abs(y)];                
    }     

#endif

  #ifndef USE_AXISALIGNED_OBSTACLES
    // mitigate erroneous simulation behavior along shorelines
    D = mix(0.25, 1.0, D);
  #endif
  
    float A = mix(Aa, Ab, (D*D) / (2.0/7.0 + 5.0/7.0 * (D*D))) * D;
    
   // A = Ab;// deep
   // A = Aa * 0.5;// shallow

    A *= -9.81*GridScale;


    // painting
    bool isSingleDrop = ReadKey(KEY_SHIFT) != 0.0;
    
    if(iMouse.w > 0.0 || (!isSingleDrop && iMouse.z > 0.0 || (iMouse.x != iMouseLast.x && iMouse.y != iMouseLast.y)))
    {
        vec2 c = PatchUVfromScreenUV(iMouse.xy, iResolution.xy);
        
        vec2 vec = (uv0 - c);
  
        if(!isSingleDrop)
        if(iMouseLast.z > 0.0 || iMouseLast.w > 0.0)
        {
            vec2 c2 = PatchUVfromScreenUV(iMouseLast.xy, iResolution.xy);
            
            vec = uv0 - (c2 + (c-c2)*clamp01(dot(c-c2, uv0-c2)/dot(c-c2,c-c2)));
        }
  
        float v = exp2(-dot(vec, vec) * 1.0);
        h12 = mix(h12, vec2(0.75), v);
    }
    
    if(iFrame == 0) h12 = vec2(0.0);

    // rain drops
    if(ReadKeyToggle(KEY_N5) == 0.0)
    if(WellonsHash(uint(iFrame)) < 100000000u)
    {
        vec2 c = Float01(WellonsHash(uint(iFrame) * uvec2(3242174893u, 2447445397u) + 3u)) * GridSize;
        vec2 vec = (uv0 - c);
    
        float v = exp2(-dot(vec, vec) * 1.0);
        h12 = mix(h12, vec2(0.75), v);
    }

    float dt = 0.016667;
    float dt2 =  dt * dt;

    float h0 = 0.0;
    float h1 = h12.x;
    float h2 = h12.y;

#if 1
    // Verlet integration
    h0 = (2.0 * h1 - h2) + A * dt2;

#else

    // ...damped version
    float a = 1.0/2.0;
    float adt = a * dt;
    
    h0 = (((2.0 + adt) * h1 - h2) + A * dt2) / (1.0 + adt);

#endif

    vec2 h01 = vec2(h0, h1);

    // exponential state buffer smoothing
    float beta = 2.0;
    h01 = mix(h01, h12, 1.0-exp2(-dt*beta));

    // mask out obstacles
    h01 *= mask;

    // grid windowing
    bool isGridWindowed = ReadKeyToggle(KEY_N2) == 0.0;
    if(isGridWindowed)
    {
        float r = 32.0;

        vec2 u = min((vec2(GridSize*0.5) - abs(uv0 - vec2(GridSize*0.5))) / r, vec2(1.0));

        u = 1.0 - u;
        u *= u;
        u *= u;
        u = 1.0 - u;

        float s = u.x*u.y;

        h01 *= mix(0.75, 1.0, s);        
    }
    
    if(ReadKey(KEY_SPACE) != 0.0) { h01 *= 0.95; } 
    
    col = vec4(h01, 0.0, 0.0);
}









