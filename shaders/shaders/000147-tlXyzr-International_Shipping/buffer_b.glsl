// Buffer B (buffer) — International Shipping by blackle
// https://www.shadertoy.com/view/tlXyzr

//original International Shipping shader. not much different here.
//it waits until the wave heightmap is done calculating (WAVE_DEPTH frames, see Common) before doing multisampling.

#define MAXDEPTH 4

float maxdist = 100.0;
vec3 suncol = vec3(1.5,1.0,0.6);
vec3 skycol = vec3(0.4,0.75,1.0);
vec3 sundir = normalize(vec3(-1.0,-1.0,0.1));

uint rand = 0u;
void stepState()
{
	rand = rand ^ (rand << 13u);
	rand = rand ^ (rand >> 17u);
	rand = rand ^ (rand << 5u);
	rand *= 1685821657u;
}

void feed(float value)
{
	rand += floatBitsToUint(value);
	stepState();
}

float getFloat() {
	stepState();
	return uintBitsToFloat( (rand & 0x007FFFFFu) | 0x3F800000u ) - 1.5;
}

vec3 getVec3() {
	return vec3(getFloat(),getFloat(),getFloat());
}

struct Ray
{
	vec3 m_origin;
	vec3 m_direction;
	vec3 m_point;
	int m_intersected;
	vec3 m_color;
	vec3 m_attenuation;
};

Ray newRay(vec3 origin, vec3 direction, vec3 attenuation) {
	// Create a default ray
	return Ray(origin, direction, origin, 0, vec3(0.0), attenuation);
}

//https://iquilezles.org/articles/distfunctions
float dot2( in vec3 v ) { return dot(v,v); }
float udTriangle( vec3 p, vec3 a, vec3 b, vec3 c )
{
	vec3 cb = c - b; vec3 pb = p - b;
	vec3 ba = b - a; vec3 pa = p - a;
	vec3 ac = a - c; vec3 pc = p - c;
	vec3 nor = cross( ba, ac );

	return sqrt(
	(sign(dot(cross(ba,nor),pa)) +
	 sign(dot(cross(cb,nor),pb)) +
	 sign(dot(cross(ac,nor),pc))<2.0)
	 ?
	 min( min(
	 dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
	 dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
	 dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
	 :
	 dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}


float scene(vec3 p) {
	vec3 point = vec3(abs(p.xy), p.z+0.04);
	if (length(point)>0.8) return 0.8;
	float scale = 3.5;
	point *= scale;
	point += sin(point.yzx*6.0)*0.005;

	// return bottle(p4b);
	vec3 mast = vec3(0.03, 0.0, 1.8);
	vec3 keel = vec3(0.0, 0.3, 0.0);
	vec3 port = vec3(0.0, 0.9, 0.7);
	vec3 port_bow = vec3(1.0, 0.0, 0.0);
	vec3 bow = vec3(1.9, 0.0, 1.2);
	vec3 mid = vec3(0.02, 0.5, 0.4);

	float tri1 = udTriangle(point, mast, mid, port_bow);
	float tri2 = udTriangle(point, port, keel, port_bow);
	float tri3 = udTriangle(point, port, bow, port_bow);

	return (min(min(tri2, tri3),tri1)-0.01+cos(p.x*8.0)*.005)/scale;
}

float wake(vec2 uv) {
	vec2 uvm = vec2(uv.x,sqrt(uv.y*uv.y+0.0004));
	vec2 wakeangle = normalize(vec2(1.0));
	vec2 wakeangleflipped = vec2(wakeangle.y,-wakeangle.x);

	float wakeangledot = dot(uvm,wakeangle);
	float wakeangleflippeddot = dot(uvm,wakeangleflipped);


	float xwiggly = sqrt(1.0-8.0*wakeangledot/(1.0+8.0*abs(wakeangledot)));

	float distance = xwiggly*(wakeangledot > 0.0 ? abs(wakeangleflippeddot) : length(uvm));
	return sign(wakeangleflippeddot)*sin(distance*120.0)*exp(-distance*20.0-wakeangledot*5.0);
}

float heightmap(vec2 uv) {
	float height = texture(iChannel0, uv*0.15).x*0.04+0.01;
	return height - (wake(vec2(0.28,0.0)-uv)+wake(-uv)+0.1*wake(vec2(-0.3,0.0)-uv))*0.025;
}

vec2 epsi = vec2(0.0005, 0.0);
vec3 heightmapNormal(vec2 uv) {
	float xdiff = heightmap(uv) - heightmap(uv+epsi.xy);
	float ydiff = heightmap(uv) - heightmap(uv+epsi.yx);
	return normalize(cross(vec3(epsi.yx, -xdiff), vec3(epsi.xy, -ydiff)));
}

vec3 sceneGrad(vec3 point) {
  float t = scene(point);
  return normalize(vec3(
    t - scene(point + epsi.xyy),
    t - scene(point + epsi.yxy),
    t - scene(point + epsi.yyx)));
}

void castRay(inout Ray ray) {
	// Cast ray from origin into scene
	float dt = 0.008;
	float lastdiff = 0.0;
	for (int i = 0; i < 200; i++) {
		if (length(ray.m_origin - ray.m_point) > maxdist) return;
		if (ray.m_point.z > 0.1 && ray.m_point.y + ray.m_point.x < -0.5 && ray.m_direction.z > 0.0) return;
		float dist2scene = scene(ray.m_point);
		float diff = ray.m_point.z - heightmap(ray.m_point.xy);

		if (abs(dist2scene) < epsi.x) {
			ray.m_intersected = 2;
			return;
		}

		if (diff < 0.0) {
			ray.m_point -= dt * diff / (diff - lastdiff) * ray.m_direction;
			ray.m_intersected = 1;
			return;
		}

		dt = dt*1.02;
		ray.m_point += min(dt*max(diff*(1.0-abs(ray.m_direction.z)+max(ray.m_direction.z,0.0)*30.0)*80.0,1.0),dist2scene) * ray.m_direction;
		lastdiff = diff;
	}
}

//this is trash and needs to be better
vec3 skyDomeShade(vec3 angle) {
	return mix(vec3(1.71, 1.31, 0.83),skycol, pow(abs(angle.z), 0.5)) + pow(max(dot(angle, sundir),0.0),1500.0)*suncol*4.0;
}

Ray reflectionForRay(Ray ray, float fade) {
	vec3 normal = -heightmapNormal(ray.m_point.xy);
	float frensel = abs(dot(ray.m_direction, normal));
	vec3 atten = fade * ray.m_attenuation * 0.9 * (1.0 - frensel*0.98);
	vec3 reflected = reflect(ray.m_direction, normal);

	return newRay(ray.m_point + normal*0.01, reflected, atten);
}

void shadeBoat(inout Ray ray) {
	//this code is super spaghetti and I'm so fucking sorry
	vec3 normal = -sceneGrad(ray.m_point);
	float frensel = abs(dot(ray.m_direction, normal));
	float nearness = abs(ray.m_point.z);
	nearness = sqrt(min(nearness*6.0+.1,1.0));
	vec3 reflected_sun = reflect(sundir, normal);
	vec3 reflected_sky = reflect(vec3(0.0,0.0,1.0), normal);
	float specular_sun = pow(max(dot(ray.m_direction, reflected_sun),0.0), 20.0) * (1.0-frensel*0.98);
	float specular_sky = pow(max(dot(ray.m_direction, reflected_sky)+0.75,0.0)/1.75, 2.0) * (1.0-frensel*0.98);

	float ao = mix(1.0,scene(ray.m_point + normal*0.1)/0.1,0.3);

	float shitty_shadow_approximation = scene(ray.m_point + sundir*0.1) < scene(ray.m_point + sundir*0.2) ? 1.0 : 0.0;

#ifdef FINLANDSFARJAN
    vec2 crds = vec2(-abs(ray.m_point.x), ray.m_point.z);
	bool mst = sin(dot(crds,vec2(.5,2))*20.+.5) > 0.;
	vec3 diffusecol = mst ? vec3(0.9) : vec3(0.9, 0.05, 0.01);
#else
    vec3 diffusecol = vec3(.8,.3,.1);
#endif
	float sundot = dot(normal, sundir);
	sundot = max(sundot, 0.0) + frensel*0.0;
	ray.m_color += ao * (sundot*suncol*diffusecol + (1.0+normal.z)/2.0 * mix(suncol,skycol,0.6) * diffusecol ) * nearness + shitty_shadow_approximation*specular_sun*suncol + specular_sky * skycol * nearness + skycol*0.02;
}

Ray rayQueue[MAXDEPTH];
int raynum = 1;
void addToQueue(Ray ray) {
	if (raynum >= MAXDEPTH) return;
	rayQueue[raynum] = ray;
	raynum++;
}

void recursivelyRender(inout Ray ray) {
	//jump close to surface of water
	//this was useful in the demo to only jump if not in the middle of the frame but here it makes no sense
	float t = -(dot(ray.m_point, vec3(0.0,0.0,1.0)) - 0.08)/dot(ray.m_direction, vec3(0.0,0.0,1.0));
	//except near boat
	ray.m_point += ray.m_direction*t*0.5;
	rayQueue[0] = ray;

	for (int i = 0; i < MAXDEPTH; i++) {
		if (i >= raynum) break;

		castRay(rayQueue[i]);
		//shading...
		float fading = (rayQueue[i].m_intersected > 0) ? pow(max(maxdist - distance(rayQueue[i].m_origin, rayQueue[i].m_point), 0.0)/maxdist, 2.0) : 0.0;
		rayQueue[i].m_color = (1.0-fading)*skyDomeShade(rayQueue[i].m_direction);
		//reflection
		if (rayQueue[i].m_intersected == 1) {
			addToQueue(reflectionForRay(rayQueue[i], fading));
		} else if (rayQueue[i].m_intersected == 2) {
			shadeBoat(rayQueue[i]);
		}
	}
	for (int i = 0; i < raynum; i++) {
		ray.m_color += rayQueue[i].m_color * rayQueue[i].m_attenuation;
	}
	raynum = 1;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(ax,p)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);

	vec2 uv_base = (fragCoord/iResolution.xy*2.0-1.0)/2.0;
	uv_base.x *= iResolution.x/iResolution.y;

	feed(uv_base.x);
	feed(uv_base.y);
    feed(float(iFrame));

	// Camera parameters

	vec2 uv = uv_base + getVec3().xy/500.0;
	vec3 cameraOrigin = vec3(3.5, 3.5, heightmap(vec2(3.5, 3.5))+1.5) + normalize(getVec3())*0.04;
	vec3 focusOrigin = vec3(0.0, 0.0, 0.15);
	vec3 cameraDirection = normalize(focusOrigin-cameraOrigin);

    vec3 up = vec3(0.0,0.0,-1.0);
	vec3 plateXAxis = normalize(cross(cameraDirection, up));
	vec3 plateYAxis = normalize(cross(cameraDirection, plateXAxis));

	vec3 platePoint = (plateXAxis * -uv.x + plateYAxis * uv.y) * 0.3;

	Ray ray = newRay(cameraOrigin, normalize(platePoint + cameraDirection), vec3(1.0));
	recursivelyRender(ray);

    //skip multisampling while wave heightmap is being computed
    if (iFrame < WAVE_DEPTH) {
		fragColor = vec4(0);
    }
    fragColor += vec4(ray.m_color, 1);
}

