// Image (image) — Joe Gardner (Soul Pixar) by leon
// https://www.shadertoy.com/view/3ltyRB

// Joe Gardner from Soul (Pixar 2020)
//
// by Leon Denise 2020.12.31
// 
// thanks to Inigo Quilez, Dave Hoskins, Koltes, NuSan
// for sharing useful lines of code
//
// Licensed under hippie love conspiracy

bool ao_pass = false;

// volumes description
Volume map(vec3 pos)
{
    float shape = 100.;

    // global twist animation
    pos.zy *= rot(sin(pos.y*.2 + time) * .1 + .2);
    pos.yx *= rot(0.1 * sin(pos.y * .3 + time));
    vec3 p = pos;

    Volume ghost;
    ghost.mat = 0;
    ghost.density = 0.05;
    ghost.space = 0.12;
    
    Volume opaque;
    opaque.mat = 0;
    opaque.density = 1.;
    opaque.space = 0.;
    
    Volume hair;
    hair.mat = mat_eyebrows;
    hair.density = .2;
    hair.space = 0.1;
    
    Volume glass;
    glass.mat = mat_glass;
    glass.density = .15;
    glass.space = 0.1;

    // head
    ghost.dist = length(p*vec3(1,0.9,1))-1.0;
    ghost.dist = opSmoothUnion(ghost.dist, length(p-vec3(0,1.2,0))-0.55, 0.35);
    
    // mouth
    p.z += 1.3;
    p.yz *= rot(p.z * .5 + 0.1*sin(time+p.z*4.));
    shape = sdBox(p, vec3(1,0.01,1.));
    shape = max(shape, -length(pos.xz)+.99);
    ghost.dist = opSmoothSubtraction(shape, ghost.dist, 0.1);

    // hat
    p = pos-vec3(0,1.6,0);
    shape = sdRoundedCylinder(p + sin(p.z*4.)*.03, .4, .01, .01);
    shape = min(shape, sdCappedCone(p+.05*sin(p.z*8.), vec3(0,.5,0), vec3(0), .3, .445));
    ghost.dist = min(ghost.dist, shape);

    // eyes globes
    p = pos-vec3(0,1.,-.55);
    float s = sign(p.x);
    p.xz *= rot(-pos.x*1.);
    p.x = abs(p.x)-.15;
    opaque.dist = max(length(p*vec3(1,1.,1.3))-0.18, -ghost.dist);
    opaque.mat = mat_eye_globe;

    // eyebrows
    p -= vec3(0.05,.3,-.03);
    p.y -= 0.01*sin(time*3.);
    p.xy *= rot(0.2 + sin(pos.x * 2. + time)*.5);
    shape = sdBox(p, vec3(.15,0.02-p.x*.1,.03));
    hair.dist = shape;

    // body
    p = pos;
    ghost.dist = opSmoothUnion(ghost.dist, length(p+vec3(0,1.8,0))-.5, 0.6);

    // legs
    p.x = abs(p.x)-.2;
    p.z += 0.1*sin(p.x*4. + time);
    ghost.dist = opSmoothUnion(ghost.dist, sdVerticalCapsule(p+vec3(0,2.8,0), 0.6, 0.01+max(0.,p.y+3.)*0.3), 0.2);

    // arms
    p = pos;
    p.x = abs(p.x)-.4;
    p.xy *= rot(3.14/2.);
    p.x += pos.x*0.2*sin(pos.x + time);
    ghost.dist = opSmoothUnion(ghost.dist, sdVerticalCapsule(p+vec3(-1.5,0,0), 0.6, 0.2), 0.2);
    
    Volume volume = select(select(ghost, opaque), hair);

    // glass
    if (!ao_pass)
    {
        p = pos-vec3(0,1.,-.65);
        p.x = abs(p.x)-.18;
        glass.dist = sdRoundBox(p+vec3(-0.1,0,.1), vec3(0.2+p.y*0.1, 0.15+p.x*.05, 0.001), 0.05);
        glass.dist = max(glass.dist, -sdRoundBox(p+vec3(-0.1,0,.1), vec3(0.18+p.y*0.1, 0.14+p.x*.05, 0.1), 0.05));
        glass.dist = max(glass.dist, abs(p.z)-.1);
        volume = select(volume, glass);
    }

    return volume;
}

// NuSan
// https://www.shadertoy.com/view/3sBGzV
vec3 getNormal(vec3 p) {
	vec2 off=vec2(0.001,0);
	return normalize(map(p).dist-vec3(map(p-off.xyy).dist, map(p-off.yxy).dist, map(p-off.yyx).dist));
}

// Inigo Quilez
// https://www.shadertoy.com/view/Xds3zN
float getAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        Volume volume = map( pos + h*nor );
        float d = volume.dist;
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

void mainImage( out vec4 color, in vec2 coordinate )
{
    color = vec4(0,0,0,0);
    
    // coordinates
    vec2 uv = coordinate / iResolution.xy;
    vec2 p = 2.*(coordinate - 0.5 * iResolution.xy)/iResolution.y;
    
    // camera
    vec3 pos = vec3(-5,0,-8);
    
    // look at
    vec3 z = normalize(vec3(0,-0.3,0)-pos);
    vec3 x = normalize(cross(z, vec3(0,1,0)));
    vec3 y = normalize(cross(x, z));
    vec3 ray = normalize(z * 3. + x * p.x + y * p.y);
    
    // background gradient
    color.rgb += vec3(0.2235, 0.3804, 0.5882) * uv.y;
    
    // render variables
    float shade = 0.0;
    vec3 normal = vec3(0,1,0);
    float ao = 1.0;
    float rng = hash12(coordinate + time);
    const int count = 30;
    
    // raymarch iteration
    for (int index = 0; index < count; ++index)
    {
        Volume volume = map(pos);
        if (volume.dist < 0.01)
        {
            // sample ao when first hit
            if (shade < 0.001)
            {
                ao_pass = true;
                ao = getAO(pos, normal);
                ao_pass = false;
            }
            
            // accumulate fullness
            shade += volume.density;
            
            // step further on edge of volume
            normal = getNormal(pos);
            float fresnel = pow(dot(ray, normal)*.5+.5, 1.2);
            volume.dist = volume.space * fresnel;
            
            // coloring
            vec3 col = vec3(0);
            switch (volume.mat)
            {
                // eye globes color
                case mat_eye_globe:
                float globe = dot(normal, vec3(0,1,0))*0.5+0.5;
                vec3 look = vec3(0,0,-1);
                look.xz *= rot(sin(time)*0.2-.2);
                look.yz *= rot(sin(time*2.)*0.1+.5);
                float pupils = smoothstep(0.01, 0.0, dot(normal, look)-.95);
                col += vec3(1)*globe*pupils;
                break;

                // eyebrows color
                case mat_eyebrows:
                col += vec3(0.3451, 0.2314, 0.5255);
                break;

                // glass color
                case mat_glass:
                col += vec3(.2);
                break;

                // ghost color
                default:
                vec3 leftlight = normalize(vec3(6,-5,1));
                vec3 rightlight = normalize(vec3(-3,1,1));
                vec3 frontlight = normalize(vec3(-1,1,-2));
                vec3 blue = vec3(0,0,1) * pow(dot(normal, leftlight)*0.5+0.5, 0.2);
                vec3 green = vec3(0,1,0) * pow(dot(normal, frontlight)*0.5+0.5, 2.);
                vec3 red = vec3(0.8941, 0.2039, 0.0824) * pow(dot(normal, rightlight)*0.5+0.5, .5);
                col += blue + green + red;
                col *= ao*0.5+0.3;
                break;
            }
            
            // accumulate color
            color.rgb += col * volume.density;
        }
        
        // stop when fullness reached
        if (shade >=  1.0)
        {
            break;
        }
        
        // dithering trick inspired by Duke
        volume.dist *= 0.9 + 0.1 * rng;
        
        // keep marching
        pos += ray * volume.dist;
    }
}