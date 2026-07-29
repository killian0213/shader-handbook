// Buffer B (buffer) — Path racer by XT95
// https://www.shadertoy.com/view/WtlXWS

// Created by anatole duprat - XT95/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// Raytracing pass

// ---------------------------------------------
// Shading
// ---------------------------------------------
vec3 tex3D( sampler2D tex, vec3 p, vec3 n )
{
    n = abs(n);
	vec4 col = texture(tex, p.yz)*n.x + texture(tex, p.xz)*n.y + texture(tex, p.xy)*n.z;
    return pow(col.rgb,vec3(2.2));
}
// clever code taken from Shane
// https://www.shadertoy.com/view/MscSDB
vec3 bumpMapping( sampler2D tex, vec3 p, vec3 n, float bf )
{
    const vec2 e = vec2(0.001, 0);
    
    mat3 m = mat3( tex3D(tex, p - e.xyy, n).rgb,
                   tex3D(tex, p - e.yxy, n).rgb,
                   tex3D(tex, p - e.yyx, n).rgb);
    
    vec3 g = vec3(0.299, 0.587, 0.114) * m;
    g = (g - dot( tex3D(tex,  p , n).rgb, vec3(0.299, 0.587, 0.114)) )/e.x;
    g -= n * dot(n, g);
                      
    return normalize( n + g*bf );
    
}
vec3 skyColor( vec3 rd )
{
    rd.y = max(rd.y+0.03, 0.02);
	const float anisotropicIntensity = 0.03; 
	const float density = .3;
    
    
    float l = length(rd - sunDir);
    
    vec3 col = vec3(0.39, 0.57, 1.0) * (1.0 + anisotropicIntensity);
    
	float zenith = density / pow(max(rd.y, 0.35e-2), 0.75);
    vec3 absorption = exp2(col * -zenith) * 2.;
	float rayleig = 1.0 + pow(1.0 - clamp(l, 0.0, 1.0), 2.0) * PI * 0.5;
    
    vec3 sun = vec3(1.,.3,.01) * smoothstep(0.03, 0.0, l) * 100.0;
    sun += vec3(1.,.7,.5) * smoothstep(0.3, 0.0, l) * .5;
    col = col * zenith * rayleig * absorption*.5 + sun;
    col *= (vec3(.6,.7,.8)/sqrt(l)); //sun
    //col = mix(col, FOGCOLOR, saturate((.06-rd.y)*50.));
    return col*2.;
}


void getMaterial(in vec3 p, inout vec3 n, out float metalness,out vec3 albedo) {

    if (level(p) < ship(p)) {
    	float rnd = hash(floor(p.xz*.01));
        if (rnd>.4) {
			albedo = tex3D(iChannel2,p.xyz*.025,n)*vec3(.4,.6,1.)*2.;
			n = bumpMapping(iChannel2,p.xyz*.2,n,.05);
			metalness = 0.;
		} else if(rnd>.2){
			albedo = tex3D(iChannel3,p.xyz*.002,n)*vec3(.3,.7,1.);
			n = bumpMapping(iChannel3,p.xyz*.15,n,.05);
			metalness = 2.;
        } else {
			albedo = tex3D(iChannel3,p.xyz*.03,n);
			n = bumpMapping(iChannel3,p.xyz*.2,n,.05);
            metalness = .2;
        }
     } else {
		albedo = vec3(1.);
        metalness = 1.;
     }
}
void computeGlow(inout vec3 col, vec2 acc) {
    col += vec3(.8,.3,1.) / pow(acc.y+.95,20.);
    col += vec3(.8,.3,1.)*.3 / pow(acc.y+.95,3.);
    
    col += (vec3(1.,.2,.1) / pow(acc.x+.9,20.) +
            vec3(1.,.2,.1) / pow(acc.x+.95,3.)*.5)* max(0.4,data.shipAccel.z);

    
}
vec3 shadeFast( vec3 p, vec3 n, vec3 ro, vec3 rd )
{
    float d = length(p-ro);
    vec3 sky = skyColor(rd);
    vec3 col = sky;
    
    if (d < 100.)
    {
        vec3 albedo = vec3(.8);
        float metalness = 0.;
        getMaterial(p, n, metalness, albedo);
        
        float ao = ambientOcclusion(p,n, 10., 2.);
        float shad = shadowFast(vec3(p), vec3(sunDir), float(0.5), float(80.));
		float fre = saturate(1.+dot(rd,n));
        
        vec3 amb = vec3(.5,.5,.5) * ao;
        vec3 diff = vec3(1.,.7,.5) * max(0., dot(n, sunDir) ) * shad;
                
        col = albedo * ( diff*2. + amb );
        
        col = mix(col, skyColor(vec3(1.,.2,.1))*.25, 1.-exp(-length(p-ro)*.01));
    }
    computeGlow(col,glowAcc);
    
    return col;
}

vec3 shade( vec3 p, vec3 n, vec3 ro, vec3 rd )
{
    vec2 glowAccCopy = glowAcc; // copy since it will be reset by the reflection raymarch loop
    float d = length(p-ro);
    vec3 sky = skyColor(rd);
    vec3 col = sky;
    
    if (d < 300.)
    {
        vec3 albedo = vec3(.8);
        float metalness = 0.;
        getMaterial(p, n, metalness, albedo);
        
        float ao = ambientOcclusion(p,n, 10., 2.)* ambientOcclusion(p,n, 1., .5);
        float shad = shadow(vec3(p), vec3(sunDir), float(1.), float(80.));
		float fre = saturate(1.+dot(rd,n));
        
        vec3 amb = vec3(.5,.5,.5) * ao;
        vec3 diff = vec3(1.,.7,.5) * max(0., dot(n, sunDir) ) * shad;
        vec3 bnc = vec3(1.,.7,.4) * saturate(-n.y) * ao;
        
        
        col = albedo * ( diff*2. + amb );
        
        vec3 refl;
        {
            vec3 rro = p+n*0.1;
            vec3 rrd = reflect(rd,n);
            vec3 rp = raymarchFast(rro,rrd, vec2(.1,100.), 0.001);
            refl = shadeFast(rp, normal(rp, 0.01), rro, rrd);
            if (ship(p)<level(p)) {
                col = refl;
            } else {
				col += refl * pow(fre,5.)*metalness;
            }
        }
        
        col = mix(col, skyColor(vec3(1.,.2,.1))*.25, 1.-exp(-length(p-ro)*.01));
    }
    computeGlow(col,glowAccCopy);
    
    return col;
}



// ---------------------------------------------
// Rendering
// ---------------------------------------------
void mainImage( out vec4 fragColor, vec2 fragCoord )
{    
    // coord setup
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes;
    
    // init
    time = iTime;
    data = readGameData(iChannel0, invRes);
    
    
    // camera setup
    vec2 v = -1.0+2.0*(uv);
	v.x *= iResolution.x/iResolution.y;
    vec3 ro = vec3(0., 1.3, 0.)+data.shipPos-data.shipDirection*3.;
    vec3 rd = normalize( vec3(v, 1.45) );
    rd.xy = rotate(data.shipAccel.x*.2) * rd.xy;
    rd.xz = rotate(-data.shipTheta) * rd.xz;
    
    // sdf rendering
    vec3 p = raymarch(ro, rd, vec2(2.,300.), 0.01);
    vec3 n = normal(p, 0.001);
    vec3 col = shade(p, n, ro, rd);
    
    // color + depth in the alpha channel
    fragColor = vec4(col,length(p-ro));
}