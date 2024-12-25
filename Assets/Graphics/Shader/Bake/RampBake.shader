Shader "ShaderTemplate/RampBake"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _LightMapFac ("LightMap Fac", Range(0, 2)) = 1
        
        [HDR]_RampColor_0 ("Ramp Color 0", Color) = (1, 1, 1, 1)
        [HDR]_RampColor_1 ("Ramp Color 1", Color) = (1, 1, 1, 1)
        _GradientThreshold ("Gradient Threshold", Range(0, 1)) = 0
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
        float4 _BaseColor,
                _RampColor_0, _RampColor_1,
                _MainTex_ST;
        float _LightMapFac,
                _GradientThreshold;
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
                float2 lightmapUV : TEXCOORD1;
            };

            struct v2f
            {
                float4 position: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float3 worldNormal: TEXCOORD2;
                float3 viewDir: TEXCOORD3;
                float2 lightmapUV : TEXCOORD4;
            };
            
            v2f vert(a2v IN)
            {
                v2f OUT;
                VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(IN.vertex.xyz);
                VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(IN.normal);
                OUT.position = vertex_position_inputs.positionCS;
                OUT.worldPos = vertex_position_inputs.positionWS;
                OUT.worldNormal = vertex_normal_inputs.normalWS;
                OUT.viewDir = GetCameraPositionWS() - OUT.worldPos;
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.lightmapUV = IN.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                return OUT;
            }
            
            float4 frag(v2f IN): SV_Target
            {
                float4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float3 lightMapColor = DecodeLightmap(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, IN.lightmapUV), 2.2);
                float3 indirectColor = _LightMapFac * lightMapColor;

                float nov = saturate(dot(IN.worldNormal, IN.viewDir));
                float F = pow(nov, 5);

                float3 gradient = lerp(_BaseColor, _RampColor_0, min(0.2, _GradientThreshold) * 5);
                gradient = lerp(gradient, _RampColor_1, saturate((step(0.2, _GradientThreshold) * _GradientThreshold - 0.2) / 0.8));
                
                float3 finalColor = indirectColor * mainColor.xyz * _BaseColor * gradient * F;
                return float4(finalColor, 1);
            }
            
            ENDHLSL
        }
        
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
            Cull Off
            HLSLPROGRAM
            
            #pragma vertex vert_meta
            #pragma fragment frag_meta
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/MetaPass.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            struct a2v
            {
                float4 vertex: POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
            };

            struct v2f
            {
                float4 position: SV_POSITION;
                float2 uv: TEXCOORD0;
            };

            v2f vert_meta(a2v IN)
            {
                v2f OUT;
                OUT.position = UnityMetaVertexPosition(IN.vertex, IN.uv1, IN.uv1, unity_LightmapST, unity_DynamicLightmapST);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag_meta(v2f IN) : SV_Target
            {
                UnityMetaInput meta_IN;
                float4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                meta_IN.Albedo = mainColor * _BaseColor * 0.82;
                meta_IN.Emission = mainColor * _BaseColor * 0.3;
                return UnityMetaFragment(meta_IN);
            }
            ENDHLSL
        }

        
    }
    CustomEditor "ShaderGUIGlobalIlluminationFlags"
}
