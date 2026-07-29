// Buf A (buffer) — Rocket City by eiffie
// https://www.shadertoy.com/view/lsd3Dl

//now with autopilot, thanks Fabrice!
//#define USE_AUTO_PILOT

#define THRUST 0.04*iTimeDelta
#define ROLL 1.0*iTimeDelta
#define ROTATE 4.0*iTimeDelta
#define TOO_CLOSE 0.01

#define LEFT_ARROW 37
#define UP_ARROW 38
#define RIGHT_ARROW 39
#define DOWN_ARROW 40

//originally from iq but messed up by me
float isInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }

vec4 load(in int re) {
    return texture(iChannel0, (0.5+vec2(re,0.0)) / iChannelResolution[0].xy, -100.0 );
}

void store( in int re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord) {
    fragColor = ( isInside(fragCoord,vec2(re,0.0)) > 0.0 ) ? va : fragColor;
}

bool KeyDown(in int key){return (texture(iChannel1,vec2((float(key)+0.5)/256.0, 0.25)).x>0.0);}

//some quaterion math just to be different
#define quat vec4
quat qid(){return quat(0.0,0.0,0.0,1.0);}
quat qmulq(quat q1, quat q2){//multiply two quats
	return quat(q1.xyz*q2.w+q2.xyz*q1.w+cross(q1.xyz,q2.xyz),(q1.w*q2.w)-dot(q1.xyz,q2.xyz));
}
quat aa2q(vec3 axis, float angle){return quat(normalize(axis)*sin(angle*0.5),cos(angle*0.5));}
quat qinv(quat q){return quat(-q.xyz,q.w)/dot(q,q);}//inverse quaternion
vec3 qmulv(quat q, vec3 p){return qmulq(q,qmulq(quat(p,0.0),qinv(q))).xyz;}//rotate a vector
quat qpyr(vec3 o){ o*=0.5; vec3 s=sin(o),c=cos(o); //rotate pitch,yaw,roll in that order
	return quat(s.x*c.y*c.z+s.y*c.x*s.z, s.y*c.x*c.z-s.x*c.y*s.z, s.x*s.y*c.z+s.z*c.x*c.y, c.x*c.y*c.z-s.x*s.y*s.z);
}

/*//extras
quat q2aa(quat q){return quat(q.xyz/sqrt(1.0-q.w*q.w),acos(q.w)*2.0);}//assumed q is normalized coverts to axis&angle
quat qlookat(vec3 v){return aa2q(vec3(-v.y,v.x,0.0),acos(v.z/length(v)));}//point in direction v
vec3 vmulq(vec3 p, quat q){return qmulq(qinv(q),qmulq(quat(p,0.0),q)).xyz;}//inverse rotation
quat qslerp(quat q1, quat q2, float f){
	float d=dot(q1,q2),theta=acos(abs(d)),ost=(1.0/sin(theta)); 
	return normalize(q1*sin(theta*(1.0-f))*ost*sign(d)+q2*sin(theta*f)*ost); 
}
*/

//repeated code...
vec3 Tile(vec3 p){vec3 a=vec3(8.0);return abs(mod(p,a)-a*0.5)-a*0.25;}
float DERect(vec4 z,vec3 r){return length(max(abs(z.xyz)-r,0.0))/z.w;}
const float mr=0.5, mxr=0.975, scale = 2.52;
const vec3 rc=vec3(3.31,2.79,4.11),rcL=vec3(2.24,1.88,2.84);
const vec4 p0=vec4(4.0,0.0,-4.0,1.0);

float DE(in vec3 p){//for collision detection
	p=Tile(p);
	vec4 z = vec4(p,1.0);
	float dG=1000.0;
	for (int n = 0; n<5; n++) {
		z.xyz=clamp(z.xyz, -1.0, 1.0) *2.0-z.xyz;
		z*=scale/clamp(max(dot(z.xy,z.xy),max(dot(z.xz,z.xz),dot(z.yz,z.yz))),mr,mxr);
		z+=p0;
		if(n==2){dG=DERect(z,rcL);}
	}
	float ds=DERect(z,rc);
	return min(dG,ds)-0.005;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if(fragCoord.y>0.5 || fragCoord.x>1.5)discard;
	vec4 pos;
	quat qrot;
	if(iFrame<2){
		pos=vec4(0.1,0.0,0.0,0.01);
		qrot=normalize(vec4(0.1,0.2,0.3,0.8));
	}else{
		pos=load(0);
		qrot=load(1);
		vec3 fw=vec3(0.0,0.0,1.0);
		fw=qmulv(qrot,fw);
		vec3 newp=pos.xyz+fw*pos.w;
		if(DE(newp)>TOO_CLOSE)pos.xyz=newp;
		else{//per Dave kinda
			if(DE(vec3(pos.xy,newp.z))>TOO_CLOSE){pos.z=newp.z;}
			if(DE(vec3(pos.x,newp.y,pos.z))>TOO_CLOSE){pos.y=newp.y;} 
			if(DE(vec3(newp.x,pos.yz))>TOO_CLOSE){pos.x=newp.x;}
		}
		if(KeyDown(UP_ARROW))pos.w+=THRUST;
		if(KeyDown(DOWN_ARROW))pos.w-=THRUST;
		float roll=0.0;
		if(KeyDown(LEFT_ARROW))roll-=ROLL;
		if(KeyDown(RIGHT_ARROW))roll+=ROLL;
		vec2 mous=vec2(0.0);
		if(iMouse.z>0.0){
			mous.xy=(iMouse.xy-iMouse.zw)/iResolution.xy;
		}
#ifdef USE_AUTO_PILOT
        else{//I'm pretty sure this is how google cars steer
			float d=DE(pos.xyz);
			newp=qmulv(qrot,vec3(d,0.0,0.0));
			float d2=DE(pos.xyz+newp);
			mous.x=sign(d2-d)*ROTATE/(0.1+2.0*d*d);
		}
#endif
        quat qp=qpyr(vec3(-mous.y*ROTATE,mous.x*ROTATE,roll));//finally did the math!!
		//quat qp=aa2q(vec3(1.0,0.0,0.0),-mous.y*ROTATE);//pitch,yaw,roll rotations
		//quat qy=aa2q(vec3(0.0,1.0,0.0),mous.x*ROTATE);//there must be a way to
		//quat qr=aa2q(vec3(0.0,0.0,1.0),roll);		//cram these into a quat at once?
		//qrot=qmulq(qrot,qp);
		//qrot=qmulq(qrot,qy);
		qrot=normalize(qmulq(qrot,qp));//normalize before saving
	}
	store(0,pos,fragColor,fragCoord);//position,velocity
	store(1,qrot,fragColor,fragCoord);//rotation
}