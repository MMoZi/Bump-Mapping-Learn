#ifndef PARALLAX_MAP
#define PARALLAX_MAP

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(UnityPerMaterial)
float _NormalScale; 
float _HeightScale;
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


Varyings ParallaxMappingVert(Attributes input){

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

half4 ParallaxMappingFrag(Varyings input) : SV_Target{
     
    half3x3 tbn = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    
    half3 positionWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
    half3 viewDirWS = GetCameraPositionWS() - positionWS;
    half3 viewDirTS = normalize(TransformWorldToTangent(viewDirWS,tbn));
    
    //https://learnopengl-cn.github.io/05%20Advanced%20Lighting/05%20Parallax%20Mapping/
    //有一个地方需要注意，就是viewDir.xy除以viewDir.z那里。因为viewDir向量是经过了标准化的，viewDir.z会在0.0到1.0之间的某处。
    //当viewDir大致平行于表面时，它的z元素接近于0.0，除法会返回比viewDir垂直于表面的时候更大的P¯向量。
    //所以，从本质上，相比正朝向表面，当带有角度地看向平面时，我们会更大程度地缩放P¯的大小，从而增加纹理坐标的偏移；这样做在视角上会获得更大的真实度。

    //有些人更喜欢不在等式中使用viewDir.z，因为普通的视差贴图会在角度上产生不尽如人意的结果；
    //这个技术叫做有偏移量限制的视差贴图（Parallax Mapping with Offset Limiting）。选择哪一个技术是个人偏好问题，但我倾向于普通的视差贴图。

    half depth = 1.0 - SAMPLE_TEXTURE2D(_Height, sampler_Height, input.uv).r;
    half2 offsetUV = -viewDirTS.xy / viewDirTS.z * depth * _HeightScale; 
    input.uv += offsetUV;
    
    if(input.uv.x > 1.0 || input.uv.y > 1.0 || input.uv.x < 0.0 || input.uv.y < 0.0)
        discard;


    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, input.uv ),_NormalScale);
    half3 normalWS = normalize(TransformTangentToWorld(normalTS, tbn));
     
    Light mainLight = GetMainLight();
    half3 baseColor = SAMPLE_TEXTURE2D(_BaseColor,sampler_BaseColor,input.uv).xyz; 
    half3 diffuseColor = LightingLambert(mainLight.color, mainLight.direction, normalWS);
     
    return half4(diffuseColor * baseColor ,1.0); 
}
 
#endif