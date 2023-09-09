/////////////////////////
/// Taken from
/// https://github.com/iweinbau/PBR-shader/blob/master/src/main/resources/shader/fragment.glsl
/// https://gist.github.com/steaklive/d6676b1703584d345473a9d97cc03258
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

//Uchimura tone mapping helper
float uchimura(float x, float P, float a, float m, float l, float c, float b) {
  float l0 = ((P - m) * l) / a;
  float L0 = m - m / a;
  float L1 = m + (1.0 - m) / a;
  float S0 = m + l0;
  float S1 = m + a * l0;
  float C2 = (a * P) / (P - S1);
  float CP = -C2 / P;

  float w0 = 1.0 - smoothstep(0.0, m, x);
  float w2 = step(m + l0, x);
  float w1 = 1.0 - w0 - w2;

  float T = m * pow(x / m, c) + b;
  float S = P - (P - S1) * exp(CP * (x - S0));
  float L = m + a * (x - m);

  return T * w0 + L * w1 + S * w2;
}
//Uchimura tone mapping helper
float uchimura(float x) {
  const float P = 1.0;  // max display brightness
  const float a = 1.0;  // contrast
  const float m = 0.22; // linear section start
  const float l = 0.4;  // linear section length
  const float c = 1.33; // black
  const float b = 0.0;  // pedestal

  return uchimura(x, P, a, m, l, c, b);
}

//PBR Helpers
float spacularD(float cosThetaH, float roughness) {
    float aa      = roughness*roughness;
    float a2     = aa*aa;
    float NdotH  = cosThetaH;
    float NdotH2 = NdotH*NdotH;

    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

float3 spacularF(float cosThetaD, float3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosThetaD, 5.0);
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float rr = (roughness + 1.0);
    float k = (rr*rr) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}

float specularG(float cosThetaV, float cosThetaL, float roughness){
  float G1 = GeometrySchlickGGX(cosThetaV, roughness);
  float G2 = GeometrySchlickGGX(cosThetaL, roughness);
  return G1 * G2;
}


///MAIN
PixelShaderOutput main(PixelShaderInput INPUT) {
  PixelShaderOutput OUTPUT;
  
  float4 albedo = gm_BaseTextureObject.Sample(gm_BaseTexture, INPUT.vTexcoord);
  albedo.rgb = pow(albedo.rgb, 2.2);
  if (albedo.a < 0.8) { discard; }

  float metalness = texMetalRoughness.Sample(samp_MetalRoughness, INPUT.vTexcoord).b;
  float roughness = texMetalRoughness.Sample(samp_MetalRoughness, INPUT.vTexcoord).g;
  
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

  float3 R = normalize(reflect(-V, PN));
  
  //Angles bewteen vector and normal
  float costhetaL = max(dot(L,PN), 0.0);
  float costhetaV = max(dot(PN,V), 0.0);
  float costhetaH = max(dot(H,PN), 0.0);
  float costhetaD = max(dot(H,V),  0.0);
    
  float3 F0 = 0.04;
  F0 = lerp(F0, albedo.rgb, metalness);

  float  D = spacularD(costhetaH, roughness);
  float3 F = spacularF(costhetaD, F0);
  float  G = specularG(costhetaL, costhetaV, roughness);
  
  float3 kD = lerp(1.0 - F0, 0.0, metalness);

  float3 numerator  = D * G * F;
  float denominator = 4.0 * costhetaV * costhetaL;
  float3 specular   = numerator / max(denominator, 0.001);
	
  //Direct diffuse
  float3 diffuse = kD * (( albedo.rgb * costhetaL) /PI) * radiance;
  diffuse = diffuse + specular;
  
  //Direct fake "garbage" hemispheric ambient
  float up = PN.z * 0.5 + 0.5;
  float3 ambient = float3(0.1, 0.1, 0.1) + up * float3(0.3, 0.3, 0.3);
  ambient = ambient * albedo.rgb;

  float3 directLighting = ambient + diffuse;

  //IBL 
  float3 indirectDiffuseLighting = pow(texCubemap.SampleLevel(sampCubemap, cube2uv(PN), 6), 2.2) * albedo.rgb;
  
  float mipIndex = roughness * 6;
  float3 reflectedColor = pow(texCubemap.SampleLevel(sampCubemap, cube2uv(R), mipIndex), 2.2);
  
  float3 environmentBRDF = texBRDFLUT.Sample(sampBRDFLUT, float2(roughness, costhetaV));
  
  float fresnel = pow(1.0 - costhetaV, 5.0);
  float3 specularAlbedo = albedo.rgb * metalness;
  float3 indirectSpecular = reflectedColor * (specularAlbedo * environmentBRDF.x + environmentBRDF.y) * fresnel;
  float3 indirectLighting = indirectDiffuseLighting + indirectSpecular;
  
  float3 color = directLighting + indirectLighting;
  color = float3(uchimura(color.r), uchimura(color.g), uchimura(color.b)); //Stop being lazy and FIX THIS so tonemapping is done on a final surface
  color = pow(color, 1.0 / 2.2);
  
  OUTPUT.Color0 = float4(color, 1.0);
  
  return OUTPUT;
}