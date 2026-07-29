// Buffer B (buffer) — vt220 coding at night edition by sprash3
// https://www.shadertoy.com/view/XdtfzX

#define FONT_SIZE vec2(10.,20.)
#define ROWCOLS vec2(80., 24.)

// Some Plasma stolen from dogeshibu for testing
float somePlasma(vec2 uv)
{
    uv /= iResolution.xy;
    uv *= ROWCOLS; // 80 by 24 characters
    uv = ceil(uv);
    uv /= ROWCOLS;
    
    float color = 0.0;
    color += 0.7*sin(0.5*uv.x + iTime/5.0);
    color += 3.0*sin(1.6*uv.y + iTime/5.0);
    color += 1.0*sin(10.0*(uv.y * sin(iTime/2.0) + uv.x * cos(iTime/5.0)) + iTime/2.0);
    float cx = uv.x + 0.5*sin(iTime/2.0);
    float cy = uv.y + 0.5*cos(iTime/4.0);
    color += 0.4*sin(sqrt(100.0*cx*cx + 100.0*cy*cy + 1.0) + iTime);
    color += 0.9*sin(sqrt(75.0*cx*cx + 25.0*cy*cy + 1.0) + iTime);
    color += -1.4*sin(sqrt(256.0*cx*cx + 25.0*cy*cy + 1.0) + iTime);
    color += 0.3 * sin(0.5*uv.y + uv.x + sin(iTime));
    return 17.0*(0.5+0.499*sin(color))*(0.7+sin(iTime)*0.3);
}

float textLines(vec2 uvG)
{
    float wt = 5. * (iTime + 0.5*sin(iTime*1.4) + 0.2*sin(iTime*2.9)); // wobbly time
    vec2 uvGt = uvG + vec2(0., floor(wt));
    float ll = rand(vec2(uvGt.y, - 1.)) * ROWCOLS.x; // line length
    
    if (uvG.y > ROWCOLS.y - 2.){
        if (ceil(uvG.x) == floor(min(ll, fract(wt)*ROWCOLS.x)))
        	return 2.;
        if (ceil(uvG.x) > floor(min(ll, fract(wt)*ROWCOLS.x)))
        	return 0.;
    }
    if (uvGt.x > 5. && rand(uvGt) < .075)
        return 0.;
    if (max(5., uvGt.x) > ll)
        return 0.;
       
    return rand(uvGt)*15. + 2.;
}

// Font Rendering
// From my shader https://www.shadertoy.com/view/llSXDV
// Can be done much better in the future...
#define l(y,a,b) roundLine(p, vec2(float(a), float(y)), vec2(float(b), float(y)))
float roundLine(vec2 p, vec2 a, vec2 b) 
{
	b -= a + vec2(1.0,0.);
	p -= a;
    float f = length(p-clamp(dot(p,b)/dot(b,b),0.0,1.0)*b);
	if (iResolution.y < 320.) // attempt to get rid of aliasing on small resolution
		return smoothstep(1.0, 0.9, f);    
    else if (iResolution.y < 720.)
		return smoothstep(0.75, 0.5, f);    
	else
		return smoothstep(1., 0., f);    
}

float vt220Font(vec2 p, float c)
{
    if (c < 1.) return 0.;
    if(p.y > 16.){
        if(c > 2.) return 0.0;
		if(c > 1.) return l(17,1,9);
    }
    if(p.y > 14.){
		if(c > 16.) return l(15,3,8);
		if(c > 15.) return l(15,1,8);
		if(c > 14.) return l(15,1,3)+ l(15,7,9);
		if(c > 13.) return l(15,2,8);
		if(c > 12.) return l(15,1,9);
		if(c > 11.) return l(15,2,8);
		if(c > 10.) return l(15,1,3)+ l(15,6,8);
		if(c > 9.) return l(15,4,6);
        if(c > 8.) return l(15,2,4)+ l(15,5,7);
		if(c > 7.) return l(15,2,8);
		if(c > 6.) return l(15,2,8);
		if(c > 5.) return l(15,2,8);
		if(c > 4.) return l(15,2,9);
		if(c > 3.) return l(15,1,8);
		if(c > 2.) return l(15,2,9);
    }
    if(p.y > 12.){
		if(c > 16.) return l(13,2,4)+ l(13,7,9);
		if(c > 15.) return l(13,2,4)+ l(13,7,9);
		if(c > 14.) return l(13,1,3)+ l(13,7,9);
		if(c > 13.) return l(13,1,3)+ l(13,7,9);
		if(c > 12.) return l(13,1,3);
		if(c > 11.) return l(13,4,6);
		if(c > 10.) return l(13,2,4)+ l(13,5,9);
		if(c > 9.) return l(13,2,8);
		if(c > 8.) return l(13,2,4)+ l(13,5,7);
		if(c > 7.) return l(13,1,3)+ l(13,7,9);
		if(c > 6.) return l(13,1,3)+ l(13,7,9);
		if(c > 5.) return l(13,1,3)+ l(13,7,9);
		if(c > 4.) return l(13,1,3)+ l(15,2,9);
		if(c > 3.) return l(13,1,4)+ l(13,7,9);
		if(c > 2.) return l(13,1,3)+ l(13,6,9);
    }
    if(p.y > 10.){
		if(c > 16.) return l(11,1,3);
		if(c > 15.) return l(11,2,4)+ l(11,7,9);
		if(c > 14.) return l(11,1,9);
		if(c > 13.) return l(11,7,9);
		if(c > 12.) return l(11,2,5);
		if(c > 11.) return l(11,4,6);
		if(c > 10.) return l(11,3,5)+ l(11,6,8);
		if(c > 9.) return l(11,4,6)+ l(11,7,9);
		if(c > 8.) return l(11,1,8);
		if(c > 7.) return l(11,1,3)+ l(11,7,9);
		if(c > 6.) return l(11,1,3)+ l(11,7,9);
		if(c > 5.) return l(11,1,3)+ l(11,7,9);
		if(c > 4.) return l(11,1,3);
		if(c > 3.) return l(11,1,3)+ l(11,7,9);
		if(c > 2.) return l(11,2,9);
    }
    if(p.y > 8.){
		if(c > 16.) return l(9,1,3);
		if(c > 15.) return l(9,2,8);
		if(c > 14.) return l(9,1,3)+ l(9,7,9);
		if(c > 13.) return l(9,4,8);
		if(c > 12.) return l(9,4,8);
		if(c > 11.) return l(9,4,6);
		if(c > 10.) return l(9,4,6);
		if(c > 9.) return l(9,2,8);
		if(c > 8.) return l(9,2,4)+ l(9,5,7);
		if(c > 7.) return l(9,1,3)+ l(9,7,9);
		if(c > 6.) return l(9,1,3)+ l(9,7,9);
		if(c > 5.) return l(9,1,3)+ l(9,7,9);
		if(c > 4.) return l(9,1,3)+ l(9,7,9);
		if(c > 3.) return l(9,1,4)+ l(9,7,9);
		if(c > 2.) return l(9,7,9);
    }
    if(p.y > 6.){
		if(c > 16.) return l(7,1,3);
		if(c > 15.) return l(7,2,4)+ l(7,7,9);
		if(c > 14.) return l(7,2,4)+ l(7,6,8);
		if(c > 13.) return l(7,5,7);
		if(c > 12.) return l(7,7,9);
		if(c > 11.) return l(7,2,6);
		if(c > 10.) return l(7,2,4)+ l(7,5,7);
		if(c > 9.) return l(7,1,3)+ l(7,4,6);
		if(c > 8.) return l(7,1,8);
		if(c > 7.) return l(7,2,8);
		if(c > 6.) return l(7,2,8);
		if(c > 5.) return l(7,2,8);
		if(c > 4.) return l(7,2,8);
		if(c > 3.) return l(7,1,8);
		if(c > 2.) return l(7,2,8);
    }
    if(p.y > 4.){
		if(c > 16.) return l(5,2,4)+ l(5,7,9);
		if(c > 15.) return l(5,2,4)+ l(5,7,9);
		if(c > 14.) return l(5,3,7);
		if(c > 13.) return l(5,6,8);
		if(c > 12.) return l(5,1,3)+ l(5,7,9);
		if(c > 11.) return l(5,3,6);
		if(c > 10.) return l(5,1,5)+ l(5,6,8);
		if(c > 9.) return l(5,2,8);
		if(c > 8.) return l(5,2,4)+ l(5,5,7);
		if(c > 7.) return 0.;
		if(c > 6.) return 0.;
		if(c > 5.) return 0.;
		if(c > 4.) return 0.;
		if(c > 3.) return l(5,1,3);
		if(c > 2.) return 0.;
    }
    if(p.y > 2.){
		if(c > 16.) return l(3,3,8);
		if(c > 15.) return l(3,1,8);
		if(c > 14.) return l(3,4,6);
		if(c > 13.) return l(3,1,9);
		if(c > 12.) return l(3,2,8);
		if(c > 11.) return l(3,4,6);
		if(c > 10.) return l(3,2,4)+ l(3,7,9);
		if(c > 9.) return l(3,4,6);
		if(c > 8.) return l(3,2,4)+ l(3,5,7);
		if(c > 7.) return l(3,2,4)+ l(3,6,8);
		if(c > 6.) return l(3,1,3)+ l(3,4,7);
		if(c > 5.) return l(3,2,4)+ l(3,6,8);
		if(c > 4.) return 0.;
		if(c > 3.) return l(3,1,3);
		if(c > 2.) return 0.;
    }
    else{
		if(c > 7.) return 0.;
		if(c > 6.) return l(1,2,5)+ l(1,6,8);
    }
    return 0.0;      
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    float val = 0.;
    
   	vec2 uv = vec2(fragCoord.x, iResolution.y - fragCoord.y);
   	vec2 uvT = vec2(80, 24) * FONT_SIZE * uv / iResolution.xy;
   	vec2 uvG = floor(ROWCOLS * uv / iResolution.xy);
    
    // Switch between 3 "programs"
    float prog = sin(iTime*0.5);
    if(prog < -0.1)
    	val = somePlasma(fragCoord.xy);
    else if(prog < 0.1)
    	val = rand(uvG * iTime) * 17.;
    else
    	val = textLines(uvG);
	fragColor = vt220Font(uvT - uvG * FONT_SIZE, val) * PHOSPHOR_COL;
}
