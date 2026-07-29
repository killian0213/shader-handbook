// Image (image) — Another Marble by KylBlz
// https://www.shadertoy.com/view/lsG3D3

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Modified from S. Guillitte 2015
#define tex(a,b) textureLod(a,b,0.)

float zoom=1.25, size = 0.19;

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 csqr( vec2 a )  { return vec2( a.x*a.x - a.y*a.y, 2.*a.x*a.y  ); }

vec3 ACESFilm( vec3 x ) {
	float a = 2.51;
	float b = 0.03;
	float c = 2.43;
	float d = 0.59;
	float e = 0.14;
	return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

mat2 rot(float a) {
	return mat2(cos(a),sin(a),-sin(a),cos(a));	
}

vec2 iSphere( in vec3 ro, in vec3 rd, in vec4 sph ) { //from iq
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return vec2(-1.0);
	h = sqrt(h);
	return vec2(-b-h, -b+h );
}

float map(in vec3 p) {
	
	float res = 0., st = cos(iTime*.1)*.4;
	
    vec3 c = p;
	for (int i = 0; i < 6; ++i) {
        p =.4*abs(p)/dot(p,p) - .3 + st;
        p.yz= csqr(p.yz);
        res += exp(-20. * abs(dot(p,c)));
	}
	return res*0.325;
}

vec3 raymarch( in vec3 ro, vec3 rd, vec2 tminmax ) {
    float t = tminmax.x, m = cos(iTime * .1) - 5.;
    float dt = (tminmax.y / tminmax.x) * 0.25;
    vec3 col = vec3(0.);
    float c = 0.;
    for( int i=0; i<192; i++ ) {
        t+=dt*exp(m*c);
        if(t>tminmax.y)break;
        vec3 pos = (ro+t*rd)*size;
        c = map(pos);               
        col += vec3(c*(c+0.5)*c*c-pos.z, c*c*c-pos.y, c*c-pos.x) + rd*rd*c*c;//get some hues in here
    }    
    return col * 0.003;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	float time = iTime;
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 m = vec2(0.);
    
	if ( iMouse.z>0.0 )
        m = iMouse.xy/iResolution.xy*3.14;
    m-=.5;

    // camera
    vec3 ro = zoom*vec3(4.);
    ro.yz*=rot(m.y);
    ro.xz*=rot(m.x+ -0.1*time);
    vec3 ta = vec3( 0.0 , 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 4.0*ww );
    vec2 tmm = iSphere( ro, rd, vec4(0.,0.,0.,2.) );

	// raymarch, but bring tMin down because glass does that
    vec3 col = raymarch(ro,rd,tmm * vec2(0.6, 1.0));
    if (tmm.x<0.) col = tex(iChannel0, rd).rgb * 2.0;
    else {
        vec3 nor=(ro+tmm.x*rd)/2.;
        nor = reflect(rd, nor);        
        float fre = pow(.5+ clamp(dot(nor,rd),0.0,1.0), 3. )*1.2;
        col += tex(iChannel0, nor).rgb * fre;
    }
	
	// shade
    col = ACESFilm(col);
	col = col*col*col*col;
    fragColor = vec4( col, 1.0 );
}
