#ifndef PARALLAX_MAPPING
#define PARALLAX_MAPPING

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(UnityPerMaterial)
float _NormalScale; 
float _HeightScale;
float _LayerCount;
float _BinarySteps;
CBUFFER_END

TEXTURE2D(_BaseColor);
SAMPLER(sampler_BaseColor);

TEXTURE2D(_Normal);
SAMPLER(sampler_Normal);

TEXTURE2D(_Height);
SAMPLER(sampler_Height);

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


Varyings ReliefMappingVert(Attributes input){

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

half4 ReliefMappingFrag(Varyings input) : SV_Target{
     
     
    half3x3 tbn = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    
    half3 positionWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
    half3 viewDirWS = normalize(GetCameraPositionWS() - positionWS);
    half3 viewDirTS = normalize(TransformWorldToTangent(viewDirWS,tbn));
     
    half layerHeight = 1.0f;
    half currHeight = SAMPLE_TEXTURE2D(_Height, sampler_Height, input.uv).r;
    half2 deltaUV = -viewDirTS.xy / (viewDirTS.z  * _LayerCount) * _HeightScale; 
    half2 offsetUV = input.uv;
    /*
    ------------------------------ 1.0


    ------------------------------ 0.0
    */
    half perLayerHeight = 1.0 / _LayerCount;
    [unroll(50)]
    while(currHeight < layerHeight ){
        layerHeight = layerHeight - perLayerHeight;
        offsetUV = offsetUV + deltaUV;
        currHeight = SAMPLE_TEXTURE2D(_Height, sampler_Height, offsetUV).r; 
    }

    half deltaUVLen = length(deltaUV);
    half2 currUV = offsetUV;
    half2 preUV  = offsetUV - deltaUV;
    for(int i = 0 ; i < _BinarySteps; i++){
        half2 mid = (preUV + currUV) * 0.5;
        half midLayerHeight = 1.0 - (length(mid - input.uv) / deltaUVLen) * perLayerHeight;
        half midHeight = SAMPLE_TEXTURE2D(_Height, sampler_Height, mid).r;
        if(midHeight < midLayerHeight){
            preUV = mid;
        }else{
            currUV = mid;
        }
    }

    offsetUV = (preUV + currUV) * 0.5;

    if(offsetUV.x > 1.0 || offsetUV.y > 1.0 || offsetUV.x < 0.0 || offsetUV.y < 0.0)
        discard;

    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, offsetUV),_NormalScale);
    half3 normalWS = normalize(TransformTangentToWorld(normalTS, tbn));
     
    Light mainLight = GetMainLight();
    half3 baseColor = SAMPLE_TEXTURE2D(_BaseColor,sampler_BaseColor,offsetUV).xyz; 
    half3 diffuseColor = LightingLambert(mainLight.color, mainLight.direction, normalWS);
     
    return half4(diffuseColor * baseColor ,1.0); 
}
 
#endif