// Buf B (buffer) — Gray-Scott diffusion by knighty
// https://www.shadertoy.com/view/MdVGRh

const vec2 Diffusion = vec2(0.08,0.03);
//const float F = 0.04;
//const float k = 0.06;
const float dt = 2.;

float rand(vec2 co){
	// implementation found at: lumina.sourceforge.net/Tutorials/Noise.html
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// nine point stencil
vec2 laplacian1(vec2 position) {
    vec2 pixelSize = 1. / iResolution.xy;
    vec4 P = vec4(pixelSize, 0.0, -pixelSize.x);
	return  
	0.5* texture( iChannel0,  position - P.xy ).xy // first row
	+ texture( iChannel0,  position - P.zy ).xy
	+  0.5* texture( iChannel0,  position - P.wy ).xy
	+  texture( iChannel0,  position - P.xz).xy // seond row
	- 6.0* texture( iChannel0,  position ).xy
	+   texture( iChannel0,  position + P.xz ).xy
	+  0.5*texture( iChannel0,  position +P.wy).xy  // third row
	+ texture( iChannel0,  position +P.zy ).xy
	+   0.5*texture( iChannel0,  position + P.xy   ).xy;	
}
// nine point stencil
vec2 laplacian2(vec2 position) {
    vec2 pixelSize = 5. / iResolution.xy;
    vec4 P = vec4(pixelSize, 0.0, -pixelSize.x);
	return  
	0.5* texture( iChannel0,  position - P.xy ).xy // first row
	+ texture( iChannel0,  position - P.zy ).xy
	+  0.5* texture( iChannel0,  position - P.wy ).xy
	+  texture( iChannel0,  position - P.xz).xy // seond row
	- 6.0* texture( iChannel0,  position ).xy
	+   texture( iChannel0,  position + P.xz ).xy
	+  0.5*texture( iChannel0,  position +P.wy).xy  // third row
	+ texture( iChannel0,  position +P.zy ).xy
	+   0.5*texture( iChannel0,  position + P.xy   ).xy;	
}
// nine point stencil
vec2 laplacian3(vec2 position) {
    vec2 pixelSize = 7. / iResolution.xy;
    vec4 P = vec4(pixelSize, 0.0, -pixelSize.x);
	return  
	0.5* texture( iChannel0,  position - P.xy ).xy // first row
	+ texture( iChannel0,  position - P.zy ).xy
	+  0.5* texture( iChannel0,  position - P.wy ).xy
	+  texture( iChannel0,  position - P.xz).xy // seond row
	- 6.0* texture( iChannel0,  position ).xy
	+   texture( iChannel0,  position + P.xz ).xy
	+  0.5*texture( iChannel0,  position +P.wy).xy  // third row
	+ texture( iChannel0,  position +P.zy ).xy
	+   0.5*texture( iChannel0,  position + P.xy   ).xy;	
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    fragColor = vec4(0.0,0.0,0.0,1.0);
    /*if(iFrame == 0) {
        float rnd=rand(uv)+(sin(50.*uv.x)+sin(50.*uv.y))*0.;
        if(rnd>0.5) fragColor.x=.1;
        else fragColor.y=.1;
        return;
    }*/
    float F = uv.y*0.05+0.0;
    float k = uv.x*0.05+0.025;
    vec4 data = texture(iChannel0, uv);
    float u = data.x;
    float v = data.y;
    vec2 Duv = (1.*laplacian1(uv)+0.*laplacian2(uv)+0.*laplacian3(uv))*Diffusion;
    float du = Duv.x - u*v*v + F*(1.-u);
    float dv = Duv.y + u*v*v - (F+k)*v;
    fragColor.xy = clamp(vec2(u+du*dt,v+dv*dt), 0., 1.);
}