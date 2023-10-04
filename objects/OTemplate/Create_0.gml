draw_set_font(FntOpenSans10);

surfColourOutput = surface_create(room_width, room_height, surface_rgba16float);

camera = camera_create();
clipFar = 512.0;
fov = 60.0;
x = 0.0;
y = 0.0;
z = 1.7;
direction = 180.0;
directionUp = 0.0;
mouseLastX = 0;
mouseLastY = 0;

model = new CModel();

if (file_exists("Data/Sponza/Sponza.bin"))
{
	var _buffer = buffer_load("Data/Sponza/Sponza.bin");
	model.FromBuffer(_buffer);
	buffer_delete(_buffer);

}
else
{
	model.FromOBJ("Data/Sponza/Sponza.obj");

	var _buffer = buffer_create(1, buffer_grow, 1);
	model.ToBuffer(_buffer);
	buffer_save(_buffer, game_save_id + "Data/Sponza/NEWSponza.bin");
	buffer_delete(_buffer);
}

model.Freeze();
	
modelScale = 0.01;
modelMatrix = matrix_build(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, modelScale, modelScale, modelScale);


gui = new CGUI();
guiShow = false;
screenshotMode = false;

texCubemap = sprite_get_texture(sprEnv, 0);
texBRDFLUT = sprite_get_texture(spr_BRDF_LUT, 0);

//Gun textures
texGunDiffuse = sprite_get_texture(SprGun, 0);
texGunNormal = sprite_get_texture(SprGun, 1);
texGunMetalRough = sprite_get_texture(SprGun, 2);

//Knight textures
texKnightDiffuse = sprite_get_texture(SprKnight, 0);
texKnightNormal = sprite_get_texture(SprKnight, 1);
texKnightMetalRough = sprite_get_texture(SprKnight, 2);

//Tester textures
texTestDiffuse = sprite_get_texture(SprTester, 0);
texTestNormal = sprite_get_texture(SprTester, 1);
texTestMetalRough = sprite_get_texture(SprTester, 2);

//Asian Helmet textures
texHelmetDiffuse = sprite_get_texture(SprHelmet, 0);
texHelmetNormal = sprite_get_texture(SprHelmet, 1);
texHelmetMetalRough = sprite_get_texture(SprHelmet, 2);

//Damaged Helmet textures
texDamagedHelmetDiffuse = sprite_get_texture(SprDamagedHelmet, 0);
texDamagedHelmetNormal = sprite_get_texture(SprDamagedHelmet, 1);
texDamagedHelmetMetalRough = sprite_get_texture(SprDamagedHelmet, 2);

sampCubemap = shader_get_sampler_index(ShPassthrough, "sampCubemap");
sampBRDFLUT = shader_get_sampler_index(ShPassthrough, "sampBRDFLUT");

samp_Normal = shader_get_sampler_index(ShPassthrough, "samp_Normal");
samp_MetalRoughness = shader_get_sampler_index(ShPassthrough, "samp_MetalRoughness");

var _temp_buffer;
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_textcoord();
vertex_format_add_colour();
vertex_format = vertex_format_end();

//Gun buffer
temp_buffer = buffer_load("Cerberus_LP.buf");
buffer_Gun = vertex_create_buffer_from_buffer(temp_buffer, vertex_format);
buffer_delete(temp_buffer);
vertex_freeze(buffer_Gun);
gunDir = 270;

//Knight buffer
temp_buffer = buffer_load("ShovelKnight.buf");
buffer_Knight = vertex_create_buffer_from_buffer(temp_buffer, vertex_format);
buffer_delete(temp_buffer);
vertex_freeze(buffer_Knight);

//Tester buffer
temp_buffer = buffer_load("shapetester.buf");
buffer_Tester = vertex_create_buffer_from_buffer(temp_buffer, vertex_format);
buffer_delete(temp_buffer);
vertex_freeze(buffer_Tester);

//Skybox buffer
temp_buffer = buffer_load("Skybox.buf");
buffer_Skybox = vertex_create_buffer_from_buffer(temp_buffer, vertex_format);
buffer_delete(temp_buffer);
vertex_freeze(buffer_Skybox);

//Helmet buffer
temp_buffer = buffer_load("Helmet.buf");
buffer_Helmet = vertex_create_buffer_from_buffer(temp_buffer, vertex_format);
buffer_delete(temp_buffer);
vertex_freeze(buffer_Helmet);

//Damaged Helmet buffer
temp_buffer = buffer_load("damagedhelmet.buf");
buffer_DamagedHelmet = vertex_create_buffer_from_buffer(temp_buffer, vertex_format);
buffer_delete(temp_buffer);
vertex_freeze(buffer_DamagedHelmet);



gpu_set_zwriteenable(true);
gpu_set_ztestenable(true);
gpu_set_tex_filter(true);
gpu_set_tex_mip_enable(mip_on);
gpu_set_tex_repeat(true);

gpu_set_cullmode(cull_counterclockwise);

draw_clear(c_black);