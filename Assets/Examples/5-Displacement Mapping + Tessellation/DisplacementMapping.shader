Shader "Bump/DisplacementMapping"
{
    Properties
    {
        _BaseColor ("Base Color", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump" {}
        _Height ("Height", 2D) = "height"{}

        _NormalScale ("NormalScale", Range(0.0 ,5.0)) = 1.0
        _HeightScale ("HeightScale", Range(0.0, 5)) = 1
     
        [IntRange]_TessellationFactor ("TessellationFactor", Range(1,32)) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
         
        Pass
        { 
            HLSLPROGRAM
            #pragma target 4.6 
            #pragma vertex DisplacementMappingVert
            #pragma fragment DisplacementMappingFrag 
            #pragma hull DisplacementMappingHull
            #pragma domain DisplacementMappingDomain
            #include "./DisplacementMapping.hlsl"
            ENDHLSL
        }
    }
}
