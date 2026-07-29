// Buffer D (buffer) — Swarming Anchoveta by fenix
// https://www.shadertoy.com/view/mtSGDt

// ---------------------------------------------------------------------------------------
// Lighting and shading first pass
// ---------------------------------------------------------------------------------------

// water surface borrowed from "ocean under" by rockhard
//     https://shadertoy.com/view/7dyXWc
float wavedx(vec2 position, vec2 direction, float time, float freq){
    float x = dot(direction, position) * freq + time;
    return exp(sin(x) - 1.0);
}

float getwaves(vec2 position){
    float iter = 0.0,phase = 6.0,speed = 2.0;
    float weight = 1.0,w = 0.0,ws = 0.0;   
    for(int i=0;i<5;i++){
        vec2 p = vec2(sin(iter), cos(iter));
        float res = wavedx(position,p,speed*iTime,phase);        
        w += res * weight; ws += weight;
        iter += 12.0; weight *=0.75; phase *= 1.18; speed *= 1.08;
    }
    return w / ws;
}
float sea_octave(vec2 uv,float choppy){
return getwaves(uv*choppy)+getwaves(uv); }

const vec3 WATER_COLOR = vec3(0.0,0.39,0.62);
vec3 water(vec3 cameraPos, vec3 rayDir)
{
    vec3 sun = vec3(-0.6, 0.5,-0.3); 
    float i = max(0.0, 1.4/(length(sun-rayDir)+1.0));
    vec3 col = vec3(pow(i, 1.9), pow(i, 1.0), pow(i, .8));
    col = mix(col, WATER_COLOR,(1.0-rayDir.y)*0.9);   

    if (rayDir.y > 0.0){//water suf
        float d = (cameraPos.y-3.0)/rayDir.y;	
        vec2 wat = (rayDir * d).xz-cameraPos.xz;
        d += sin(wat.x + iTime);
        wat = (rayDir * d).xz-cameraPos.xz;     
        wat = wat * 0.1 + 0.2* texture(iChannel0,wat*0.01).xz;      
        col += sea_octave(wat,0.5) * max(2.0/-d, 0.0);
    }
    
    return col*col*col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fxGBufferPixel pix = fxUnpackGBuffer(texture(iChannel0, fragCoord/iResolution.xy));
    
    vec3 cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp;
    fxCalcCamera(cameraLookAt, cameraPos, cameraFwd, cameraLeft, cameraUp);

    vec3 rayDir = fxCalcRay(fragCoord, iResolution, cameraFwd, cameraUp, cameraLeft);

    if (pix.t >= FAR_CLIP)
    {
        fragColor.xyz = water(cameraPos, rayDir);
    }
    else
    {
        // ssao model inspired by SSAO (basic) by iq: https://www.shadertoy.com/view/Ms23Wm
        // sample neighbor pixels
        float ao = 0.0;
        const float SAMPLES = 20.; // increase for higher quality if your GPU can handle it
        for( float i=0.; i<SAMPLES; i++ )
        {
            vec3 h = hash3(uvec3(fragCoord, 0));

            // get a random 2D offset vector
            vec2 off = texture(iChannel1, (fragCoord.xy + 23.71*float(i)) / iChannelResolution[1].xy).xz - .5
                + vec2(0, 1.); // shift search in the direction of normal
            off += sign(off) * .0; // don't waste samples looking at nearby pixels

            // sample the zbuffer at a neightbor pixel		
            fxGBufferPixel nbPix = fxUnpackGBuffer(texture(iChannel0, fragCoord.xy / iResolution.xy + off * .03));
            
            // accumulate occlusion if difference is less than 0.02 units		
            ao += clamp((pix.t-nbPix.t)/.02, 0., 1.);
        }
        
        // average down the occlusion	
        ao = clamp(1. - ao/SAMPLES, 0., 1.);
        
        // lighting
        vec3 hitPos = cameraPos + rayDir * pix.t;
        float hf = (smoothstep(-.7, -.1, hitPos.y) * .9 + .1); // darken lowest area (cheat!) because ao doesn't reach far enough
        if (keyDown(KEY_SHIFT)) { ao = 1.; hf = 1.; }
        fragColor.xyz = ao * water(hitPos, pix.n) * .95 * hf + WATER_COLOR * .05;
    }

    fragColor.a = 1.;
}
