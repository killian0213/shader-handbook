// Sound (sound) — [NV15] Space Curvature by iq
// https://www.shadertoy.com/view/llj3Rz

vec2 mainSound( in int samp, float time )
{
	vec2 y = vec2( 0.0 );
	
    float d = 1.0;
    for( int j=0; j<4; j++ )
    {

        float base = 512.0 + 512.0*sin( time * 0.25 );

        for(int i=0; i<256; i++ )
        {
            float h = float(i)/256.0;

            vec2 ti = texture( iChannel0, vec2(h,time*0.1)).xy;

            float a = ti.x*ti.x/(0.1+h*h);

            y += d * a * cos( vec2(3.0*h,0.0) + 6.2831*time*base*h + ti.y*100.0 );
        }
        time += 0.15;
        d *= 0.9;
    }    

    y /= 256.0;
    y /= 2.0;
    
    y = sin(1.57*y);
    
    return y;
}