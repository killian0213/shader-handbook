// Buffer A (buffer) — Rain Drips at Night by granito
// https://www.shadertoy.com/view/tstXRj

vec2 writePos (int i, vec2 fragCoord, vec2 res, vec2 value)
{
    if (fragCoord.x == float(i))
    {
		return value;
    } 
    else {return vec2(0);}
}

float writeLife (int i, vec2 fragCoord, vec2 res, float value)
{
    if (fragCoord.x == float(i))
    {
		return value;
    } 
    else {return 0.;}
}

float loadLife(int index) 
{ 
    return texture( iChannel0, vec2((float(index)+0.5) / iChannelResolution[0].x, 0.), -100.0 ).z; 
}

vec4 loadData(int index) 
{ 
    return texture( iChannel0, vec2((float(index)+0.5) / iChannelResolution[0].x, 0.), -100.0 ); 
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 res = iResolution.xy;
    vec2 uv = fragCoord/res;
    vec2 inv = vec2(1., res.x / res.y); 
    
    vec2 pos;
    vec4 col;
    float radius = DROPSIZE * 0.005;
    float life01 = 1. / float(LIFETIME);
    float life;
    
    if (fragCoord.y < 2.) //update particle values (stored on 1st pixel row of buffer A)
    {
        for (int i = 0; i < COUNT-1; ++i)
        {
            float perinstancerandom = hash11(i);
            float perinstancelife = life01 * (perinstancerandom + 0.5);
            if (iFrame == 0) //re-init particles
            {
                pos += writePos(i, floor(fragCoord), res, hash21f(float(i)+iDate.x+iDate.y+iDate.z+iDate.w) ); //randomize position at index
                life += writeLife(i, floor(fragCoord), res, perinstancerandom * 121.317 );

            }
            else //increment 
            {
                float rndgrav = -GRAVITY * pow( 0.7 + 0.3 * sin(perinstancerandom * 15. + iTime * 0.05), 2. );
                pos += writePos(i, floor(fragCoord), res, (hash21(i*COUNT+int(iTime*60.)) * 2. - 1.) * DROPJITTER * inv * rndgrav + vec2(0., rndgrav )   );
            	life += writeLife(i, floor(fragCoord), res, life01 / abs(pos.y * 10.) * 0.01 );
            }
        }
        float vel = pos.y; 
        pos = fract(texture(iChannel0,uv).xy + pos);
        life = fract(texture(iChannel0,uv).z + life);
    	fragColor = vec4(pos, life, vel);
    }
    else //draw results to buffer A
    {
        for (int i = 0; i < COUNT-1; ++i) 
        {
            vec4 get = loadData(i);
            vec2 uvscale = (uv-get.xy) / vec2(2,4) + get.xy; 
            float mask = 1. - saturate( (distance(get.xy, uvscale) / radius) );
            mask *= smoothstep( 0.9, 0.95, get.z);
            vec2 normal = normalize(get.xy - uvscale) *(1. - mask)*ceil(mask);
            mask = ceil(mask);
            col.xy += normal;
            col.w = max(col.w,mask) ;
        }
        fragColor = col;  
    }
}