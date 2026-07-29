// Buffer B (buffer) — Interactive Rubik's Cube by kishimisu
// https://www.shadertoy.com/view/w3lGRf

/* This buffer only has 2 active threads.

   Thread #1: Camera management (update phi and theta camera angles with mouse)
   
   Thread #2: Rotation management
       - Manages the starting state (auto-shuffle)
       - Manages the animation timer
       - Detect if a click is on the cube or background
       - Detect swipes on the cube, and convert a swipe to its corresponding
         rotation index (0-8) and direction (clockwise / counter-clockwise).
*/
void mainImage(out vec4 O, vec2 F)
{
    ivec2 tid = ivec2(F);
    if (tid.x > 1 || tid.y > 0) discard; // 2 active threads
    
    vec2 R = iResolution.xy,
         M = (iMouse.xy*2.-R)/R.y;
    
    vec4 state = texture(iChannel0, F/R);
    
    // Camera management (0, 0)
    // x, y: mouse pos on last frame
    // z, w: persistent theta & phi angles
    if (tid.x == 0)
    {
        float hitStart = texelFetch(iChannel0, ivec2(1, 0), 0).g;
        
        // Reset
        if (iFrame < 3) {
            state = vec4(-1, -1, 1.57*.5, -1.57*.65);
        }
        // Mouse moved outside cube
        else if (iMouse.z > 0. && hitStart < 0.) {
            // Update camera angles
            if (state.xy != vec2(-1)) {
                state.zw += state.xy - M;
                state.w = min(-0.01, max(-3.14, state.w));
            }
            // Save mouse pos
            state.xy = M; 
        }
        // Initial camera rotation
        else if (hitStart == -2.) {
            state.z += .001;
        }
        else {
            state.xy = vec2(-1);
        }
    }
    
    // Swipe management (1, 0)
    // r: anim start time
    // g: state flag (-2: shuffle, -1: clicked outside, 0: waiting for release, >0: clicked cube + distance)
    // b: rotation index (0-8)
    // a: counter-clockwise (0-1)
    else
    {
        vec2 a = texelFetch(iChannel0, ivec2(0), 0).wz+.001;    
        vec3 ro = 17. * vec3(sin(a.x)*cos(a.y), cos(a.x), sin(a.x)*sin(a.y));
        mat4 view = lookAt(ro);
        vec3 rd   = computeRayDirection(M, view);
        vec4 hit  = boxIntersect(ro, rd, 3.);        
        
        // Reset
        if (iFrame < 3) state = vec4(1, -2, -1, 0);
        
        // Initial shuffle state
        else if (state.g == -2.) 
        {
            // Exit state on click
            if (iMouse.w > 0.) state.g = hit.w, state.x = (state.x==1.?1e9:state.x);
            // Start next rotation
            else if (iTime - state.r > ANIM_DURATION || (state.x==1.&&iTime>1.)) {
                vec2 move = floor(hash21(iDate.w) * vec2(9, 2)); // Random move
                if (move.x == state.z) move.y = state.w; // Prevent cancelling previous move
                state.r = iTime; // Start animation
                state.zw = move;
            }
        }
        
        // Mouse clicked
        else if (iMouse.w > 0.) state.g = hit.w;
        // Mouse moved
        else if (iMouse.z > 0. && state.g > 0.) 
        {
            bool animating = iTime > state.r && iTime - state.r < ANIM_DURATION;
            vec2 iMouseStart = abs(iMouse.zw);
            
            // Process swipe
            if (!animating && (length(iMouse.xy - iMouseStart) > 20. || hit.w < 0.))
            {
                state.g = 0.;
                state.zw = vec2(-1);
                
                // Compute intersection
                vec2 startM = (iMouseStart*2.-R)/R.y;
                rd = computeRayDirection(startM, view);
                vec4 n = boxIntersect(ro, rd, 3.);
                
                vec3 pos = ro + n.w * rd;
                
                // Get world-space up/right
                vec3 right = normalize(cross(n.xyz, vec3(0,1,1e-4)));
                vec3 up    = normalize(cross(right, n.xyz));
                
                // Project to clip space
                mat4 viewproj = proj * view;
                vec2 projP = project(pos, viewproj);
                vec2 projU = project(pos + up, viewproj);    
                vec2 projR = project(pos + right, viewproj);
                
                // Get normalized vectors
                vec2 normU = normalize(projU - projP);
                vec2 normR = normalize(projR - projP);
                vec2 normM = normalize(M - startM);
                
                // Compute swipe direction
                float du = dot(normM, normU);
                float dr = dot(normM, normR);
                bool UPP = du >  .7;
                bool DWN = du < -.7;
                bool RGT = dr >  .7;
                bool LFT = dr < -.7;
                
                ivec3 p = ivec3(pos*.5 + 1.5);
                
                // Store rotation and direction
                if (LFT || RGT) {
                    if (abs(n.y)>.5) state.zw = vec2(p.z + 6, LFT);
                    else             state.zw = vec2(p.y + 3, RGT);
                }
                else if (UPP || DWN) {
                    if (abs(n.x)>.5) state.zw = vec2(p.z + 6, n.x < -.5 ? DWN : UPP);
                    else             state.zw = vec2(p.x, n.y < -.5 || n.z > .5 ? DWN : UPP);
                }
                
                if (state.z > -1.) state.r = iTime; // Start animation
            }
        }
        
        if (iTime - state.r > ANIM_DURATION) state.r = 1e9; // Stop animation
    }
    
    O = state;
}