// Buffer B (buffer) — Morning glare by loicvdb
// https://www.shadertoy.com/view/wd33zl

#define GoldenAngle 2.39996323

#define Aperture .06
#define DoFClamping .3
//change the sample count to 256 or more if you see some dots in the DoF
#define DoFSamples 128

float FocalDistance = 2.0;


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    float time = iTime;
    
    
    if( iMouse.z > 0.0 )
        FocalDistance *= 1.0 + (iMouse.y/iResolution.y-.5)*.65;
    else
        FocalDistance *= 1.0 + sin(pow(abs(sin(time/4.0)), 70.0) * 6.0) *.25;
    
    vec3 col = vec3(0);
    float samples = 0.0, r, phi, dr, influence;
    vec2 d;
    vec4 p;
    for(int i = 0; i < DoFSamples; i++){
        r = sqrt(float(i) / float(DoFSamples))*DoFClamping;
        phi = GoldenAngle * float(i);
        d = r * vec2(cos(phi), sin(phi));
        p = texture(iChannel0, (fragCoord + d*iResolution.y*Aperture)/iResolution.xy);
        dr = min(atan(abs(p.a-FocalDistance), p.a), DoFClamping);
        influence = clamp((dr - length(d))*iResolution.y*Aperture + .5, 0.0, 1.0) / (dr*dr+.001);
        col += influence * p.rgb;
        samples += influence;
    }
    col /= samples;
    
    fragColor = vec4(col, 1.0);
}