// Buffer C (buffer) — Stellar evolution by michael0884
// https://www.shadertoy.com/view/Wl2yWm

//density
//gravity solved by using a Jacobi-like solver with future estimation
#define Rad 4

void mainImage( out vec4 fragColor, in vec2 pos )
{
    R = iResolution.xy; time = iTime;
    ivec2 p = ivec2(pos);

    vec4 data = texel(ch0, pos);
    particle P = getParticle(data, pos);
    
    //particle render
    vec4 rho = vec4(0.);
    float U = 0.;
    vec3 avgV = vec3(0.00, 0, 0.0000001);
    vec4 avgU = vec4(0.00, 0, 0, 0.00000001);
    vec4 dd = pixel(ch1, pos);
    range(i, -Rad, Rad) range(j, -Rad, Rad)
    {
        vec2 ij = vec2(i,j);
        vec4 data = texel(ch0, pos + ij);
        particle P0 = getParticle(data, pos + ij);

        vec2 x0 = P0.X; //update position
        //how much mass falls into this pixel
        vec2 dx = pos - x0;
        rho += 1.*vec4(P.V, P.M, P.I)*G(dx/1.5); 
       
        //local potential
        U += P0.M/(length(dx)+0.1);
        //local average velocity
        avgV += vec3(P0.V, 1.)*G(ij/1.)*P0.M; 
        
        //advected blurring, 
        //i.e. estimating where the past potential could have moved 
        vec3 pU = pixel(ch1, pos + ij - dd.xy*dt).xyw;
        avgU += vec4(pU, 1.)*G(ij/3.); //blurring field
    }
    
    //spacio-temporally blurred velocity
    rho.xy = mix(avgV.xy/avgV.z, avgU.xy/avgU.w, 0.95);
                  
    //spacio-temporally blurred gravitational potential
    rho.w = U + temporal_blurring*avgU.z/avgU.w;
                  
    fragColor = rho;
}