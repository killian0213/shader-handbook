// Image (image) — DragonBall  by ivansafrin
// https://www.shadertoy.com/view/Mtd3DB

const float PI = 3.14159265359;

float scene(vec3 position) {
    float height = 0.3;
    return length(position)-height;
}

vec3 getNormal(vec3 pos, float smoothness) {	
	vec3 n;
	vec2 dn = vec2(smoothness, 0.0);
	n.x	= scene(pos + dn.xyy) - scene(pos - dn.xyy);
	n.y	= scene(pos + dn.yxy) - scene(pos - dn.yxy);
	n.z	= scene(pos + dn.yyx) - scene(pos - dn.yyx);
	return normalize(n);
}

float raymarch(vec3 position, vec3 direction) {
    float total_distance = 0.0;
    for(int i = 0 ; i < 32 ; ++i) {
        float result = scene(position + direction * total_distance);
        if(result < 0.005)
        {
            return total_distance;
        }
        total_distance += result;
    }
    return -1.0;
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.y;
    uv -= vec2(0.5*iResolution.x/iResolution.y, 0.5); 
    uv.y *= -1.0;
    vec3 origin = vec3(sin(iTime*0.1) * 2.5, 0.0, cos(iTime*0.1) * 2.5);
    
    mat3 camMat = calcLookAtMatrix( origin, vec3(0.0), 0.0 );
	vec3 direction = normalize( camMat * vec3(uv, 2.5));
    
    
    float dist = raymarch(origin, direction);
    if(dist < 0.0) {
		fragColor = texture(iChannel1, direction);
    } else{
        vec3 fragPosition = origin+direction*dist;
 		vec3 N = getNormal(fragPosition, 0.01);
        vec4 ballColor = vec4(1.0, 0.8, 0.0, 1.0) * 0.75;
        vec3 ref = reflect(direction, N);
        
        float P = PI/5.0;
        float starVal = (1.0/P) * (P - abs( mod(atan(uv.x, uv.y)+ PI,(2.0*P)) - P));
        vec4 starColor = (distance(uv, vec2(0.0,0.0)) < 0.06-(starVal * 0.03)) ? vec4(2.8, 1.0, 0.0, 1.0) : vec4(0.0);
        
        float rim = max(0.0, (0.7 + dot(N,direction)));
        
        vec3 refr = refract(direction, N, 0.7);
        fragColor =  
           
            texture(iChannel1, refr) * ballColor +
            (vec4(0.6, 0.2, 0.0, 1.0) * max(0.0, 1.0-distance(uv * 4.0, vec2(0.0,0.0)))) * 4.0  * (0.2 + abs(sin(iTime)) * 0.8) + 
           + starColor
            + texture(iChannel1, ref) * 0.3
        + vec4(rim, rim * 0.5, 0.0, 1.0);
    }
}