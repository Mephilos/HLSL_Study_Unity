Shader "Custom/BlackHoleShader"
{
    Properties
    {
        _EventHorizonRadius ("Event Horizon Radius", Range(0, 5)) = 0.5
        _AccretionDiskRadius ("Disk Radius", Range(1, 10)) = 2.5
        _GravityStrength ("Gravity Strength", Range(0, 20)) = 5.0
        _DiskColor ("Disk Color", Color) = (1, 0.5, 0.1, 1)
        
        _CenterPosition ("Center Position", Vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "BlackHolePass"
            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            float _EventHorizonRadius;
            float _AccretionDiskRadius;
            float _GravityStrength;
            float4 _DiskColor;
            float4 _CenterPosition;

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.screenPos = ComputeScreenPos(output.positionCS);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 ro = GetCameraPositionWS();
                float3 rd = normalize(input.positionWS - ro);
                float3 p = ro;
                
                float3 center = _CenterPosition.xyz;
                float3 accumulatedGlow = float3(0, 0, 0);
                
                const int MAX_STEPS = 48; 
                const float STEP_SIZE = 0.2; 
                
                bool hitHorizon = false;

                
                for(int i = 0; i < MAX_STEPS; i++)
                {
                    float dist = length(p - center);

                    
                    if(dist < _EventHorizonRadius)
                    {
                        hitHorizon = true;
                        break;
                    }

                    // 2. 중력 왜곡
                    float force = _GravityStrength / (dist * dist + 0.001);
                    float3 toCenter = normalize(center - p);
                    
                    rd = normalize(rd + toCenter * force * STEP_SIZE);

                    
                    float heightDiff = abs(p.y - center.y);
                    if(heightDiff < 0.1 && dist < _AccretionDiskRadius && dist > _EventHorizonRadius)
                    {
                        float diskIntensity = 1.0 - (dist / _AccretionDiskRadius);
                        accumulatedGlow += _DiskColor.rgb * diskIntensity * 0.2;
                    }

                    p += rd * STEP_SIZE * dist; 

                    if(dist > 50.0) break;
                }

                half4 finalColor = half4(0, 0, 0, 1);

                if(hitHorizon)
                {
                    finalColor = half4(0, 0, 0, 1);
                }
                else
                {
                    float3 farPoint = p + rd * 100.0;
                    float4 clipPos = TransformWorldToHClip(farPoint);
                    float2 screenUV = clipPos.xy / clipPos.w;
                    screenUV = screenUV * 0.5 + 0.5;

                    #if UNITY_UV_STARTS_AT_TOP
                    screenUV.y = 1.0 - screenUV.y;
                    #endif

                    half3 bgCol = SampleSceneColor(screenUV);
                    finalColor = half4(bgCol, 1.0);
                }

                finalColor.rgb += accumulatedGlow;

                return finalColor;
            }
            ENDHLSL 
        }
    }
}