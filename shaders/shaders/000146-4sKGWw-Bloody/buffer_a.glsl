// Buf A (buffer) — Bloody by huwb
// https://www.shadertoy.com/view/4sKGWw

// Originally from tomkh's wave equation solver
// https://www.shadertoy.com/view/Xsd3DB
//

#define HEIGHTMAPSCALE 90.0

vec3 cam( in vec2 p, out vec3 cameraPos );

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 e = vec3(vec2(1.)/iResolution.xy,0.);
    vec2 q = fragCoord.xy/iResolution.xy;

    float p11 = texture(iChannel0, q).x;
    float p10 = texture(iChannel1, q-e.zy).x;
    float p01 = texture(iChannel1, q-e.xz).x;
    float p21 = texture(iChannel1, q+e.xz).x;
    float p12 = texture(iChannel1, q+e.zy).x;

    // accel on fluid surface
    float d = 0.;

    if( iMouse.z > 0. )
    {
        vec3 ro;
        vec3 rd = cam( 2.*iMouse.xy/iResolution.xy - 1., ro );
        if( rd.y < 0. )
        {
            vec3 mp = ro + rd * ro.y/-rd.y;
            vec2 uv = mp.xz/HEIGHTMAPSCALE + 0.5;
            float screenscale = iResolution.x/640.;
            d += .06*smoothstep(20.*screenscale,5.*screenscale,length(uv*iResolution.xy - fragCoord.xy));
        }
    }
    
    // force from video sampled by buffer B to avoid vid sync problems
    d += texture(iChannel1, q).y;

    // The actual propagation:
    d += -(p11-.5)*2. + (p10 + p01 + p21 + p12 - 2.);
    d *= .97; // damping
    if( iFrame == 0 ) d = 0.;
    d = d*.5 + .5;

    fragColor = vec4(d, 0.0, 0.0, 0.0);
}

vec3 cam( in vec2 p, out vec3 cameraPos )
{
    // camera orbits around origin
    float camRadius = 50.;
	float theta = -3.141592653/2.;
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    cameraPos = vec3(xoff,30.,zoff);
     
    // camera target
    vec3 target = vec3(0.,0.,-30.);
     
    // camera frame
    vec3 fo = normalize(target-cameraPos);
    vec3 ri = normalize(vec3(fo.z, 0., -fo.x ));
    vec3 up = normalize(cross(fo,ri));
     
    // multiplier to emulate a fov control
    float fov = .5;
	
    // ray direction
    vec3 rayDir = normalize(fo + fov*p.x*ri + fov*p.y*up);
	
	return rayDir;
}
