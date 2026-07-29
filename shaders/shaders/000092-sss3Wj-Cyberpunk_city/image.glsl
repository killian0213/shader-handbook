// Image (image) — Cyberpunk city by z0rg
// https://www.shadertoy.com/view/sss3Wj

// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

vec3 doBloom(vec2 uv, float blur, float threshold)
{
    vec3 col;
    int cnt = 50;
    float fcnt = float(cnt);
    for (int i = 0;i <cnt;++i)
    {
        float fi = float(i);
        float coef = (fi/fcnt);
        float sz = 1.+pow(coef,2.)*blur;
        float samplePerTurn = 5.;
        float an = (fi/(fcnt/samplePerTurn))*PI;
        vec2 p = uv - vec2(sin(an), cos(an))*an*blur*.1;
        vec3 smple = texture(iChannel0, p).xyz;
        if (length(smple) > threshold)
            col += smple;
    	
        
    }
    
    return col/float(cnt);
}

vec3 chromaFlare(vec2 uv, vec2 ouv, float sz, float id)
{
    vec3 col = vec3(0.);// = texture(iChannel0, uv).xyz;
    
    float c = abs(length(ouv)-.3-id*sz*8.-sz*9.)-sz;
    vec3 rgb;
    float a = atan(ouv.y, ouv.x)*1.;
    float cnt = 16.;
    for (float i = 0.; i < cnt; ++i)
    {
           
        rgb += vec3(1.)*
        (sat((sin(a*400.)+sin(a*200.)+sin(a*100.))*.2+.5)*.5+.5)*
        texture(iChannel0, vec2(.5)+((uv-vec2(.5))*(i+1.)*0.01*r2d((i-cnt/2.)*.025)*-1.*sat(length(ouv*2.)))).x;
    }
    col += pow((1.-sat(c*5.))*pow(rgb/cnt, vec3(1.)), vec3(1.));
    
    return col*.2;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 cuv = (fragCoord-vec2(.5)*iResolution.xy)/iResolution.xx;
    
    vec3 col = texture(iChannel0, uv).xyz;
    
    float bloomIntensity = 424./640.;  
    vec3 bloomSample = doBloom(uv, 40./360., 237./ 640.);
    bloomSample = pow(bloomSample, vec3(0.5));
    
    col = col + (bloomSample*bloomIntensity);
    

    col += chromaFlare(uv, cuv, 0.01, 0.)*vec3(1.,0.,0.);
    col += chromaFlare(uv, cuv, 0.01, -1.)*vec3(0.,1.,0.);
    col += chromaFlare(uv, cuv, 0.01, -2.)*vec3(0.,0.,1.);

    col = mix(col, col.zyx, pow(sat(length(cuv*2.)),4.));

    col = pow(col, vec3(1.95));

    fragColor = vec4(col, 1.);
}