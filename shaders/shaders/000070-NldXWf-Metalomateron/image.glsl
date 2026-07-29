// Image (image) — Metalomateron by davidar
// https://www.shadertoy.com/view/NldXWf

// Original shaders by lomateron.
// I find it rather pleasing how the core loop for each of the buffers can be distilled into a short one-liner,
// such complex behaviour from quite simple systems!

MAIN {
    vec4 a = Du;
    if(SHADER == 2) { // veinss
        r = sin(a.x*4.+vec4(1,3,5,4))*.25 + sin(a.y*4.+vec4(1,3,2,4))*.25 + .5;
    } else if(SHADER == 3) { // exploding blobs
        r = a.z+a.z*sin(length(a.xy)+vec4(1,2,3,4));
    } else if(SHADER == 4) { // wigli wires
        r = sin(a.x*2.+vec4(1,2,3,4)+0.)*.25 + sin(a.y*2.+vec4(1,2,3,4)+0.)*.25 + .5;
    } else if(SHADER == 5) { // spirals vs ghosts
        r = pow(a.z,.15)*(cos(length(a.xy)*2.+vec4(0,2,4,6)+3.)*.3+.7);
    } else if(SHADER == 6) { // radioactive space balls
        r = sin(pow(a.z,.15)*5.+vec4(1,2,3,4))*.5+.5;
    } else if(SHADER == 7) { // exotic smoke
        r = a.xxyz*.1+sin(pow(a.z,.2)*2.+vec4(1,2,3,4))*.5+.5;
    }
}
