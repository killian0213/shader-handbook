// Image (image) — The explorer by Virgill
// https://www.shadertoy.com/view/lsGyDt

// ***********************************************************
// Alcatraz / The explorer 4k Intro
// by Jochen "Virgill" Feldkötter
//
// 4kb executable: http://www.pouet.net/prod.php?which=75741
//
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


    
	fragColor=vec4(dof(iChannel0,uv,texture(iChannel0,uv).w),1.);
}