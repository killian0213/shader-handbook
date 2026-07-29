// Image (image) — Castle Argh by Antonalog
// https://www.shadertoy.com/view/ldsGRX

#define pi 3.1415927

//various primitives, thanks IQ! https://iquilezles.org/articles/distfunctions

float Sphere( vec3 p, vec3 c, float r )
{
	return length(p-c) - r;
}

float Box( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float BevelBox(vec3 p, vec3 size, float box_r)
{
	vec3 box_edge = size - box_r*0.5;
	vec3 dd = abs(p) - box_edge;

	//in (dd -ve)
	float maxdd = max(max(dd.x,dd.y),dd.z);
	//0 away result if outside
	maxdd = min(maxdd,0.0);
		
	//out (+ve);
	dd = max(dd,0.0);
	float ddd = (length(dd)-box_r);

	//combine the in & out cases
	ddd += maxdd;
	return ddd;
}

float CylinderXY( vec3 p, vec3 c ) {
	return length(p.xy-c.xy)-c.z;
}

float CylinderXZ( vec3 p, vec3 c ) {
	return length(p.xz-c.xy)-c.z;
}

float CylinderYZ( vec3 p, vec3 c ) {
	return length(p.yz-c.xy)-c.z;
}

float udHexPrism( vec2 p, float h ) {
    vec2 q = abs(p);
    return max(q.x+q.y*0.57735,q.y*1.1547)-h;
}

float Cone( vec3 p, vec2 c )
{
    // c must be normalized
//    float q = length(p.xz);
	
	p.xz *= p.xz;
	p.xz *= p.xz;
	p.xz *= p.xz;
	float q = pow(p.x+p.z, 1./8.);	
		
    return dot(c,vec2(q,p.y));
}

// cube intersection function
//borrowed from Exploding Cubes by Kali https://www.shadertoy.com/view/Xdf3zl
bool RayBox( in vec3 p, in vec3 dir, in vec3 pos, in vec3 edge, out float t
		//	inout vec2 startend,
		//	inout vec3 nor, 
		//	inout vec3 hit
		   )
{
	float fix=.00001;
	vec3 minim=pos-edge*.5;
	vec3 maxim=pos+edge*.5;
	vec3 inv_dir = vec3(1.)/dir;
	vec3 omin = ( minim - p ) * inv_dir;
	vec3 omax = ( maxim - p ) * inv_dir;
	vec3 maxi = max ( omax, omin );
	vec3 mini = min ( omax, omin );
	vec2 startend;
	startend.y = min ( maxi.x, min ( maxi.y, maxi.z ) );
	startend.x = max ( max ( mini.x, 0.0 ), max ( mini.y, mini.z ) );
	float rayhit=0.;
	if (startend.y-startend.x>fix) rayhit=1.;

	t = startend.x;
	
//	hit=p+startend.x*dir; //intersection point
/*	
	// get normal
		nor=vec3(0.,0.,-1.);
		if (abs(hit.x-minim.x)<fix) nor=vec3( 1., 0., 0.);
		if (abs(hit.y-minim.y)<fix) nor=vec3( 0., 1., 0.);
		if (abs(hit.z-minim.z)<fix) nor=vec3( 0., 0., 1.);
		if (abs(hit.x-maxim.x)<fix) nor=vec3(-1., 0., 0.);
		if (abs(hit.y-maxim.y)<fix) nor=vec3( 0.,-1., 0.);
*/
	return rayhit>0.5;
}

//stoopid old VLIW processors
bvec4 RayVs4Boxes(in vec3 p, in vec3 dir, in vec4 pos_x, in vec4 pos_y, in vec4 pos_z,
				  in vec4 edge_x, in vec4 edge_y, in vec4 edge_z,
				  out vec4 t
	)
{
	vec3 inv_dir = vec3(1.)/dir;
	
	vec4 minim_x=pos_x-edge_x*.5;
	vec4 minim_y=pos_y-edge_y*.5;
	vec4 minim_z=pos_z-edge_z*.5;
	
	vec4 maxim_x=pos_x+edge_x*.5;
	vec4 maxim_y=pos_y+edge_y*.5;
	vec4 maxim_z=pos_z+edge_z*.5;

	vec4 omin_x = ( minim_x - p.x ) * inv_dir.x;
	vec4 omin_y = ( minim_y - p.y ) * inv_dir.y;
	vec4 omin_z = ( minim_z - p.z ) * inv_dir.z;
	
	vec4 omax_x = ( maxim_x - p.x ) * inv_dir.x;
	vec4 omax_y = ( maxim_y - p.y ) * inv_dir.y;
	vec4 omax_z = ( maxim_z - p.z ) * inv_dir.z;

	vec4 maxi_x = max ( omax_x, omin_x );
	vec4 maxi_y = max ( omax_y, omin_y );
	vec4 maxi_z = max ( omax_z, omin_z );
	
	vec4 mini_x = min ( omax_x, omin_x );
	vec4 mini_y = min ( omax_y, omin_y );
	vec4 mini_z = min ( omax_z, omin_z );

	vec4 start = max ( max ( mini_x, vec4(0.) ), max ( mini_y, mini_z ) );
	vec4 end = min ( maxi_x, min ( maxi_y, maxi_z ) );
	
	t = start;
	
	return greaterThan(end-start,vec4(.00001));
}


vec3 RotX(vec3 p, float t) {
	float c = cos(t); float s = sin(t);
	return vec3(p.x,
				p.y*c+p.z*s,
				-p.y*s+p.z*c);
}

vec3 RotY(vec3 p, float t) {
	float c = cos(t); float s = sin(t);
	return vec3(p.x*c+p.z*s,
				p.y,
				-p.x*s+p.z*c);
}

vec3 RotZ(vec3 p, float t) {
	float c = cos(t); float s = sin(t);
	return vec3(p.x*c+p.y*s,
				-p.x*s+p.y*c,
				p.z);
}

float Rep(float x, float t) { return mod(x,t)-0.5*t; }
float U(float a,float b) { return min(a,b); }
float I(float a,float b) { return max(a,b); }
float S(float a,float b) { return max(a,-b); }
float ClipX(float d, vec3 p, float x) { return I(d,p.x-x); }
float ClipXX(float d, vec3 p, float x) { return I(d,abs(p.x)-x); }

float ClipY(float d, vec3 p, float x) { return I(d,p.y-x); }
float ClipYY(float d, vec3 p, float x) { return I(abs(d),p.y-x); }

float ClipZZ(float d, vec3 p, float x) { return I(d,abs(p.z)-x); }

float Stair(vec3 p)
{
	//convention: neg in, pos out
	//Vertical distance to stair = y - floor(x)
	//Horizontal distance to stair =  x - ceil(y)
	float stair = min( abs(p.y-floor(p.x)), abs(p.x-ceil(p.y)) );
	
	float o = p.y > p.x ? 0. : 1.;				//select y=x or y=x-1 as bounding line
	vec2 A = p.xy +(p.y-p.x+o)*vec2(.5,-.5);	//nearest point of stair on line
	A=round(A);									//step it
	float t1 = length(p.xy-A);					//distance to it
	stair = min(stair,t1);						//min of that and straight line h or v distance
	
	stair = p.y < floor(p.x) ? -stair : stair;	//fix sign
	
	stair -= 0.1;	//bevel!

//	stair = ClipZZ(stair,p,2.);
	return stair;	
}

float floor_height = -15.0;
float ground_height = -5.;

vec3 TowerReflect(vec3 p)
{
	vec3 q=p;
	q.xz=abs(p.xz); 
	q.xz -= vec2(6.,8.);
	return q;
}

vec3 ss_grad(vec3 X)
{
	return cross(dFdx(X),dFdy(X));
}

vec3 Tex(vec3 p)
{
	//if (p.y > 7.) return vec3(1.,1.,1.);
	
	vec3 splat = texture(iChannel1,p.xz*.05).xyz;
	if (p.y < ground_height*0.99) //return vec3(1,1,1);
									return splat;
//	p = RotY(p,iTime);
	
//	vec3 q=TowerReflect(p);
	
//	vec2 uv = abs(q.x) < abs(q.z) ? p.xy : p.zy;
	
	vec3 g=abs(ss_grad(p));	
	vec2 uv = abs(g.x) < abs(g.z) ? p.xy : p.zy;
	uv = abs(g.y) > max(abs(g.x), abs(g.z)) ? p.xz : uv;	
	return texture(iChannel0,uv*0.4).xyz;
}

float bevel = 0.1;

float Tower(vec3 p)
{
	vec3 q = p;
	p=TowerReflect(p);
	
	//main tower
	float w = 5.0*0.25;
	float h = 10.0*0.5;
	float hh = q.x > 0. ? h : 10.*0.3;
	float w_fat = w + clamp(p.y-3.5-(hh-h),0.,0.9)*0.2;
	float d = BevelBox(p-vec3(0.,(hh-h),0.),vec3(w_fat,h,w_fat),bevel);
	return d;
}

float Wall(vec3 p)
{
//	vec3 tex=Tex(p);
//	float grain = tex.x*0.05;
	
	//wall	
	float thick = 0.5 + (p.z > 0. ? clamp(p.y+2.5,0.,0.5)*.5 : 0.);
	float wall_d = BevelBox(p+vec3(3.,3.0,-0.5),vec3(3.0,2.0,thick),bevel); 

	vec3 cren_p = p;
	cren_p.x = Rep(cren_p.x,1.);
	wall_d = S(wall_d, Box(cren_p,vec3(0.25,1.5,10.)));
	wall_d = S(wall_d, Box(p, vec3(7.0,2.0,1.0)));

	float stair_size = 4.;
	float s = Stair(p*stair_size)/stair_size;
	s = ClipZZ(s,p,1.);
	s = ClipY(s,p,-2.);
	s = ClipX(s,p,-1.);
	wall_d = U(s,wall_d);
	
	return wall_d;	
}

float Pole(vec3 p)
{
	return ClipY( CylinderXZ(p,vec3(6.,8.,.1)), p, 9.);
}

float Flag(vec3 p)
{
	float t = iTime*2.;
	float z=1.;
	float z_off = 7.;
	float s = sin(p.z+t)-sin(t+z+z_off);//-sin(7.5);
	float d = BevelBox(p-vec3(s+6.,8.,z_off),vec3(0.01,0.7,z),0.05);
	
	d=U(d,Pole(p));
    return d * 0.8; //thanks to vipiao fixes flag glitch with lipschitz constant
}

float Gate(vec3 p)
{
	p += vec3(6.75,3.,0.);
	
	//main
	float fat = clamp(p.y-2.,0.,1.)*.45;
	float d = BevelBox(p,vec3(1.+fat,4.0,2.+fat),bevel);
	
	//hollow top
	d = S(d,Box(p+vec3(0.,-5.,0.),vec3(1.,2.0,2.)));
	
	vec3 cren_p = p;
	cren_p.z = Rep(cren_p.z,0.8);
	float cd = Box(cren_p+vec3(0.,-5.,0.),vec3(2.,1.5,0.2));
	d = S(d,cd);

	cren_p=p;
	cren_p.x = Rep(cren_p.x,1.6);	
	cd=Box(cren_p+vec3(0,-5.,0.),vec3(0.2,1.5,4.0));
//	cd = ClipXX(cd,cren_p,0.250);	
	d = S(d,cd);
	
//	d = U(d, BevelBox(p,vec3(1.,2.85,1.2),0.25));
	
	//archway
	float arch=clamp(p.y,0.,1.);
	arch = sqrt(1.-arch*arch);
	d = S(d,Box(p,vec3(2.,2.0,0.0+arch)));
	
	float w = 1.;
	float h = 3.;
//	float grain = 0.;
	float foot = 0.1*w + clamp(-p.y-1.,0.,1.)*0.2;
	float foot_d = BevelBox(abs(p)-vec3(w,0.,w), vec3(foot,h,0.1*w),.05);
//	foot_d = ClipY(foot_d,p,hh);
	d = U(d, foot_d);
	foot_d = BevelBox(abs(p)-vec3(w,0.,2.*w), vec3(foot,h,foot),.05);
	d = U(d, foot_d);
	
	return d;
}

float Roof(vec3 p)
{
	p += vec3(-6.,3.,0.);
	
	float r=8.0-p.y*.9;
	float s=6.5-p.y*.8;
	float d = BevelBox(p+vec3(0.,-6.,0.),vec3(s,1.0,r),0.5);

	return d;	
}
		   
float House(vec3 p)
{
	p += vec3(-6.,3.,0.);

	//main
	float fat = clamp(p.y-1.5,0.,1.)*.45;
	float d = BevelBox(p,vec3(2.+fat,5.0,2.75+fat),0.05);
	
	//hollow
	d = S(d, Box(p,vec3(1.5+fat,6.0,2.5+fat)));

	//door
	float arch=clamp(p.y+1.,0.,1.);
	arch = sqrt(1.-arch*arch)*.5;
	d = S(d,Box(p+vec3(2.,1.,1.),vec3(4.,1.0,0.0+arch)));
	
	//windows
	vec3 q=p;
	q.z = Rep(q.z,1.5);
	q.y -= 4.;
	
	float t=clamp(q.y,0.,1.);
	float win = Box(q,vec3(10.,1.0,0.25-t));
	d = S(d,win);
	
	//roof
	float r=8.0-p.y*.9;
	float s=6.5-p.y*.8;
	d = U(d,BevelBox(p+vec3(0.,-6.,0.),vec3(s,1.0,r),0.5));
	
	//columns	
	float w = 3.;
	float foot = 0.1*w + clamp(-p.y-1.,0.,1.)*0.2;
	p.z = abs(p.z);
	d = U(d,Box(p+vec3(2.,1.,-2.4),vec3(foot,4.0,0.125)));
	
	return d;	
}

float SoftU(float a, float b, float k)
{	
	float sum = exp(k*a) + exp(k*b);

	return log( sum ) / k;	
}

float Hill(vec3 p)
{
	float plane = p.y-floor_height;

	float mound = Cone( p+vec3(0.,-6.5,0.), normalize(vec2(1.,1.)) );

	mound = SoftU( p.y+5., mound, 1.);

//	mound += (sin(p.x)+sin(p.y))*0.2;
	
	return SoftU(plane,mound,-0.5);
}


float sdf( vec3 p, bvec4 sdf_bound_test )
{
	float d = Hill(p);
//	return Hill(p);
//	
//	p.y += 0.2*sin(p.z*0.5+iTime);

	vec3 tex=Tex(p);
	
	//floor!
//	float d = p.y-floor_height+tex.x*.25-.05-sin(p.z)*.1;
//	float d = p.y-floor_height;
	
//	if (p.x < 0.)
//	if (sdf_bound_test.z)
		d = U(d,Gate(p));
//	else
//	if (sdf_bound_test.w)
		d = U(d,House(p));
	
//	p = RotY(p,iTime);
	
	vec3 q = p;
	p=TowerReflect(p);
	
#if 1	
	//walls
//	if (sdf_bound_test.y)
	{
		d = U(d,Wall(p));
		d = U(d,Wall(p.zyx));
	}
	
//	if (sdf_bound_test.x)
	{
		//main tower
		float w = 5.0*0.25;
		float h = 10.0*0.5;
		float hh = q.x > 0. ? h : 10.*0.3;
		float w_fat = w + clamp(p.y-3.5-(hh-h),0.,0.9)*0.2;
		d = U(d, BevelBox(p-vec3(0.,(hh-h),0.),vec3(w_fat,h,w_fat),.05));
	
		float foot = 0.1*w + clamp(-p.y-3.,0.,1.)*0.2;
		float foot_d = BevelBox(abs(p)-vec3(w,0.,w), vec3(foot,h,foot),.05);
		foot_d = ClipY(foot_d,p,hh);
		d = U(d, foot_d);
		
		//hollow out
		d = S(d,Box(p,vec3(w*0.8,h*2.0,w*0.8)));
		
		//window
		float wind_h = h*.15;
		float wind_w = w*0.2; // - clamp(p.y*.5,0.,1.);
		vec3 wind_p = p;
		wind_p.y -= 2.+(hh-h);
		d = S(d,Box(wind_p,vec3(w*1.25,wind_h,wind_w)));
		d = S(d,Box(wind_p,vec3(wind_w,wind_h,w*1.2)));
	
		//sil
		wind_p.xz=abs(wind_p.xz);
		vec3 sil_off = vec3(w,-h*.15,0.);
		vec3 sil = vec3(w*.15,h*.0125,w*0.25);
		d = U(d,Box(wind_p-sil_off,sil));
		d = U(d,Box(wind_p-sil_off.zyx,sil.zyx));
					
		//crenulate towers
		p.xz=abs(p.xz);
		float cren_w=w*0.3;
		d = U(d, BevelBox(p-vec3(w,hh*1.1,w),vec3(cren_w,h*0.15,cren_w),.1));
				
		d = U(d,Flag(q));
	}
#endif	
	
	return d;
}

vec3 ss_nor(vec3 X)
{
	return normalize(cross(dFdx(X),dFdy(X)));
}

float nsdf(vec3 p)
{
//	return sdf(p); 
	
	//for normals, add small bump displacements
	float tex=Tex(p).x;
	float grain = -tex*0.075;

	float d = sdf(p, bvec4(1,1,1,1));
	d -= grain;
	
	return d;
}

vec3 nor(vec3 X)
{
	vec2 e = vec2(0.01,0.0); //fatter filter looks like bevelled edges on hard CSG shapes
	vec3 N = vec3(nsdf(X-e.xyy),nsdf(X-e.yxy),nsdf(X-e.yyx)) -
			 vec3(nsdf(X+e.xyy),nsdf(X+e.yxy),nsdf(X+e.yyx));
	return -normalize(N);
}


//thanks BRDF guys!
//http://hal.inria.fr/docs/00/70/23/04/PDF/paper.pdf

float gamma = //1.8; 
			2.2;
	//2.0;
float one_pi = 0.31830988618;
float lightIntensity = 16.0;

// gold-paint
#if 1
vec3 rho_d = vec3(0.147708, 0.0806975, 0.033172);
vec3 rho_s = vec3(0.160592, 0.217282, 0.236425);
vec3 alpha = vec3(0.122506, 0.108069, 0.12187);
vec3 p = vec3(0.795078, 0.637578, 0.936117);
vec3 F_0 = vec3(9.16095e-12, 1.81225e-12, 0.0024589);
vec3 F_1 = vec3(-0.596835, -0.331147, -0.140729);
vec3 K_ap = vec3(5.98176, 7.35539, 5.29722);
vec3 sh_lambda = vec3(2.64832, 3.04253, 2.3013);
vec3 sh_c = vec3(9.3111e-08, 8.80143e-08, 9.65288e-08);
vec3 sh_k = vec3(24.3593, 24.4037, 25.3623);
vec3 sh_theta0 = vec3(-0.284195, -0.277297, -0.245352);
#endif

void alum_bronze() {
rho_d = vec3(0.0478786, 0.0313514, 0.0200638);
rho_s = vec3(0.0364976, 0.664975, 0.268836);
alpha = vec3(0.014832, 0.0300126, 0.0490339);
p = vec3(0.459076, 0.450056, 0.529272);
F_0 = vec3(6.05524, 0.235756, 0.580647);
F_1 = vec3(5.05524, 0.182842, 0.476088);
K_ap = vec3(46.3841, 24.5961, 14.8261);
sh_lambda = vec3(2.60672, 2.97371, 2.7827);
sh_c = vec3(1.12717e-07, 1.06401e-07, 5.27952e-08);
sh_k = vec3(47.783, 36.2767, 31.6066);
sh_theta0 = vec3(0.205635, 0.066289, -0.0661091);
}
void alumina_oxide() {
rho_d = vec3(0.316358, 0.292248, 0.25416);
rho_s = vec3(0.00863128, 0.00676832, 0.0103309);
alpha = vec3(0.000159222, 0.000139421, 0.000117714);
p = vec3(0.377727, 0.318496, 0.402598);
F_0 = vec3(0.0300766, 1.70375, 1.96622);
F_1 = vec3(-0.713784, 0.70375, 1.16019);
K_ap = vec3(4381.96, 5413.74, 5710.42);
sh_lambda = vec3(3.31076, 4.93831, 2.84538);
sh_c = vec3(6.72897e-08, 1.15769e-07, 6.32199e-08);
sh_k = vec3(354.275, 367.448, 414.581);
sh_theta0 = vec3(0.52701, 0.531166, 0.53301);
}
void aluminium() {
rho_d = vec3(0.0305166, 0.0358788, 0.0363463);
rho_s = vec3(0.0999739, 0.131797, 0.0830361);
alpha = vec3(0.0012241, 0.000926487, 0.000991844);
p = vec3(0.537669, 0.474562, 0.435936);
F_0 = vec3(0.977854, 0.503108, 1.77905);
F_1 = vec3(-0.0221457, -0.0995445, 0.77905);
K_ap = vec3(449.321, 658.044, 653.86);
sh_lambda = vec3(8.2832e-07, 9.94692e-08, 6.11887e-08);
sh_c = vec3(3.54592e-07, 16.0175, 15.88);
sh_k = vec3(23.8656, 10.6911, 9.69801);
sh_theta0 = vec3(-0.510356, 0.570179, 0.566156);
}
void aventurnine() {
rho_d = vec3(0.0548217, 0.0621179, 0.0537826);
rho_s = vec3(0.0348169, 0.0872381, 0.111961);
alpha = vec3(0.000328039, 0.000856166, 0.00145342);
p = vec3(0.387167, 0.504525, 0.652122);
F_0 = vec3(0.252033, 0.133897, 0.087172);
F_1 = vec3(0.130593, 0.0930416, 0.0567429);
K_ap = vec3(2104.51, 676.157, 303.59);
sh_lambda = vec3(3.12126, 2.50965e-07, 2.45778e-05);
sh_c = vec3(1.03849e-07, 8.53824e-07, 3.20722e-07);
sh_k = vec3(251.265, 24.2886, 29.0236);
sh_theta0 = vec3(0.510125, -0.41764, -0.245097);
}
void beige_fabric() {
rho_d = vec3(0.20926, 0.160666, 0.145337);
rho_s = vec3(0.121663, 0.0501577, 0.00177279);
alpha = vec3(0.39455, 0.15975, 0.110706);
p = vec3(0.474725, 0.0144728, 1.70871e-12);
F_0 = vec3(0.0559459, 0.222268, 8.4764);
F_1 = vec3(-0.318718, -0.023826, 7.4764);
K_ap = vec3(3.8249, 7.32453, 10.0904);
sh_lambda = vec3(2.26283, 2.97144, 3.55311);
sh_c = vec3(0.0375346, 0.073481, 0.0740222);
sh_k = vec3(7.52635, 9.05672, 10.6185);
sh_theta0 = vec3(0.217453, 0.407084, 0.450203);
}
void black_fabric() {
rho_d = vec3(0.0189017, 0.0112353, 0.0110067);
rho_s = vec3(2.20654e-16, 6.76197e-15, 1.57011e-13);
alpha = vec3(0.132262, 0.128044, 0.127838);
p = vec3(0.189024, 0.18842, 0.188426);
F_0 = vec3(1, 1, 1);
F_1 = vec3(0, 0, 0);
K_ap = vec3(8.1593, 8.38075, 8.39184);
sh_lambda = vec3(3.83017, 3.89536, 3.89874);
sh_c = vec3(0.00415117, 0.00368324, 0.00365826);
sh_k = vec3(12.9974, 13.2597, 13.2737);
sh_theta0 = vec3(0.207997, 0.205597, 0.205424);
}
void black_obsidian() {
rho_d = vec3(0.00130399, 0.0011376, 0.00107233);
rho_s = vec3(0.133029, 0.125362, 0.126188);
alpha = vec3(0.000153649, 0.000148939, 0.000179285);
p = vec3(0.186234, 0.227495, 0.25745);
F_0 = vec3(2.42486e-12, 0.0174133, 0.091766);
F_1 = vec3(-0.0800755, -0.048671, 0.0406445);
K_ap = vec3(5668.57, 5617.79, 4522.84);
sh_lambda = vec3(13.7614, 8.59526, 6.44667);
sh_c = vec3(1e10, 1e10, 1e10);
sh_k = vec3(117.224, 120.912, 113.366);
sh_theta0 = vec3(1.19829, 1.19885, 1.19248);
}
void black_oxidized_steel() {
rho_d = vec3(0.0149963, 0.0120489, 0.0102471);
rho_s = vec3(0.373438, 0.344382, 0.329202);
alpha = vec3(0.187621, 0.195704, 0.200503);
p = vec3(0.661367, 0.706913, 0.772267);
F_0 = vec3(0.0794166, 0.086518, 0.080815);
F_1 = vec3(0.0470402, 0.0517633, 0.0455037);
K_ap = vec3(5.1496, 4.91636, 4.69009);
sh_lambda = vec3(4.0681, 3.95489, 3.71052);
sh_c = vec3(1.07364e-07, 1.05341e-07, 1.16556e-07);
sh_k = vec3(20.2383, 20.1786, 20.2553);
sh_theta0 = vec3(-0.479617, -0.4885, -0.478388);
}
void black_phenolic() {
rho_d = vec3(0.00204717, 0.00196935, 0.00182908);
rho_s = vec3(0.177761, 0.293146, 0.230592);
alpha = vec3(0.00670804, 0.00652009, 0.00656043);
p = vec3(0.706648, 0.677776, 0.673986);
F_0 = vec3(0.16777, 0.12335, 0.166663);
F_1 = vec3(0.111447, 0.0927321, 0.125663);
K_ap = vec3(65.4189, 70.8936, 70.9951);
sh_lambda = vec3(1.06318, 1.15283, 1.16529);
sh_c = vec3(1.24286e-07, 3.00039e-08, 9.77334e-08);
sh_k = vec3(74.0711, 75.1165, 73.792);
sh_theta0 = vec3(0.338204, 0.319306, 0.33434);
}
void black_soft_plastic() {
rho_d = vec3(0.00820133, 0.00777718, 0.00764537);
rho_s = vec3(0.110657, 0.0980322, 0.100579);
alpha = vec3(0.0926904, 0.0935964, 0.0949975);
p = vec3(0.14163, 0.148703, 0.143694);
F_0 = vec3(0.150251, 0.169418, 0.170457);
F_1 = vec3(0.100065, 0.113089, 0.114468);
K_ap = vec3(11.2419, 11.113, 10.993);
sh_lambda = vec3(4.3545, 4.3655, 4.31586);
sh_c = vec3(0.00464641, 0.00384785, 0.0046145);
sh_k = vec3(14.6751, 14.8089, 14.5436);
sh_theta0 = vec3(0.275651, 0.262317, 0.271284);
}
void blue_acrylic() {
rho_d = vec3(0.0134885, 0.0373766, 0.10539);
rho_s = vec3(0.0864901, 0.0228191, 0.204042);
alpha = vec3(0.000174482, 0.000269795, 0.0015211);
p = vec3(0.373948, 0.362425, 0.563636);
F_0 = vec3(0.0185562, 0.399982, 0.0525861);
F_1 = vec3(-0.0209713, 0.241543, 0.0169474);
K_ap = vec3(4021.24, 2646.36, 346.898);
sh_lambda = vec3(3.38722, 3.62885, 1.83684e-06);
sh_c = vec3(9.64334e-08, 9.96105e-08, 3.61787e-07);
sh_k = vec3(338.073, 272.828, 23.5039);
sh_theta0 = vec3(0.526039, 0.515404, -0.526935);
}
void blue_fabric() {
rho_d = vec3(0.0267828, 0.0281546, 0.066668);
rho_s = vec3(0.0825614, 0.0853369, 0.0495164);
alpha = vec3(0.248706, 0.249248, 0.18736);
p = vec3(9.23066e-13, 1.66486e-12, 2.27218e-12);
F_0 = vec3(0.201626, 0.213723, 0.56548);
F_1 = vec3(0.225891, 0.226267, 0.638493);
K_ap = vec3(5.15615, 5.14773, 6.43713);
sh_lambda = vec3(2.25846, 2.25536, 2.68382);
sh_c = vec3(0.128037, 0.128363, 0.0944915);
sh_k = vec3(6.95531, 6.94633, 8.17665);
sh_theta0 = vec3(0.407528, 0.407534, 0.411378);
}
void blue_metallic_paint2() {
rho_d = vec3(0.010143, 0.0157349, 0.0262717);
rho_s = vec3(0.0795798, 0.0234493, 0.0492337);
alpha = vec3(0.00149045, 0.00110477, 0.00141008);
p = vec3(0.624615, 0.598721, 0.67116);
F_0 = vec3(9.36434e-14, 3.61858e-15, 1.15633e-14);
F_1 = vec3(-0.210234, -1, -1);
K_ap = vec3(314.024, 441.812, 299.726);
sh_lambda = vec3(1.20935e-05, 7.51792e-06, 3.86474e-05);
sh_c = vec3(3.38901e-07, 2.94502e-07, 3.15718e-07);
sh_k = vec3(27.0491, 28.576, 30.6214);
sh_theta0 = vec3(-0.326593, -0.274443, -0.187842);
}
void blue_metallic_paint() {
rho_d = vec3(0.00390446, 0.00337319, 0.00848198);
rho_s = vec3(0.0706771, 0.0415082, 0.104423);
alpha = vec3(0.155564, 0.139, 0.15088);
p = vec3(1.01719, 1.02602, 1.16153);
F_0 = vec3(0.149347, 0.153181, 1.87241e-14);
F_1 = vec3(-0.487331, -0.76557, -1);
K_ap = vec3(4.4222, 4.59265, 3.93929);
sh_lambda = vec3(2.54345, 2.33884, 2.24405);
sh_c = vec3(6.04906e-08, 5.81858e-08, 1.2419e-07);
sh_k = vec3(23.9533, 25.0641, 24.6856);
sh_theta0 = vec3(-0.34053, -0.294595, -0.258117);
}
void blue_rubber() {
rho_d = vec3(0.0371302, 0.0732915, 0.146637);
rho_s = vec3(0.384232, 0.412357, 0.612608);
alpha = vec3(0.218197, 0.2668, 0.478375);
p = vec3(0.815054, 1.00146, 1.24995);
F_0 = vec3(0.0631713, 0.0622636, 0.0399196);
F_1 = vec3(0.0478254, 0.0422186, 0.007015);
K_ap = vec3(4.41586, 3.76795, 3.46276);
sh_lambda = vec3(3.77807, 3.82679, 3.33186);
sh_c = vec3(1.2941e-07, 1.07194e-07, 0.00045665);
sh_k = vec3(19.8046, 19.3115, 11.4364);
sh_theta0 = vec3(-0.499472, -0.557706, -0.172177);
}
void brass() {
rho_d = vec3(0.0301974, 0.0223812, 0.0139381);
rho_s = vec3(0.0557826, 0.0376687, 0.0775998);
alpha = vec3(0.0002028, 0.000258468, 0.00096108);
p = vec3(0.362322, 0.401593, 0.776606);
F_0 = vec3(0.639886, 0.12354, 0.0197853);
F_1 = vec3(-0.360114, -0.87646, -0.0919344);
K_ap = vec3(3517.61, 2612.49, 331.815);
sh_lambda = vec3(3.64061, 2.87206, 0.529487);
sh_c = vec3(1.01146e-07, 9.83073e-08, 5.48819e-08);
sh_k = vec3(312.802, 283.431, 183.091);
sh_theta0 = vec3(0.522711, 0.516719, 0.474834);
}
void cherry_235() {
rho_d = vec3(0.0497502, 0.0211902, 0.0120688);
rho_s = vec3(0.166001, 0.202786, 0.165189);
alpha = vec3(0.0182605, 0.0277997, 0.0255721);
p = vec3(0.0358348, 0.163231, 0.129135);
F_0 = vec3(0.0713408, 0.0571719, 0.0791809);
F_1 = vec3(0.0200814, 0.00887306, 0.0251675);
K_ap = vec3(54.7448, 33.7294, 37.36);
sh_lambda = vec3(6.11314, 6.23697, 6.16351);
sh_c = vec3(30.3886, 0.00191869, 0.0495069);
sh_k = vec3(18.8114, 25.8454, 23.3753);
sh_theta0 = vec3(0.816378, 0.387479, 0.522125);
}
void chrome() {
rho_d = vec3(0.00697189, 0.00655268, 0.0101854);
rho_s = vec3(0.0930656, 0.041946, 0.104558);
alpha = vec3(0.000155335, 0.000156872, 7.39851e-05);
p = vec3(0.353854, 0.3327, 0.300437);
F_0 = vec3(0.256314, 0.819565, 3.22085e-13);
F_1 = vec3(-0.743686, -0.180435, -1);
K_ap = vec3(4642.1, 4726.66, 10421.9);
sh_lambda = vec3(3.8545, 4.44817, 5.40959);
sh_c = vec3(5.30781e-08, 1.04045e-07, 1e10);
sh_k = vec3(354.965, 349.356, 272.736);
sh_theta0 = vec3(0.526796, 0.528469, 1.00293);
}
void chrome_steel() {
rho_d = vec3(0.0206718, 0.0240818, 0.024351);
rho_s = vec3(0.129782, 0.109032, 0.0524555);
alpha = vec3(5.51292e-05, 3.13288e-05, 4.51944e-05);
p = vec3(0.207979, 0.152758, 0.325431);
F_0 = vec3(1.18818e-12, 2.06813e-11, 0.580895);
F_1 = vec3(-0.316807, -0.265326, -0.419105);
K_ap = vec3(15466.8, 28628.9, 16531.2);
sh_lambda = vec3(12.8988, 68.7898, 4.68237);
sh_c = vec3(1e10, 1e10, 44.7025);
sh_k = vec3(197.744, 257.536, 618.155);
sh_theta0 = vec3(1.20035, 1.2003, 0.579562);
}
void colonial_maple_223() {
rho_d = vec3(0.100723, 0.0356306, 0.0162408);
rho_s = vec3(0.059097, 0.0661341, 0.11024);
alpha = vec3(0.0197628, 0.0279336, 0.0621265);
p = vec3(0.0311867, 0.112022, 0.344348);
F_0 = vec3(0.0576683, 0.0617498, 0.0479061);
F_1 = vec3(-0.0503364, -0.0382196, -0.0382636);
K_ap = vec3(50.7952, 34.6835, 14.201);
sh_lambda = vec3(6.03342, 6.01053, 4.56588);
sh_c = vec3(18.9034, 0.087246, 1.03757e-07);
sh_k = vec3(18.3749, 21.6159, 26.9347);
sh_theta0 = vec3(0.801289, 0.544191, -0.139944);
}
void dark_specular_fabric() {
rho_d = vec3(0.0197229, 0.00949167, 0.00798414);
rho_s = vec3(0.556218, 0.401495, 0.378651);
alpha = vec3(0.140344, 0.106541, 0.166715);
p = vec3(0.249059, 0.177611, 0.434167);
F_0 = vec3(0.0351133, 0.0387177, 0.0370533);
F_1 = vec3(0.0243153, 0.0293178, 0.0264913);
K_ap = vec3(7.60492, 9.81673, 6.19307);
sh_lambda = vec3(3.93869, 4.23097, 4.3775);
sh_c = vec3(0.00122421, 0.00238545, 8.47126e-06);
sh_k = vec3(13.889, 14.5743, 17.2049);
sh_theta0 = vec3(0.114655, 0.210179, -0.227628);
}
void fruitwood_241() {
rho_d = vec3(0.0580445, 0.0428667, 0.0259801);
rho_s = vec3(0.203894, 0.233494, 0.263882);
alpha = vec3(0.00824986, 0.0534794, 0.0472951);
p = vec3(0.160382, 1.07206, 0.768335);
F_0 = vec3(0.00129482, 0.00689891, 0.01274);
F_1 = vec3(-0.0211778, -0.0140791, -0.00665974);
K_ap = vec3(110.054, 6.98485, 11.6203);
sh_lambda = vec3(6.74678, 1.31986, 1.76021);
sh_c = vec3(162.121, 1.18843e-07, 1.0331e-07);
sh_k = vec3(32.6966, 36.752, 34.371);
sh_theta0 = vec3(0.765181, 0.0514459, 0.0106852);
}
void gold_paint() {
rho_d = vec3(0.147708, 0.0806975, 0.033172);
rho_s = vec3(0.160592, 0.217282, 0.236425);
alpha = vec3(0.122506, 0.108069, 0.12187);
p = vec3(0.795078, 0.637578, 0.936117);
F_0 = vec3(9.16095e-12, 1.81225e-12, 0.0024589);
F_1 = vec3(-0.596835, -0.331147, -0.140729);
K_ap = vec3(5.98176, 7.35539, 5.29722);
sh_lambda = vec3(2.64832, 3.04253, 2.3013);
sh_c = vec3(9.3111e-08, 8.80143e-08, 9.65288e-08);
sh_k = vec3(24.3593, 24.4037, 25.3623);
sh_theta0 = vec3(-0.284195, -0.277297, -0.245352);
}
void green_fabric() {
rho_d = vec3(0.0511324, 0.0490447, 0.0577457);
rho_s = vec3(0.043898, 0.108081, 0.118528);
alpha = vec3(0.0906425, 0.14646, 0.125546);
p = vec3(0.199121, 0.21946, 0.130311);
F_0 = vec3(0.117671, 0.0797822, 0.0840896);
F_1 = vec3(0.107501, 0.0628391, 0.0668466);
K_ap = vec3(11.1681, 7.43507, 8.69777);
sh_lambda = vec3(4.65909, 3.72793, 3.72472);
sh_c = vec3(0.00055264, 0.00331292, 0.0119365);
sh_k = vec3(16.8276, 12.7802, 12.1538);
sh_theta0 = vec3(0.153958, 0.17378, 0.291679);
}
void green_latex() {
rho_d = vec3(0.0885476, 0.13061, 0.0637004);
rho_s = vec3(0.177041, 0.16009, 0.101365);
alpha = vec3(0.241826, 0.21913, 0.2567);
p = vec3(0.175925, 0.162514, 0.326958);
F_0 = vec3(0.0213854, 0.0498004, 0.0677643);
F_1 = vec3(-0.0864353, -0.0518848, -0.00668045);
K_ap = vec3(5.17117, 5.55867, 4.84094);
sh_lambda = vec3(2.61304, 2.75985, 2.84236);
sh_c = vec3(0.0417628, 0.0352726, 0.0128547);
sh_k = vec3(8.4496, 8.91691, 9.57998);
sh_theta0 = vec3(0.296393, 0.295144, 0.18077);
}
void ipswich_pine_221() {
rho_d = vec3(0.0560746, 0.0222518, 0.0105117);
rho_s = vec3(0.0991995, 0.106719, 0.110343);
alpha = vec3(0.014258, 0.0178759, 0.0188163);
p = vec3(0.0625943, 0.113994, 0.118296);
F_0 = vec3(1.55288e-13, 6.595e-12, 3.97788e-13);
F_1 = vec3(-0.0675784, -0.0696373, -0.0703103);
K_ap = vec3(68.7248, 53.3521, 50.6148);
sh_lambda = vec3(6.36482, 6.37738, 6.35839);
sh_c = vec3(111.962, 1.68378, 0.850892);
sh_k = vec3(20.956, 23.9475, 24.0837);
sh_theta0 = vec3(0.842456, 0.66795, 0.641354);
}
void light_brown_fabric() {
rho_d = vec3(0.0612259, 0.0263619, 0.0187761);
rho_s = vec3(3.65487e-12, 9.7449e-12, 4.13685e-12);
alpha = vec3(0.147778, 0.137639, 0.13071);
p = vec3(0.188292, 0.188374, 0.189026);
F_0 = vec3(1, 1, 1);
F_1 = vec3(0, 0, 0);
K_ap = vec3(7.46192, 7.90085, 8.23842);
sh_lambda = vec3(3.59765, 3.74493, 3.85476);
sh_c = vec3(0.00660661, 0.0049581, 0.00395337);
sh_k = vec3(12.0657, 12.6487, 13.0977);
sh_theta0 = vec3(0.221546, 0.213332, 0.206743);
}
void neoprene_rubber() {
rho_d = vec3(0.259523, 0.220477, 0.184871);
rho_s = vec3(0.275058, 0.391429, 0.0753145);
alpha = vec3(0.143818, 0.207586, 0.0764912);
p = vec3(0.770284, 0.774203, 0.700644);
F_0 = vec3(0.113041, 0.110436, 0.16895);
F_1 = vec3(0.060346, 0.0565499, 0.0788468);
K_ap = vec3(5.56845, 4.61088, 8.84784);
sh_lambda = vec3(3.02411, 3.82334, 2.38942);
sh_c = vec3(5.3042e-08, 1.01087e-07, 6.70643e-08);
sh_k = vec3(23.2109, 20.1103, 28.3099);
sh_theta0 = vec3(-0.379072, -0.500903, -0.156114);
}

void pickled_oak_260() {
rho_d = vec3(0.181735, 0.14142, 0.125486);
rho_s = vec3(0.0283411, 0.0296418, 0.025815);
alpha = vec3(0.0105853, 0.0102771, 0.0101188);
p = vec3(2.31337e-14, 2.35272e-14, 1.99762e-14);
F_0 = vec3(5.38184e-13, 2.15933e-13, 3.55496e-12);
F_1 = vec3(-0.309259, -0.291046, -0.329625);
K_ap = vec3(95.4759, 98.3089, 99.831);
sh_lambda = vec3(6.37433, 6.39032, 6.39857);
sh_c = vec3(4641.15, 5970.15, 6818.76);
sh_k = vec3(18.1707, 18.2121, 18.2334);
sh_theta0 = vec3(1.00563, 1.01274, 1.01645);
}
void red_fabric2() {
rho_d = vec3(0.155216, 0.0226757, 0.0116884);
rho_s = vec3(1.80657e-15, 5.51946e-13, 1.35221e-15);
alpha = vec3(0.16689, 0.135884, 0.128307);
p = vec3(0.184631, 0.18856, 0.1883);
F_0 = vec3(1, 1, 1);
F_1 = vec3(0, 0, 0);
K_ap = vec3(6.78759, 7.98303, 8.36701);
sh_lambda = vec3(3.33819, 3.77225, 3.89063);
sh_c = vec3(0.0112096, 0.00468671, 0.00372538);
sh_k = vec3(11.0557, 12.7596, 13.2393);
sh_theta0 = vec3(0.240935, 0.21164, 0.206003);
}
void red_fabric() {
rho_d = vec3(0.201899, 0.0279008, 0.0103965);
rho_s = vec3(0.168669, 0.0486346, 0.040485);
alpha = vec3(0.324447, 0.228455, 0.109436);
p = vec3(0.787411, 0.821197, 0.279212);
F_0 = vec3(0.0718348, 0.0644687, 0.0206123);
F_1 = vec3(-0.0585917, -0.0062547, -0.050402);
K_ap = vec3(3.88129, 4.32067, 9.16355);
sh_lambda = vec3(3.59825, 3.93046, 4.66379);
sh_c = vec3(0.000130047, 1.04152e-07, 4.59182e-05);
sh_k = vec3(13.0776, 19.649, 17.8852);
sh_theta0 = vec3(-0.209387, -0.530789, -0.0242035);
}
void red_metallic_paint() {
rho_d = vec3(0.0380897, 0.00540095, 0.00281156);
rho_s = vec3(0.0416724, 0.07642, 0.108438);
alpha = vec3(0.00133258, 0.00106883, 0.00128863);
p = vec3(0.693854, 0.52857, 0.539477);
F_0 = vec3(2.45718e-16, 0.0598671, 0.0633332);
F_1 = vec3(-1, -0.08904, -0.0114056);
K_ap = vec3(300.371, 521.418, 425.982);
sh_lambda = vec3(6.45857e-05, 6.3446e-07, 8.51754e-07);
sh_c = vec3(2.75773e-07, 4.05125e-07, 3.41703e-07);
sh_k = vec3(33.0213, 24.3646, 23.5793);
sh_theta0 = vec3(-0.121415, -0.469753, -0.532083);
}

void silver_metallic_paint2() {
rho_d = vec3(0.0554792, 0.0573803, 0.0563376);
rho_s = vec3(0.121338, 0.115673, 0.10966);
alpha = vec3(0.029859, 0.0303706, 0.0358666);
p = vec3(0.144097, 0.104489, 0.158163);
F_0 = vec3(1.03749e-14, 3.52034e-15, 4.41778e-12);
F_1 = vec3(-1, -1, -1);
K_ap = vec3(31.9005, 32.1514, 26.5685);
sh_lambda = vec3(6.08248, 5.89319, 5.95156);
sh_c = vec3(0.00761403, 0.0839948, 0.00138703);
sh_k = vec3(23.5891, 20.6786, 23.3297);
sh_theta0 = vec3(0.435405, 0.54017, 0.34665);
}
void silver_metallic_paint() {
rho_d = vec3(0.0189497, 0.0205686, 0.0228822);
rho_s = vec3(0.173533, 0.168901, 0.165266);
alpha = vec3(0.037822, 0.038145, 0.0381908);
p = vec3(0.165579, 0.162955, 0.160835);
F_0 = vec3(5.66903e-12, 1.65276e-14, 4.28399e-14);
F_1 = vec3(-1, -1, -1);
K_ap = vec3(25.1551, 24.9957, 25.0003);
sh_lambda = vec3(5.92591, 5.90225, 5.89007);
sh_c = vec3(0.000684235, 0.000840795, 0.000995926);
sh_k = vec3(23.4725, 23.1898, 23.0144);
sh_theta0 = vec3(0.310575, 0.317996, 0.324938);
}
void silver_paint() {
rho_d = vec3(0.152796, 0.124616, 0.113375);
rho_s = vec3(0.30418, 0.30146, 0.283174);
alpha = vec3(0.110819, 0.105318, 0.0785677);
p = vec3(0.640378, 0.641115, 0.445228);
F_0 = vec3(2.37347e-13, 7.68194e-13, 2.9434e-12);
F_1 = vec3(-0.350607, -0.355433, -0.359297);
K_ap = vec3(7.21531, 7.46519, 10.8289);
sh_lambda = vec3(3.06016, 2.97652, 3.78287);
sh_c = vec3(9.71666e-08, 1.09342e-07, 9.82336e-08);
sh_k = vec3(24.1475, 24.5083, 25.6757);
sh_theta0 = vec3(-0.281384, -0.257633, -0.200968);
}
void special_walnut_224() {
rho_d = vec3(0.0121712, 0.00732998, 0.00463072);
rho_s = vec3(0.209603, 0.216118, 0.211885);
alpha = vec3(0.117091, 0.119932, 0.131119);
p = vec3(0.548899, 0.524858, 0.569425);
F_0 = vec3(0.0808859, 0.0802614, 0.0789982);
F_1 = vec3(0.0327605, 0.0324012, 0.0274637);
K_ap = vec3(7.42314, 7.41578, 6.77215);
sh_lambda = vec3(3.61532, 3.82778, 3.71096);
sh_c = vec3(1.19182e-07, 1.03098e-07, 1.08004e-07);
sh_k = vec3(22.9756, 22.7318, 22.2976);
sh_theta0 = vec3(-0.31158, -0.332257, -0.35462);
}

vec3 Fresnel(vec3 F0, vec3 F1, float V_H)
{
	return F0 - V_H * F1  + (1. - F0)*pow(1. - V_H, 5.);
}

vec3 D(vec3 _alpha, vec3 _p, float cos_h, vec3 _K)
{
	float cos2 = cos_h*cos_h;
	float tan2 = (1.-cos2)/cos2;
	vec3 ax = _alpha + tan2/_alpha;
	
	ax = max(ax,0.); //bug?
	
	return one_pi * _K * exp(-ax)/(pow(ax,_p) * cos2 * cos2);
	// return vec3( 0.0 / (cos2 * cos2));
}

vec3 G1(float theta)
{
	theta = clamp(theta,-1.,1.); //bug?
	return 1.0 + sh_lambda * (1. - exp(sh_c * pow(max(acos(theta) - sh_theta0,0.), sh_k)));
}

vec3 shade(float inLight, float n_h, float n_l, float n_v, float v_h, vec3 dif_tex)
{
  	return  one_pi * inLight * ( n_l * rho_d * dif_tex	
	+ rho_s * D(alpha, p, n_h, K_ap) * G1(n_l) * G1 (n_v) * Fresnel(F_0, F_1, v_h));
}

vec3 brdf(vec3 lv, vec3 ev, vec3 n, vec3 dif_tex)
{
	vec3 halfVector = normalize(lv + ev);
	
	float v_h = dot(ev, halfVector);
	float n_h = dot(n, halfVector);
	float n_l = dot(n, lv); 
	float inLight = 1.0;
	if (n_l < 0.) inLight = 0.0;
	float n_v = dot(n, ev); 
	
	vec3 sh = shade(inLight, n_h, n_l, n_v, v_h, dif_tex);
	sh = clamp( sh, 0., 1.); //bug?
	vec3 retColor = lightIntensity * sh;
		
	
	return retColor;
}


int ChooseMat(vec3 X)
{
//	int i = int( floor(X.x*0.25) );

//	i = int(mod(float(i),100.0));
	
	if (X.y < ground_height*0.99) green_latex();
	else if (Pole(X)<.05) gold_paint();
	else if (X.y > 7. || Roof(X)<0.1) red_fabric();
		//alumina_oxide();
	else	beige_fabric();
		//red_fabric();
		//white_marble();
		//alum_bronze();
		//colonial_maple_223();
	//gold_paint();
	return 0;
}

//thanks again IQ https://iquilezles.org/articles/rmshadows
float shadow( in vec3 X, in vec3 n, in vec3 L )
{
	float mint = 0.001;
	float maxt = 20.0;
	
	X += n*.01;
	
	float h=0.4;
	float sharpness = 25.;
	float soft=1.0;
	float t = mint;
	for (int i=0; i<32; i++)
    {
        float d = sdf(X + L*t, bvec4(1,1,1,1));
        if( d<-0.1 )
            return h; //t*h;
		
		soft = min( soft, (sharpness*d)*(1./t));
		
		if (t > maxt) break;
        t += d * 0.9;
    }
    return clamp(soft,h,1.0);
}


float Ao(vec3 p, vec3 n, float d) {
	float vis = 0.0;
	float w= 1.;
	for (int i=0; i<10; i++)
	{
		float d = sdf(p, bvec4(1,1,1,1));
		//this made more sense to me as volume of sphere that is clear of stuff blocking light ??
		vis += d; //* (4.*pi/3.);	
		
	//	vis+=d*w;
	//	w *= 0.5;
		p += n * d * 0.9;
	}
	vis*=.1;
	return pow(clamp(vis,0.,1.),1.0);
}


void MakeViewRay(out vec3 viewP, out vec3 viewD, vec2 fragCoord)
{
	vec2 xy = fragCoord.xy;
	xy.y=iResolution.y-fragCoord.y;
	vec2 filmUv = (xy + vec2(0.5,0.5))/iResolution.xy;

	float tx = (2.0*filmUv.x - 1.0)*(iResolution.x/iResolution.y);
	float ty = (1.0 - 2.0*filmUv.y);
	float tz = 0.0;

	viewP = vec3(0.0, 0.0, 5.0);
	viewD = vec3(tx, ty, tz) - viewP;	
	
	viewD = normalize(viewD);

	float t = iTime*0.2-pi*0.4;
//	float t = pi*0.5;
	viewD=RotX(viewD,pi*0.25); //2+sin(iTime)*0.2);
	
	viewP.y += 24.0;
	viewP.z += 20.0;
	
//	viewP.y += sin(iTime)*8.;
	
	viewP.yz -= cos(iTime*0.3)*12.;
//	viewP.yz += 8.;
		
	viewP = RotY(viewP,t);
	
	viewD = RotY(viewD,t);

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec3 viewP, viewD;
	MakeViewRay(viewP, viewD,fragCoord);
	
	float d;

	float t = 0.;
	
		
	vec3 neighViewD = dFdy(viewD)+viewD;	
		
	bool fail=true;
	
	float glo=0.;

				//castle	//walls,	gate, 	keep
	vec4 pos_x =  vec4(0.,	0.,			-6.75, 	6. );
	vec4 pos_y =  vec4(0.,	0.,			-3., 	-3. );
	vec4 pos_z =  vec4(0.,	0.,			0., 	0. );
	vec4 edge_x = vec4(17.,	17.,		4., 	8. );
	vec4 edge_y = vec4(18.,	6., 		8., 	8. );
	vec4 edge_z = vec4(20.,	20.,		8., 	8. );
	
//	vec4 box_t;
	bvec4 sdf_bound_test =bvec4(1);
//		RayVs4Boxes(viewP, viewD, pos_x, pos_y, pos_z,
//				  edge_x, edge_y, edge_z,			  box_t);
				  
//	if (sdf_bound_test.x) t = box_t.x;
	
	//save some iters on zoomed out views
//	if (RayBox( viewP, viewD, vec3(0.,0.,0), vec3(17.,18.,20.),t))
	{
		for (int i=0; i<64; i++)
		{
			vec3 X = viewP + viewD * t;
			d = sdf(X,sdf_bound_test);
			
	
			vec3 nX = viewP + neighViewD*t;
			float r = length(X-nX);				
			if (abs(d) < r*(0.25)){
				fail = false; break; //less sparkly crap on silhouette edges?
			}
			
	//		if (abs(d) < 0.00001) break; //near enough surface for normals to look OK.
		
	#if 1	
			if (t>100.) //too far - won't converge: just go to ground plane.
			{
	//			fail=1.;
	//			t = floor_intersect_t;
				break;
			}
	#endif		
			t += d; //*0.9; //bounding volumes make the distance a bit wrong so slow down
			
			glo += 1.;
		}
	}
	
	float floor_intersect_t = (-viewP.y + floor_height) / (viewD.y);
	if (fail)
	{
		t = floor_intersect_t;
	}
	vec3 X = viewP + viewD * t;
	vec3 n = nor(X);
	
	vec3 lightDir = normalize(vec3(3,8,5));

#if 1	
	float ao = Ao(X+n*0.03, normalize(n), sdf(n*0.03+X,bvec4(1.,1.,1.,1)));	
	lightIntensity *= ao * 2.;
#endif
	
#if 1	
	float sha = shadow(X,n,lightDir);
	lightIntensity *= sha;
#endif
	
	ChooseMat(X);
		
	vec3 tex = Tex(X);
#if 0	
	if (Tower(X)>0.1)
	{
		tex = vec3(tex.x);
	}
#endif	
	tex.x = pow(tex.x,gamma);
	tex.y = pow(tex.y,gamma);
	tex.z = pow(tex.z,gamma);
	
	vec3 c = brdf(lightDir, -viewD, n, tex);
//	vec3 c = ao*sha*max(dot(n,lightDir),0.)*tex;
			
	lightIntensity = ao*10.;
	c += brdf(-lightDir, -viewD, n, tex)*vec3(0.9,0.9,1.);
		
	c += texture(iChannel2,reflect(viewD,n)).xyz*(1.-ao)*.05;
	
#if 0	
	glo /= 64.;
	c = vec3(glo);
	if (glo < 0.5) c.x = 0.;
	if (glo < 0.25) c.y = 0.;
	if (glo < 0.125) c.z = 0.;
#endif
	
	c = pow(c, vec3(1./gamma));
//	c = vec3(ao);
	fragColor = vec4(c,1.0);
}
