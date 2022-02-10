Shader "Bump/NormalMapping"
{
    Properties
    {
        [NoScaleOffset]_BaseColor ("Base Color", 2D) = "white" {}
        [NoScaleOffset]_Normal ("Normal", 2D) = "bump" {}
        [NoScaleOffset]_NormalScale ("NormalScale", Range(0.0 ,10.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
         
        Pass
        { 
            HLSLPROGRAM
            #pragma vertex NormalMappingVert
            #pragma fragment NormalMappingFrag 
             
            #include "./NormalMapping.hlsl"
            ENDHLSL
        }
    }
}
