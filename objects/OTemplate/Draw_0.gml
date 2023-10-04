
gpu_set_texrepeat_ext(sampCubemap, false)


if (!surface_exists(surfColourOutput)) {
	surfColourOutput = surface_create(room_width, room_height,surface_rgba16float);
}

surface_set_target(surfColourOutput);
draw_clear(c_black);
camera_apply(camera);
  shader_set(ShPassthrough);
  
    texture_set_stage(sampCubemap, texCubemap);
    texture_set_stage(sampBRDFLUT, texBRDFLUT);
    
    //Draw Sponza
    matrix_set(matrix_world, modelMatrix);
    model.Submit();
    
    //Draw gun
    //gunDir += 0.1;
    mat_rotate_translate = matrix_build(3,0,1.5, 0,0,gunDir, modelScale*3,modelScale*3,modelScale*3);
    matrix_set(matrix_world, mat_rotate_translate);
    texture_set_stage(samp_Normal, texGunNormal);
    texture_set_stage(samp_MetalRoughness, texGunMetalRough);  
    vertex_submit(buffer_Gun, pr_trianglelist, texGunDiffuse);
    
    //Draw Knight
    mat_rotate_translate = matrix_build(-9,0,0, 0,0,gunDir, modelScale*5,modelScale*5,modelScale*5);
    matrix_set(matrix_world, mat_rotate_translate);
    texture_set_stage(samp_Normal, texKnightNormal);
    texture_set_stage(samp_MetalRoughness, texKnightMetalRough);  
    vertex_submit(buffer_Knight, pr_trianglelist, texKnightDiffuse);
    
    //Draw Tester
    mat_rotate_translate = matrix_build(-6,0,0, 0,0,gunDir, modelScale*5,modelScale*5,modelScale*5);
    matrix_set(matrix_world, mat_rotate_translate);
    texture_set_stage(samp_Normal, texTestNormal);
    texture_set_stage(samp_MetalRoughness, texTestMetalRough);  
    vertex_submit(buffer_Tester, pr_trianglelist, texTestDiffuse);
    
    //Draw Helmet
    mat_rotate_translate = matrix_build(6,0,1.5, 0,0,gunDir, modelScale*3,modelScale*3,modelScale*3);
    matrix_set(matrix_world, mat_rotate_translate);
    texture_set_stage(samp_Normal, texHelmetNormal);
    texture_set_stage(samp_MetalRoughness, texHelmetMetalRough);  
    vertex_submit(buffer_Helmet, pr_trianglelist, texHelmetDiffuse);
    
    //Draw Damaged Helmet
    mat_rotate_translate = matrix_build(-3,0,1.5, 270,0,gunDir, modelScale*50,modelScale*50,modelScale*50);
    matrix_set(matrix_world, mat_rotate_translate);
    texture_set_stage(samp_Normal, texDamagedHelmetNormal);
    texture_set_stage(samp_MetalRoughness, texDamagedHelmetMetalRough);  
    vertex_submit(buffer_DamagedHelmet, pr_trianglelist, texDamagedHelmetDiffuse);  
    
    matrix_set(matrix_world, matrix_build_identity());
  shader_reset();
surface_reset_target();
