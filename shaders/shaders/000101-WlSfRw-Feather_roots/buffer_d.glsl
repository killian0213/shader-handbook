// Buffer D (buffer) — Feather roots by michael0884
// https://www.shadertoy.com/view/WlSfRw

//normal advection
const int KEY_SPACE = 32;
bool isKeyPressed(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,0), 0 ).x > 0.5;
}

void mainImage( out vec4 fragColor, in vec2 pos )
{
    vec2 V0 = vec2(0.);
    if(iFrame%1 == 0)
    {
    	vec4 data = T(pos);
    	V0 = 1.*DECODE(data.y);
   		float M0 = data.z;
    }
    else
    {
      
    }
    
    fragColor = C(pos - V0*dt);
    //initial condition
    if(iFrame < 1 || isKeyPressed(KEY_SPACE))
    {
        fragColor.xy = pos/R;
    }
}