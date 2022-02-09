#ifndef NORMAL_MAPPING
#define NORMAL_MAPPING

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(UnityPerMaterial)
float _NormalScale; 
CBUFFER_END

TEXTURE2D(_BaseColor);
SAMPLER(sampler_BaseColor);

TEXTURE2D(_Normal);
SAMPLER(sampler_Normal);


struct Attributes
{
    float3 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;  
    float2 texcoord     : TEXCOORD0;
    
};

struct Varyings
{
    float4  positionCS      : SV_POSITION;
    half2   uv              : TEXCOORD0;
    float4  normalWS        : TEXCOORD1;
    float4  tangentWS       : TEXCOORD2;
    float4  bitangentWS     : TEXCOORD3; 
};


Varyings NormalMappingVert(Attributes input){

    Varyings output;
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.uv = input.texcoord; 
    
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS.xyz,input.tangentOS);
    output.normalWS.xyz     = normalInputs.normalWS;
    output.tangentWS.xyz    = normalInputs.tangentWS;
    output.bitangentWS.xyz  = normalInputs.bitangentWS;

    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.tangentWS.w      = positionWS.x;
    output.bitangentWS.w    = positionWS.y;
    output.normalWS.w       = positionWS.z;

    return output;
}

half4 NormalMappingFrag(Varyings input) : SV_Target{
     
    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, input.uv),_NormalScale);
    half3 normalWS = normalize(TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)));
    
    half3 positionWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);

    Light mainLight = GetMainLight();
    half3 baseColor = SAMPLE_TEXTURE2D(_BaseColor,sampler_BaseColor,input.uv).xyz; 
    half3 diffuseColor = LightingLambert(mainLight.color, mainLight.direction, normalWS);
     
    return half4(diffuseColor * baseColor ,1.0); 
}
 
#endif