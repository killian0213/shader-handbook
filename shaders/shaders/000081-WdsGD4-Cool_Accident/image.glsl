// Image (image) — Cool Accident by wyatt
// https://www.shadertoy.com/view/WdsGD4

vec2 R;
vec4 T (vec2 U) {
	return texture(iChannel0,U/R);
}
void mainImage( out vec4 C, in vec2 U )
{
   R = iResolution.xy;
    
    vec4 
        a = T(U+vec2(1,0)),
        b = T(U-vec2(1,0)),
        c = T(U+vec2(0,1)),
        d = T(U-vec2(0,1));
        
    vec3 n = normalize(vec3(a.z-b.z,c.z-d.z,1));
   	C = 0.7+0.5*sin(T(U).z*vec4(1.0,1.02,1.04,1.3));
    C *= .5+texture(iChannel1,n);
   	
}