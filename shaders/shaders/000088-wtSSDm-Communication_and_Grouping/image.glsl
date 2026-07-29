// Image (image) — Communication and Grouping by wyatt
// https://www.shadertoy.com/view/wtSSDm

float ln (vec3 p, vec3 a, vec3 b) {return length(p-a-(b-a)*min(dot(p-a,b-a),0.)/dot(b-a,b-a));}
void mainImage( out vec4 Q, in vec2 U )
{
 	vec4 
        n = D(U+vec2(0,1)),
        e = D(U+vec2(1,0)),
        s = D(U-vec2(0,1)),
        w = D(U-vec2(1,0));
    vec4 a = A(U);
    Q = C(U);
    Q = vec4(.7,.8,.9,1);
    vec3 no = normalize(vec3(e.w-w.w,n.w-s.w,2));
    vec3 re = reflect(normalize(vec3((U-0.5*R)/R.y,1)),no);
    float light = ln(vec3(2,2,2),vec3(U/R.y,0),vec3(U/R.y,0)+re);
    Q *= (exp(-light)+.4*exp(-.3*light))*(0.7+0.5*dot(re,normalize(vec3(U/R.y,0)-vec3(2,2,2))));

    
	
}