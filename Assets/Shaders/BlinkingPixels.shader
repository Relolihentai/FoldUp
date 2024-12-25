// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/BlinkingPixels"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        [MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
        [PerRendererData] _AlphaTex ("External Alpha", 2D) = "white" {}
        [PerRendererData] _EnableExternalAlpha ("Enable External Alpha", Float) = 0
        
        _CellSize("Cell Size", Float) = 20
        _BlinkSpeed("Blink Speed", Float) = 1
        _DisplayRatio("Display Ratio", Range(0, 1)) = 1
        _DisplaySmooth("Display Smooth", Range(0, 1)) = 0.1
        _Lightest ("Lightest", Color) = (0.8, 0.8, 0.8, 1)
        _Darkest ("Darkest", Color) = (0.6, 0.6, 0.6, 1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex SpriteVert
            #pragma fragment SpriteFrag
            #pragma target 2.0
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA

            #include "UnityCG.cginc"
            
            #ifdef UNITY_INSTANCING_ENABLED
            
                UNITY_INSTANCING_BUFFER_START(PerDrawSprite)
                    // SpriteRenderer.Color while Non-Batched/Instanced.
                    UNITY_DEFINE_INSTANCED_PROP(fixed4, unity_SpriteRendererColorArray)
                    // this could be smaller but that's how bit each entry is regardless of type
                    UNITY_DEFINE_INSTANCED_PROP(fixed2, unity_SpriteFlipArray)
                UNITY_INSTANCING_BUFFER_END(PerDrawSprite)
            
                #define _RendererColor  UNITY_ACCESS_INSTANCED_PROP(PerDrawSprite, unity_SpriteRendererColorArray)
                #define _Flip           UNITY_ACCESS_INSTANCED_PROP(PerDrawSprite, unity_SpriteFlipArray)
            
            #endif // instancing
            
            CBUFFER_START(UnityPerDrawSprite)
            #ifndef UNITY_INSTANCING_ENABLED
                fixed4 _RendererColor;
                fixed2 _Flip;
            #endif
                float _EnableExternalAlpha;
            CBUFFER_END
            
            // Material Color.
            fixed4 _Color;

            float _CellSize;
            float _BlinkSpeed;
            float _DisplayRatio;
            float _DisplaySmooth;
        
            fixed4 _Lightest;
            fixed4 _Darkest;
            
            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 screenPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            inline float4 UnityFlipSprite(in float3 pos, in fixed2 flip)
            {
                return float4(pos.xy * flip, pos.z, 1.0);
            }
            
            v2f SpriteVert(appdata_t IN)
            {
                v2f OUT;
            
                UNITY_SETUP_INSTANCE_ID (IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            
                OUT.vertex = UnityFlipSprite(IN.vertex, _Flip);
                OUT.vertex = UnityObjectToClipPos(OUT.vertex);
                OUT.texcoord = IN.texcoord;
                OUT.color = IN.color * _Color * _RendererColor;
            
                #ifdef PIXELSNAP_ON
                OUT.vertex = UnityPixelSnap (OUT.vertex);
                #endif
                
                OUT.screenPosition = ComputeScreenPos(OUT.vertex);
            
                return OUT;
            }
            
            sampler2D _MainTex;
            sampler2D _AlphaTex;
            
            fixed4 SampleSpriteTexture (float2 uv)
            {
                fixed4 color = tex2D (_MainTex, uv);
            
            #if ETC1_EXTERNAL_ALPHA
                fixed4 alpha = tex2D (_AlphaTex, uv);
                color.a = lerp (color.a, alpha.r, _EnableExternalAlpha);
            #endif
            
                return color;
            }
        
            float random(int x)
            {
	            x = (x << 13) ^ x;
	            return (1.0 - ((x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0);
            }

            float random01(int x)
            {
                return (random(x) + 1) / 2;
            }

            float smooth(float x)
            {
                return ((6 * x - 15) * x + 10) * x * x * x;
            }

            float smoothLerp(float t, float a, float b)
            {
                t = smooth(t);
                return t * b + (1 - t) * a;
            }

            float noise(float t, int seed)
            {
                int i = (int) t;
                seed = seed * 19 + i * 17;
                return smoothLerp(t - i, random01(seed), random01(seed + 17));
            }
        
            fixed4 SpriteFrag(v2f IN) : SV_Target
            {
                float2 screenPosition = IN.screenPosition.xy / IN.screenPosition.w;
                screenPosition.xy *= _ScreenParams.xy;

                int cellID = (int)(screenPosition.x / _CellSize) +
                             (int)(screenPosition.y / _CellSize) * 256;
                
                float r = noise(_Time.y * _BlinkSpeed + random01(cellID), cellID);
                fixed4 c = r * _Lightest + (1 - r) * _Darkest;

                float displayRatio = (_DisplayRatio * (1 + _DisplaySmooth) - random01(cellID)) / _DisplaySmooth;
                if (displayRatio > 1) displayRatio = 1;
                if (displayRatio < 0) displayRatio = 0;
                
                c *= SampleSpriteTexture (IN.texcoord) * IN.color;
                c.a *= smooth(displayRatio);
                c.rgb *= c.a;
                return c;
            }
        ENDCG
        }
    }
}
