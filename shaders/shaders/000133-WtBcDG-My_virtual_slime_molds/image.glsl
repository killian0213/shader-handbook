// Image (image) — My virtual slime molds by michael0884
// https://www.shadertoy.com/view/WtBcDG

// Fork of "Everflow" by michael0884. https://shadertoy.com/view/ttBcWm
// 2020-07-19 18:18:22

// Fork of "Paint streams" by michael0884. https://shadertoy.com/view/WtfyDj
// 2020-07-11 22:38:47

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 mixN(vec3 a, vec3 b, float k)
{
    return sqrt(mix(a*a, b*b, clamp(k,0.,1.)));
}

vec4 V(vec2 p)
{
    return pixel(ch1, p);
}

void mainImage( out vec4 col, in vec2 pos )
{
	R = iResolution.xy; time = iTime;
    //pos = R*0.5 + pos*0.1;
    ivec2 p = ivec2(pos);
    
    //border render
    float bord = smoothstep(2.*border_h,border_h*0.5,border(pos));
   
    vec4 data = texel(ch0, pos);
    particle P0 = getParticle(data, pos);

    vec2 x0 = P0.X; //update position
    //how much mass falls into this pixel
    vec4 rho = vec4(P0.V, P0.M)*G((pos - x0)/0.75); 
    vec3 dx = vec3(-3., 0., 3.);
 
    float a = pow(smoothstep(fluid_rho*0., fluid_rho*2., rho.z),0.1);
    float b = exp(-1.7*smoothstep(fluid_rho*1., fluid_rho*7.5, rho.z));
    vec3 col0 = vec3(1., 0.7, 0.7);
    vec3 col1 = vec3(0., 0.9, 1.);
    // Output to screen
    col.xyz = vec3(0.2*a); 
    col.xyz += 0.5 - 0.5*cos(8.*vec3(0.2,0.8,0.6)*rho.w);
    //col.xyz += vec3(1,1,1)*bord;
    col.xyz = tanh(4.*pow(col.xyz,vec3(1.5)));
    col.w=1.0;
}