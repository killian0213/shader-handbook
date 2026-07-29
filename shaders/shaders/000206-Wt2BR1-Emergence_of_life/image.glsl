// Image (image) — Emergence of life by michael0884
// https://www.shadertoy.com/view/Wt2BR1

// Fork of "Fireballs" by michael0884. https://shadertoy.com/view/tlfBDX
// 2020-08-20 00:44:41

// Fork of "Random slime mold generator" by michael0884. https://shadertoy.com/view/ttsfWn
// 2020-08-19 23:28:40

// Fork of "Everflow" by michael0884. https://shadertoy.com/view/ttBcWm
// 2020-07-19 18:18:22

// Fork of "Paint streams" by michael0884. https://shadertoy.com/view/WtfyDj
// 2020-07-11 22:38:47

//3d mode
//#define heightmap

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

#define FOV 1.56
#define RAD R.x*0.6

float gauss(float x, float r)
{
    x/=r;
    return exp(-x*x);
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float rho(vec3 pos)
{
    pos.xy += R*0.5;
 	pos.xy = mod(pos.xy, R-1.);
    vec4 v = P(pos.xy);
    return v.z;
}

vec3 color(vec3 pos)
{
    pos.xy += R*0.5;
 	pos.xy = mod(pos.xy, R-1.);

    vec4 v = C(pos.xy);
    return v.xyz;
}


float DE(vec3 pos)
{
    float y = 16.*rho(pos);  
    
    pos.xy += R*0.5;
 	pos.xy = mod(pos.xy, R-1.);
    float de = 1e10;
    de = min(de, 0.7*sdBox(pos - vec3(R, 4.*y)*0.5, vec3(R*0.51, 3.)));
    return de;
}


vec4 calcNormal(vec3 p, float dx) {
	const vec3 K = vec3(1,-1,0);
	return  (K.xyyx*DE(p + K.xyy*dx) +
			 K.yyxx*DE(p + K.yyx*dx) +
			 K.yxyx*DE(p + K.yxy*dx) +
			 K.xxxx*DE(p + K.xxx*dx))/vec4(4.*dx,4.*dx,4.*dx,4.);
}

#define marches 70.
#define min_d 1.
vec4 ray_march(vec3 p, vec3 r)
{
    float d;
    for(float i = 0.; i < marches; i++)
    {
        d = DE(p); 
        p += r*d;
        if(d < min_d || d > R.x) break;
    }
    return vec4(p, d);
}

void mainImage( out vec4 col, in vec2 pos )
{    
    #ifdef heightmap
        // Normalized pixel coordinates 
        pos = (pos - R*0.5)/max(R.x,R.y);
		pos = vec2(pos.x, pos.y);
        vec2 uv = iMouse.xy/R;
        vec2 angles = vec2(-1.5 + 0.03*iTime, -0.4)*PI;

        vec3 camera_z = vec3(cos(angles.x)*cos(angles.y),sin(angles.x)*cos(angles.y),sin(angles.y));
        vec3 camera_x = normalize(vec3(cos(angles.x+PI*0.5), sin(angles.x+PI*0.5),0.)); 
        vec3 camera_y = -normalize(cross(camera_x,camera_z));

        //tracking particle
        vec4 fp = vec4(R*0.5 + 0.*vec2(150.*iTime, 0.), 0., 0.);

        vec3 ray = normalize(camera_z + FOV*(pos.x*camera_x + pos.y*camera_y));
        vec3 cam_pos = vec3(fp.xy-R*0.5, 0.) - RAD*vec3(cos(angles.x)*cos(angles.y),sin(angles.x)*cos(angles.y),sin(angles.y));

        vec4 X = ray_march(cam_pos, ray);

        if(X.w < min_d)
        {

            float D = rho(X.xyz);
          	vec3 c = color(X.xyz);
           
            vec3 albedo =sin(vec3(1,2,3)*3.*D*D);
            float rough = 1. - 0.1*distance(albedo, vec3(1.));

            vec4 N0 = calcNormal(X.xyz, 2.*X.w)*vec4(4.,4.,1.,1.);
            vec3 n = normalize(N0.xyz);
            vec3 rd = reflect(ray, n);
            vec3 colA =texture(iChannel2,  rd.yzx).xyz;
            vec3 colB = (vec3(0.5) + 0.5*dot(rd, normalize(vec3(1.))));
            colB += 4.*rough*pow(max(dot(rd, normalize(vec3(1.))), 0.), 8.);
            colB += 4.*rough*pow(max(dot(rd, normalize(vec3(-0.5,-0.9,0.8))), 0.), 8.);
            float b = clamp(0.5 + 0.5*dot(n, normalize(vec3(1,1,1))), 0.,1.);
            float K = 1. - pow(max(dot(n,rd),0.), 2.);
            col.xyz = 1.*albedo*colB + 0.*rough*colA*K;
        }
        else
        {    
            //background
            col = 1.*texture(iChannel2,  ray.yzx);
        }
    col = tanh(2.*col);
    #else
    	float r = P(pos.xy).z;
    	vec4 c = C(pos.xy);
    	
    	//get neighbor data
        vec4 d_u = T(pos + dx.xy), d_d = T(pos - dx.xy);
        vec4 d_r = T(pos + dx.yx), d_l = T(pos - dx.yx);
        
        //position deltas
        vec2 p_u = DECODE(d_u.x), p_d = DECODE(d_d.x);
        vec2 p_r = DECODE(d_r.x), p_l = DECODE(d_l.x);
        
        //velocities
        vec2 v_u = DECODE(d_u.y), v_d = DECODE(d_d.y);
        vec2 v_r = DECODE(d_r.y), v_l = DECODE(d_l.y);
       
        //pressure gradient
        vec2 p = vec2(Pressure(d_r) - Pressure(d_l),
                      Pressure(d_u) - Pressure(d_d));
        
        //velocity operators
        float div = (v_r.x - v_l.x + v_u.y - v_d.y);
        float curl = (v_r.y - v_l.y - v_u.x + v_d.x);
    	
    	
    	col=sin(vec4(1,2,3,4)*25.*r*r*r);
    	//col.xyz += vec3(1,0.1,0.1)*max(curl,0.) + vec3(0.1,0.1,1.)*max(-curl,0.);
    	
    #endif
}