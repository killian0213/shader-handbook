// Image (image) — Fluid 3D Volumetric* by wyatt
// https://www.shadertoy.com/view/WsSXRy

//Rendering
mat2 ro (float a) {
	float s = sin(a),c = cos(a);
    return mat2(c,-s,s,c);
}
void mainImage( out vec4 Q, in vec2 U )
{ R = iResolution.xy;
    
 
   	vec3 p = vec3(0,0,-.6*R.x/N);
 	vec3 d = normalize(vec3(3.*(U-0.5*R)/R.y,2));
 	if (iMouse.z>0.) {
 		p.xz *= ro(6.2*iMouse.x/R.x);
		d.xz *= ro(6.2*iMouse.x/R.x);
        p.yz *= ro(6.2*iMouse.y/R.y);
		d.yz *= ro(6.2*iMouse.y/R.y);
    } else {
		p.xz *= ro(3.1+.1*iTime);
		d.xz *= ro(3.1+.1*iTime);
	}
	Q = vec4(0);
 	for (int i = 0; i < 4; i++) {
        vec3 o = abs(p)-0.5*vec3(R/N,N*N);
 		p+= d*max(o.x,max(o.y,o.z));
 	}
 	p += 2.*d*fract(iTime*sin(dot(U,U)));
 	p+=0.5*vec3(R/N,N*N);
 	for (int i = 0; i < 40; i++) {
        vec4 a = s3d(iChannel1,p);
        if (p.x < 2. || R.x/N-p.x < 2. ||
            p.y < 2. || R.y/N-p.y < 2. ||
            p.z < .8 || N*N - p.z < 1.1) a*=0.;
        p += d*max(.1,3.*exp(-100.*length(a.xyz)));
        Q += a;
 	}
 	Q = atan(4.*Q)*.7;
 	Q += exp(-10.*length(Q.xyz))*atan(10.*texture(iChannel1,U/R));


}