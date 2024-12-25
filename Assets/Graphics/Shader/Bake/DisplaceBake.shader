Shader "ShaderTemplate/DisplaceBake"
{
    Properties
    {
    	_MainTex ("Base Tex", 2D) = "white" {}
        [HDR]_BaseColor_0 ("Base Color 0", Color) = (1,1,1,1)
    	[HDR]_BaseColor_1 ("Base Color 1", Color) = (1,1,1,1)
    	[HDR]_BaseColor_2 ("Base Color 2", Color) = (1,1,1,1)
        _LightMapFac ("LightMap Fac", Range(0, 2)) = 1
    	
    	_TessCenterPos("Tess Center Position", Vector) = (0, 0, 0, 0)
    	_TessMinVal("Tess Min Value", Float) = 0
    	_TessMaxVal("Tess Max Value", Float) = 10
    	_TessFactor("Tess Factor", Float) = 15
    	
    	_PixelThreshold ("PixelThreshold", Range(1, 150)) = 1
        _DisplaceThreshold ("_DisplaceThreshold", Range(-1, 1)) = 0
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
        float4 _BaseColor_0, _BaseColor_1, _BaseColor_2;
        float4 _MainTex_ST;
        float _LightMapFac,
				_TessMinVal, _TessMaxVal, _TessFactor,
				_DisplaceThreshold, _PixelThreshold;
        float3 _TessCenterPos;
        CBUFFER_END
        
        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag

            #include "Noise.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            struct a2v
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;
            };

            struct v2t
            {
	            float3 worldPos : TEXCOORD0;
            	float3 normal: NORMAL;
            	float2 uv : TEXCOORD1;
            	float2 lightmapUV : TEXCOORD2;
            };

            struct TessOut
            {
            	float3 worldPos : TEXCOORD0;
            	float3 normal: NORMAL;
	            float2 uv : TEXCOORD1;
            	float2 lightmapUV : TEXCOORD2;
            };

            struct TessParam
            {
	            float EdgeTess[3] : SV_TessFactor;
            	float InsideTess : SV_InsideTessFactor;
            };

            struct t2f
            {
            	float4 positionCS : SV_POSITION;
	            float3 worldPos : TEXCOORD0;
            	float2 uv : TEXCOORD1;
            	float2 lightmapUV : TEXCOORD2;
            };

            float3 randto3D(float3 seed)
			{
				float3 f = sin(float3(dot(seed, float3(127.1, 337.1, 256.2)), dot(seed, float3(129.8, 782.3, 535.3))
				, dot(seed, float3(269.5, 183.3, 337.1))));
				f = -1 + 2 * frac(f * 43785.5453123);
				return f;
			}

			float rand(float3 seed)
			{
				float f = sin(dot(seed, float3(127.1, 337.1, 256.2)));
				f = -1 + 2 * frac(f * 43785.5453123);
				return f;
			}

			float3x3 AngleAxis3x3(float angle, float3 axis)
			{
				float s, c;
				sincos(angle, s, c);
				float x = axis.x;
				float y = axis.y;
				float z = axis.z;
				return float3x3(
					x * x + (y * y + z * z) * c, x * y * (1 - c) - z * s, x * z * (1 - c) - y * s,
					x * y * (1 - c) + z * s, y * y + (x * x + z * z) * c, y * z * (1 - c) - x * s,
					x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z + (x * x + y * y) * c
				);
			}

			float3x3 rotation3x3(float3 angle)
			{
				return mul(AngleAxis3x3(angle.x, float3(0, 0, 1)), mul(AngleAxis3x3(angle.y, float3(1, 0, 0)), AngleAxis3x3(angle.z, float3(0, 1, 0))));
			}

			float projVectorFac(float3 pointPos, float3 vectorDir)
            {
	            return (vectorDir.x * pointPos.x + vectorDir.y * pointPos.y + vectorDir.z * pointPos.z) /
	            	(vectorDir.x * vectorDir.x + vectorDir.y * vectorDir.y + vectorDir.z * vectorDir.z);
            }
            
            v2t vert(a2v IN)
            {
                v2t OUT;
                OUT.worldPos = TransformObjectToWorld(IN.vertex.xyz);
                OUT.normal = IN.normal;
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.lightmapUV = IN.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                return OUT;
            }

            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [outputcontrolpoints(3)]
            [patchconstantfunc("ConstantHS")]
            [maxtessfactor(64.0)]
            TessOut hull(InputPatch<v2t, 3> IN, uint index : SV_OutputControlPointID)
            {
	            TessOut OUT;
            	OUT.worldPos = IN[index].worldPos;
            	OUT.normal = IN[index].normal;
            	OUT.uv = IN[index].uv;
            	OUT.lightmapUV = IN[index].lightmapUV;
            	return OUT;
            }

            TessParam ConstantHS(InputPatch<v2t, 3> IN, uint index : SV_PrimitiveID)
            {
	            TessParam OUT;
            	//float3 worldPos = (IN[0].worldPos + IN[1].worldPos + IN[2].worldPos) / 3;
            	//float smoothstepResult = smoothstep(_TessMinVal, _TessMaxVal, distance(worldPos.xz, _TessCenterPos.xz));
            	float smoothstepResult = _TessMaxVal;
            	float fac = max((1.0 - smoothstepResult) * _TessFactor, 1);
            	OUT.EdgeTess[0] = fac;
            	OUT.EdgeTess[1] = fac;
            	OUT.EdgeTess[2] = fac;
            	OUT.InsideTess = fac;
            	return OUT;
            }

            [domain("tri")]
            t2f domain(TessParam tessParam, float3 bary : SV_DomainLocation, const OutputPatch<TessOut, 3> IN)
            {
	            t2f OUT;
            	OUT.uv = IN[0].uv * bary.x + IN[1].uv * bary.y + IN[2].uv * bary.z;
            	float3 normal = IN[0].normal * bary.x + IN[1].normal * bary.y + IN[2].normal * bary.z;

            	float displacement = voronoiNoise(OUT.uv, _PixelThreshold);
            	displacement = (displacement - 0.5) * _DisplaceThreshold * 10;
            	
            	OUT.worldPos = IN[0].worldPos * bary.x + IN[1].worldPos * bary.y + IN[2].worldPos * bary.z;
            	OUT.worldPos += normal * displacement;
            	OUT.positionCS = TransformWorldToHClip(OUT.worldPos);
            	
            	OUT.lightmapUV = IN[0].lightmapUV * bary.x + IN[1].lightmapUV * bary.y + IN[2].lightmapUV * bary.z;
            	return OUT;
            }
            
            float4 frag(t2f IN): SV_Target
            {
            	float3 baseColor = _BaseColor_0.xyz;
                float4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            	float noiseParam = voronoiNoise(IN.uv, _PixelThreshold);
            	float3 noiseColor = float3(noiseParam, noiseParam, noiseParam);
                //float3 lightMapColor = DecodeLightmap(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, IN.lightmapUV), 2.2);
                //float3 indirectColor = _LightMapFac * lightMapColor;
                float3 finalColor_0 = smoothstep(noiseColor, hash1to3(noiseParam), 0.5) * mainColor.xyz * baseColor;
            	float allThreshold = smoothstep(0, 150, _PixelThreshold - 1);
            	float3 finalColor_1 = (1 - noiseColor) * mainColor.xyz * _BaseColor_1.xyz;
            	finalColor_1 = sin(_Time.y + 6.2831 * hash33(finalColor_1)) * 0.5 + 0.5;
            	float3 finalColor = lerp(finalColor_0, finalColor_1, allThreshold);
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
                OUT.position = UnityMetaVertexPosition(IN.vertex.xyz, IN.uv1, IN.uv1, unity_LightmapST, unity_DynamicLightmapST);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag_meta(v2f IN) : SV_Target
            {
                UnityMetaInput meta_IN;
                float4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            	float3 baseColor = _BaseColor_0.xyz * _BaseColor_1.xyz * _BaseColor_2.xyz;
                meta_IN.Albedo = mainColor.xyz * baseColor.xyz * 0.82;
                meta_IN.Emission = mainColor.xyz * baseColor.xyz * 0.3;
                return UnityMetaFragment(meta_IN);
            }
            ENDHLSL
        }
    }
    CustomEditor "ShaderGUIGlobalIlluminationFlags"
}
