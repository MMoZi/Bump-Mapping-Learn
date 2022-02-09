Shader "Bump/NormalMapping"
{
    Properties
    {
        _BaseColor ("Base Color", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump" {}
        _NormalScale ("NormalScale", Range(0.0 ,10.0)) = 1.0
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
