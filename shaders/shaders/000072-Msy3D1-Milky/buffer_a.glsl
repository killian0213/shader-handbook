// Buffer A (buffer) — Milky by huwb
// https://www.shadertoy.com/view/Msy3D1

// Riffing off tomkh's wave equation solver
// https://www.shadertoy.com/view/Xsd3DB
// article: http://freespace.virgin.net/hugo.elias/graphics/x_water.htm
// 1-buffer version: https://www.shadertoy.com/view/4dK3Ww
// 1-buffer with half res sim to maintain wave speed: https://www.shadertoy.com/view/4dK3Ww

#define HEIGHTMAPSCALE 90.0

vec3 computePixelRay( in vec2 p, out vec3 cameraPos );

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 e = vec3(vec2(1.)/iResolution.xy,0.);
    vec2 q = fragCoord.xy/iResolution.xy;

    vec4 c = textureLod(iChannel0, q, 0.);

    float p11 = c.x;

    float p10 = textureLod(iChannel1, q-e.zy, 0.).x;
    float p01 = textureLod(iChannel1, q-e.xz, 0.).x;
    float p21 = textureLod(iChannel1, q+e.xz, 0.).x;
    float p12 = textureLod(iChannel1, q+e.zy, 0.).x;

    float d = 0.;

    if( iMouse.z > 0. )
    {
        vec3 ro;
        vec3 rd = computePixelRay( 2.*iMouse.xy/iResolution.xy - 1., ro );
        if( rd.y < 0. )
        {
            vec3 mp = ro + rd * ro.y/-rd.y;
            vec2 uv = mp.xz/HEIGHTMAPSCALE + 0.5;
            float screenscale = iResolution.x/640.;
            d += .02*smoothstep(20.*screenscale,5.*screenscale,length(uv*iResolution.xy - fragCoord.xy));
        }
    }

    // The actual propagation:
    d += -(p11-.5)*2. + (p10 + p01 + p21 + p12 - 2.);
    d *= .99; // damping
    d *= step(.1, iTime); // hacky way of clearing the buffer
    d = d*.5 + .5;

    fragColor = vec4(d, 0, 0, 0);
}

vec3 computePixelRay( in vec2 p, out vec3 cameraPos )
{
    // camera orbits around origin
	
    float camRadius = 60.;
	float theta = -3.141592653/2.;
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    cameraPos = vec3(xoff,20.,zoff);
     
    // camera target
    vec3 target = vec3(0.,0.,0.);
     
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

// i tried to refactor the above into an explicit solve of the wave equation, which is correct
// for spatial sampling and temporal sampling, but the result was plagued with instabilities.
// i guess the stability happens when the wave speed exceeds the maximum rate of propagation of
// information (1 pixel per frame)? (theres a formal definition for this but the name eludes me
// right now)
// UPDATE i think the stabilities are normal for this resolution and time step, and the below
// is probably correct. its all about the CFL condition: https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition
//float hx = HEIGHTMAPSCALE / iResolution.x;
//float hy = HEIGHTMAPSCALE / iResolution.y;
//void mainImage( out vec4 fragColor, in vec2 fragCoord )
//{
//    vec2 q = fragCoord.xy/iResolution.xy;
//
//    // unpack nearby heights from texture
//    float p11		= texture(iChannel1, q).x;
//    float p11_prev	= texture(iChannel0, q).x;
//    float p10		= texture(iChannel1, q-dd.zy).x;
//    float p01		= texture(iChannel1, q-dd.xz).x;
//    float p21		= texture(iChannel1, q+dd.xz).x;
//    float p12		= texture(iChannel1, q+dd.zy).x;
//
//    // the force (or accel)
//    float d = 0.;
//
//    if( iMouse.z > 0. )
//    {
//        vec3 ro;
//        vec3 rd = computePixelRay( 2.*iMouse.xy/iResolution.xy - 1., ro );
//        if( rd.y < 0. )
//        {
//            vec3 mp = ro + rd * ro.y/-rd.y;
//            vec2 uv = mp.xz/HEIGHTMAPSCALE + 0.5;
//            float screenscale = iResolution.x/640.;
//            d += 30.*smoothstep(20.*screenscale,5.*screenscale,length(uv*iResolution.xy - fragCoord.xy));
//        }
//    }
//
//    float dt = 1./60.;
//    
//	  // discrete laplacian
//    float L = (p01 + p21 - 2.0 * p11) / (hx*hx)
//        + (p10 + p12 - 2.0 * p11) / (hy*hy);
//    
//    // wave speed
//    float c = 4.25;
//    // wave equation
//    d += c*c*L;
//    // hacky way of clearing the buffer
//    d *= step(0.01, iTime);
//    
//    // prev vel - i guess this is a form of position based dynamics (PBD). i think this only
//    // works because shadertoy maintains a copy of of the target we're writing to
//    float v = (p11 - p11_prev) / dt; // technically, this is the wrong dt - should use prev dt
//    // integrate accel
//    v += d * dt;
//    // new height
//    float p_new = p11 + v * dt;
//    
//    // damping
//    p_new *= .99;
//    
//    fragColor = vec4(p_new, -v, 0., 0.);
//}

