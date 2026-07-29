// Image (image) — Bricks [300] by Xor
// https://www.shadertoy.com/view/cdKBDy

/*
    "Bricks" by @XorDev
    
    I wanted to try the double mod pattern (shadertoy.com/view/dsyBDy) in 3D.

    X: X.com/XorDev/status/1718731726434824357
    twigl: twigl.app/?ol=true&ss=-NhxByN14idHvVurpv8Q
    
    <300 chars playlist: shadertoy.com/playlist/fXlGDN
    -5 Thanks to FabriceNeyret2
*/


void mainImage( out vec4 O, vec2 I)
{
    int i;
    for(vec2 c = iResolution.xy, 
             u = (c*.5 - roundEven(I)) / c.y, 
             p, z = p+2e1
           ; i = int(p)^int(p.y)^int(z), z.x < 1e2 && i%93%43 < 32
           ; p = iTime*vec2(2,9) - u*z 
       )
        z += min( fract(-z), min( c = fract(p*sign(u)) / abs(u),c.yx) ) + 2e-5,
        O = ( 1e2 - z.x ) * ( 2. - cos(vec4(i/=3,i+5,i+4,0)) );
    O /= 2e2 + fwidth(O.g)*5e2;
}
//Original [300]
/*
void mainImage( out vec4 O, vec2 I)
{
    //Voxel index for coloring
    int i;
    //Resolution, rounded/centered screen coords, xy pos, z (vec2 for convenience), closest plane
    for(vec2 c=iResolution.xy, u=(roundEven(I)-c*.5)/c.y, p, z=p+2e1;
            //Loop to a max distance of 100 or when you hit something (xor + double mod technique)
            z.x<1e2 && (i=int(p)^int(p.y)^int(z))%93%43<32; //Try playing with these numbers!
            //Compute next xy pos with time offset
            p=u*z+iTime*vec2(2,9))

        //Compute the distance to the nearest x and y planes
        c=fract(-p*sign(u))/abs(u),
        //March to next nearest x, y and z plane
        z+=min(min(c,c.yx), fract(-z))+2e-5,
        //Colorize with depth and voxel index
        O.rgb=(1e2-z.x)*(2.-cos(vec3(i/=3,i+5,i+4)));
    
    //Dampen and shade
    O/=2e2+fwidth(O.g)*5e2;
}
*/