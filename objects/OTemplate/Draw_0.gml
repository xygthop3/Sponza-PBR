SurfaceCheck(application_surface, window_get_width(), window_get_height())
gpu_push_state();
gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
gpu_set_tex_filter(true);
gpu_set_tex_mip_enable(mip_on);
gpu_set_tex_repeat(true);

draw_clear(c_black);
camera_apply(camera);

/*
gpu_set_tex_mip_filter(tf_point);
gpu_set_tex_filter_ext(sampCubemap, tf_point);
gpu_set_tex_mip_enable_ext(sampCubemap, false);
*/

shader_set(ShPassthrough);

  texture_set_stage(sampCubemap, texCubemap);
  texture_set_stage(sampBRDFLUT, texBRDFLUT);
  
  //Draw Sponza
  matrix_set(matrix_world, modelMatrix);
  model.Submit();
  
  //Draw gun
  gunDir += 0.3;
  mat_rotate_translate = matrix_build(3,0,1.5, 0,0,gunDir, modelScale*3,modelScale*3,modelScale*3);
  matrix_set(matrix_world, mat_rotate_translate);
  texture_set_stage(samp_Normal, texGunNormal);
  texture_set_stage(samp_MetalRoughness, texGunMetalRough);  
  vertex_submit(buffer_Gun, pr_trianglelist, texGunDiffuse);
  
  //Draw Knight
  mat_rotate_translate = matrix_build(-3,0,0, 0,0,270, modelScale*5,modelScale*5,modelScale*5);
  matrix_set(matrix_world, mat_rotate_translate);
  texture_set_stage(samp_Normal, texKnightNormal);
  texture_set_stage(samp_MetalRoughness, texKnightMetalRough);  
  vertex_submit(buffer_Knight, pr_trianglelist, texKnightDiffuse);
  
  //Draw Tester
  mat_rotate_translate = matrix_build(-6,0,1, 0,0,0, modelScale*5,modelScale*5,modelScale*5);
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
  
  matrix_set(matrix_world, matrix_build_identity());
shader_reset();

//gpu_set_tex_mip_filter(tf_anisotropic);

gpu_pop_state();
