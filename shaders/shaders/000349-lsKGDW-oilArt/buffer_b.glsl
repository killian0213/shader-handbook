// Buffer B (buffer) — oilArt by and
// https://www.shadertoy.com/view/lsKGDW

// oilArt - Buf A/B
//
// Main audio decoder.
// Buf B is redundant and runs the same code as Buf A but reads slightly delayed
// audio stream to increase reliability when FPS drops or high sample rate is used.
//
// Audio stream is made up of 160 samples long packets that come in buckets of 6
// packets in a row needed to have stable frequency content within ~1000 sample wide
// window to minimize frequency masking during mp3 compression. Though SoundCloud
// is streaming 128 kBps mp3 @ 44.1 kHz, in reality its closer to FM radio quality
// with 32 kHz sample rate. Thus out of 80 available frequency bands only 61 are used.
// 
// Shadertoy reads content of web audio analyzer node and clamps input buffer to 512.
// Having 6x packet redundancy helps to remedy that as well. Additionally, some
// browsers like Firefox do some funky stuff to that buffer applying some pinching
// effect around some buffer boundaries once in a while making some packets unusable.
//
// Out of 61 frequency bands fundamental (carrier) is used for packet location,
// 4 bands are used to encode block location within the image using quantized phase,
// Then 48 DCT luminance coefficients are interleaved with 8 chrominance coefficients
// representing final 496x280 image plane that gets processed further.
//
// Currently, Shadertoy doesn't provide any access to current web audio sample rate.
// iSampleRate doesn't work correctly. To solve that a pilot tone is provided
// in the beginning of the stream, its period is measured and standard sample rates
// are deduced. Supported rates are 44.1, 48, 88.2, 96 kHz.
//
// The best case is 44.1 kHz @ 60 fps. When fps drops or sample rate increased then
// we will receive fewer packets and more sparsely. That takes more stream runs
// for image to form. Meanwhile, missing block reconstruction is performed.
//
// Created by Dmitry Andreev - and'2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.14159265

#define BUFFER_SIZE 500
#define PACKET_SIZE 160
#define RESAMPLE_WINDOW_RADIUS 7

#define DO_MINIMIZE_ERROR 1

// Fourier transform utilities.

struct FFTBand
{
    vec2 di;
    vec2 df;
    vec2 f;
};

FFTBand FFTBand_create(const float n, const int fft_size)
{
    FFTBand band;

    float fi = (float(n) / float(fft_size / 2)) * float(fft_size) * 0.5;
    float angle = 2.0 * PI * fi / float(fft_size);

    band.di = vec2(cos(angle), sin(angle));
    band.df = vec2(1.0 / float(fft_size), 0.0);
    band.f  = vec2(0.0, 0.0);

    return band;
}

void FFTBand_update(inout FFTBand band, float value)
{
    band.f += band.df * value;
    band.df = vec2(
        band.df.x * band.di.x - band.df.y * band.di.y,
        band.df.y * band.di.x + band.df.x * band.di.y
        );
}

float FFTBand_amplitude(FFTBand band)
{
    return length(band.f);
}

float FFTBand_angle(FFTBand band)
{
    return degrees(atan(band.f.y, band.f.x));
}

// Additional helpers.

float decodePhase(float x)
{
    return mod(111.0 - x, 360.0) - 20.0;
}

float angDiff(float a, float b)
{
    return mod(a - b + 180.0, 360.0) - 180.0;
}

float windowedSinc(float x, float radius)
{
    float w = abs(x) < 0.001 ? 1.0 : sin(PI * x) / (PI * x);

    // Zero-phase Hamming window
    w *= 0.54 + 0.46 * cos(PI * x / radius);

    return w;
}

vec4 loadSelf(int x, int y)
{
    return textureLod(iChannel1, (vec2(x, y) + 0.5) / iChannelResolution[1].xy, 0.0);
}

//

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Discard everything outside of working area
    // to increase performance.

    if (any(greaterThan(fragCoord, vec2(500, 280-60)))) discard;

    vec2 pos = floor(fragCoord);
    vec2 last_pos = pos;
    bool is_expecting_data  = iChannelTime[0] > 1.5;
    bool is_expecting_pilot = iChannelTime[0] > 1.1 && iChannelTime[0] < 1.5;

    // Propagate decoded data down the pipeline during reduction.

    last_pos.y -=
           (56.0 <= pos.y && pos.y < 56.0 + 16.0)
        || (40.0 <= pos.y && pos.y < 40.0 + 16.0)
        || (24.0 <= pos.y && pos.y < 24.0 + 16.0)
        ?
        16.0 : 0.0;

    vec4 last_color = loadSelf(int(last_pos.x), int(last_pos.y));

    fragColor = last_color;

    // Read detected sample rate.

    float sample_rate_index = floor(0.5 + loadSelf(0, 1).w);
    float sample_rate_khz = 44.1;

    sample_rate_khz = sample_rate_index == 2.0 ? 48.0 : sample_rate_khz;
    sample_rate_khz = sample_rate_index == 3.0 ? 88.2 : sample_rate_khz;
    sample_rate_khz = sample_rate_index == 4.0 ? 96.0 : sample_rate_khz;

    // Downsample incoming sound wave by reconstructing
    // continuous signal using windowed Sinc kernel
    // and resampling @ 44.1 kHz.
    // Supported rates are 44.1, 48, 88.2, 96 kHz.

    if (pos.y == 0.0
        // Bypass FFT during pilot and inject wave directly into phase channel.
        || (pos.y == 8.0 && is_expecting_pilot)
        )
    {
        float k = pos.x;

        // Do not resample during pilot as sample rate not yet known.

        if (is_expecting_data)
        {
            k *= sample_rate_khz / 44.1;
        }

        // Windowed Sinc reconstruction and resampling.

        float v = 0.0;
        float total_weight = 0.0;
        float f = fract(k);

        for (int n = -RESAMPLE_WINDOW_RADIUS; n <= RESAMPLE_WINDOW_RADIUS; n++)
        {
            float fn = float(n);
            float weight = windowedSinc(fn - f, float(RESAMPLE_WINDOW_RADIUS));

            float source_wave =
                texture(iChannel0, vec2((floor(k) + fn + 0.5) / iChannelResolution[0].x, 0.75)).x;

            v += weight * source_wave;
            total_weight += weight;
        }

        v /= total_weight;

        // Clear area outside of buffer with virtual zero.

        if (k >= float(BUFFER_SIZE)) v = 128.0 / 255.0;

        fragColor = vec4(v * 2.0 - 1.0);
    }

    // Perform Fourier transform and convert 160 samples @ 44.1 kHz
    // into 61 complex coefficients of orthogonal bases.
    // Though SoundCloud is streaming 128 kBps MP3 @ 44.1 kHz
    // in reality audio is cutoff at around 16.something kHz.
    // Encoder is aware of that and only 61 out of 80 bases are used.

    if (8.0 <= pos.y && pos.y < 8.0 + 16.0)
    {
        int i = int(pos.x);
        int line_index = int(pos.y - 8.0);

        //  0     : fundamental.xy, dcY.xy
        //  1     : block_pos.xy, 0, 0
        //  2..13 : 48 DCT luma   coefficients including DC
        // 14..15 :  8 DCT chroma coefficients

        FFTBand coeff[4];
        vec4    ic = vec4(0);

        if (line_index ==  0) ic = vec4( 1, 6, 0, 0);
        if (line_index ==  1) ic = vec4( 2, 3, 4, 5);
        if (line_index == 14) ic = vec4( 6, 7,14,15) + 6.0;
        if (line_index == 15) ic = vec4(22,23,30,31) + 6.0;

        if (2 <= line_index && line_index <= 13)
        {
            float icoeff4 = float(line_index - 2);
            vec4  idx = icoeff4 * 4.0 + vec4(0, 1, 2, 3);

            // Chrominance coefficients are interleaved with
            // luminance for safe failure.
            // Build indexes jumping over chroma when needed.

            ic = mix(idx + 8.0, mod(idx, vec4(6)) + 8.0 * floor(idx / vec4(6.0)), vec4(lessThan(idx, vec4(24)))) + 6.0;
        }

        coeff[0] = FFTBand_create(ic.x, PACKET_SIZE);
        coeff[1] = FFTBand_create(ic.y, PACKET_SIZE);
        coeff[2] = FFTBand_create(ic.z, PACKET_SIZE);
        coeff[3] = FFTBand_create(ic.w, PACKET_SIZE);

        for (int k = 0; k < PACKET_SIZE; k++)
        {
            float v = loadSelf(i + k, 0).w;

            FFTBand_update(coeff[0], v);
            FFTBand_update(coeff[1], v);
            FFTBand_update(coeff[2], v);
            FFTBand_update(coeff[3], v);
        }

        float cf[4];

        for (int k = 0; k < 4; k++)
        {
            // Coefficient sign is encoded in phase.

            float s = FFTBand_angle(coeff[k]) >= 0.0 ? 1.0 : -1.0;
            cf[k] = s * FFTBand_amplitude(coeff[k]) * 127.0;
        }

        if (line_index == 2)
        {
            // DC coefficient is encoded with reduced amplitude
            // to minimize frequency masking during mp3 encoding
            // and interfering with meta data.

            cf[0] *= 2.0;
        }

        fragColor = vec4(cf[0], cf[1], cf[2], cf[3]);

        if (line_index == 0)
        {
            // Store fundamental and DC components as raw complex numbers
            // required by packet locator.

            fragColor = vec4(coeff[0].f.xy, coeff[1].f.xy);
        }

        if (line_index == 1)
        {
            // Decode metadata.
            // Amplitude of a low frequency signal may be altered
            // by mp3 compression quite a lot and is unreliable.
            // However constant amplitude is less prone to that.
            // Use quantized phase instead to encode
            // low and high parts of block positions.

            vec4 phi = vec4(
                decodePhase(FFTBand_angle(coeff[0])),
                decodePhase(FFTBand_angle(coeff[1])),
                decodePhase(FFTBand_angle(coeff[2])),
                decodePhase(FFTBand_angle(coeff[3]))
                );
            vec4 amp = vec4(
                FFTBand_amplitude(coeff[0]),
                FFTBand_amplitude(coeff[1]),
                FFTBand_amplitude(coeff[2]),
                FFTBand_amplitude(coeff[3])
                );

            ivec4 op = ivec4(0.425 + (phi / 45.0));
            vec2  fp = vec2(op.xz * 8 + op.yw) / 64.0;

            // Amplitudes must be in expected range.

            const vec4 lvl = vec4(3.7 / 127.0);
            const vec4 th  = vec4(0.3 / 127.0);

            bool is_amp_ok = all(lessThan(abs(amp - lvl), th));
            fp = is_amp_ok ? fp : vec2(1000);

            fragColor = vec4(fp.xy, 0, 0);
        }

        if (i >= BUFFER_SIZE - PACKET_SIZE) fragColor = vec4(0);
    }

    // Locate packets in processed data.

    if (pos.y == 72.0)
    {
        int i = int(pos.x);

        fragColor = vec4(0);

        vec4 prev = loadSelf(i - 1, 8);
        vec4 curr = loadSelf(i    , 8);
        vec4 next = loadSelf(i + 1, 8);

        // Check if we are above expected noise level.

        bool has_carrier = length(curr.xy) > (100.0 / 32767.0);
        bool has_dc =
               length(curr.zw) > (120.0 / 32767.0)
            && length(prev.zw) > (120.0 / 32767.0)
            && length(next.zw) > (120.0 / 32767.0);

        // Use fundamental frequency for coarse synchronisation.
        // It is the lowerest frequency in the stream
        // and phase shifts may occur after mp3 compression.

        if (prev.x * curr.x <= 0.0 // carrier phase crosses 90 degree point
            && ((prev.x <= curr.x  // it's rising
                 && curr.x >= 0.0) // and it's 90 but not -90 degrees.
                || is_expecting_pilot)
            )
        {
            if (has_carrier)
            {
                bool  is_valid = true;
                float max_err = 16.0;

                // Use phase of DC wave for location refinement.

                float m = has_dc ? 99.0    : 45.0;
                vec2  p = has_dc ? prev.zw : prev.xy;
                vec2  c = has_dc ? curr.zw : curr.xy;
                vec2  n = has_dc ? next.zw : next.xy;

                float l2 = degrees(atan(p.y, p.x));
                float c2 = degrees(atan(c.y, c.x));
                float r2 = degrees(atan(n.y, n.x));

                float l2_0 = abs(angDiff(l2, 90.0));
                float c2_0 = abs(angDiff(c2, 90.0));
                float r2_0 = abs(angDiff(r2, 90.0));
                float l2_1 = abs(angDiff(l2,-90.0));
                float c2_1 = abs(angDiff(c2,-90.0));
                float r2_1 = abs(angDiff(r2,-90.0));

                m = min(min(m, min(l2_0, l2_1)), min(min(c2_0, c2_1), min(r2_0, r2_1)));

                int delta = 0;

                if (m == l2_0 || m == l2_1) delta = -1;
                if (m == r2_0 || m == r2_1) delta = +1;

                if (has_dc)
                {
                    is_valid = m < max_err;
                }
                else
                {
                    // Even though DC is bellow threshold and can't be used for refinement,
                    // it can still be used for error estimation.

                    c = (delta == -1 ? prev : delta == 1 ? next : curr).zw;

                    c2 = degrees(atan(c.y, c.x));
                    c2_0 = abs(angDiff(c2, 90.0));
                    c2_1 = abs(angDiff(c2,-90.0));

                    // Overestimate by 20% so that block that has_dc can override it.
                    m = min(c2_0, c2_1) * 1.2;
                }

                float err = 0.001 + m;

                if (is_expecting_data)
                {
                    // Additional validation to account for resampling.

                    is_valid = is_valid && (
                        pos.x > float(RESAMPLE_WINDOW_RADIUS + 1)
                        && pos.x < (float(BUFFER_SIZE) - float(PACKET_SIZE) * sample_rate_khz / 44.1
                            - float(RESAMPLE_WINDOW_RADIUS + 1))
                        );
                }

                fragColor = is_valid ? vec4(10.0 + float(delta), err, 0, 0) : fragColor;
            }

            if (is_expecting_pilot && pos.x < float(BUFFER_SIZE - PACKET_SIZE))
            {
                fragColor = vec4(10, 0, 0, 0);
            }
        }
    }

    // Transform location array into array of packet locations
    // by reduction over multiple frames.

    int px = 0;
    int py = 74;

    if (pos.y == 74.0) py = 73, px = int(pos.x);
    if (pos.y == 73.0) py = 72, px = int(pos.x);

    vec2 bp[8];
    {
        // bp[] is not really an array. Can't write to it in a loop. Unroll.
        #define IBP(k)IBP1(k)IBP2(k)IBP3(k)
        #define IBP1(k) bp[k] = loadSelf(px * 8 + k, py).xy;
        #define IBP2(k) bp[k].x = floor(bp[k].x);
        // Location array stores relative deltas that we need
        // to convert to absolute positions for later stages.
        #define IBP3(k) bp[k].x += pos.y == 73.0 && bp[k].x > 0.0 ? float(px * 8 + k) : 0.0;

        IBP(0)IBP(1)IBP(2)IBP(3)IBP(4)IBP(5)IBP(6)IBP(7)
    }

    if (pos.y == 73.0 || pos.y == 74.0)
    {
        // Blocks are sparse enough that we don't worry about collisions.
        // Just grab a single location. This could be improved.

        vec2 p = vec2(0.0, 1000.0);
        float cnt = 0.0;

        for (int k = 0; k < 8; k++)
        {
            p = bp[k].x > 0.0 ? bp[k] : p;
            cnt += bp[k].x > 0.0 ? 1.0 : 0.0;
        }

        // If we have more than one block per bin then something went wrong.
        // Packets can't be that close. Reject everything.
        p = cnt > 1.0 ? vec2(0.0, 1000.0) : p;

        fragColor = vec4(p, 0, 0);
    }

    // Copy located packets into corresponding image blocks.

    if (is_expecting_data)
    {
        vec2 cpos = ((pos - vec2(0, 140-60)) / 4.0);
        cpos.y = 34.0 - cpos.y;
        vec2 lpos = fract(cpos) * 4.0;
        cpos = floor(cpos);

        int icoeff = int(lpos.x + 4.0 * lpos.y);

        if (all(lessThan(cpos, vec2(64, 35))))
        {
        #if DO_MINIMIZE_ERROR
            ivec2 cp = ivec2(cpos.xy * 4.0);
            float old_err = loadSelf(cp.x, 140-60 + 140 - 4 - (cp.y + 3)).x;
            float err = old_err > 0.0 ? min(old_err, 100.0) : 100.0;
        #endif

            for (int k = 0; k < 8; k++)
            {
                if (all(greaterThan(bp[k], vec2(0))))
                {
                    int i = int(bp[k].x - 10.0);
                    vec2 bpos = floor(64.0 * loadSelf(i, 57).xy);

                    if (all(equal(bpos, cpos)))
                    {
                    #if DO_MINIMIZE_ERROR
                        // Generally it is true that the less the phase error
                        // of fundamental and DC waves the better the quality.
                        // We keep track of the error in current block
                        // and only accept new data when the error is smaller.

                        float new_err = bp[k].y;

                        if (new_err < err)
                        {
                            err = new_err;
                            fragColor = icoeff < 12 ? loadSelf(i, 58 + icoeff) : vec4(err);
                        }
                    #else

                        fragColor = icoeff < 12 ? loadSelf(i, 58 + icoeff) : vec4(0);
                    #endif                        
                    }
                }
            }
        }
    }

    // Predict chroma blocks that have not been received yet.
    // Chroma components are 1/8th size of the luminance and
    // get bilinearly interpolated to full resolution in the
    // next stage when combined with reconstructed luminance.
    // This is needed to minimize desaturated bleeding.

    if (255.0 <= pos.x && pos.x < 335.0
        && pos.y >= 145.0 - 60.0
        && last_color.w < 0.5
        )
    {
        int x = int(pos.x);
        int y = int(pos.y);

        vec3 l = loadSelf(x-1, y).rgb;
        vec3 r = loadSelf(x+1, y).rgb;
        vec3 t = loadSelf(x, y+1).rgb;
        vec3 b = loadSelf(x, y-1).rgb;

        fragColor = vec4((l + r + t + b) / 4.0, 0);
    }

    // Decode chrominance in-place.
    // CgCo components are coded at 1/8th size of luminance
    // and represented by 8 DCT coefficients total.
    // To take advantage of hardware filtering and simplify
    // final reconstruction, perform IDCT in-place.

    if (is_expecting_data)
    {
        vec2 cpos = ((pos.yx - vec2(150-60, 260)) / 2.0);
        vec2 lpos = fract(cpos) * 2.0;
        cpos = floor(cpos);

        if (all(lessThan(cpos, vec2(64, 35))))
        {
            for (int k = 0; k < 8; k++)
            {
                if (all(greaterThan(bp[k], vec2(0))))
                {
                    int i = int(bp[k].x - 10.0);
                    vec2 bpos = floor(64.0 * loadSelf(i, 57).xy);

                    if (all(equal(bpos, cpos)))
                    {
                        vec4 a = 0.25 * loadSelf(i, 58 + 12) / vec4(1,1,2,2);
                        vec4 b = 0.25 * loadSelf(i, 58 + 13) / vec4(3,3,4,4);
                        
                        vec2 val = vec2(0);
                        
                        val = all(equal(lpos, vec2(0,0))) ? a.xy + a.zw + b.xy + b.zw : val;
                        val = all(equal(lpos, vec2(1,0))) ? a.xy - a.zw + b.xy - b.zw : val;
                        val = all(equal(lpos, vec2(0,1))) ? a.xy + a.zw - b.xy - b.zw : val;
                        val = all(equal(lpos, vec2(1,1))) ? a.xy - a.zw - b.xy + b.zw : val;

                        fragColor = vec4(-val.x + val.y, val.x, -val.x - val.y, 1);
                    }
                }
            }
        }
    }

    // Detect sample rate by checking period of pure sine wave
    // at the beginning of stream.

    if (pos.y == 1.0)
    {
        float sample_rate_index = last_color.w;

        if (is_expecting_pilot)
        {
            float f = 0.0;
            float first_sync  = 0.0;
            float second_sync = 0.0;

            for (int k = 0; k < 8; k++)
            {
                bool sync = bp[k].x > 0.0;

                first_sync  = sync && f == 0.0 ? bp[k].x : first_sync;
                second_sync = sync && f == 1.0 ? bp[k].x : second_sync;

                f += sync ? 1.0 : 0.0;
            }

            if (first_sync > 0.0 && second_sync > 0.0)
            {
                // We are measuring half period actually.
                float size = 2.0 * (second_sync - first_sync);
                float id = 0.0;

                id = abs(size - 348.0) < 10.0 ? 4.0 : id; // 96.0
                id = abs(size - 320.0) < 10.0 ? 3.0 : id; // 88.2
                id = abs(size - 174.0) <  5.0 ? 2.0 : id; // 48.0
                id = abs(size - 160.0) <  5.0 ? 1.0 : id; // 44.1

                sample_rate_index = id > 0.0 ? id : sample_rate_index;
            }
        }

        fragColor.w = sample_rate_index;
    }
}
