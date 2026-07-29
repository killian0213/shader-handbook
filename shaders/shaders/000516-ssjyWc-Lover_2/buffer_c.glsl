// Buffer C (buffer) — Lover 2 by FabriceNeyret2
// https://www.shadertoy.com/view/ssjyWc

Main 
    Q = vec4(0);
    for (float x = -30.; x <= 30.; x++)
        Q += G1(x,10.)*B(U+vec2(x,0)).w;
}