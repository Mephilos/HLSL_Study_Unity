Shader "MyShaders/DissolveShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1) // 기본 색상
        _DissolveMap("Dissolve Noise Texture", 2D) = "white" {} // 노이즈 텍스처
        [HDR]_DissolveEdgeColor("Edge Color", Color) = (1, 0, 0, 1) // 디졸브 경계선 색상
        _DissolveAmount("Dissolve Amount", Range(0.0, 1.0)) = 0.0 // 디졸브 진행도
        _DissolveEdgeWidth("Edge Width", Range(0.0, 0.1)) = 0.01 // 디졸브 엣지
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float _DissolveAmount;
                half4 _DissolveEdgeColor;
                half _DissolveEdgeWidth;
            CBUFFER_END
            
            TEXTURE2D(_DissolveMap);
            SAMPLER(sampler_DissolveMap);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half noiseValue = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, IN.uv).r;

                clip(noiseValue - _DissolveAmount);

                half edgeValue = step(_DissolveAmount, noiseValue) - step(_DissolveAmount + _DissolveEdgeWidth, noiseValue);
                
                half4 finalColor = lerp(_BaseColor, _DissolveEdgeColor, edgeValue);

                return finalColor;
            }
            ENDHLSL
        }
    }
}