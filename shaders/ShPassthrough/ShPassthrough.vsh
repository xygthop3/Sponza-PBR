struct VertexShaderInput {
  float4 vPosition : POSITION;
//  float4 vColor	   : COLOR0;
  float2 vTexcoord : TEXCOORD0;
  float3 vNormal   : NORMAL;

};

struct VertexShaderOutput {
  float4 vPosition      : SV_POSITION;
  float4 vPositionWorld : POSITION1;  
//  float4 vColor	        : COLOR0;
  float2 vTexcoord      : TEXCOORD0;
  float3 vNormalWorld	: NORMAL0;
};

VertexShaderOutput main(VertexShaderInput INPUT) {
  VertexShaderOutput OUTPUT;
  
  OUTPUT.vPosition = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], INPUT.vPosition);
  OUTPUT.vPositionWorld = mul(gm_Matrices[MATRIX_WORLD], INPUT.vPosition);
  
 // OUTPUT.vColor = INPUT.vColor;
  OUTPUT.vTexcoord = INPUT.vTexcoord;
  OUTPUT.vNormalWorld = mul(gm_Matrices[MATRIX_WORLD], float4(INPUT.vNormal, 0.0)).xyz;
  	
  return OUTPUT;
}