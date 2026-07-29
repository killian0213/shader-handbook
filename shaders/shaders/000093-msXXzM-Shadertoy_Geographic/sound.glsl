// Sound (sound) — Shadertoy Geographic by iapafoto
// https://www.shadertoy.com/view/msXXzM

// Created by Sebastien Durand - 11/2022
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//-----------------------------------------------------
// Sounds based with minor changed on
//     Dave Hoskins [Frozen wasteland] https://www.shadertoy.com/view/Xls3D2
// ------------------------------------------------------------
// Many part of shading based on 
//     iq [Bridge] https://www.shadertoy.com/view/Mds3z2
// ------------------------------------------------------------
// Penguin feets and texture bedes on
//     kuvkar [AngryBird] https://www.shadertoy.com/view/ldKXRz
// ------------------------------------------------------------

vec2 add = vec2(1,0);



float tri(in float x) { 
    return abs(fract(x)-.5)*2.;
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
float Noise11(float x) {
    float p = floor(x), f = fract(x);
    f = f*f*(3.-2.*f);
    return mix( hash11(p), hash11(p + 1.), f)-.5;
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 Noise21(float x) {
    float p = floor(x), f = fract(x);
    f = f*f*(3.-2.*f);
    return  mix( hash21(p), hash21(p + 1.), f)-.5;
}

//----------------------------------------------------------------------------------------
//  2 out, 2 in...
vec2 Noise22(vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.-2.*f);
    vec2 res = mix(mix( hash22(p),          hash22(p + add.xy),f.x),
                   mix( hash22(p + add.yx), hash22(p + add.xx),f.x),f.y);
    return res-.5;
}

//----------------------------------------------------------------------------------------
// Fractal Brownian Motion...
vec2 FBM22(vec2 x) {
    vec2 r = vec2(0);
    float a = .6;
    for (int i = 0; i<8; i++) {
        r += Noise22(x * a) / a;
        a += a;
    }
    return r;
}



vec2 mainSound( in int samp, float time) {
    float gTime = time - 40.;

    int sceneId = 6;
         if (gTime <-20.) sceneId = -2;
    else if (gTime <  1.) sceneId = -1;
    else if (gTime < 20.) sceneId = 0;
    else if (gTime < 25.) sceneId = 1;
    else if (gTime < 44.) sceneId = 2;
    else if (gTime < 70.) sceneId = 3;
    else if (gTime < 85.) sceneId = 4;
    else if (gTime < 105.) sceneId = 5;
    else sceneId = 6;


    vec2 audio = vec2(.0);
    
    // le vent    
    for (float t = 0.0; t < 1.0; t+=.5)
    {
        time = time+t;
        vec2 n1 = FBM22( time*(Noise21(time*3.25)*40.0+Noise21(time*.03)*5500.0+9500.0)) * (abs(Noise21(time)))*1.5;
        vec2 n2 = FBM22( time*(Noise21(time*.4)+1900.0))*abs(Noise21(time*1.5))*1.5;
        vec2 n3 = FBM22( time*(Noise21(time*1.3)+Noise21(-time*.03)*200.0+1940.0))*(.5+abs(Noise21(time-99.)))*1.5;
        vec2 s1 = sin(time*3300.+(Noise21(time*.23))*(Noise21(-time*.12)*3000.0+4000.0))*abs(Noise21(time*32.3+199.))*abs(Noise21(-time*.04+9.)+.5)*3.;

        audio += (n1+n2+n3+s1)/8.0;
    }
    
    if (sceneId == -1) {
        audio *= .1;
    } else if (sceneId == 5) {
        audio *= 2.; // bcp de event
    }
    // Les pas
    if (sceneId > -2 && sceneId < 3 || sceneId == 5) { 
        float foot = tri(time*(sceneId == 1 ? 3.7 : 1.85));
        audio += 6. * Noise11(time*10.0)*Noise11(time*500.0)*Noise11(time*3000.0)* smoothstep(0.6,1.,abs(foot));

        if (sceneId > -1) { // + de pas
            foot = tri(time*1.85+.8);
            audio += 6. * Noise11(time*10.0)*Noise11(time*500.0)*Noise11(time*3000.0)* smoothstep(0.6,1.,abs(foot));
        }
        if (sceneId == 5) { // + de pas
            foot = tri(time*1.85+1.2);
            audio += 6. * Noise11(time*10.0)*Noise11(time*500.0)*Noise11(time*3000.0)* smoothstep(0.6,1.,abs(foot));
        }
    }
    if (sceneId == -2) audio *= .25 +.15*cos(time*1.5);  // ocean
    if (sceneId == 1) audio *= .05; // glissades
  
    return .15*clamp(audio, -1.0, 1.0); 
    
    
}
