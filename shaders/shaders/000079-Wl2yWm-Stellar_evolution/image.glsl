// Image (image) — Stellar evolution by michael0884
// https://www.shadertoy.com/view/Wl2yWm

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
    
    vec4 data = texel(ch0, pos);
    particle P = getParticle(data, pos);
    
    //border render
    vec3 Nb = bN(P.X);
    float bord = smoothstep(2.*border_h,border_h*0.5,border(pos));
    
    vec4 rho = V(pos);
    rho.z *= 5.;
    //rho.w = tanh(rho.w);
    vec3 dx = vec3(-3., 0., 3.);
    vec4 grad = -0.5*vec4(V(pos + dx.zy).zw - V(pos + dx.xy).zw,
                         V(pos + dx.yz).zw - V(pos + dx.yx).zw);
    vec2 N = pow(length(grad.xz),0.2)*normalize(grad.xz+1e-5);
    float specular = pow(max(dot(N, Dir(1.4)), 0.), 3.5);
    float specularb = G(0.4*(Nb.zz - border_h))*pow(max(dot(Nb.xy, Dir(1.4)), 0.), 3.);
    
    float a = pow(smoothstep(fluid_rho*0.5, fluid_rho*2., rho.z),0.1);
   
    col.xyz = 0.02*vec3(0.2, 0.5, 1.)*rho.w;
    col.xyz += vec3(1., 0.7, 0.5)*rho.z;
    
    col.xyz = tanh(col.xyz);
}