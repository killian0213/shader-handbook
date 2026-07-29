// Image (image) — Rippling Flag by TekF
// https://www.shadertoy.com/view/ldX3DX

// Hazel Quantock 2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

const float tau = 6.28318530717958647692;


// Divide the view into multiple viewports
// Set global variables to replace iResolution and fragCoord for the local viewport
// Returns index of which panel is being drawn for this pixel
// in the range [0,numPanels.x*numPanels.y)
vec2 view_Resolution;
vec2 view_FragCoord;
int view_Index;
vec4 view_selectionRelativeMouse;
/*bool SideMenu( ivec2 numPanels )
{
	// arrange so that the main view and the side views have the same aspect ratio
	vec2 dims = vec2(
						iResolution.x/float(numPanels.x+numPanels.y), // main view is sv.y times bigger on both axes!
						iResolution.y/float(numPanels.y)
						);


	// which one is selected?
	ivec2 viewIndex = ivec2(floor(iMouse.xy/dims));

	int selectedPanel = 0;
	if ( viewIndex.x < numPanels.x )
	{
		selectedPanel = viewIndex.y+viewIndex.x*numPanels.y;
	}
	

	// figure out which one we're drawing
	viewIndex = ivec2(floor(fragCoord.xy/dims));

	int index;
	vec4 viewport;
	if ( viewIndex.x < numPanels.x )
	{
		viewport.xy = vec2(viewIndex)*dims;
		viewport.zw = dims;
		index = viewIndex.y+viewIndex.x*numPanels.y;
	}
	else
	{
		// main view, determined by where the last click was
		viewport.x = float(numPanels.x)*dims.x;
		viewport.y = 0.0;
		viewport.zw = dims*float(numPanels.y);
		index = selectedPanel;
	}
	
	// highlight currently selected
	if ( index == selectedPanel && viewIndex.x < numPanels.x &&
		( fragCoord.x-viewport.x < 2.0 || viewport.x+viewport.z-fragCoord.x < 2.0 ||
		  fragCoord.y-viewport.y < 2.0 || viewport.y+viewport.w-fragCoord.y < 2.0 ) )
	{
		fragColor = vec4(1,1,0,1);
		return false;
	}
	
	// compute viewport-relative coordinates
	view_FragCoord = fragCoord.xy - viewport.xy;
	view_Resolution = viewport.zw;
	view_Index = index;

	view_selectionRelativeMouse = fract(iMouse/dims.xyxy);
	
	return true;
}*/

// Gamma correction
#define GAMMA (2.2)

vec3 ToLinear( in vec3 col )
{
	// simulate a monitor, converting colour values into light values
	return pow( col, vec3(GAMMA) );
}

vec3 ToGamma( in vec3 col )
{
	// convert back into colour values, so the correct light will come out of the monitor
	return pow( col, vec3(1.0/GAMMA) );
}

// Set up a camera looking at the scene.
// origin - camera is positioned relative to, and looking at, this point
// distance - how far camera is from origin
// rotation - about x & y axes, by left-hand screw rule, relative to camera looking along +z
// zoom - the relative length of the lens
void CamPolar( out vec3 pos, out vec3 ray, in vec3 origin, in vec2 rotation, in float distance, in float zoom )
{
	// get rotation coefficients
	vec2 c = vec2(cos(rotation.x),cos(rotation.y));
	vec4 s;
	s.xy = vec2(sin(rotation.x),sin(rotation.y)); // worth testing if this is faster as sin or sqrt(1.0-cos);
	s.zw = -s.xy;

	// ray in view space
	ray.xy = view_FragCoord.xy - view_Resolution.xy*.5;
	ray.z = view_Resolution.y*zoom;
	ray = normalize(ray);
	
	// rotate ray
	ray.yz = ray.yz*c.xx + ray.zy*s.zx;
	ray.xz = ray.xz*c.yy + ray.zx*s.yw;
	
	// position camera
	pos = origin - distance*vec3(c.x*s.y,s.z,c.x*c.y);
}


vec4 Noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
	f = f*f*(3.0-2.0*f);
//	vec2 f2 = f*f; f = f*f2*(10.0-15.0*f+6.0*f2);

	vec2 uv = p + f;

#if (1)
	vec4 rg = textureLod( iChannel0, (uv+0.5)/256.0, 0.0 );
#else
	// on some hardware interpolation lacks precision
	vec4 rg = mix( mix(
				texture( iChannel0, (floor(uv)+0.5)/256.0, -100.0 ),
				texture( iChannel0, (floor(uv)+vec2(1,0)+0.5)/256.0, -100.0 ),
				fract(uv.x) ),
				  mix(
				texture( iChannel0, (floor(uv)+vec2(0,1)+0.5)/256.0, -100.0 ),
				texture( iChannel0, (floor(uv)+1.5)/256.0, -100.0 ),
				fract(uv.x) ),
				fract(uv.y) );
#endif			  

	return rg;
}

float DistanceField( vec3 pos );

vec3 Normal( vec3 pos )
{
	const vec2 delta = vec2(0,.01);
	vec3 grad;
	grad.x = DistanceField( pos+delta.yxx )-DistanceField( pos-delta.yxx );
	grad.y = DistanceField( pos+delta.xyx )-DistanceField( pos-delta.xyx );
	grad.z = DistanceField( pos+delta.xxy )-DistanceField( pos-delta.xxy );
	return normalize(grad);
}


// ----------------------

float RippleHeight( vec2 pos )
{
	vec2 p = pos+vec2(-1,.2)*iTime;
	
	p += vec2(1,0)*Noise(p).y; // more natural looking ripples
	float f = Noise(p).x-.5;
	p *= 2.0;
	p += vec2(0,-.5)*iTime;
	f += (Noise(p).x-.5)*.2;
	p *= 2.0;
	p += vec2(-3,0)*iTime;
	f += (Noise(p).x-.5)*.05;
	
	f = f*(1.0-exp2(-abs(pos.x)));
	return f*1.0;
}

float DistanceField( vec3 pos )
{
	return (RippleHeight(pos.xy)-pos.z)*.5;
}

// map a uv space onto a distorted surface
vec2 UVMapping( vec2 target )
{
	// need to march vertically to absorb vertical creases, and horizontally for horizontal ones
	// cheat, by seperating these two
	vec2 uv = vec2(0);
	
	const int n = 16;
	const float fudge = 1.0; // use values > 1 to allow for extra ripples we're not measuring
	vec2 d = target/float(n);
	vec2 l;
	l.x = RippleHeight( vec2(0,target.y) );
	l.y = RippleHeight( vec2(target.x,0) );
	for ( int i=0; i < n; i++ )
	{
		vec2 s;
		s.x = RippleHeight( vec2(d.x*float(i),target.y) );
		s.y = RippleHeight( vec2(target.x,d.y*float(i)) );
		//uv.x += sign(d.x)*sqrt(pow(fudge*,2.0)+d.x*d.x);
		//uv.y += sign(d.y)*sqrt(pow(fudge*,2.0)+d.y*d.y);
		uv += sign(d)*sqrt(pow(fudge*(s-l),vec2(2.0))+d*d);
		l = s;
	}
	
	return (uv+vec2(0,1))/vec2(3.0,2.0);
}

vec3 Pattern( vec2 uv )
{
	if ( view_Index == 0 )
	{
		// nyan cat
		float frame = 0.0;//floor(iTime*8.0)
		vec4 t = texture( iChannel1, uv*vec2(1.0/6.4,-1)+vec2(fract(frame/6.0)*.938,1) );
		float f = uv.y*5.5+1.9; //*tau
		return mix( vec3(cos(f),-sin(f),-cos(f))*.5+.5, ToLinear(t.rgb), t.a );
	}
	
	if ( view_Index == 1 )
	{
		// gay pride (roughly)
		uv.y = floor(uv.y*6.0)/6.0+.3;
		return vec3(cos(uv.y*tau),-sin(uv.y*tau),-cos(uv.y*tau))*.5+.5;
	}

	if ( view_Index == 2 )
	{
		// Sweden (because it's easy)
		return mix( vec3(1,.6,0), vec3(.02,.1,.5), smoothstep(.095,.1,min(abs(uv.x-.4),abs(uv.y-.5))) );
	}
	
//	if ( view_Index == 3 )
	{
		// union jack
		vec3 b = vec3(0,0,.5);
		vec3 w = vec3(1);
		vec3 r = vec3(.8,0,0);
		vec3 col = b;
		
		uv = uv*2.0-1.0;
		col = mix( w, col, smoothstep( .245,.255, min(abs(uv.y-uv.x-.05),abs(uv.y+uv.x-.05)) ) );
		col = mix( r, col, smoothstep( .095,.105, min(abs(uv.y-uv.x),abs(uv.y+uv.x)) ) );
	
		float q = min(abs(uv.x*1.5),abs(uv.y));
		col = mix( w, col, smoothstep( .245,.255, q ) );
		col = mix( r, col, smoothstep( .145,.155, q ) );
		
		return col;
	}
}

// xyz = normal, w = transmission from far side
vec4 Weave( vec2 uv )
{
	vec2 a = uv*vec2(3.0,2.0)*view_Resolution.y*.85;
	float h = (sin(a.x)+sin(a.y))*.25+.5;
	
	h = h*.1; // transparency within the flag
	
	// edges
	h = max(h,smoothstep(.495,.5,abs(uv.x-.5)));
	h = max(h,smoothstep(.495,.5,abs(uv.y-.5)));
	
	return vec4(0,0,0,h);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// since Chrome 36 the extra logic for the SideMenu won't compile on some PCs (my work PC is ok, my home one is not)
	view_Resolution = iResolution.xy;
	view_FragCoord = fragCoord.xy;
	view_Index = 1;
	view_selectionRelativeMouse = iMouse/view_Resolution.xyxy;

	//if ( SideMenu( ivec2(1,4) ) )
	{
		vec3 pos, ray;
		CamPolar( pos, ray, vec3(1.5,0,0), vec2(-.8,-.5)+vec2(.9,1.5)*view_selectionRelativeMouse.yx, 10.0, 3.5 );
		
		float t = 0.0;
		float h = 1.0;
		for ( int i=0; i < 20; i++ )
		{
			if ( h < .01 )
				break;
			float h = DistanceField( pos+t*ray );
			t += h;
		}
		
		pos += t*ray;

		vec2 uv = UVMapping( pos.xy );
		
		vec3 col = Pattern( uv );
		
		vec4 weave = Weave(uv);
		
		vec3 normal = Normal( pos );
		
		float nl = dot(normal,normalize(vec3(-3,1,-2)));
		float l = max( nl, .0 );
		float bl = (max( -nl, .0 ))*(weave.a*.0);
		col *= (l + bl*vec3(1,.8,1))*vec3(1.2,1.1,1) + vec3(.1,.13,.2);
		
		//if ( uv.x < .0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 )
		col = mix( col, vec3(.5,.65,.9)*(Noise(ray.xy*4.0).x*.3+1.0), weave.a );
		
		col = mix( col, vec3(cos(uv.x*50.0)),smoothstep(0.015,0.01,abs(uv.x+.01))*smoothstep(1.01,1.0,uv.y));
		
		fragColor = vec4(ToGamma(col),1.0);
	}
}

