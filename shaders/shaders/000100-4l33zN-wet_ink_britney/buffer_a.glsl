// Buf A (buffer) — wet ink britney by flockaroo
// https://www.shadertoy.com/view/4l33zN

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define Res iResolution
#define Res0 iChannelResolution[0]
float twopi=6.28318531;
float slope=15.;

float posTri(float x)
{
    // thanks Shane for the anti-branching-fix
    return abs(fract(x - .5) - .5)*2.;
    //x=fract(x);
   	//return 2.*(x<.5?x:1.-x);
}

vec3 getRand(vec2 uv) {return texture(iChannel1,uv).xyz;}

float spiral(vec2 pos, float slope, out vec2 coord)
{
    float l=length(pos);
    float ang=atan(pos.y,pos.x)+5.0*iTime;
    float r=posTri(ang/twopi+l/slope);
    //coord = normalize(pos)*(floor(ang/twopi+l/slope)+0.5)*slope;
    //floor(fract(ang/twopi)+l/slope)
    coord = normalize(pos)*(floor(l/slope+fract(ang/twopi))-fract(ang/twopi)+.5)*slope;
    //coord =pos;
    coord = (coord+0.5*iResolution.xy)/ iResolution.xy;
    //float lmax=iResolution.y*.49;
    //if(l>lmax) r+=l-lmax;
    return r;
}

vec3 getCol(vec2 uv)
{
    vec3 c=texture(iChannel0,uv,0.5*log2(slope/(Res.x/Res0.x))).xyz;
    float d=clamp(dot(c.xyz,vec3(-0.5,1.0,-0.5)),0.0,1.0);
    c=mix(c,vec3(1.5),1.8*d);
    c=clamp(vec3(dot(c,vec3(1./3.))),0.,1.);
    return c;
    //return mix(c,vec3(1),dot(c,vec3(0,1,0)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	float t1=texture(iChannel1,fragCoord.xy/100.0).x;
    vec3 pattern = vec3(spiral(fragCoord-0.5*iResolution.xy,slope,uv)+0.15*(t1-.5));
    vec3 col = getCol(uv);
    //col=pow(col,vec3(1.));
    //col=floor(col*8.)/8.;
	//fragColor = vec4(1.-smoothstep(0.85,1.15,pattern.x+0.8*(1.-col.x)+0.1));
    float b=0.7*(1.-col.x)+0.35;
    float c=clamp(pattern.x-1.+b,0.,1.);
    c=b-(b-c)*(b-c)/b/b;
    //c=sqrt(b*b-(b-c)*(b-c));
	fragColor = vec4(1.-c);
    //fragColor.xyz = 0.5*fragColor.xyz + 0.5*col;
    //fragColor.xyz = col;
}
