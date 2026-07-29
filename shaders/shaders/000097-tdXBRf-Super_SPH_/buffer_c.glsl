// Buffer C (buffer) — Super SPH  by michael0884
// https://www.shadertoy.com/view/tdXBRf

vec2 sc(vec2 p)
{
    return SC*(p - 0.5*R) + 0.5*R;
}

// iq's smooth HSV to RGB conversion 
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

obj getObj(int id)
{
    obj o;
    
    vec4 a = texel(ch0, i2xy(ivec3(id, 0, 0))); 
    o.X = a.xy; o.V = a.zw;
    
    a = texel(ch0, i2xy(ivec3(id, 1, 0))); 
    o.Pressure = a.x;
    o.Rho = a.y;
    o.SScale = a.z;
    o.Div = a.w;
    
    o.Y = texel(ch0, i2xy(ivec3(id, 2, 0)));
    
    o.id = id;
    return o;
}

void mainImage( out vec4 fragColor, in vec2 pos )
{
    sN = SN; 
    N = ivec2(R*P/vec2(sN));
    TN = N.x*N.y;
    ivec2 pi = ivec2(floor(pos));
    
    int ID = int(texel(ch1, pi).x); 
    obj O = getObj(ID);
    float d =distance(pos, sc(O.X));
    float d1 = exp(-sqr(d/1.)) +  0.*exp(-0.1*d);
    float d2 = 10.*O.Y.x;
   
    /*loop(j,4)
    {
        vec4 nb = texel(ch0, i2xy(ivec3(ID, j, 1)));
        loop(i,4)
    	{
            if(nb[i] < 0.) continue;
            vec2 nbX = texel(ch0, i2xy(ivec3(nb[i], 0, 0))).xy; 
        	d1 += exp(-0.5*distance(pos, sc(nbX)));
    	}
    }*/
    d1*=1.;
    // Output to screen
 	vec3 pcol = texel(ch2, pi).xyz;
    vec3 ncol = 0.*sin(vec3(1,2,3)*d2*0.3)*d1 + hsv2rgb(vec3(atan(O.V.x,O.V.y)/PI, 2.*length(O.V),20.*length(O.V)))*d1;
    fragColor = vec4(mix(pcol,ncol,0.5),1.0);
}