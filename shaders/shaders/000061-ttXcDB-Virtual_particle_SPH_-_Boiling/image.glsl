// Image (image) — Virtual particle SPH - Boiling by michael0884
// https://www.shadertoy.com/view/ttXcDB

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
    
    //pressure
    vec4 P = textureLod(ch1, pos/R, 0.);
    
    //border render
    vec3 bord = smoothstep(border_h+1.,border_h-1.,border(pos))*vec3(1.);
    
    //particle render
    vec2 rho = vec2(0.);

    range(i, -1, 1) range(j, -1, 1)
    {
       vec2 dx = vec2(i,j);
       vec4 data = texel(ch0, pos + dx);
       particle P = getParticle(data, pos + dx);
       
        vec2 x0 = P.X; //update position
        //how much mass falls into this pixel
        rho += 1.*P.M*G((pos - x0)/0.75); 
    }
  	rho = 1.2*rho;
    
     vec4 D = pixel(ch2, pos);
    float ang = atan(D.x, D.y);
    float mag = 0. + 10.*length(D.xy)*rho.x;
    
    // Output to screen
    fragColor = vec4(1.6*vec3(0.2,0.4,1.)*rho.x + 1.*vec3(1.5,0.3,0.3)*rho.y*rho.x + bord + 0.*abs(P.x),0);
	fragColor.xyz = tanh(vec3(1.,1.1,1.3)*fragColor.xyz);
}