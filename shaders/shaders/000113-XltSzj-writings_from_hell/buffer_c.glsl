// Buf C (buffer) — writings from hell by flockaroo
// https://www.shadertoy.com/view/XltSzj

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

float getVign(vec2 fragCoord)
{
	float vign=1.;
    
	float rs=length(fragCoord-iResolution.xy*.5)/iResolution.x/.7;	
    vign*=1.-rs*rs*rs;
    
    vec2 co=2.*(fragCoord.xy-.5*iResolution.xy)/iResolution.xy;
	vign*=cos(0.75*length(co));
    vign*=0.5+0.5*(1.-pow(co.x*co.x,16.))*(1.-pow(co.y*co.y,16.));
    
    return vign;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera rattle
    vec4 rattle=texture(iChannel2,vec2(iTime*.1234*.5,.5/256.));
	vec2 uv = fract(((fragCoord.xy / iResolution.xy-.5)*(1.+rattle.z*.01)+.5) + rattle.xy*.005);
    vec4 c = texture(iChannel0,uv);
    vec4 old = texture(iChannel1,fragCoord.xy / iResolution.xy);
    // brightness flickering
    vec4 flicker=texture(iChannel2,vec2(iTime*.2,.5/256.));
    
    // yellow-red fade
    fragColor= 1.5*mix(abs(c.xxww*vec4(1,.2,0,1)),.6*abs(c.xxxw),(1.-smoothstep(.35,.45,c.z))*(1.-smoothstep(.25,.35,c.x)));
    
    fragColor+=
        +abs(c.yyyw)*vec4(.4,.4,.3,1)                            // bright core
        +(.8+.2*flicker)*vec4(1,1,.5,1)*clamp(c.zzzw-.5,0.,1.);  // halo
    
    // mix bg image
    fragColor=mix(vec4(1),vec4(.2,.12,.06,0)*1.2+.4*texture(iChannel3,uv).x*vec4(1,1,1,0),-fragColor+1.1);

    fragColor*=(flicker*.25+.75)*2.3*fragColor;     // fragColor^2 contrast
    fragColor*=getVign(fragCoord);                  // vignetting
    fragColor=mix(fragColor,old*vec4(.7,1,1,1),.6); // slight motion blur (camera latency)
}