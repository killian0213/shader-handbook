// Image (image) — Shadertoy Geographic by iapafoto
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

#define WITH_DOF

#ifdef WITH_DOF

// fade in out arround t during dt
#define fade(t,dt) smoothstep(0.,dt,abs(iTime-t))
//#define iTime (iTime + 120.)

int[] txt = int[] (83,72,65,68,69,82,84,79,89,0,71,69,79,71,82,65,80,72,73,67,0); 


float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sample_dist_gaussian(vec2 uv) {
    const int nstep = 3;
    const float w[3] = float[3](1., 2., 1.);
    float d, wij, dsum = 0., wsum = 0.;    
    for (int i=0; i<nstep; ++i) {
        for (int j=0; j<nstep; ++j) {
            vec2 delta = vec2(float(i-1), float(j-1))/1024.;
            d = textureLod(iChannel1, uv-delta, 0.).w - 127./255.;
            wij = w[i]*w[j];
            dsum += wij * d;
            wsum += wij;
        }
    }
    return dsum / wsum;
}

float sdFont(vec2 p, int c) {
    vec2 uv = (p + vec2(float(c%16), float(15-c/16)) + .5)/16.;
    return max(max(abs(p.x) - .25, max(p.y - .35, -.38 - p.y)), sample_dist_gaussian(uv));
}

float sdMessage(vec2 p, int[21] text, int start, float scale, float bold) {
    p /= scale;
    float d = 9999.;
    vec2 pp;

    for (int i=min(iFrame,0)+start; i<text.length(); i++) {  
        if (text[i] == 0) break;
        d = min(d, sdFont(p, text[i]));
        p.x-=.5;

    }
    return d*scale - bold;
}

//-----------------------------------------------
// Based on Iq Dof
//-----------------------------------------------
void mainImage(out vec4 fragColor, vec2 fragCoord )
{
    vec2 q = fragCoord / iResolution.xy;
    
    if (iTime > 1. && iTime < 158.) {

        float focus = 1.5;

        float gTime = iTime - 40.;
            
        if (gTime < 110.) focus = 1.5;
        if (gTime < 85.) focus = (1.25+.05*gTime); 
        if (gTime < 70.) focus = mix(6.,1.5,smoothstep(50.,60.,gTime));
        if (gTime < 44.) focus = 10.;
        if (gTime < 25.) focus = 7.;
        if (gTime < 20.) focus = 2.;
        if (gTime < 0.) focus = 5.;
        if (gTime < -20.) focus = mix(2.,.25,smoothstep(.5,3.,iTime));

        float a = 1.;

        vec4 acc = vec4(0.0);
        const int N = 12;
        for( int j=-N; j<=N; j++ )
        for( int i=-N; i<=N; i++ )
        {
            vec2 off = vec2(float(i),float(j));
            vec4 tmp = texture( iChannel0, q + off/iResolution.xy ); 
            float depth = tmp.w;
            vec3  color = tmp.xyz;
            float coc = .001 + 3.*abs(depth-focus)/depth;
            if( dot(off,off) < (coc*coc) ) {
                float w = 1.0/(coc*coc); 
                acc += vec4(color*w,w);
            }
        }

        vec3 col = acc.xyz / acc.w;


        //-----------------------------------------------------
        // postprocessing
        //-----------------------------------------------------
        // gamma
        col = pow( abs(clamp(col,0.0,1.0)), vec3(0.5) );

        // contrast, desat, tint and vignetting	
        col = col*0.8 + 0.2*col*col*(3.0-2.0*col);
        col = mix( col, vec3(col.x+col.y+col.z)*0.333, 0.25 );
        col *= vec3(1.0,1.02,0.96);
        col *= pow(16.0*q.x*q.y*(1.-q.x)*(1.-q.y),.25);
        col += .05*(vec3(hash22(q*100.),hash12(111.*q)) - .5);
        fragColor = vec4(col,1.0);
    
        fragColor *= fade(20.,1.5); // fondu noir entre scene
        fragColor *= fade(60.,1.); 
        fragColor *= fade(110.,1.5); 
        fragColor *= fade(125.,2.);
  //      fragColor *= fade(140.,1.5);
  //      fragColor *= fade(145.,1.5);
  //      fragColor *= fade(165.,1.5);
    } else {
        vec2 uv = q-vec2(0.5);
        uv.y /= iResolution.x/iResolution.y;
        uv.x += .1;
        float d = max(sdBox(uv-vec2(-.18,0), .6*vec2(.14,.2)), -sdBox(uv-vec2(-.18,0), .6*vec2(.1,.16)));
        float dTxt = sdMessage(uv-vec2(-.05,.05), txt, 0,.11,0.);
        dTxt = min(dTxt, sdMessage(uv-vec2(-.05,-.05), txt, 10,.11,0.));
        vec3 col = mix(vec3(0), vec3(1,1,0),step(d,0.));
        col = mix(vec3(1.),col, smoothstep(0.,1./iResolution.y,dTxt));
        fragColor = vec4(col,1.0);
    }
}

#else 


void mainImage(out vec4 fragColor, vec2 fragCoord) {
	fragColor= texture(iChannel0, gl_FragCoord.xy/iResolution.xy);
}


#endif