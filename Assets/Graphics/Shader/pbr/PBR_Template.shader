Shader "ShaderTemplate/PBR_Template"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _EmissionColor("_Emission Color", Color) = (1, 1, 1, 1)
        _DiffuseTex("Texture", 2D) = "white" {}
        [Normal]_NormalTex("_NormalTex", 2D) = "bump" {}
        _NormalScale("_NormalScale",Range(0, 1)) = 1
        _RoughTex ("_RoughTex", 2D) = "white"{}
        _RoughFac ("RoughFac", Range(0, 3)) = 0
        _MetallicTex ("_MetallicTex", 2D) = "white"{}
        _HeightTex ("_HeightTex", 2D) = "black"{}
        _HeightStrength ("_HeightStrength", Range(-0.05, 0.05)) = 0
        _DisplaceTex ("_DisplaceTex", 2D) = "black" {}
        _DisplaceStrength ("_DisplaceStrength", Range(0, 1)) = 0
        _AoTex ("_AoTex", 2D) = "white"{}
        _EmissionTex ("_EmissionTex", 2D) = "white"{}
        _BRDFIntegrationMap ("_BRDFIntegrationMap", 2D) = "white"{}

        _Metallic("_Metallic", Range(0, 1)) = 1
        _Roughness("_Roughness", Range(0, 1)) = 1
        _LightMapFac("_LightMap Fac", Range(0, 1)) = 0.7
        //[Toggle(_True)]_CullOff("Cull Off", Float) = 1
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _DiffuseTex_ST;
        float4 _Diffuse;
        float _NormalScale, _Metallic, _Roughness, _DisplaceStrength, _HeightStrength, _RoughFac, _LightMapFac;
        float4 _BaseColor;
        float4 _EmissionColor;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float2 texcoord : TEXCOORD0;
            float2 lightmapUV : TEXCOORD1;
            float4 tangentOS : TANGENT;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD1;
            float3 normalWS : NORMAL;
            float3 tangentWS : TANGENT;
            float3 BtangentWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD3;
            float2 lightmapUV : TEXCOORD4;

        };

        TEXTURE2D(_DiffuseTex);
        SAMPLER(sampler_DiffuseTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_NormalTex);
        //TEXTURE2D(_MaskTex);
        //SAMPLER(sampler_MaskTex);
        TEXTURE2D(_RoughTex);
        SAMPLER(sampler_RoughTex);
        TEXTURE2D(_MetallicTex);
        SAMPLER(sampler_MetallicTex);
        TEXTURE2D(_HeightTex);
        SAMPLER(sampler_HeightTex);
        TEXTURE2D(_AoTex);
        SAMPLER(sampler_AoTex);
        TEXTURE2D(_EmissionTex);
        SAMPLER(sampler_EmissionTex);
        TEXTURE2D(_DisplaceTex);
        SAMPLER(sampler_DisplaceTex);
        TEXTURE2D(_BRDFIntegrationMap);
        SAMPLER(sampler_BRDFIntegrationMap);
        
        ENDHLSL
        
        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }
            //Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _MetallicTexOn
            #pragma shader_feature _RoughTexOn


            // D 法线分布函数
            float Distribution(float roughness, float noh)
            {
                float lerpSquareRoughness = pow(lerp(0.01, 1, roughness), 2);
                float D = lerpSquareRoughness / (pow(pow(noh, 2) * (lerpSquareRoughness - 1) + 1, 2) * PI);
                return D;
			}

            // G项子项
            inline float G_subSection(float dot, float k)
            {
                //return dot / lerp(dot, 1, k);
                return dot / (k + (1 - k) * dot); 
            }

            // G
            float Geometry(float roughness, float nol, float nov)
            {
                float k = pow(1 + roughness, 2) / 8;

                float GLeft = G_subSection(nol, k);
                float GRight = G_subSection(nov, k);
                float G = GLeft * GRight;
                return G;
			}

            // 间接光 F
            float3 IndirF_Function(float NdotV, float3 F0, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(float3(1, 1, 1) - float3(roughness, roughness, roughness) - F0);
            }
            // 直接光 F
            float3 FresnelEquation(float3 F0, float nov)
            {
                float3 F = F0 + (1 - F0) * pow(1 - nov, 5);
                //float3 F = F0 + (1 - F0) * exp2((-5.55473 * nov - 6.98316) * nov);
                return F;
			}
            
            //间接光高光 反射探针
            /*float3 IndirectSpeCube(float3 normalWS, float3 viewWS, float3 F, float roughness, float AO)
            {
                float3 reflectDirWS = reflect(-viewWS, normalWS);                                                  // 计算出反射向量
                roughness = roughness * (1.7 - 0.7 * roughness);                                                   // Unity内部不是线性 调整下拟合曲线求近似
                float MidLevel = roughness * 6;                                                                    // 把粗糙度remap到0-6 7个阶级 然后进行lod采样
                float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel);//根据不同的等级进行采样
            #if !defined(UNITY_USE_NATIVE_HDR)
                return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
            #else
                return speColor.xyz * AO;
            #endif
            }*/

            float3 IndirectSpeCube(float3 normalWS, float3 viewWS, float3 F, float roughness, float AO)
            {
                float3 reflectDir = reflect(-viewWS, normalWS);
                // 有时候反射方向完全相反
                if (reflectDir.y * normalWS.y < 0) reflectDir.y *= -1;
                roughness = roughness * (1.7 - 0.7 * roughness);
                //return reflectDir;
                float MidLevel = roughness * 6;
                float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, MidLevel);
                //float2 envBRDF = SAMPLE_TEXTURE2D(_BRDFIntegrationMap, sampler_BRDFIntegrationMap, float2(saturate(dot(normalWS, viewWS)), roughness)).xy;
                //return speColor;
                //float4 indirectSpecular = speColor * (F.x * envBRDF.x + envBRDF.y);
            #if !defined(UNITY_USE_NATIVE_HDR)
                return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
            #else
                return indirectSpecular.xyz * AO;
            #endif
            }

            float3 IndirectSpeFactor(float roughness, float smoothness, float3 BRDFspe, float3 F0, float NdotV)
            {
                #ifdef UNITY_COLORSPACE_GAMMA
                float SurReduction = 1 - 0.28 * roughness * roughness;
                #else
                float SurReduction = 1 / (roughness * roughness + 1);
                #endif
                #if defined(SHADER_API_GLES) // Lighting.hlsl 261 行
                float Reflectivity = BRDFspe.x;
                #else
                float Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
                #endif
                float GrazingTSection = saturate(Reflectivity + smoothness);
                float fre = Pow4(1 - NdotV);
                // float fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行
                return lerp(F0, GrazingTSection, fre) * SurReduction;
            }
            
            float3 SH_IndirectionDiff(float3 normal)
            {
                float4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
                float3 Color = SampleSH9(SHCoefficients, normal);
                return max(0, Color);
            }

            float2 ParallaxMapping(float2 texCoords, float3 viewDir)
            { 
                //高度层数
                float numLayers = 100;

                //每层高度
                float layerHeight = 1.0 / numLayers;
                // 当前层级高度
                float currentLayerHeight = 0.0;

                if (_HeightStrength == 0) return texCoords;
                //视点方向偏移总量
                float2 P = viewDir.xy / viewDir.z * _HeightStrength; 

                //每层高度偏移量
                float2 deltaTexCoords = P / numLayers;

                //当前 UV
                float2 currentTexCoords = texCoords;
                float currentHeightMapValue = 0;

                for (int i = 0; i < numLayers; i++)
                {
                    // 按高度层级进行 UV 偏移
                    currentTexCoords += deltaTexCoords;
                    // 从高度贴图采样获取的高度
                    currentHeightMapValue = SAMPLE_TEXTURE2D(_HeightTex, sampler_HeightTex, currentTexCoords).r; 
                    // 采样点高度
                    currentLayerHeight += layerHeight;
                    if (currentLayerHeight > currentHeightMapValue) break;
                }
                //return currentTexCoords;
            
                //前一个采样的点
                float2 prevTexCoords = currentTexCoords - deltaTexCoords;
                
                //线性插值
                float afterHeight  = currentHeightMapValue - currentLayerHeight;
                float beforeHeight = SAMPLE_TEXTURE2D(_HeightTex, sampler_HeightTex, prevTexCoords).r - (currentLayerHeight - layerHeight);
                float weight =  afterHeight / (afterHeight - beforeHeight);
                float2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);
                
                return finalTexCoords;  
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.texcoord, _DiffuseTex);
                o.lightmapUV = v.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;

                float displacement = SAMPLE_TEXTURE2D_LOD(_DisplaceTex, sampler_DisplaceTex, o.uv, 0);
                displacement = (displacement - 0.5) * _DisplaceStrength;
                v.positionOS.xyz += v.normalOS * displacement;
                
            
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;
                o.positionWS = PositionInputs.positionWS;

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz, v.tangentOS);
                o.normalWS.xyz = NormalInputs.normalWS;
                o.tangentWS.xyz = NormalInputs.tangentWS;
                o.BtangentWS.xyz = NormalInputs.bitangentWS;

                o.viewDirWS = SafeNormalize(GetCameraPositionWS() - PositionInputs.positionWS);

            
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // TBN
                float3x3 TBN = {i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz};
                TBN = transpose(TBN);
                
                Light mainLight = GetMainLight();
                float4 lightColor = float4(mainLight.color, 1);
                float3 viewDir = normalize(i.viewDirWS);
                float3 lightDir = normalize(mainLight.direction);
                float3 halfDir = normalize(viewDir + lightDir);
                
                // 视差纹理偏移
                float3 tanViewDir = mul(viewDir, TBN);
                /*float height = SAMPLE_TEXTURE2D(_HeightTex, sampler_HeightTex, i.uv).x;
                float2 displace = tanViewDir.xy / tanViewDir.z * height * _HeightStrength;
                i.uv += displace;*/
                i.uv = ParallaxMapping(i.uv, tanViewDir);
                
                float4 albedo = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, i.uv) * _BaseColor;
                float4 rawNormal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);
                //float4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv);
                float metallic = 0;
                #if _MetallicTexOn
                    metallic = SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, i.uv).x;
                #else
                    metallic = _Metallic;
                #endif

                float smoothness = 0;
                #if _RoughTexOn
                    smoothness = SAMPLE_TEXTURE2D(_RoughTex, sampler_RoughTex, i.uv).x;
                #else
                    smoothness = 1 - _Roughness;
                #endif
                
                float ao = SAMPLE_TEXTURE2D(_AoTex, sampler_AoTex, i.uv).x;
                float em = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, i.uv).x;
                float roughness = pow(1 - smoothness, _RoughFac + 1);
                //float roughness = smoothness;

                float3 realNormal = UnpackNormalScale(rawNormal, _NormalScale);
                realNormal.z = sqrt(1 - saturate(dot(realNormal.xy, realNormal.xy)));
                float3 normal = NormalizeNormalPerPixel(mul(TBN, realNormal));
                float3 normalDir = normalize(normal);

                float noh = max(saturate(dot(normalDir, halfDir)), 0.0001);
                //mark 不取max会导致边缘与过渡线发黑
                float nol = max(saturate(dot(normalDir, lightDir)), 0.01);
                float nov = max(saturate(dot(normalDir, viewDir)), 0.01);
                float hol = max(saturate(dot(halfDir, lightDir)), 0.0001);
                float hov = max(saturate(dot(halfDir, viewDir)), 0.0001);

                float3 F0 = lerp(0.04, albedo.rgb, metallic);
                
                //直接光
                float D = Distribution(roughness, noh);
                
                float G = Geometry(roughness, nol, nov);
                
                float3 F = FresnelEquation(F0, nov);
                
                float3 SpecularResult = (D * G * F) / max(nov * nol * 4, 0.002);
                float3 SpecColor = SpecularResult * ao;

                float3 ks = F;
                float3 kd = saturate(1 - ks) * (1 - metallic);

                float3 diffColor = albedo.xyz;
                float3 directLightResult = (kd * diffColor + (1 - kd) * SpecColor) * lightColor.xyz;
                
                // 间接光漫反射
                //float3 shcolor = SH_IndirectionDiff(normalDir) * ao;
                /*float3 indirect_ks = FresnelEquation(F0, nov);
                float3 indirect_kd = 1 - indirect_ks;*/
                //float3 indirect_ks = IndirF_Function(nov, F0, roughness);
                //float3 indirect_kd = (1 - indirect_ks) * (1 - metallic);
                //float3 indirectDiffColor = shcolor * indirect_kd * albedo.xyz;
                
                // 间接光高光反射
                //float3 IndirectSpeCubeColor = IndirectSpeCube(normalDir, viewDir, F, roughness, ao);
                //float3 IndirectSpeCubeFactor = IndirectSpeFactor(roughness, smoothness, SpecularResult, F0, nov);

                //float3 IndirectSpeColor = IndirectSpeCubeFactor * IndirectSpeCubeColor;

                // 间接光
                //float3 IndirectColor = IndirectSpeColor + indirectDiffColor;
                //float3 lightMapColor = DecodeLightmap(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, i.uv), 1);

                float3 lightMapColor = DecodeLightmap(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, i.lightmapUV), 2.2);
                float3 indirectColor = _LightMapFac * lightMapColor;
                
                float3 finalCol = indirectColor + directLightResult + em * _EmissionColor.xyz;
                return float4(finalCol, 1);
            }
            ENDHLSL
        }
    }
    CustomEditor "ShaderGUIReal"
}