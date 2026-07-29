// Buffer C (buffer) — Quake / Introduction by adx
// https://www.shadertoy.com/view/lsKfWd

////////////////////////////////////////////////////////////////
// Buffer C:
// - lightmap accumulation and post-processing
// - UI textures
// - font glyphs
////////////////////////////////////////////////////////////////

// config.cfg //////////////////////////////////////////////////

const int TEXTURE_AA = 4;

////////////////////////////////////////////////////////////////
// Implementation //////////////////////////////////////////////
////////////////////////////////////////////////////////////////

#define ALWAYS_REFRESH_TEXTURES		0
#define DEBUG_TEXT_MASK				0

////////////////////////////////////////////////////////////////

const int
    NUM_DILATE_PASSES				= 1,
    NUM_BLUR_PASSES					= 0,
    NUM_POSTPROCESS_PASSES			= NUM_DILATE_PASSES + NUM_BLUR_PASSES;

#define USE_DIAGONALS				0

void accumulate(inout LightmapSample total, LightmapSample new)
{
    total.values = (total.values*total.weights + new.values*new.weights) / max(total.weights + new.weights, 1.);
    total.weights += new.weights;
}

void accumulate(inout LightmapSample total, vec4 encoded_new)
{
    accumulate(total, decode_lightmap_sample(encoded_new));
}

bool postprocess(inout vec4 fragColor, ivec2 address)
{
	if (iFrame < NUM_LIGHTMAP_FRAMES)
        return false;

    int pass = iFrame - NUM_LIGHTMAP_FRAMES;
    bool blur = pass >= NUM_DILATE_PASSES;

    const ivec2 MAX_COORD = ivec2(LIGHTMAP_SIZE.x - 1u, LIGHTMAP_SIZE.y/4u - 1u);
    vec4
        N  = texelFetch(iChannel1, clamp(address + ivec2( 0, 1), ivec2(0), MAX_COORD), 0),
        S  = texelFetch(iChannel1, clamp(address + ivec2( 0,-1), ivec2(0), MAX_COORD), 0),
        E  = texelFetch(iChannel1, clamp(address + ivec2( 1, 0), ivec2(0), MAX_COORD), 0),
        W  = texelFetch(iChannel1, clamp(address + ivec2(-1, 0), ivec2(0), MAX_COORD), 0),
        NE = texelFetch(iChannel1, clamp(address + ivec2( 1, 1), ivec2(0), MAX_COORD), 0),
        SE = texelFetch(iChannel1, clamp(address + ivec2( 1,-1), ivec2(0), MAX_COORD), 0),
        NW = texelFetch(iChannel1, clamp(address + ivec2(-1, 0), ivec2(0), MAX_COORD), 0),
        SW = texelFetch(iChannel1, clamp(address + ivec2(-1, 0), ivec2(0), MAX_COORD), 0);

    N  = vec4(fragColor.yzw, N.x);
    NE = vec4(E.yzw, NE.x);
    NW = vec4(W.yzw, NW.x);
    S  = vec4(S .w, fragColor.xyz);
    SE = vec4(SE.w, E.xyz);
    SW = vec4(SW.w, W.xyz);

    LightmapSample
        current = decode_lightmap_sample(fragColor),
        total = empty_lightmap_sample();

    accumulate(total, N);
    accumulate(total, S);
    accumulate(total, E);
    accumulate(total, W);
#if USE_DIAGONALS
    accumulate(total, NE);
    accumulate(total, NW);
    accumulate(total, SE);
    accumulate(total, SW);
#endif

    if (blur)
    {
        accumulate(total, current);
	    fragColor = encode(total);
    }
    else
    {
        vec4 neighbors = encode(total);
        fragColor = mix(fragColor, neighbors, lessThanEqual(current.weights, vec4(0)));
    }
    
    return true;
}

void accumulate_lightmap(inout vec4 fragColor, ivec2 address)
{
    if (uint(address.x) >= LIGHTMAP_SIZE.x || uint(address.y) >= LIGHTMAP_SIZE.y/4u)
        return;
    if (iFrame >= NUM_LIGHTMAP_FRAMES + NUM_POSTPROCESS_PASSES)
        return;

    if (postprocess(fragColor, address))
        return;
    
    int region = iFrame & 3;
    int base_y = region * int(LIGHTMAP_SIZE.y/16u);
    if (uint(address.y - base_y) >= LIGHTMAP_SIZE.y/16u)
        return;

    address.y = (address.y - base_y) * 4;
    vec4 light = vec4
        (
            texelFetch(iChannel0, address + ivec2(0,0), 0).x,
            texelFetch(iChannel0, address + ivec2(0,1), 0).x,
            texelFetch(iChannel0, address + ivec2(0,2), 0).x,
            texelFetch(iChannel0, address + ivec2(0,3), 0).x
		);

    vec4 weights = step(vec4(0), light);
    vec4 values = max(light, 0.);
    
    LightmapSample total = decode_lightmap_sample(fragColor);
    accumulate(total, LightmapSample(weights, values));
    fragColor = encode(total);
}

// Options text ////////////////////////////////////////////////

float sdf_Options(vec2 p)
{
    const float
        OFFSET_P = 15.,
        OFFSET_T = 35.,
        OFFSET_I = 53.,
        OFFSET_O = 63.,
        OFFSET_N = 81.,
        OFFSET_S = 98.;

    vec4 box = vec4(0);
    vec3 disk1 = vec3(0), disk2 = vec3(0,0,1), disk3 = vec3(0,0,2);
    float vline_x = 1e3, vline_thickness = 2.5;
    float max_ydist = 6.;
    
    p.x -= 15.;
    
	#define MIRROR(compare, midpoint, value) (compare <= midpoint ? value : midpoint*2.-value)
    
    if (p.x <= 20.)
    {
    	max_ydist = 7.;
        disk1 = vec3(MIRROR(p.x, 8.5, 7.5), 11.5, 8.);
        disk2 = vec3(MIRROR(p.x, 8.5, 12.), 11.5, 9.);
    }
    else if (p.x <= OFFSET_T)
    {
        p.x -= OFFSET_P;
        vline_x = 9.;
        disk1 = vec3(14.5, 13.5, 4.);
        disk2 = vec3(10.5, 13.5, 5.);
    }
    else if (p.x <= OFFSET_I)
    {
        const float
            BOX_X = 4., BOX_Y = 15.5, BOX_SIZE = 1.5,
            X3 = BOX_X+BOX_SIZE, Y3 = BOX_Y-BOX_SIZE, R3 = BOX_SIZE * 2.;
        
        p.x -= OFFSET_T;
        disk3 = vec3(MIRROR(p.x, 9., X3), Y3, R3);
        box   = vec4(MIRROR(p.x, 9., BOX_X), BOX_Y, BOX_SIZE, BOX_SIZE);
        vline_x = 9.;
    }
    else if (p.x <= OFFSET_O)
    {
        vline_x = OFFSET_I + 4.5;
    }
    else if (p.x <= OFFSET_N)
    {
        p.x -= OFFSET_O;
        disk1 = vec3(MIRROR(p.x, 9., 8.), 11.5, 7.);
        disk2 = vec3(MIRROR(p.x, 9., 12.), 11.5, 8.);
    }
    else if (p.x <= OFFSET_S)
    {
        p.x -= OFFSET_N;
        vline_x = p.x < 9. ? 4.5 : 15.;
        vline_thickness = 2.;
        box = vec4(clamp(p.x, 5., 14.) * vec2(1, -.75) + vec2(0, 18), 1., 2.);
    }
    else
    {
        const float
            X1 = 8., Y1 = 14., R1 = 3.5,
            X2 = 9.5, Y2 = 15.5, R2 = 2.5,
            BOX_X = 6., BOX_Y = 7., BOX_SIZE = 1.5,
            X3 = BOX_X+BOX_SIZE, Y3 = BOX_Y+BOX_SIZE, R3 = BOX_SIZE * 2.;
        
        p.x -= OFFSET_S;
        // TODO: simplify
        if (p.x < 9.)
        {
            disk1 = vec3(X1, Y1, R1);
            disk2 = vec3(X2, Y2, R2);
            disk3 = vec3(X3, Y3, R3);
            box   = vec4(BOX_X, BOX_Y, BOX_SIZE, BOX_SIZE);
        }
        else
        {
            disk1 = vec3(18. - X1, 23. - Y1, R1);
            disk2 = vec3(18. - X2, 23. - Y2, R2);
            disk3 = vec3(18. - X3, 23. - Y3, R3);
            box   = vec4(18. - BOX_X, 23. - BOX_Y, BOX_SIZE, BOX_SIZE);
        }
    }
    
    #undef MIRROR
    
    float dist;
    dist = sdf_disk(p, disk1.xy, disk1.z);
    dist = sdf_exclude(dist, sdf_disk(p, disk2.xy, disk2.z));
    
    dist = sdf_union(dist, sdf_seriffed_box(p, vec2(vline_x, 5.5), vec2(vline_thickness, 12.), vec2(1,.2), vec2(1,.2)));
                       
	float d2 = sdf_centered_box(p, box.xy, box.zw);
    d2 = sdf_exclude(d2, sdf_disk(p, disk3.xy, disk3.z));
    dist = sdf_union(dist, d2);
    dist = sdf_exclude(dist, max_ydist - abs(p.y - 11.5));
   
    return dist;
}

vec2 engraved_Options(vec2 uv)
{
    const float EPS = .1, BEVEL_SIZE = 1.;
    vec3 sdf;
    for (int i=NO_UNROLL(0); i<3; ++i)
    {
        vec2 uv2 = uv;
        if (i != 2)
            uv2[i] += EPS;
        sdf[i] = sdf_Options(uv2);
    }
    vec2 gradient = safe_normalize(sdf.xy - sdf.z);
    float mask = sdf_mask(sdf.z, 1.);
    float bevel = clamp(1. + sdf.z/BEVEL_SIZE, 0., 1.);
    float intensity = .4 + sqr(bevel) * dot(gradient, vec2(0, -1.1));
    intensity = mix(1.5, intensity, mask);
    mask = sdf_mask(sdf.z - 1., 1.);
    return vec2(intensity, mask);
}

// QUAKE text //////////////////////////////////////////////////

float sdf_QUAKE(vec2 uv)
{
    uv /= 28.;
    uv.y -= 4.;
    uv.x -= .0625;
    
    float sdf						   = sdf_Q_top(uv);
    uv.y += .875;   sdf = sdf_union(sdf, sdf_U(uv));
    uv.y += .75;	sdf = sdf_union(sdf, sdf_A(uv));
    uv.y += .75;	sdf = sdf_union(sdf, sdf_K(uv - vec2(.2, 0)));
    uv.y += .8125;	sdf = sdf_union(sdf, sdf_E(uv));
    
    sdf *= 28.;
    uv += sin(uv.yx * TAU) * (5./28.);
    sdf = sdf_union(sdf, 28. * (.75 - around(.3, .25, smooth_weyl_noise(2. + uv * 3.24))));
    return sdf_exclude(sdf, (uv.y - .15) * 28.);
}

vec2 engraved_QUAKE(vec2 uv)
{
    const float EPS = .1, BEVEL_SIZE = 2.;
    vec3 sdf;
    for (int i=NO_UNROLL(0); i<3; ++i)
    {
        vec2 uv2 = uv;
        if (i != 2)
            uv2[i] += EPS;
        sdf[i] = sdf_QUAKE(uv2);
    }
    vec2 gradient = safe_normalize(sdf.xy - sdf.z);
    float mask = sdf_mask(sdf.z, 1.);
    float bevel = clamp(1. + sdf.z/BEVEL_SIZE, 0., 1.);
    float intensity = .75 + sqr(bevel) * dot(gradient, vec2(0, -3));
    intensity = mix(1.5, intensity, mask);
    mask = sdf_mask(sdf.z - 1., 1.);
    return vec2(intensity, mask * .7);
}

////////////////////////////////////////////////////////////////

void generate_ui_textures(inout vec4 fragColor, vec2 fragCoord)
{
#if !ALWAYS_REFRESH_TEXTURES
    if (iFrame != 0)
        return;
#endif
    
    const int
		UI_TEXTURE_OPTIONS		= 0,
		UI_TEXTURE_QUAKE_ID		= 1,
        AA_SAMPLES				= clamp(TEXTURE_AA, 1, 128);
    int id = -1;

    vec2 texture_size, bevel_range;
    vec3 base_color;
    
    if (is_inside(fragCoord, ADDR2_RANGE_TEX_OPTIONS) > 0.)
    {
        id = UI_TEXTURE_OPTIONS;
        fragCoord -= ADDR2_RANGE_TEX_OPTIONS.xy;
        texture_size = ADDR2_RANGE_TEX_OPTIONS.zw;
        bevel_range = vec2(1.7, 3.9);
        base_color = vec3(.32, .21, .13);
    }

    if (is_inside(fragCoord, ADDR2_RANGE_TEX_QUAKE) > 0.)
    {
        id = UI_TEXTURE_QUAKE_ID;
        fragCoord -= ADDR2_RANGE_TEX_QUAKE.xy;
        fragCoord = fragCoord.yx;
        texture_size = ADDR2_RANGE_TEX_QUAKE.wz;
        bevel_range = vec2(2.7, 4.9);
        base_color = vec3(.16, .12, .07);
    }
    
    if (id == -1)
        return;

    vec2 base_coord = floor(fragCoord);
    float grain = random(base_coord);

    vec3 accum = vec3(0);
    for (int i=NO_UNROLL(0); i<AA_SAMPLES; ++i)
    {
        fragCoord = base_coord + hammersley(i, AA_SAMPLES);
        vec2 uv = fragCoord / min_component(texture_size);

        float base = weyl_turb(3.5 + uv * 3.1, .7, 1.83);
        if (id == UI_TEXTURE_QUAKE_ID && fragCoord.y < 26. + base * 4. && fragCoord.y > 3. - base * 2.)
        {
            base = mix(base, grain, .0625);
            fragColor.rgb = vec3(.62, .30, .19) * linear_step(.375, .85, base);
            vec2 logo_uv = (uv - .5) * vec2(1.05, 1.5) + .5;
            logo_uv.y += .0625;
            float logo_sdf = sdf_id(logo_uv);
            float logo = sdf_mask(logo_sdf + .25/44., 1.5/44.);
            fragColor.rgb *= 1. - sdf_mask(logo_sdf - 2./44., 1.5/44.);
            fragColor.rgb = mix(fragColor.rgb, vec3(.68, .39, .17) * mix(.5, 1.25, base), logo);
        }
        else
        {
            base = mix(base, grain, .3);
            fragColor.rgb = base_color * mix(.75, 1.25, smoothen(base));
        }

        float bevel_size = mix(bevel_range.x, bevel_range.y, smooth_weyl_noise(uv * 9.));
        vec2 mins = vec2(bevel_size), maxs = texture_size - bevel_size;
        vec2 duv = (fragCoord - clamp(fragCoord, mins, maxs)) * (1./bevel_size);
        float d = mix(length(duv), max_component(abs(duv)), .75);
        fragColor.rgb *= clamp(1.4 - d*mix(1., 1.75, sqr(base)), 0., 1.);
        float highlight = 
            (id == UI_TEXTURE_OPTIONS) ?
            	max(0., duv.y) * step(d, .55) :
        		sqr(sqr(1. + duv.y)) * around(.4, .4, d) * .35;
        fragColor.rgb *= 1. + mix(.75, 2.25, base) * highlight;

        if (DEBUG_TEXT_MASK != 0)
        {
            float sdf = (id == UI_TEXTURE_OPTIONS) ? sdf_Options(fragCoord) : sdf_QUAKE(fragCoord);
            fragColor.rgb = vec3(sdf_mask(sdf, 1.));
            accum += fragColor.rgb;
            continue;
        }

        vec2 engrave = (id == UI_TEXTURE_OPTIONS) ? engraved_Options(fragCoord) : engraved_QUAKE(fragCoord);
        fragColor.rgb *= mix(1., engrave.x, engrave.y);

        if (id == UI_TEXTURE_OPTIONS)
        {
            vec2 side = sign(fragCoord - texture_size * .5); // keep track of side before folding to 'unmirror' light direction
            fragCoord = min(fragCoord, texture_size - fragCoord);
            vec2 nail = add_knob(fragCoord, 1., vec2(6), 1.25, side * vec2(0, -1));
            fragColor.rgb *= mix(clamp(length(fragCoord - vec2(6, 6.+2.*side.y))/2.5, 0., 1.), 1., .25);
            nail.x += pow(abs(nail.x), 16.) * .25;
            fragColor.rgb = mix(fragColor.rgb, vec3(.7, .54, .43) * nail.x, nail.y * .75);
        }

        accum += fragColor.rgb;
    }
    fragColor.rgb = accum * (1./float(AA_SAMPLES));
}

////////////////////////////////////////////////////////////////

const int NUM_GLYPHS = 56;

WRAP(FontBitmap,FONT_BITMAP,int,NUM_GLYPHS*2)(0,0,0x7c2c3810,25190,0x663e663e,15974,0x606467c,31814,0x6666663e,15974,0x61e467e,
31814,0x61e467c,1542,0x7303233e,1062451,0x637f6363,25443,404232216,6168,808464432,792624,991638339,17251,0x6060606,32326,
0x6f7f7763,26989,0x5f4f4743,6320505,0x6363633e,15971,0x6666663e,1598,0x6b436322,526398,0x663e663e,17990,0x603c067c,15970,
404249214,530456,0x66666666,15462,0x3e367763,2076,0x7f7b5b5b,8758,941379271,58230,0xc1c3462,3084,473461374,32334,0x66663c00,
15462,404233216,6168,0x7c403e00,32258,945831424,536672,909651968,12415,0x3c043c00,536672,0x3e061c00,15462,541097472,12336,
0x3c663c00,15462,0x7c663c00,536672,0x7e181800,6168,63<<25,0,0xc183060,774,0,1542,0,198150,1579008,6168,404232216,6144,406347838,
6144,0x3f3f3f3f,16191,0xc0c1830,3151884,808458252,792624,0,32256,0xc0c0c3c,15372,808464444,15408,0xc183000,6303768,806882304,
396312,0x83e7f7f,8355646,0x7f7f3e1c,67640382,0x3f3f0f03,783));

int glyph_bit(uint glyph, int index)
{
    if (glyph >= uint(NUM_GLYPHS))
        return 0;
    uint data = uint(FONT_BITMAP.data[(glyph<<1) + uint(index>=32)]);
    return int(uint(data >> (index & 31)) & 1u);
}

vec4 glyph_color(uint glyph, ivec2 pixel, float variation)
{
    pixel &= 7;
    pixel.y = 7 - pixel.y;
    int bit_index = pixel.x + (pixel.y << 3);
    int bit = glyph_bit(glyph, bit_index);
    int shadow_bit = min(pixel.x, pixel.y) > 0 ? glyph_bit(glyph, bit_index - 9) : 0;
    return vec4(vec3(bit > 0 ? variation : .1875), float(bit|shadow_bit));
}

void bake_font(inout vec4 fragColor, vec2 fragCoord)
{
#if !ALWAYS_REFRESH_TEXTURES
    if (iFrame != 0)
        return;
#endif

    ivec2 addr = ivec2(floor(fragCoord - ADDR2_RANGE_FONT.xy));
    if (any(greaterThanEqual(uvec2(addr), uvec2(ADDR2_RANGE_FONT.zw))))
        return;
    
    const int GLYPHS_PER_LINE = int(ADDR2_RANGE_FONT.z) >> 3;
    
    int glyph = (addr.y >> 3) * GLYPHS_PER_LINE + (addr.x >> 3);
    float variation = mix(.625, 1., random(fragCoord));
    fragColor = glyph_color(uint(glyph), addr, variation);
}

////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    if (is_inside(fragCoord, ADDR2_RANGE_PARAM_BOUNDS) < 0.)
        DISCARD;

    ivec2 address = ivec2(fragCoord);
    fragColor = (iFrame == 0) ? vec4(0) : texelFetch(iChannel1, address, 0);
    
    accumulate_lightmap		(fragColor, address);
    generate_ui_textures	(fragColor, fragCoord);
    bake_font				(fragColor, fragCoord);
}
