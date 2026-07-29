// Image (image) — Copper / Flesh by tdhooper
// https://www.shadertoy.com/view/WljSWz

/*

    Copper / Flesh
    --------------

    Press 'f' for the gory flesh version.
	Press 'l' to disable the texture loop.
	Mouse click for a closeup.

	I was introduced to volume displacement a few weeks ago, which works
    wonderfully for ray marched SDFs:

	https://docs.arnoldrenderer.com/display/A5AFMUG/Polymesh+to+Volume

	An FBM domain warp texture is created in Buffer A, and used to adjust
    the surface distance while marching.

	The model is quite slow to march, so I've stored it in a 3D texture.
	Shadertoy doesn't support writing to 3D textures, so I've used the
    cubemap feature, and subdivided the 6 2D textures to get another
    dimension.

*/

bool FLESH = false;

#define PI 3.14159265359

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

bool isMapPass = false;
bool isBound = false;

// Read head sdf from '3D' texture
float mHead(vec3 p) {
    p.x = -abs(p.x);
    p += OFFSET / SCALE;
    if (isMapPass) {
    	float bound = fBox(p, 1./SCALE);
        isBound = bound > .01;
    	if (isBound) return bound;
    }
    p *= SCALE;
    float d = mapTex(iChannel0, p, iChannelResolution[0].xy);
    return d;
}

float g_disp;

vec3 projectOnPlane(vec3 v, vec3 n) {
	float scalar = dot(n, v) / length(n);
	vec3 v1 = n * scalar;
	return v - v1;
}

// Wrap the fbm texture around the model, focus on getting as
// much detail as possible on the visible parts.
// Triplanar mapping would be worth trying here.
float calcDisplacement(vec3 p) {
    float disp;
    vec2 uv;
    p.y += .1;
    
    vec3 focus = vec3(.0,.1,1.);
    vec3 center = -focus * .7;
    vec3 up = vec3(0,1,0);
    vec2 rad = vec2(PI/1.25,PI/2.5)/1.5;
    
    center *= length(p);
    
    p = normalize(p - center);
    focus = normalize(focus - center);
    
    vec3 yPlane = cross(focus, up);
    vec3 xPlane = cross(focus, yPlane);
    
    vec3 xp = normalize(projectOnPlane(p, xPlane));
    vec3 yp = normalize(projectOnPlane(p, yPlane));
	
    float xa = acos(dot(focus, xp)) * sign(dot(p, yPlane));
    float ya = acos(dot(focus, yp)) * sign(dot(p, xPlane));
        
    uv = .5 - (vec2(xa, ya) / rad / 2.);

    vec4 tex = texture(iChannel2, uv);
    disp = tex.r;
    disp = disp * 3. - 1.3;
    disp = smoothstep(-.5, 5., disp) * 10.;
	disp *= .3;
  	
    if (isMapPass) {
        g_disp = disp;
    }
   
    // create slight ridges around the edges of holes
    // I can't decide if I like this
 	disp = abs(disp - .1) - .1;

    return disp;
}

float map(vec3 p) {
    p.y -= .14;
    #ifndef GIF_EXPORT
        pR(p.xz, sin(4. * fTime * PI * .5) * .05);
        pR(p.zy, sin(4. * fTime * PI * 2.) * .03 + .05);
        if (iMouse.x > 0. && iMouse.y > 0.) {
            pR(p.zx, ((iMouse.x/iResolution.x)*2.-1.)*.5);
            pR(p.zy, ((iMouse.y/iResolution.y)*2.-1.)*.5);
        }
   	#else
    	pR(p.zy, .05);
   	#endif
    float d = mHead(p);
    if (d < .1 && ! isBound) {
        float ds = calcDisplacement(p);
        d += ds * .03;
    }
    return d;
}


const int NORMAL_STEPS = 6;
vec3 calcNormal(vec3 pos){
    vec3 eps = vec3(.0005,0,0);
    vec3 nor = vec3(0);
    float invert = 1.;
    vec3 npos;
    for (int i = 0; i < NORMAL_STEPS; i++){
        npos = pos + eps * invert;
        nor += map(npos) * eps * invert;
        eps = eps.zxy;
        invert *= -1.;
    }
    return normalize(nor);
}

// https://www.shadertoy.com/view/lsKcDD
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    float ph = 1e10;
    
    for( int i=0; i<32; i++ )
    {
        float h = map( ro + rd*t );
        res = min( res, 10.0*h/t );
        t += h;
        if( res<0.0001 || t>tmax ) break;
        
    }
    return clamp( res, 0.0, 1.0 );
}

// https://www.shadertoy.com/view/Xds3zN
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

const int KEY_F = 70;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec2 p = (-iResolution.xy + 2. * fragCoord.xy) / iResolution.y;
    
    //fragColor = texture(iChannel2,fragCoord / iResolution.xy); return;
    
    vec3 col;

    vec2 bguv = p + (texture(iChannel2, fragCoord / iResolution.xy).rb* 2. - 1.);
    
    float delay = 10. * 1.5;
    //FLESH = dot(p, vec2(.5)) > sin(clamp(abs(mod(iTime * 1.5, delay * 2.) - delay) - (delay - 1.) / 2., 0., 1.) * PI * .5) * 3. - 1.5;
    FLESH = bool(texelFetch( iChannel3, ivec2(KEY_F,2),0 ).x);
    if (FLESH) {
    	col = vec3(0);
    } else {
        #ifndef GIF_EXPORT
    		col = mix(vec3(.05,.2,.2), vec3(.1,.12,.11), range(2., 1., length(bguv - vec2(1,0))));
    		col = mix(col, vec3(.7,.4,.28) * .7, range(4., 1., length(bguv - vec2(-1,3))));
       	#else
        	col = vec3(.05,.2,.2);
        #endif
    }
    
    if (iMouse.z > 0. && iMouse.w > 0.) {
    	p /= 1.8;
    }

    p /= 1.15;

    vec3 camPos = vec3(0,.05,3.2);
    vec3 rayDirection = normalize(vec3(p + vec2(0,-0),-4));        
    vec3 rayPosition = camPos;
    float rayLength = 0.;
    float dist = 0.;
    bool bg = false;

    isMapPass = true;

    for (int i = 0; i < 600; i++) {
        rayLength += dist * .5;
        
        rayPosition = camPos + rayDirection * rayLength;
        dist = map(rayPosition);

        if (abs(dist) < .0001) {
        	break;
        }
        
        if (rayLength > 5.) {
            bg = true;
            break;
        }
    }

    isMapPass = false;    
            
    if ( ! bg) {
        vec3 pos = rayPosition;
        vec3 rd = rayDirection;
        vec3 nor = calcNormal(rayPosition);
        vec3 ref = reflect(rd, nor);
        vec3 up = normalize(vec3(1));

        // lighitng
        // IQ - Raymarching - Primitives 
        // https://www.shadertoy.com/view/Xds3zN
        float hole = range(4., 1., g_disp);
        float occ = calcAO( pos, nor ) * mix(.5, 1., hole);
		vec3  lig = normalize( vec3(-.5, 1., .5) );
        vec3  lba = normalize( vec3(.5, -1., -.5) );
        vec3  hal = normalize( lig-rd );
		float amb = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, lba ), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        
        dif *= softshadow( pos, lig, 0.01, .5 ) * hole;

		float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

		vec3 lin = vec3(0.0);
        lin += 2.80*dif*vec3(1.30,1.00,0.70);
        lin += 0.55*amb*vec3(0.40,0.60,1.15)*occ;
        lin += 1.55*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
        if (FLESH) {
        	col = vec3(1, 0.8, 0.78) * .3;
        	col = mix(col, vec3(.4,.05,.03) * .5, range(.0, .15, g_disp));
        	col = mix(col, vec3(1,.0,.05) * .2, range(.2, .5, g_disp));
        	col = mix(col, vec3(.05,0,0), range(.4, .5, g_disp));
        } else {
			col = pow(texture(iChannel1, ref).rgb, vec3(2.2)) * vec3(1,1,.9);
        	col = mix(col, vec3(0,.3,.2), range(.02, .5, g_disp));
        	col = mix(col, vec3(0,.1,.12), range(.3, .5, g_disp));
        }
        col = col*lin;
		col += 5.00*spe*vec3(1.10,0.90,0.70);
    }

    #ifndef GIF_EXPORT
    	col *= range(1.5, .4, length(fragCoord.xy / iResolution.xy - .5));
   	#endif
    col = pow( col, vec3(0.4545) );
    fragColor = vec4(col,1);
}