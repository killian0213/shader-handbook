// Buffer A (buffer) — Virtual particle advection by michael0884
// https://www.shadertoy.com/view/WtfyW7

#define mass 0.1
#define div 0.7

vec2 Force(vec2 dx)
{
    return 0.*dx*exp(-dot(dx,dx));
}

vec2 P(vec2 p)
{
    return pixel(ch1, p).zw;
}

//diffusion amount
#define dif 0.93
vec3 distribution(vec2 x, vec2 p)
{
    vec4 aabb0 = vec4(p - 0.5, p + 0.5);
    vec4 aabb1 = vec4(x - dif*0.5, x + dif*0.5);
    vec4 aabbX = vec4(max(aabb0.xy, aabb1.xy), min(aabb0.zw, aabb1.zw));
    vec2 center = 0.5*(aabbX.xy + aabbX.zw); //center of mass
    vec2 size = max(aabbX.zw - aabbX.xy, 0.); //only positive
    float m = size.x*size.y/(dif*dif); //relative amount
    //if any of the dimensions are 0 then the mass is 0
    return vec3(center, m);
}

void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime;
    ivec2 p = ivec2(pos);
        
    //particle velocity, mass and grid distributed density
    vec4 vm = vec4(0.);
    vec2 F = vec2(0., -0.00);
    vec2 dF = vec2(0.);
    
    //particle position
    vec2 x = pos*vm.z;

    //reintegration advection
    //basically sum over all updated neighbors 
    //that fall inside of this pixel
    //this makes the tracking conservative
    range(i, -2, 2) range(j, -2, 2)
    {
        vec4 data = texel(ch0, p + ivec2(i,j));
        vec4 vm0 = decode(data.zw);
       
        vec2 vv = vm0.xy;
        vec2 xx = data.xy + vv*dt; //integrate position

        vec3 D = distribution(xx, pos);

        //the deposited mass into this cell
        float m = vm0.z*D.z;
        //local center of mass in this cell
        xx = D.xy; 

        //add weighted positions by mass
        x += xx*m;
        //add weighted velocities by mass
        vm.xy += vv*m;
        //add mass
        vm.z += m;
    }
    
    if(vm.z != 0.)
    {
        //normalize
        x /= vm.z;
        vm.xy /= vm.z;

        //update velocity
        //border 
        vec3 N = bN(x);
        N.z += 0.0001;
        
        if(N.z < 0.) vm.z*=0.99;

        float vdotN = step(abs(N.z), border_h)*dot(N.xy, vm.xy);
        vm.xy = vm.xy - 1.*(N.xy*vdotN + N.xy*abs(vdotN));
        F += N.xy*step(abs(N.z), border_h)/N.z;

         vec3 dx = vec3(-1., 0., 1.) + 1.;
        //global force field
        vec2 pressure = P(x);

        F += 0.4*pressure - 0.01*vm.xy*step(N.z, border_h + 5.);
        if(iMouse.z > 0.)
        {
            vec2 dm =(iMouse.xy - iMouse.zw)/10.; 
            float d = distance(iMouse.xy, x)/20.;
            F += 0.01*dm*exp(-d*d);
        }
        vm.xy += 0.4*F*dt;
        
        //velocity limit
        float v = length(vm.xy);
        vm.xy /= (v > 1.)?v:1.;
    }

    if(pos.x < 1.)
    {
        x = pos;
        vm.xyz = vec3(0.6, 0., 0.5*mass);
    }
    
    //initial condition
    if(iFrame < 1)
    {
        //random
        vec3 rand = hash32(pos);
        if(rand.z < 0.1) 
        {
            x = pos;
            vm = vec4(0.5*(rand.xy-0.5) + vec2(0.5, 0.), 4.*mass, mass);
        }
        else
        {
            x = pos;
        	vm = vec4(0.);
        }
    }
    
    U = vec4(x, encode(vm));
}