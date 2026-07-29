// Buffer B (buffer) — Light Propagation Volume by paniq
// https://www.shadertoy.com/view/XdtSRn

// albedo volume for bounces

///////////////////


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float posidx = packfragcoord2(fragCoord.xy, iResolution.xy);
    if (posidx < (lpvsize.x * lpvsize.y * lpvsize.z)) {
	    vec3 pos = unpackfragcoord3(posidx,lpvsize);
        float offset = -0.5;
        vec3 tpos = (pos + offset) / lpvsize;
        vec3 wpos = (tpos * 2.0 - 1.0) * 2.5 + vec3(0.0,1.0,0.0);
        fragColor = doMaterial(wpos, iTime);
    } else {
        fragColor = vec4(0.0,0.0,0.0,0.0);
    }
}