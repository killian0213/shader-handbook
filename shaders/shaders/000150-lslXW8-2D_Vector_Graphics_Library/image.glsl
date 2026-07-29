// Image (image) — 2D Vector Graphics Library by paniq
// https://www.shadertoy.com/view/lslXW8

// see Common tab for implementation

//////////////////////////////////////////////////////////

// DEMO

float myf(float x) {
    return sin(x) * cos((x + iTime * 0.2) * 20.0);
}

float myf2(vec2 x) {
    float r = length(x);
    float a = atan(x.y,x.x);
    return r - 1.0 + 0.5 * sin(3.0*a + 2.0*r*r);
}

void shield_shape() {
    move_to(0.2, 0.2);
    line_to(0.0, 0.3);
    line_to(-0.2, 0.2);    
    curve_to(-0.2, -0.05, 0.0, -0.2);
    curve_to(0.2, -0.05, 0.2, 0.2);
}

void paint() {
    float t = iTime;

    // clear screen with a subtle gradient

    set_source_linear_gradient(
        vec3(0.0,0.0,0.3),
        vec3(0.0,0.0,0.6),
        vec2(0.0,-1.0),
        vec2(0.0,1.0));
    clear();
    
    grid(vec2(1.0/10.0));
    set_line_width_px(1.0);
    set_source_rgba(vec4(vec3(1.0),0.3));
    stroke();    

    // draw 1D graph
    graph1D(myf);
    // graphs only look good at pixel size
    set_line_width_px(1.0);
    set_source_rgba(vec4(vec3(1.0),0.3));
    stroke();

    // draw 2D graph
    graph2D(myf2);
    // graphs only look good at pixel size
    set_line_width_px(1.0);
    set_source_rgba(vec4(vec3(0.0),0.8));
    fill_preserve();
    set_source_rgba(vec4(vec3(1.0),0.3));
    stroke();

    // fill ellipse
    ellipse(0.0, 0.0, 0.3, 0.5);
    bool in_circle = in_fill();
    set_source_radial_gradient(
        hsl(0.1, 1.0, in_circle?0.7:0.5),
        hsl(0.0, 1.0, 0.5),
		vec2(0.0), 0.3);
    fill_preserve(); // don't reset shape

    // add a circle
    circle(0.3 + 0.3*(sin(t)*0.5+0.5), 0.0, 0.2);
    set_line_width(0.04);
    bool in_circle_rim = in_circle || in_stroke();
    // stroke circle and ellipse, twice
    set_source_rgb(hsl(0.0, 1.0, 0.3));
    set_line_width(0.04);
    stroke_preserve();
    set_source_rgb(hsl(0.1, 1.0, in_circle_rim?0.8:0.5));
    set_line_width(0.02);
    stroke();

    // shadowed stop sign stroke

    move_to(-0.2,0.0);
    line_to(0.2,0.0);

    set_source_rgba(0.5,0.0,0.0,0.5);
    set_line_width(0.02);
    set_blur(0.05);
    stroke_preserve();
    set_blur(0.0);

    set_source_rgb(vec3(1.0));
    set_line_width(0.02);
    stroke();

    // transformed glowing triangle

    // to preserve stroke width, first save context...
    { save(ctx);
    translate(-1.0, 0.4);
    scale(0.01 + 0.5 * (sin(t)*0.5+0.5));
    rotate(radians(t*30.0));
    move_to(0.5, 0.0);
    for (int i = 1; i < 6; ++i) {
        float a0 = radians((float(i)-0.5) * 360.0 / 5.0);
        float a1 = radians(float(i) * 360.0 / 5.0);
        curve_to(
            cos(a0)*0.5, sin(a0)*0.5,
    		cos(a1)*0.5, sin(a1)*0.5);
    }
    //close_path();
    // ...then restore to previous transformation
    restore(ctx); }

    set_line_width_px(0.1);
    bool tri_active = in_stroke();
    set_source_rgba(hsl(tri_active?0.1:0.5, 1.0, 0.5, 0.5));
    fill_preserve();    
    // add glow
    set_source_rgba(vec4(hsl(tri_active?0.1:0.52, 1.0, 0.5)*0.2,0.0));
    set_line_width(0.02);
    set_blur(0.1);
    premultiply_alpha(true);
    stroke_preserve();
    premultiply_alpha(false);
    set_blur(0.0);
    // and stroke
    set_line_width_px(1.2);
    set_source_rgb(hsl(tri_active?0.1:0.5, 1.0, 0.5));
   	stroke();

    // pink alphablended rectangle

    { save(ctx);
    translate(0.9, 0.1);
    rotate(-radians(t*30.0));
    rounded_rectangle(-0.3,-0.4,0.6,0.8, mix(0.0,0.3,sin(iTime*1.114)*0.5+0.5));

    if (in_fill()) {
        // animate the texture a little
        save(ctx);
        translate(mod(iTime*0.2,1.0), 0.0);
        set_source(iChannel0);
        restore(ctx);
	    set_source_blend_mode(Multiply);
        set_source_linear_gradient(
            hsl(0.7, 1.0, 0.5, 1.0),
            hsl(0.9, 1.0, 0.5, 1.0),
            vec2(-0.3,-0.4),
            vec2(0.3, 0.4));
	    set_source_blend_mode(Replace);
    } else
        set_source_linear_gradient(
            hsl(0.7, 1.0, 0.5, 0.2),
            hsl(0.9, 1.0, 0.5, 0.9),
            vec2(-0.3,-0.4),
            vec2(0.3, 0.4));
    fill_preserve();

    set_line_width(0.02);
    set_source_linear_gradient(
        hsl(0.9, 1.0, 0.5, 1.0),
        hsl(0.7, 1.0, 0.5, 1.0),
        vec2(0.3,0.4),
        vec2(-0.3, -0.4));
    stroke();
    restore(ctx); }

    // quadratic bezier spline

    save(ctx);
    translate(-0.8, -0.7);
    shield_shape();
    set_source_linear_gradient(
        hsl(0.9, 1.0, 0.6),
        hsl(0.9, 1.0, 0.4),
        vec2(0.0,-0.2),
        vec2(0.0, 0.2));
    fill();
    restore(ctx);
    translate(0.8, -0.7);
    shield_shape();    
    //stroke_isolines_preserve(0.1);
    set_line_width(0.04);
    bool bezier_active = in_stroke();
    set_source_rgb(hsl(0.9, 1.0, bezier_active?1.0:0.5));    
    stroke_preserve();
    set_line_width(0.02);
    set_source_rgb(hsl(0.9, 1.0, 0.1));
    stroke();
    restore(ctx);
    
    {
        save(ctx);
        translate(-1.2, 0.7);
        scale(vec2(0.2));
        for (int i = 0; i < 26; ++i) {
            translate(0.4, 0.0);
            letter(iChannel1, 48 + i, 0);
        }
        set_line_width(0.05);
        set_source_rgb(vec3(0.0));
        stroke_preserve();
        set_source_rgb(vec3(1.0));
        fill();
        restore(ctx);
	}
}

//////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    init(fragCoord, iMouse.xy, iResolution.xy);

    paint();

    blit(fragColor);
}

#ifdef GLSLSANDBOX
void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
#endif
