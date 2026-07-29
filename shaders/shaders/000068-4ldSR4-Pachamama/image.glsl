// Image (image) — Pachamama by XT95
// https://www.shadertoy.com/view/4ldSR4

// ---------------------------------------------------------------------------------------
//	Created by anatole duprat - XT95/2016
//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//
//  /!\ Heavy GPU required /!\
//  You can disable some features on the Buffer A if it's too slow..
//
// 	Special Thanks to :
//  Shane ( Nice Bump mapping https://www.shadertoy.com/view/MscSDB )
//  Virgill ( Killer DOF https://www.shadertoy.com/view/llK3Dy )
//  iq ( OrenNayar https://www.shadertoy.com/view/ldBGz3 & Soft Shadow https://iquilezles.org/articles/rmshadows )
//
//  Wonderfull music by Tinush : https://soundcloud.com/tinush/tinush-journey-original
//  Enjoy =)
//
// ---------------------------------------------------------------------------------------



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


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor.rgb = dof(iChannel0,uv, texture(iChannel0,uv).a) ;
    fragColor.rgb *= min(mod(iTime,30.)*.5,1.) * (1.-max((mod(iTime,30.)-28.),0.)*.5);
	fragColor.a = 1.;
    
    
    
    //Gamma correction & Vignetting
    fragColor.rgb = pow(fragColor.rgb, vec3(1./2.2));
    fragColor.rgb *= .5 + .5*pow( uv.x*uv.y*(1.-uv.x)*(1.-uv.y)*16., .75);
}