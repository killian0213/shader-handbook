// Image (image) — Aurora Explorer [re] by KylBlz
// https://www.shadertoy.com/view/4dtSzX


#define view_dist 20.
//low:64	medium:128	ultra:255
#define vol_steps 128

#define PI       3.1415926
#define HPI      1.5707963
#define tex(a,b) textureLod(a,b,0.)

// storage register/texel addresses
const vec2 txVel = vec2(0.5,0.5);
const vec2 txLoc = vec2(1.5,0.5);
const vec2 txRot = vec2(2.5,0.5);
const vec2 txMou = vec2(3.5,0.5);

const float mtSphere = 1.,
            mtGround = 2.,
            mtLight = 3.,
    		zfar = 100.;

//the reflective sphere
vec4 sphere = vec4(vec3(0.1, 0.0, 0.1), 0.2);
//the light
vec4 light = vec4(vec3(0.,0.5,0.), 0.05);
//plane location, plane normal, plane width
mat3 plane = mat3(vec3(0., -0.7, 0.), vec3(0., 1., 0.), vec3(0.5, 0., 0.));
//just need this public
vec3 camVel = vec3(0.);

//properties
float modifier = 0.7,	//plasma
	  contrast = 20.0,
      clump = 1.0,
      size = 0.075,
	  ambient = 0.1,	//light
      brightness = 3.;

vec3 rotateXY(vec3 p, vec2 angle) {
    vec2 c = cos(angle), s = sin(angle);
    p.yz *= mat2 (c.x,s.x,-s.x,c.x);
    p.xz *= mat2 (c.y,s.y,-s.y,c.y);
    return p;
}

float linearAngle(float d, float r) {
    return min(HPI, abs(asin(r/d)));
}

float ROSA(in vec3 l) {
    vec3 lv = light.xyz - l,
         ov = sphere.xyz - l;
    float ld = sqrt(dot(lv, lv)),
          od = sqrt(dot(ov, ov)),
          sal = linearAngle(ld, light.w),
          sao = linearAngle(od, sphere.w),
          fsa = sal;
    if (od < ld) {
        float theta = acos(dot(lv / ld, ov / od));
	    fsa *= 1. - clamp((sao - theta) / sal, 0., 1.);
    }
    fsa /= sal;
    return fsa * fsa;
}

vec2 csqr( vec2 a )  { return vec2( a.x*a.x - a.y*a.y, 2.*a.x*a.y  ); }

//plasma noise function
float map(in vec3 p) {
	float res = 0.;
    vec3 c = p;
	for (int i = 0; i < 3; ++i) {
        p = modifier*abs(p)/dot(p,p) -modifier*clump;
        p.yz= csqr(p.yz);
        res += exp(-contrast * abs(dot(p,c)));
	}
	return res;
}

//marches air space between objects and camera
vec3 raymarch( in vec3 ro, vec3 rd, vec2 tminmax ) {
    //start at starting loc
    float t = tminmax.x;
    //small delta
    float dt = (tminmax.y - tminmax.x) / float(vol_steps);
    //output color
    vec3 col= vec3(0.);
    vec3 pos = ro;
    //current sample
    float c = 0.;
    for( int i=0; i<vol_steps; i++ ) {
        //this steps through empty space faster
        t += (.6 + t*t * 0.01) * dt*exp(-c*c);
        pos = ro+t*rd;
        //get plasma density
        c = map(pos*size);
		//adjusted sumation
        col += c*c*normalize(abs(pos.zyx));
    }
    return col * 0.007;
}

//returns { location, normal, vec3(dist, volume, material) }
mat3 traceScene( vec3 ro, vec3 rd) {
    //sphere intersection
    vec3 oc = ro - sphere.xyz;
    float c = dot( oc, oc ) - sphere.w*sphere.w;
    float bs = dot( oc, rd );
    float hs = sqrt(bs*bs - c);
    float sphereDepth = zfar;
    if (hs > 0.) {
        if (bs < 0.) sphereDepth = -bs - hs;
    }
    //now the light
    oc = ro - light.xyz;
    c = dot( oc, oc ) - light.w*light.w;
    float bl = dot( oc, rd );
    float hl = sqrt(bl*bl - c);
    float lightDepth = zfar;
    if (hl > 0.) {
        if (bl < 0.) lightDepth = -bl - hl;
    }
    //plane intersection
    float planeAng = dot(plane[1], rd);
    float planeDepth = dot(plane[1], plane[0] - ro) / planeAng;
    if (planeDepth < 0. || planeDepth > zfar) planeDepth = zfar;
    
    //depth test
    if (sphereDepth < planeDepth && sphereDepth < lightDepth) {
        vec3 sloc = ro+rd*sphereDepth;
        return mat3(sloc,
                   (sloc-sphere.xyz) / sphere.w,
                   vec3(max(0., sphereDepth), hs/sphere.w, mtSphere));
    } else if (planeDepth < sphereDepth && planeDepth < lightDepth) {
		return mat3(ro+rd*planeDepth,
                    plane[1],
                    vec3(max(0., planeDepth), planeAng+1.+plane[2].x, mtGround));
    } else if (lightDepth < planeDepth && lightDepth < sphereDepth) {
        vec3 sloc = ro+rd*lightDepth;
        return mat3(sloc,
                    sloc / light.w,
                    vec3(max(0., lightDepth), light.w, mtLight));
    } else {
        return mat3(vec3(map(rd * (0.3+0.1*sin(iTime*0.1)))), vec3(rd), vec3(zfar, zfar, 0.));
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    //place 0,0 in center from -1 to 1 ndc
    vec2 uv = fragCoord.xy * 2./iResolution.xx - vec2(1., 0.5);
    //mostly for post process
    float radial = pow(max(length(uv)-0.2, 0.), 2.);
    
    //get input, update camera
    vec3 camLoc = tex( iChannel0, txLoc/iChannelResolution[0].xy ).xyz;
    camVel = tex(iChannel0, txVel/iChannelResolution[0].xy ).xyz;
	vec3 camRot = tex(iChannel0, txRot/iChannelResolution[0].xy ).xyz;
    //camRot is angle vec in rad
    vec3 camDir = normalize(vec3(uv, 1.0));
    vec3 rayDir = normalize(rotateXY(camDir, camRot.xy));
    
    //update scene
    float time = iTime + 25.0;
    light.xz = vec2(sin(time)*1.,cos(time)*1.);
    //update fractal
    clump = 1.+0.2*sin(time*0.1);
    size = 0.075-0.01*sin(time*0.1);
    
    //contains location xyz, normal xyz, distance, material, 0.
    mat3 collision = traceScene(camLoc,  rayDir);

    //calculate light properties
    vec3 lightDir = normalize(light.xyz - collision[0]);
    float light2surface = distance(light.xyz, collision[0]),
    	  lightMoment = max(pow(0.25+dot(rayDir, reflect(lightDir, collision[1])), 3.), 0.),
          lightPow = brightness / (light2surface*light2surface+1.);
    
    //volume
    fragColor = vec4(clamp(raymarch(camLoc, rayDir, vec2(0., min(view_dist, collision[2].x))),0., 1.), 1.);
        
    //if ray collided with sphere
    if (collision[2].z == mtSphere) {
   
        //get plasma density
        float c = map(collision[0]*size*7.0);
		//adjusted sumation
        fragColor.rgb += 0.5*c*normalize(abs(collision[0].zyx))*(lightMoment+0.5)*(lightPow+0.5);
        
    }
    //if ray collided with ground
    else if (collision[2].z == mtGround) {
        float fresnel = 1.2+dot(rayDir,collision[1]);
        //sample texture with distance fade and energy conservation
        vec3 groundCol = tex(iChannel1, collision[0].xz * 0.5).rrr / (collision[2].x*collision[2].x*0.001+1.) * fresnel;
        //make floor patterned
        vec3 offset = vec3(0., (groundCol.r + .5*tex(iChannel2, collision[0].xz).r)*(0.1-fresnel*0.07), 0.);
        vec3 newrd = normalize(rayDir + offset);
        lightMoment = max(pow(0.5+dot(newrd, reflect(lightDir, collision[1])), 3.)*1.2, 0.);
        //yep
        vec3 reflectdir = reflect(newrd, collision[1]);
        //reflect off ground
        vec3 skyCol = vec3(map(reflectdir * (0.3+0.1*sin(iTime*0.1))))*abs(reflectdir);
        //reflect off ground
        mat3 collision3 = traceScene(collision[0] + collision[1]*0.001, reflect(newrd, collision[1]));
        float rosa = ROSA(collision[0]);
        //skycolor * fresnel + ground color * light properties
        fragColor.rgb += skyCol * max(fresnel - 0.5, 0.) + float(int(collision3[2].z == mtLight)) +
            			 groundCol * (ambient + lightMoment * rosa * lightPow);
    
    }
    //ray collided with light source
    else if (collision[2].z == mtLight) {
        fragColor.rgb = vec3(2.);
        
    }
    //ray did not collide (sky)
    else {
        //nothing much going on up here yet
        fragColor.rgb += collision[0]*abs(collision[1]);

    }
    
    //apply retina adjustment before clamp
    fragColor.rgb = clamp(fragColor.rgb, 0., 1.);
    //darken for now, eventually blur
    fragColor.rgb *= (1. - radial*0.2);
    //gamma correction
    fragColor.rgb = pow(fragColor.rgb, vec3(1. + radial));
}
