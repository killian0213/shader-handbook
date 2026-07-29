// Image (image) — Interactive Rubik's Cube by kishimisu
// https://www.shadertoy.com/view/w3lGRf

/* Interactive Rubik's Cube by @kishimisu (2025)

    > "Swipe" on the cube to make a rotation!
    
    > Drag the background to move the view
    > Restart the shader to shuffle, click anywhere to stop shuffling
    > Change the rotation duration and antialiasing level in "Common" tab
    
    //// Technical details ////
    
    == State Management ==
    
    (More info in corresponding tabs)
    - Buffer A: Rubik's cube state management (27 cells)
    - Buffer B: Camera management, shuffle and swipe management
    
    == Rendering ==
    
    I spent some time optimizing the rendering part of this shader.
    Initially, it used a raymarching loop with 80 iterations, each 
    containing an inner loop for 27 box sdf calculations (one per 
    cube cell), resulting in 2160 box sdf calculation per fragment. 
    While it was still running well for this simple shader, I wanted 
    to try alternative methods better suited for this case.
    
    Instead of raymarching, I switched to ray-box intersection functions.
    Using a single intersection function for the entire cube wasn't an 
    option as it wouldn't allow for animating the cube rotations individually.
    
    With that in mind, the second version of this shader replaced raymarching 
    with a single loop of 27 ray-box intersection tests, greatly improving 
    performance and removing raymarching artifacts. However, checking all 27 
    cube intersections per fragment still felt excessive.
    
    Next, I realized that the cube could be rendered as three "slices" of 
    3x3x1 cells, given that the slices are aligned with the current rotation axis.
    This reduced the loop to just 3 intersection checks, one per slice, while still 
    allowing independent rotation of each slice.
    
    Finally, after refining the logic, I got rid of the loop while maintaining
    3 intersection checks per fragment (plus a 4th one for the background).
    
    With all these optimizations, I can currently increase the antialiasing up to
    30 (30^2=900 samples per fragment!) without dropping below 60fps using the default 
    800x450 resolution, which is just enough for me to be happy with the performance!
*/
vec3 render(vec2 F) {
    // Setup ray origin & direction
    vec2 u = (F+F-iResolution.xy)/iResolution.y;
    vec2 a = texelFetch(iChannel1, ivec2(0), 0).wz+.001;
    vec3 ro = 17.*vec3(sin(a.x)*cos(a.y), cos(a.x), sin(a.x)*sin(a.y)), r0 = ro;
    vec3 rd = computeRayDirection(u, lookAt(ro));
    
    // Fetch current rotation state
    vec4 state = texelFetch(iChannel1, ivec2(1, 0), 0);
    float rot = state.z;
    float dir = state.w*2.-1.;
    
    float anim = dir * 1.571 * smoothstep(0., ANIM_DURATION, iTime - state.r);
    
    // Compute rotation matrix and axis
    mat3 rotM;
    vec3 axis;
    
    if (rot < 3.) {
        rotM = rotateX(anim);
        axis = vec3(2,0,0);
    }
    else if (rot < 6.) {
        rotM = rotateY(anim);
        axis = vec3(0,2,0);
    }
    else {
        rotM = rotateZ(anim);
        axis = vec3(0,0,2);
    }
    
    // Compute slice offsets
    vec3 size = 3. - axis;
    vec3 ro1  = ro - axis * (mod(rot+1., 3.) - 1.);
    vec3 ro2  = ro - axis * (mod(rot+2., 3.) - 1.);
    vec3 roA  = ro - axis * (mod(rot   , 3.) - 1.); // Rotating slice
    
    // Compute intersection with each slice
    vec3 roAnim = rotM * roA;
    vec3 rdAnim = rotM * rd;
    vec3 m  = 1. / rd;
    vec3 mA = 1. / rdAnim;
    vec3 k  = size * abs(m);
    vec3 kA = size * abs(mA);
    
    vec4 hit  = boxIntersectOpti(ro1, m, k);
    vec4 hit2 = boxIntersectOpti(ro2, m, k);
    vec4 hitA = boxIntersectOpti(roAnim, mA, kA); // Rotating slice
    
    // Find closest intersection
    float i = 0.; ro = ro1;
    if (hit2.w < hit.w) i =  1., hit = hit2, ro = ro2;
    if (hitA.w < hit.w) i = -1., hit = hitA, ro = roAnim, rd = rdAnim;
    
    bool inside = true;
    if (hit.w > 1e2) {
        // Quick hack to get an "interesting" background
        hit = boxIntersectOpti(r0, m, abs(m)*49.);
        inside = false;
    }
    
    // Compute world position and cell index
    vec3 p = ro + rd * (hit.w + .01);
    ivec3 pid = ivec3(floor(p*.5+.5) + axis*.5*(mod(rot+i+1., 3.) - 1.));
    int id = abs(pid.x + pid.y * 3 + pid.z * 9 + 13) % 27;
    
    // Fetch cell data
    vec4 cell = texelFetch(iChannel0, ivec2(id, 0), 0);
    vec3 col;
    vec2 uv;
    
    // Compute UVs and color depending on current side
    if (hit.x > hit.y && hit.x > hit.z) { 
        uv = ro.zy + rd.zy*hit.x;
        uv.x *= sign(p.x);
        col = palette(cell.x);
    }
    else if (hit.y > hit.z) { 
        uv = ro.xz + rd.xz*hit.y;
        uv.x *= sign(p.y);
        col = palette(cell.y);
    }
    else { 
        uv = ro.xy + rd.xy*hit.z;
        uv.x *= -sign(p.z);
        col = palette(cell.z);
    }
    
    uv = fract(uv*.5+.5);
    
    // Vignette
    vec2 v = uv * (1. - uv.yx);
    col *= min(1., v.x*v.x*v.y*v.y)*120.;
    
    // Skip lighting for background
    if (!inside) return col * .075;
        
    uv = uv * 2. - 1.;

    // Light up rotating slice
    float K = abs(iTime - state.r - ANIM_DURATION*.5) - ANIM_DURATION*.1;
    K = smoothstep(ANIM_DURATION*.4, 0., K + i + 1.);
    col *= 1. + K*2.;

    // Compute normal, up and right
    vec3 n = -sign(rd)*step(hit.yzx, hit.xyz)*step(hit.zxy, hit.xyz), n0 = n;
    vec3 right = normalize(cross(n.xyz, vec3(0,1,1e-4)));
    vec3 up    = normalize(cross(right, n.xyz));

    // Create fake gaps/depth between cells by playing with normal,
    // inspired by @Observer's shader (https://www.shadertoy.com/view/XtG3D1)
    vec2  g = smoothstep(.8, 1., abs(uv)) * .5;
    float h = 1. - max(g.x, g.y);
    n = normalize(n*h + right*g.x*sign(uv.x) + up*g.y*sign(uv.y)); // Try removing this line!

    // Specular light
    float spec = pow(max(0., -dot(n, rd)), 200.);
    col += spec * smoothstep(.085, .0, dot(n, n0) - .93) * 2.;
    
    return col;
}

void mainImage(out vec4 O, vec2 F) {
    vec3 col = vec3(0);
    
    for (float i = 0.; i < AA; i++)
    for (float j = 0.; j < AA; j++) 
    {
        col += render(F + vec2(i, j) / AA - .5);
    }
    
    O.rgb = pow(col / (AA*AA), vec3(.4545));
}