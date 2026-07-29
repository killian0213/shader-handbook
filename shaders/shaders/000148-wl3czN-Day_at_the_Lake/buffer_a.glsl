// Buffer A (buffer) — Day at the Lake by nimitz
// https://www.shadertoy.com/view/wl3czN

// Day at the Lake by nimitz, 2020 (twitter: @stormoid)
// https://www.shadertoy.com/view/wl3czN
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

// Main pass (sky and terrain)

#define ITR 120
#define time iTime

float dfog = 0.;
float matid = 0.;

// Curvature mapping and multi-scale terrain ambient occlusion all in one
// this version uses 9 fetches, but could be reduced to 7 with similar results
// also using distance to modulate the smaller scale evaluation
float curvM(in vec3 p, in float w, vec3 n, float d)
{
    vec3 haf = normalize(mix(vec3(0,1,0), n, .5));
    float t1 = map(p + n*w*0.02*d), t2 = map(p - n*w*0.02*d);
    float t3 = map(p + haf*w*.25), t4 = map(p - haf*w*.25);
    float t5 = map(p + haf*w*1.3), t6 = map(p - haf*w*1.3);
    float t7 = map(p + vec3(0.001,1,0.001)*w*20.), t8 = map(p - vec3(0.001,1,0.001)*w*20.);
    float t0 = map(p);
    float d2 = d*d;
    
    return smoothstep(-.55, .85, (800.*(t1 + t2)/d2 + 100.*(t3 + t4)/d2 + 2.5*(t5+t6) + 0.15*(t7+t8) - 40.*t0))*2.7 - 0.4;
}

vec3 normal(const in vec3 p)
{  
    vec2 e = vec2(-1., 1.)*0.005;   
	return normalize(e.yxx*map(p + e.yxx) + e.xxy*map(p + e.xxy) + 
					 e.xyx*map(p + e.xyx) + e.yyy*map(p + e.yyy) );   
}

float march(in vec3 ro, in vec3 rd)
{
	float precis = 0.0005;
    float h=precis*2.0;
    float d = 0.;
    for( int i=0; i<ITR; i++ )
    {
        if( abs(h)<precis || d>FAR ) break;
        d += h;
	    float res = map(ro+rd*d);
        h = res;
    }
	return d;
}

float shadow(in vec3 ro, in vec3 rd, in float mint, in float maxt )
{
	float res = 1.0;
    float t = mint;
    float ph = 1e10;
    
    for( int i=0; i<18; i++ )
    {
		float rz = map(ro + rd*t);
        res = min(res, 4.5*rz/t);
        t += rz;
        if( res<0.0001 || t>maxt ) break;
    }
    return clamp(res, 0.0, 1.0);
}

// Based on: http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
vec3 shade(in vec3 pos, in vec3 rd, float d)
{
    vec3 nor = normal(pos);
    vec3 alb = vec3(0.2,0.65,0.01);
    alb *= dot(cos(pos.xz*10. + sin(pos.zx*10.)*4.), sin(pos.zx*5.))*0.2 + 0.8;
    float grass = clamp(pow(nor.y,4.) - (pos.y + 2.5)*0.2, 0., 1.);
    alb = mix(vec3(0.32,0.31,0.3)*0.75, alb*0.55, grass);
    float beach = pow(pow(max(nor.y, 0.0), 5.0),3.0)*smoothstep(0.03,.01,abs(pos.y + 1.805));
    float dirt = smoothstep(0.03,.01, pos.y + 1.83);
    alb = mix(alb, vec3(1,0.95,0.5)*0.75, beach);
    alb = mix(alb, vec3(1,0.8,0.5)*0.2, dirt);
    nor = mix(nor, vec3(0,1,0),beach*0.8);
    
    float rough = 0.75;
    vec3 f0 = mix(vec3(0.1), vec3(0.004), grass);
    
	float nl = clamp(dot(nor,lgt), 0., 1.);
	vec3 col = vec3(0.);
    
    if (nl > 0.)
    {
        nl *= clamp(shadow(pos, lgt, 0.1,8.),0.35,1.);
        vec3 haf = normalize(lgt - rd);
        float nh = clamp(dot(nor, haf), 0., 1.); 
        float nv = clamp(dot(nor, -rd), 0., 1.);
        float lh = clamp(dot(lgt, haf), 0., 1.);
        float a = rough*rough;
        float a2 = a*a;
        float dnm = nh*nh*(a2 - 1.) + 1.;
        float D = a2/(3.14159*dnm*dnm);
        float k = pow(rough + 1., 2.)/8.; //hotness reducing
		float G = (1./(nl*(1. - k) + k))*(1./(nv*(1. - k) + k));
        vec3 F = f0 + (1. - f0) * exp2((-5.55473*lh - 6.98316) * lh); //"optimization"
        vec3 spec = nl*D*F*G;
        col = lcol*nl*(spec + alb*(1. - f0));		
    }
    
    float bnc3 = clamp(dot(nor, vec3(0,1,0))*.5 + 0.5, 0. , 1.);
    col.rgb += vec3(0.4,0.5,0.8)*alb*bnc3*0.1*(1.- nl)*(lcol*0.9+0.1);
    
    col *= clamp(pos.y*0.6 + 1.9,0.,1.3);
    
    float crv0 = curvM(pos, 0.1, nor, d);
    if (beach < 0.15)
        col *= crv0 + 0.45;
    
    return col;
}

//-----------------------------Sky rendering---------------------------
// modified from an prototype public domain implementation by shadertoy user Jodie: https://www.shadertoy.com/view/ttSGzh
// That version has some serious accuracy issues, I modified it to somewhat match the Hosek-Wilkie sky model visuals.

#define atmoDepth 8228.
#define earthRadius 6371000.
#define mieDepth 1800
#define sunColor vec3( .95, 0.96, 1.2 )
#define ozoneHeight 30000.
#define ozoneCoefficient (vec3(3.426, 8.298, .356) * 6e-5 / 100.)
#define mieCoefficient 16e-6 // adjust for foggier look

// custom
#define rayleighCoefficient vec3(5.6e-6  , 1.25e-5 , 2.9e-5 )

vec3 getThickness(vec3 rd)
{
    const vec4 cns = earthRadius + 
        			vec4(atmoDepth, mieDepth, ozoneHeight, ozoneHeight + atmoDepth);
    const float r2 = earthRadius * earthRadius;
    float b = -rd.y*earthRadius;
    vec4 z = sqrt( cns*cns + (b*b - r2) );
    return vec3(b + z.xy, z.w - z.z);
}

vec4 getSky(vec3 rd, vec3 lgt, float addDepth)
{
    const vec3 addCol = vec3(1.,1.,1.);
    const mat3 coeffs = mat3(rayleighCoefficient, vec3(mieCoefficient), ozoneCoefficient)/0.693147;
    vec3 thickness = getThickness(rd) + addDepth*addCol;
    float rdl = max(dot(rd, lgt), 0.0);

    vec3 rayleighScatter =(thickness.x * (0.4*rdl*rdl + 1.12))* rayleighCoefficient;
    float g = 0.8 - lgt.y*0.15 - mieCoefficient*1500.;
    float g2 = g*g;
    float a = inversesqrt(g2 - (2.0*g*rdl - 1.0));
    float phaseMie = (0.4 + lgt.y*0.1 + mieCoefficient*7000.)*(1.0 - g2)*a*a*a;
    float mieScatter = thickness.y * phaseMie * mieCoefficient;

    vec3 sunCoeff = coeffs*(getThickness(lgt) + addDepth*addCol);
    vec3 viewCoeff = coeffs*thickness;
    vec3 absorption = (exp2(-viewCoeff) - exp2(-sunCoeff))/((sunCoeff - viewCoeff)*0.693147);

    return vec4(clamp(sunColor*(rayleighScatter + mieScatter)*absorption*(0.6 + lgt.y*0.3), 0., 100.5), sunCoeff);
}


//-------------------------End of sky rendering------------------------
//---------------------------------------------------------------------

vec3 getSun(vec3 rd, float sunCoeff)
{
    float rdl = max(dot(rd, lgt), 0.0);
    float dcy = smoothstep(-0.05,0.2,lgt.y);
    vec3 sun = 50.0*vec3(1.,1.,.4)*pow(rdl, 10000.)*clamp(1.0 - dcy*.7, 0.,1.);
    sun += 10.0*vec3(1.,0.7,.2)*pow(rdl, 3500.);
    sun *= clamp(1.0 - dcy*.6, 0.,1.);
    sun *= exp2(-sunCoeff*0.45);
    return sun;
}

float linstep(in float mn, in float mx, in float x){ return clamp((x - mn)/(mx - mn), 0., 1.); }
mat2 rot2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}

vec4 getClouds( in vec3 ro, in vec3 rd, float scnD, vec3 skyCol )
{
	vec4 rez = vec4(0.);
	float t = min(intcPlane(ro, rd, -12.).x, 175.);
    
    float updl = dot(lgt, vec3(0, 1, 0));
    float sunUp = max(updl, 0.);
    float sunUp3 = clamp(sunUp*sunUp*sunUp*6., 0.0, 1.0);
    float sunDw = 1.0 - sunUp;
    sunDw = pow(sunDw, 6.0);
    
    float bsd = dot(lgt.xz, rd.xz);
    float sd = max(bsd, 0.0);
    float sd2 = max(bsd*0.55 + 0.53,0.);
    
    vec3 topSky = clamp(getSky(vec3(0, 1, 0), lgt, 0.).xyz, 0.,1.);
    vec3 baseCol = mix(topSky, vec3(0.05, 0.066, 0.09), clamp(sunUp3,0.0, 0.6))*0.2;
    
    float extraDepth = 14e4*((1.0-bsd)*0.2 + 0.9)*pow(1.0 - sunUp, 4.0);
    vec3 hlitCol = clamp(getSky(normalize((lgt-vec3(0,0.001,0))*rot_y(0.15)), lgt, extraDepth).xyz ,0.0, 1.0);
    hlitCol = hlitCol*sd2*mix(sunDw, sunDw*sunDw, sd)*8.;
    
    vec3 bSkyCol = getSky(rd, lgt, extraDepth*5.0*(sunUp*0.8 + 0.2)).xyz;
    vec3 sunLCol = mix(vec3(1.0, 0.8, 0.75), vec3(.5), sunUp);
    vec3 atmoCol = mix(bSkyCol*(sunUp*0.3+0.7), sunLCol*dot(bSkyCol, vec3(0.38)), sunUp3)*0.25;
    
	for(int i=0; i<85; i++)
	{
		vec3 pos = ro + t*rd;
        if(rez.a > 0.99 || t > 300.  || pos.y > 150.)break;
        vec4 cld = cloudMap(pos, iTime);
		float den = clamp(cld.x, 0., 1.)*1.02;
		float dn = clamp((cld.x + 1.9),0.0 , 3.0);
        float fogT = 0.;
        
		vec4 col = vec4(0);
        
        if (cld.x > 0.6)
        {   
            col = vec4(baseCol, 0.1);
            float nl = max(dot(cld.yzw, -lgt), -1.2);
            float dif = clamp((cld.x - cloudMap(pos + lgt*8., iTime).x)*0.4 + 0.2, 0.11, 2.0 )*2.5;
            dif += clamp((cld.x - cloudMap(pos + lgt*15., iTime).x)*0.2 - 0.03, -0.02, 1. )*4.0;
            
            col.rgb += atmoCol*((nl*0.25 + 0.7)*dif*0.65); //atmosphere lighting
            
            float den2 = den*den;
            float den4 = den2*den2;
            col *= den4*den4;
            col.rgb += col.a*clamp((nl*0.8 + 0.1)*dif,0.,1.)*hlitCol; //twi-lights
            //col *= smoothstep(t-0.0, t+.1, scnD); //blend with scene
        }
        
        float fogC = exp2(t*0.012/(rd.y + 0.35) - 11.7);
        col.rgba += vec4(skyCol, 1.0)*clamp(fogC, 0.0, 1.0);
		rez = rez + col*(1.0 - rez.a);
        t += clamp(7. - dn*dn*.85, 1.2, 7.);
	}    
	return clamp(rez, 0.0, 1.0);
}

vec4 render(in vec3 ro, in vec3 rd)
{
    float rz = march(ro,rd);
    float ldt = clamp(dot(lgt,rd),0.,1.);
    
    vec4 skyCol = getSky(rd, lgt, 0.);
    vec3 col = skyCol.rgb;
    vec3 bg= col;
    
    vec3 lgtOffs = normalize((lgt + vec3(0,0.03,0.)));
    vec4 haloCol = getSky(lgtOffs, lgt, 0.);    
    lcol = clamp(mix(haloCol.xyz, vec3(0.72, 0.71, 0.7), clamp(lgt.y*3.0, 0.04, 0.9)),0.,1.);
    
    if ( rz < FAR )
    {
        vec3 pos = ro +rd*rz;
        vec3 nor = normal(pos);
        col = shade(pos, rd, rz);
        col = mix(col, bg, smoothstep(5., FAR + 35.,rz));
    }
    else
    {
        col += getSun(rd, skyCol.w);
        vec4 cld = getClouds(ro, rd, 10000., bg);
    	col = col*(1.0-cld.w) + cld.xyz;
    }
    return vec4(col, rz);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    ttime = iTime;
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = q - 0.5;
	p.x*=iResolution.x/iResolution.y;
	vec2 mo = iMouse.xy / iResolution.xy-.5;
    mo = (mo==vec2(-.5))?mo=vec2(-0.1,-0.33):mo;
	mo.x *= iResolution.x/iResolution.y;
    mo*=3.14;
	mo.y = clamp(mo.y*0.6-.5,-4. ,.15 );
    
    lgt = sunPos(0.43 + mo.y*0.15, 0.5);
    lgt *= rot_y(-0.2);
    
    vec3 rd, ro;
    getRay(p, mo, ro, rd, iTime);
    fragColor = render(ro, rd);
}
