Shader "ShaderTemplate/DissolveBake"
{
    Properties
    {
        [HDR]_BaseColor ("Base Color", Color) = (1,1,1,1)
    	[HDR]_EmissionColor_0 ("Emission Color 0", Color) = (1, 1, 1, 1)
    	[HDR]_EmissionColor_1 ("Emission Color 1", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _LightMapFac ("LightMap Fac", Range(0, 2)) = 1
    	_Gloss ("Specular Gloss", Float) = 8
    	
    	_TessCenterPos("Tess Center Position", Vector) = (0, 0, 0, 0)
    	_TessMinVal("Tess Min Value", Float) = 0
    	_TessMaxVal("Tess Max Value", Float) = 10
    	_TessFactor("Tess Factor", Float) = 15
        
    	_DissolveDir("Dissolve Direction", Vector) = (0, 0, 0, 0)
    	_DissolveThreshold("Dissolve Threshold", Range(-110, 80)) = 0
        _Strength("Dissolve Strength", Float) = 1
        _Scale("Dissolve Scale", Float) = 1
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
        float4 _BaseColor, _EmissionColor_0, _EmissionColor_1;
        float4 _MainTex_ST;
        float _LightMapFac, _Strength, _Scale, _TessMinVal, _TessMaxVal, _TessFactor, _DissolveThreshold, _Gloss;
        float3 _TessCenterPos, _DissolveDir;
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
            #pragma geometry geom
            #pragma fragment frag

            #include "Hash.hlsl"

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

            struct t2g
            {
	            float3 worldPos : TEXCOORD0;
            	float3 normal: NORMAL;
            	float2 uv : TEXCOORD1;
            	float2 lightmapUV : TEXCOORD2;
            };

            struct g2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 worldNormal: TEXCOORD1;
            	float3 worldPos : TEXCOORD2;
                float2 lightmapUV : TEXCOORD3;
                float EmissionParam : TEXCOORD4;
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
                OUT.worldPos = TransformObjectToWorld(IN.vertex);
                OUT.normal = IN.normal;
                OUT.uv = IN.uv;
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
            	float3 worldPos = (IN[0].worldPos + IN[1].worldPos + IN[2].worldPos) / 3;
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
            t2g domain(TessParam tessParam, float3 bary : SV_DomainLocation, const OutputPatch<TessOut, 3> IN)
            {
	            t2g OUT;
            	OUT.worldPos = IN[0].worldPos * bary.x + IN[1].worldPos * bary.y + IN[2].worldPos * bary.z;
            	OUT.normal = IN[0].normal * bary.x + IN[1].normal * bary.y + IN[2].normal * bary.z;
            	OUT.uv = IN[0].uv * bary.x + IN[1].uv * bary.y + IN[2].uv * bary.z;
            	OUT.lightmapUV = IN[0].lightmapUV * bary.x + IN[1].lightmapUV * bary.y + IN[2].lightmapUV * bary.z;
            	return OUT;
            }

            g2f VertexOutput(float3 pos, float3 normal, float2 uv, float2 lightmapUV, float param)
            {
                g2f OUT;
                VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(normal);
                OUT.positionCS = TransformWorldToHClip(pos);
            	OUT.worldPos = pos;
                OUT.worldNormal = vertex_normal_inputs.normalWS;
                OUT.uv = TRANSFORM_TEX(uv, _MainTex);
                OUT.lightmapUV = lightmapUV;
                OUT.EmissionParam = param;
                return OUT;
            }

            [maxvertexcount(3)]
            void geom(triangle t2g IN[3], inout TriangleStream<g2f> triStream)
            {
                float3 p0 = IN[0].worldPos.xyz;
				float3 p1 = IN[1].worldPos.xyz;
				float3 p2 = IN[2].worldPos.xyz;

				float3 n0 = IN[0].normal;
				float3 n1 = IN[1].normal;
				float3 n2 = IN[2].normal;

            	float2 uv0 = IN[0].uv;
				float2 uv1 = IN[1].uv;
				float2 uv2 = IN[2].uv;

            	float2 luv0 = IN[0].lightmapUV;
				float2 luv1 = IN[1].lightmapUV;
				float2 luv2 = IN[2].lightmapUV;

				float3 center = (p0 + p1 + p2) / 3;
            	
				//float offset = center.y - _Height;
            	float dissolveFac = projVectorFac(center, _DissolveDir);
            	float fall = smoothstep(-110, 80, _DissolveThreshold);
            	dissolveFac = lerp(dissolveFac, hash11(dissolveFac), fall);
            	float offset = dissolveFac - (_DissolveThreshold / 10);

				if (offset < 0)
				{
					triStream.Append(VertexOutput(p0, n0, uv0, luv0, -1));
					triStream.Append(VertexOutput(p1, n1, uv1, luv1, -1));
					triStream.Append(VertexOutput(p2, n2, uv2, luv2, -1));
					triStream.RestartStrip();
					return;
				}

				if (offset > 1) return;

				float ss_offset = smoothstep(0, 1, offset);

				float3 translation = (offset + clamp(float3(rand(p0.xyz), rand(p1.xyz), rand(p2.xyz)), 0, 0.2)) * _Strength;
            	float posOffset = (otherHash33(_DissolveThreshold + 6.2831 * translation) * 0.5 + 0.5) / 30;
            	translation += posOffset;
            	
				float3x3 rotationMatrix = rotation3x3(sin(_DissolveThreshold + 6.2831 * rand(center.zyx)) * 0.5 + 0.5);
				float scale = _Scale - ss_offset;

				float3 t_p0 = mul(rotationMatrix, p0 - center) * scale + center + translation;
				float3 t_p1 = mul(rotationMatrix, p1 - center) * scale + center + translation;
				float3 t_p2 = mul(rotationMatrix, p2 - center) * scale + center + translation;
				float3 normal = normalize(cross(t_p1 - t_p0, t_p2 - t_p0));

				triStream.Append(VertexOutput(t_p0, normal, uv0, luv0, ss_offset));
				triStream.Append(VertexOutput(t_p1, normal, uv1, luv1, ss_offset));
				triStream.Append(VertexOutput(t_p2, normal, uv2, luv2, ss_offset));
				triStream.RestartStrip();
            }

            float4 frag(g2f IN): SV_Target
            {
            	float3 baseColor = _BaseColor;
                float4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float3 lightMapColor = DecodeLightmap(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, IN.lightmapUV), 2.2);
                float3 indirectColor = _LightMapFac * lightMapColor;
            	float3 emissionColor = step(0, IN.EmissionParam) * _EmissionColor_0 + step(IN.EmissionParam, 0) * _BaseColor;
            	if (IN.EmissionParam > 0)
            	{
            		baseColor = lerp(lerp(_BaseColor, _BaseColor * _EmissionColor_1, IN.EmissionParam), _EmissionColor_1, IN.EmissionParam);
            	}

				/*Light light = GetMainLight();
            	float3 lightDir = light.direction;
            	float3 viewDir =  SafeNormalize(GetCameraPositionWS() - IN.worldPos);
            	float3 halfDir = normalize(viewDir + lightDir);
            	
            	float nol = max(saturate(dot(IN.worldNormal, lightDir)), 0.01);
            	float noh = max(saturate(dot(IN.worldNormal, halfDir)), 0.0001);

            	float specularStrength = pow(noh, _Gloss);*/
            	
                float3 finalColor = indirectColor * mainColor.xyz * baseColor * emissionColor;
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
