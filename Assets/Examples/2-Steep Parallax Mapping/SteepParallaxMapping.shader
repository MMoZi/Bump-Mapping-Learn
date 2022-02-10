Shader "Bump/SteepParallaxMapping"
{
    Properties
    {
        [NoScaleOffset]_BaseColor ("Base Color", 2D) = "white" {}
        [NoScaleOffset]_Normal ("Normal", 2D) = "bump" {}
        [NoScaleOffset]_Height ("Height", 2D) = "height"{}

        _NormalScale ("NormalScale", Range(0.0 ,10.0)) = 1.0
        _HeightScale ("HeightScale", Range(0.0, 0.1)) = 1.0
    
        [IntRange]_LayerCount("LayerCount",Range(1.0, 40.0)) = 20.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
         
        Pass
        { 
            HLSLPROGRAM
            #pragma vertex SteepParallaxMappingVert
            #pragma fragment SteepParallaxMappingFrag 
             
            #include "./SteepParallaxMapping.hlsl"
            ENDHLSL
        }
    }
}
