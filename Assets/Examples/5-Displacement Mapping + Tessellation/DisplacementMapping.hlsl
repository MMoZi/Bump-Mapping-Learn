#ifndef DISPLACEMENT_MAPPING
#define DISPLACEMENT_MAPPING

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(UnityPerMaterial)
float _NormalScale; 
float _HeightScale; 
float _TessellationFactor;
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
    float3  normalWS        : TEXCOORD1;
    float3  tangentWS       : TEXCOORD2;
    float3  bitangentWS     : TEXCOORD3; 
};

struct HSInput{
    float3 positionOS : INTERNALTESSPOS;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
};

struct HSPCOutput {  
    float edgeFactor[3] : SV_TESSFACTOR;
    float insideFactor  : SV_INSIDETESSFACTOR;
};

HSInput DisplacementMappingVert(Attributes input){ 
    HSInput o;
    o.positionOS = input.positionOS;
    o.normalOS   = input.normalOS;
    o.tangentOS  = input.tangentOS;
    o.texcoord   = input.texcoord;
    return o;
}
   
   
HSPCOutput PatchConstant (InputPatch<HSInput,3> patch, uint patchID : SV_PrimitiveID){
 
    HSPCOutput o;
    o.edgeFactor[0] = _TessellationFactor;
    o.edgeFactor[1] = _TessellationFactor;
    o.edgeFactor[2] = _TessellationFactor;
    o.insideFactor  = _TessellationFactor;
    return o;
}

[domain("tri")]                         // quad,triangle等
[partitioning("fractional_odd")]        // equal_spacing,fractional_odd,fractional_even
[outputtopology("triangle_cw")]         //输出的三角面正面的环绕方式,triangle_cw:顶点顺时针排列代表正面,triangle_ccw:顶点逆时针排列代表正面,line:只针对line的细分
[patchconstantfunc("PatchConstant")]    //一个patch一共有三个点，但是这三个点都共用这个函数
[outputcontrolpoints(3)]                //不同的图元会对应不同的控制点
[maxtessfactor(64.0f)]                  //最大的细分因子   
HSInput DisplacementMappingControlPoint (InputPatch<HSInput,3> patch,uint id : SV_OutputControlPointID){
    return patch[id];
}
 
 
[domain("tri")] 
Varyings DisplacementMappingDomain (HSPCOutput tessFactors, const OutputPatch<HSInput,3> patch, float3 bary : SV_DOMAINLOCATION)
{
    Attributes input;
    input.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
	input.tangentOS  = patch[0].tangentOS * bary.x + patch[1].tangentOS * bary.y + patch[2].tangentOS * bary.z;
	input.normalOS   = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
	input.texcoord   = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;

    
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS.xyz,input.tangentOS);
    
    half height =  SAMPLE_TEXTURE2D_LOD(_Height, sampler_Height, input.texcoord,2).r;
    
    half3 positionWS = TransformObjectToWorld(input.positionOS);
    positionWS.y += height * _HeightScale;

    Varyings output;
    output.positionCS = TransformWorldToHClip(positionWS);
    output.uv = input.texcoord; 
    output.normalWS     = normalInputs.normalWS;  
    output.tangentWS    = normalInputs.tangentWS;
    output.bitangentWS  = normalInputs.bitangentWS;

    return output; 
}

 


half4 DisplacementMappingFrag(Varyings input) : SV_Target{ 
      
    half3x3 tbn = half3x3(input.tangentWS, input.bitangentWS, input.normalWS);
    
    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, input.uv),_NormalScale);
    half3 normalWS = normalize(TransformTangentToWorld(normalTS, tbn));
     
    Light mainLight = GetMainLight();
    half3 baseColor = SAMPLE_TEXTURE2D(_BaseColor,sampler_BaseColor,input.uv).xyz; 
    half3 diffuseColor = LightingLambert(mainLight.color, mainLight.direction, normalWS);
     
    return half4(diffuseColor * baseColor ,1.0); 
}
 
#endif