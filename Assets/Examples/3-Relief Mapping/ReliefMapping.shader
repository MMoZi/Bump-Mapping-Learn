Shader "Bump/ReliefMapping"
{
    Properties
    {
        [NoScaleOffset]_BaseColor ("Base Color", 2D) = "white" {}
        [NoScaleOffset]_Normal ("Normal", 2D) = "bump" {}
        [NoScaleOffset]_Height ("Height", 2D) = "height"{}

        _NormalScale ("NormalScale", Range(0.0 ,10.0)) = 1.0
        _HeightScale ("HeightScale", Range(0.0, 0.1)) = 0.005
    
        [IntRange]_LayerCount("LayerCount",Range(1.0, 30.0)) = 20.0
        [IntRange]_BinarySteps("BinarySteps",Range(0.0,20.0)) = 6.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
         
        Pass
        { 
            HLSLPROGRAM
            #pragma vertex ReliefMappingVert
            #pragma fragment ReliefMappingFrag 
             
            #include "./ReliefMapping.hlsl"
            ENDHLSL
        }
    }
}
