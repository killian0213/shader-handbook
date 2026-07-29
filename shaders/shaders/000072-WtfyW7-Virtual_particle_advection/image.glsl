// Image (image) — Virtual particle advection by michael0884
// https://www.shadertoy.com/view/WtfyW7

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

void mainImage( out vec4 fragColor, in vec2 pos )
{
	R = iResolution.xy; time = iTime;
    //pos = R*0.5 + pos*0.1;
    ivec2 p = ivec2(pos);
    
    //cur particle
    vec4 U = decode(texel(ch0, pos).zw);
    
    //pressure
    vec4 P = textureLod(ch1, pos/R, 0.);
    
    //border render
    vec3 bord = smoothstep(border_h-1.,border_h-3.,border(pos))*vec3(1.);
    
    //particle render
    float rho = 0.;
    range(i, -1, 1) range(j, -1, 1)
    {
        vec4 data = texel(ch0, p + ivec2(i,j));
        vec4 vm0 = decode(data.zw);
        vec2 x0 = data.xy; //update position
        //how much mass falls into this pixel
        rho += 1.*vm0.z*G((pos - x0)/0.5);
    }
    
    // Output to screen
    fragColor = vec4(tanh(4.*vec3(1.,2.,3.)*rho) + bord + 0.*abs(P.x),0);
}