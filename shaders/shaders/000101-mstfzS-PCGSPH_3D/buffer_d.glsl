// Buffer D (buffer) — PCGSPH 3D by michael0884
// https://www.shadertoy.com/view/mstfzS

float Density(vec3 p)
{
    return trilinear(ch1, p).z;
}

vec4 calcNormal(vec3 p, float dx) {
	const vec3 k = vec3(1,-1,0);
	return   (k.xyyx*Density(p + k.xyy*dx) +
			 k.yyxx*Density(p + k.yyx*dx) +
			 k.yxyx*Density(p + k.yxy*dx) +
			 k.xxxx*Density(p + k.xxx*dx))/vec4(4.*dx,4.*dx,4.*dx,4.);
}

//compute shadows
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    InitGrid(iResolution.xy);
    fragCoord = floor(fragCoord);
    vec3 pos = dim3from2(fragCoord);
    
    //ray march in the -light_dir direction
    const float step_size = 1.0;
    const int step_count = 100;
    float td = 0.0;
    vec3 rd = light_dir;
    float optical_density = 0.0;
    vec3 normal = normalize(calcNormal(pos, 0.5).xyz);
    pos += -normal*0.5;
    for(int i = 0; i < step_count; i++)
    {
        vec3 p = pos + rd * td;
        if(!all(lessThanEqual(p, size3d)) || !all(greaterThanEqual(p, vec3(0.0))))
        {
            break;
        }
        float d = Density(p);
        optical_density += d * step_size;
        td += step_size;
    }

    fragColor = vec4(0.2*optical_density);
}