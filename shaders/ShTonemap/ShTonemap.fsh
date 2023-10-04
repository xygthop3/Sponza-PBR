struct PixelShaderInput {
  float4 vPosition      : SV_POSITION;
  float4 vColor	        : COLOR0;
  float2 vTexcoord      : TEXCOORD0;
};

struct PixelShaderOutput {
  float4 Color0 : SV_TARGET0;
};

float3 uncharted2Tonemap(float3 xx) {
	const float A = 0.15;
	const float B = 0.50;
	const float C = 0.10;
	const float D = 0.20;
	const float E = 0.02;
	const float F = 0.30;
	return ((xx * (A * xx + C * B) + D * E) / (xx * (A * xx + B) + D * F)) - E / F;
}

// http://filmicworlds.com/blog/filmic-tonemapping-operators/
// outputs LINEAR tonemapped data, so should still be used with an SRGB render target
float3 tonemapUncharted2(float3 color) {
	float W = 11.2; // Hardcoded white point
	float3 curr = uncharted2Tonemap(color);
	float3 whiteScale = 1.0 / uncharted2Tonemap(float3(W, W, W));
	return curr * whiteScale;
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

PixelShaderOutput main(PixelShaderInput INPUT) {
  PixelShaderOutput OUTPUT;
  
  float3 color = gm_BaseTextureObject.Sample(gm_BaseTexture, INPUT.vTexcoord).rgb;
  color *= 5.0; //exposure
  
  //Uncharted 2 tonemap
  color = tonemapUncharted2(color);
  
  //Uchimura tonemap
  color = float3(uchimura(color.r), uchimura(color.g), uchimura(color.b));
   
  //Gamma correction
  color = pow(color, 1.0/2.2);

  //Final Output
  OUTPUT.Color0 = float4(color, 1.0);
  return OUTPUT;
}