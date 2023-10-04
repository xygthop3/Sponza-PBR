/////////////////////////
/// Taken from
/// https://github.com/KhronosGroup/glTF-Sample-Viewer/blob/glTF-WebGL-PBR/shaders/pbr-frag.glsl (MIT License)
/// https://github.com/iweinbau/PBR-shader/blob/master/src/main/resources/shader/fragment.glsl
/// https://gist.github.com/steaklive/d6676b1703584d345473a9d97cc03258
/// https://github.com/JoshuaSenouf/gl-engine/blob/master/resources/shaders/lighting/lightingBRDF.frag#L300C1-L309C2
/// https://github.com/dmnsgn/glsl-tone-map
/// http://artisaverb.info/PBT.html
/////////////////////////

struct PixelShaderInput {
  float4 vPosition      : SV_POSITION;
  float4 vPositionWorld : POSITION1;  
  //float4 vColor	        : COLOR0;
  float2 vTexcoord      : TEXCOORD0;
  float3 vNormalWorld	: NORMAL0;
};

struct PixelShaderOutput {
  float4 Color0 : SV_TARGET0;
};

//Constants
static const float PI = 3.141592;

//Uniforms
uniform float4 uni_Camera_Position_Pixel;

////Texture Samples
//1 - texNormalMap
Texture2D texNormalMap   : register(t1);
SamplerState samp_Normal : register(s1);

//2 - texMetalnessMap
Texture2D texMetalRoughness      : register(t2);
SamplerState samp_MetalRoughness : register(s2);

//3 - texBRDFLUT
Texture2D texBRDFLUT	 : register(t3);
SamplerState sampBRDFLUT : register(s3);

//4 - texCubemap
Texture2D texCubemap	 : register(t4);
SamplerState sampCubemap : register(s4);


//Start cubemapping
float2 cube2uv(float3 eyePos) {
  float2 uv;
  float3 spacePos=eyePos;
  
  if(spacePos.x<0.0) {spacePos.x=-spacePos.x;}
  if(spacePos.y<0.0) {spacePos.y=-spacePos.y;}
  if(spacePos.z<0.0) {spacePos.z=-spacePos.z;}

  if(spacePos.x>=spacePos.y&&spacePos.x>=spacePos.z) {
    if(eyePos.x>0.0) { //LEFT
      uv.x=0.125;
      uv.y=0.5;
      uv.x-=eyePos.y/eyePos.x*0.125;
      uv.y-=eyePos.z/eyePos.x*0.166;
    }
    else { //RIGHT
      uv.x=0.625;
      uv.y=0.5;
      uv.x-=eyePos.y/eyePos.x*0.125;
      uv.y+=eyePos.z/eyePos.x*0.166;
   }                    
  }
                         
  if(spacePos.y>spacePos.x&&spacePos.y>=spacePos.z) {
    if(eyePos.y>0.0) { //BACK
      uv.x=0.875;
      uv.y=0.5;
      uv.x+=eyePos.x/eyePos.y*0.125;
      uv.y-=eyePos.z/eyePos.y*0.166;
    }
    else { //FRONT
      uv.x=0.375;
      uv.y=0.5;
      uv.x+=eyePos.x/eyePos.y*0.125;
      uv.y+=eyePos.z/eyePos.y*0.166;
    }
  }
  
  if(spacePos.z>spacePos.x&&spacePos.z>spacePos.y) {
    if(eyePos.z>0.0) { //TOP
      uv.x=0.375;
      uv.y=0.166;
      uv.x-=eyePos.x/eyePos.z*0.125;
      uv.y-=eyePos.y/eyePos.z*0.166;
    }
    else { //BOTTOM
      uv.x=0.375;
      uv.y=0.832;
      uv.x+=eyePos.x/eyePos.z*0.125;
      uv.y-=eyePos.y/eyePos.z*0.166;
    }
  }
  
  return uv;
}
//End cubemapping

//TBN Matrix
float3x3 Matrix_TBN(float3 N, float3 P, float2 uv) {
  float3 dp1 =  ddx(P);
  float3 dp2 =  ddy(P);
  float2 duv1 = ddx(uv);
  float2 duv2 = ddy(uv);
 
  float3 dp2perp = cross( N, dp2 );
  float3 dp1perp = cross( dp1, N );
  float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
  float3 B = dp2perp * duv1.y + dp1perp * duv2.y;
 
  float invmax = rsqrt( max( dot(T,T), dot(B,B) ) );  
  
  return float3x3( T * invmax, B * invmax, N );     
}

float4 SRGBtoLINEAR(float4 srgbIn) {
	float3 linOut = pow(srgbIn.xyz, 2.2);
    return float4(linOut,srgbIn.w);;
}

float3 specularReflection(float reflectance0, float reflectance90, float VdotH) {
  return reflectance0  + (reflectance90 - reflectance0 ) * pow(clamp(1.0 - VdotH, 0.0, 1.0), 5.0);
}

float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(1.0 - roughness, F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
} 

float geometricOcclusion(float NdotL, float NdotV, float alphaRoughness) {
  float attenuationL = 2.0 * NdotL / (NdotL + sqrt(alphaRoughness * alphaRoughness + (1.0 - alphaRoughness * alphaRoughness) * (NdotL * NdotL)));
  float attenuationV = 2.0 * NdotV / (NdotV + sqrt(alphaRoughness * alphaRoughness + (1.0 - alphaRoughness * alphaRoughness) * (NdotV * NdotV)));
  return attenuationL * attenuationV;
}

float microfacetDistribution(float alphaRoughness, float NdotH) {
  float roughnessSq = alphaRoughness * alphaRoughness;
  float f = (NdotH * roughnessSq - NdotH) * NdotH + 1.0;
  return roughnessSq / (PI * f * f);
}

float2 xEnvBRDFApprox(float roughness, float NdotV)
{
	float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
	float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);
	float4 r = (roughness * c0) + c1;
	float a004 = (min(r.x * r.x, exp2(-9.28 * NdotV)) * r.x) + r.y;
	return ((float2(-1.04, 1.04) * a004) + r.zw);
}

///MAIN
PixelShaderOutput main(PixelShaderInput INPUT) {
  PixelShaderOutput OUTPUT;
  
  float4 baseColor  = SRGBtoLINEAR(gm_BaseTextureObject.Sample(gm_BaseTexture, INPUT.vTexcoord));
  if (baseColor.a < 0.8) { discard; }

  float metallic = texMetalRoughness.Sample(samp_MetalRoughness, INPUT.vTexcoord).b;
  metallic = clamp(metallic, 0.0, 1.0);
  
  float roughness = texMetalRoughness.Sample(samp_MetalRoughness, INPUT.vTexcoord).g;
  float perceptualRoughness = roughness;
  float alphaRoughness = perceptualRoughness * perceptualRoughness;
  float3 f0 = float3(0.04, 0.04, 0.04);
	
  float3 diffuseColor = baseColor.rgb * (float3(1.0,1.0,1.0) - f0);
  diffuseColor *= 1.0 - metallic;
  float3 specularColor = lerp(f0, baseColor.rgb, metallic);
  
  float reflectance = max(max(specularColor.r, specularColor.g), specularColor.b);
  
  float reflectance90 = clamp(reflectance * 25.0, 0.0, 1.0);
  float3 specularEnvironmentR0 = specularColor.rgb;
  float3 specularEnvironmentR90 = reflectance90;
	
  float3 lightColor = float3(0.99, 0.99, 0.99); //Stop being lazy and change this to a Uniform
  float3 lightPos   = float3(0.0, 0.0, 2.0); //Stop being lazy and change this to a Uniform
  float3 L          = normalize(lightPos - INPUT.vPositionWorld.xyz);
  float dist        = length(L);
  float attenuation = 1.0 / (dist * dist);
  float3 radiance   = lightColor * attenuation;
  
  float3 N = normalize(INPUT.vNormalWorld);
  float3 V = normalize(uni_Camera_Position_Pixel - INPUT.vPositionWorld.xyz);
  float3 H = normalize(L + V);

  float3x3 TBN = Matrix_TBN(N, V, INPUT.vTexcoord);
  float3 normalMap = normalize(texNormalMap.Sample(samp_Normal, INPUT.vTexcoord).rgb * 2.0 - 1.0);
  float3 PN = normalize(mul(normalMap, TBN));

  float3 R = -normalize(reflect(V, PN));
  
  //Angles bewteen vector and normal
  float NdotL = clamp(dot(PN, L), 0.001, 1.0);
  float NdotV = clamp(abs(dot(PN, V)), 0.001, 1.0);
  float NdotH = clamp(dot(PN, H), 0.0, 1.0);
  float LdotH = clamp(dot(L, H), 0.0, 1.0);
  float VdotH = clamp(dot(V, H), 0.0, 1.0);

  // Calculate the shading terms for the microfacet specular shading model
  float3 F = specularReflection(specularEnvironmentR0, specularEnvironmentR90, VdotH);
  float G = geometricOcclusion(NdotL, NdotV, alphaRoughness);
  float D = microfacetDistribution(alphaRoughness, NdotH);
	
  // Calculation of analytical lighting contribution
  float3 diffuseContrib = (1.0 - F) * (diffuseColor/PI);
  float3 specContrib = F * G * D / (4.0 * NdotL * NdotV);
  float3 color = NdotL * lightColor * (diffuseContrib + specContrib);

  float lod = roughness * 6.0;
  float2 brdf = xEnvBRDFApprox(roughness, NdotV); // SRGBtoLINEAR(texBRDFLUT.Sample(sampBRDFLUT, float2(roughness, NdotV))).rgb;

  float3 diffuseLight = SRGBtoLINEAR(texCubemap.SampleLevel(sampCubemap, cube2uv(PN), 6.0)).rgb;
  float3 specularLight = SRGBtoLINEAR(texCubemap.SampleLevel(sampCubemap, cube2uv(R), lod)).rgb;
   
  float3 diffuse = diffuseColor * diffuseLight;
  float3 specular = specularLight * (specularColor * brdf.x + brdf.y);
	
  color += diffuse + specular;
   
  //Final Output
  OUTPUT.Color0 = float4(color, 1.0);
  
  //Debugging
  //OUTPUT.Color0 = float4(brdf.x + brdf.y,brdf.x + brdf.y,brdf.x + brdf.y, 1.0); //BRDF
  //OUTPUT.Color0 = float4(F, 1.0); //Specular Reflectance
  //OUTPUT.Color0 = float4(F, 1.0); //Fresnel
  //OUTPUT.Color0 = float4(G,G,G, 1.0); //Occlusion
  //OUTPUT.Color0 = float4(metallic,metallic,metallic, 1.0);
  //OUTPUT.Color0 = float4(roughness,roughness,roughness, 1.0);

  return OUTPUT;
}