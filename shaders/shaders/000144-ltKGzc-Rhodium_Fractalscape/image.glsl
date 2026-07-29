// Image (image) — Rhodium Fractalscape by Virgill
// https://www.shadertoy.com/view/ltKGzc

// ***********************************************************
// Alcatraz / Rhodium 4k Intro Fractalscape
// by Jochen "Virgill" Feldkötter
//
// 4kb executable: http://www.pouet.net/prod.php?which=68239
// Youtube: https://www.youtube.com/watch?v=YK7fbtQw3ZU
// ***********************************************************



const float GA =2.399; 

mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));


// 	simplyfied version of Dave Hoskins blur
vec3 dof(sampler2D tex,vec2 uv,float rad)
{
	vec3 acc=vec3(0);
    vec2 pixel=vec2(.002*iResolution.y/iResolution.x,.002),angle=vec2(0,rad);;
    rad=1.;
	for (int j=0;j<80;j++)
    {  
        rad += 1./rad;
	    angle*=rot;
        vec4 col=texture(tex,uv+pixel*(rad-1.)*angle);
		acc+=col.xyz;
	}
	return acc/80.;
}

//-------------------------------------------------------------------------------------------
void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;

//	open and close effect
    float blend,blend2,multi1,multi2;
    blend=min (3. *abs(sin((.1*iTime)*3.1415/3.0)),1.); 
    blend2=min(2.5*abs(sin((.1*iTime)*3.1415/3.0)),1.); 
    
    multi1=((fract(uv.x*6.-4.*uv.y*(1.-blend2))< 0.5 || uv.y<blend) 
    &&(fract(uv.x*6.-4.*uv.y*(1.-blend2))>=0.5 || uv.y>1.-blend))?1.:0.;
 	multi2=(fract(uv.x*12.-0.05-8.*uv.y*(1.-blend2))>0.9)?blend2:1.;
   
    uv.y=(fract(uv.x*6.-4.*uv.y*(1.-blend2))<0.5)?uv.y-(1.-blend):uv.y+=(1.-blend);
	fragColor=vec4(dof(iChannel0,uv,texture(iChannel0,uv).w),1.)*multi1*multi2*blend2;
}