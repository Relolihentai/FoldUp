﻿Shader "ShaderTemplate/Gamma"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline" 
            "Queue"="Geometry"
            "RenderType"="Opaque"
        }
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _BaseColor;
        float4 _MainTex_ST;
        CBUFFER_END
        
        ENDHLSL
        
        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            struct a2v
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float3 positionOS: TEXCOORD4;
                float4 position: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float3 worldNormal: TEXCOORD2;
                float3 viewDir: TEXCOORD3;
            };

            v2f vert(a2v IN)
            {
                v2f OUT;
                VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(IN.vertex.xyz);
                VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(IN.normal.xyz);
                OUT.positionOS = IN.vertex;
                OUT.position = vertex_position_inputs.positionCS;
                OUT.worldPos = vertex_position_inputs.positionWS;
                OUT.worldNormal = vertex_normal_inputs.normalWS;
                OUT.viewDir = GetCameraPositionWS() - OUT.worldPos;
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float4 frag(v2f IN): SV_Target
            {
                Light light = GetMainLight();
                float3 lightDir = light.direction;
                float3 lightColor = light.color;
                float3 halfDir = normalize(IN.viewDir + lightDir);
                float nol = dot(IN.worldNormal, lightDir);
                float noh = dot(IN.worldNormal, halfDir);
                float nov = dot(IN.worldNormal, IN.viewDir);

                float4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 finalColor = mainColor * _BaseColor * nol;

                float positionOS = pow((IN.positionOS.x + 5) / 10, 2.2);
                float4 gammaColor = float4(positionOS, positionOS, positionOS, 1);
                //return mainColor;
                if (mainColor.x > 0.49) return float4(1, 1, 1, 1);
                return float4(0, 0, 0, 1);
            }
            
            ENDHLSL
        }
    }
}
