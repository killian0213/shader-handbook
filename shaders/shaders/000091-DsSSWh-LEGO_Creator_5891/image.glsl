// Image (image) — LEGO Creator 5891 by Mathis
// https://www.shadertoy.com/view/DsSSWh

/*
LEGO Creator 5891
    Rendering
        GGX Path Tracing
        Edge detection when geometry moves
    LEGO 5891
        This set is really good, I did not add interior details in this shader
        Some changes have been made to the original instructions:
            The door has another model entirely (no frame)
            The basketball hoop, mower and grey arc are not included
            The hinge for the disk is changed (the functionality still works)
            The tree has reduced complexity as the renderer is limited (max 4 bricks/voxel)
    Bricks
        They are stored in arrays and sampled/updated i Buffer A
            Modified quaternions are used to describe rotation
        3D models are not perfect of course
    Brick propagation
        Propagation-type movement is efficient for a large number of objects but put constraints on free movement
            3^3 search box in the volume means the maximum absolute velocity (translation + transformation) vector at any point
            on the brick is limited to 1 voxel_vec3/frame
        This max velocity is clamped to max 30 bricks/sec (to not break high fps counts)
        Max 4 bricks can be stored in a voxel
            When more than 4 bricks intersect with a voxel, bricks that are cut off repair themselves as they propagate
    Feedback is welcome!




Controls
    Movement
        WASD to move the camera
        Hold space to move faster
        Click and hold mouse to rotate the camera
    Bricks
        Press R to watch the building process
        Press it again during the animation to pause
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 Color = texture(iChannel3,fragCoord*IRES).xyz;
    fragColor = vec4(pow(1.-exp(-1.2*Color),vec3(0.45)),1.);
}