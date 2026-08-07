Shader "Custom/Skybox/DaylightClouds"
{
    Properties
    {
        [Header(Sky Colors)]
        _TopColor ("Sky Top Color", Color) = (0.1, 0.4, 0.85, 1)
        _HorizonColor ("Sky Horizon Color", Color) = (0.6, 0.8, 0.95, 1)
        _BottomColor ("Ground Color", Color) = (0.25, 0.22, 0.2, 1)

        [Header(Sun)]
        _SunColor ("Sun Color", Color) = (1, 0.95, 0.8, 1)
        _SunSize ("Sun Size", Range(0.001, 0.1)) = 0.02
        _SunBlur ("Sun Edge Blur", Range(0.001, 0.2)) = 0.05

        [Header(Clouds)]
        _CloudColor ("Cloud Color", Color) = (1, 1, 1, 1)
        _CloudShadowColor ("Cloud Shadow Color", Color) = (0.7, 0.75, 0.85, 1)
        _CloudScale ("Cloud Scale", Range(0.5, 10)) = 2.5
        _CloudDensity ("Cloud Density (Threshold)", Range(0.0, 1.0)) = 0.45
        _CloudSoftness ("Cloud Edge Softness", Range(0.01, 0.5)) = 0.2
        _CloudSpeed ("Cloud Movement Speed", Vector) = (0.01, 0.005, 0, 0)
    }

    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            fixed4 _TopColor, _HorizonColor, _BottomColor;
            fixed4 _SunColor;
            float _SunSize, _SunBlur;

            fixed4 _CloudColor, _CloudShadowColor;
            float _CloudScale, _CloudDensity, _CloudSoftness;
            float4 _CloudSpeed;

            // 擬似乱数生成
            float hash(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            // 2D Value Noise
            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f); // Smoothstep補間

                float bl = hash(i);
                float br = hash(i + float2(1.0, 0.0));
                float tl = hash(i + float2(0.0, 1.0));
                float tr = hash(i + float2(1.0, 1.0));

                return lerp(lerp(bl, br, f.x), lerp(tl, tr, f.x), f.y);
            }

            // フラクタルノイズ（重なり合った雲の質感を表現）
            float fBm(float2 p)
            {
                float sum = 0.0;
                float amp = 0.5;
                for (int i = 0; i < 4; i++)
                {
                    sum += noise(p) * amp;
                    p *= 2.02;
                    amp *= 0.5;
                }
                return sum;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = v.vertex.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 dir = normalize(i.worldPos);
                float y = dir.y;

                // ------------------------------------------------
                // 1. ベースの空グラデーション
                // ------------------------------------------------
                fixed3 skyColor;
                if (y > 0.0)
                {
                    skyColor = lerp(_HorizonColor.rgb, _TopColor.rgb, pow(y, 0.8));
                }
                else
                {
                    skyColor = lerp(_HorizonColor.rgb, _BottomColor.rgb, pow(-y, 0.8));
                }

                // ------------------------------------------------
                // 2. 太陽の描画 (Directional Lightと連動)
                // ------------------------------------------------
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float sunDot = max(0.0, dot(dir, lightDir));
                
                // 太陽の円とグラデーション
                float sunDist = 1.0 - sunDot;
                float sunMask = smoothstep(_SunSize + _SunBlur, _SunSize, sunDist);
                skyColor += _SunColor.rgb * sunMask;

                // ------------------------------------------------
                // 3. 雲の生成（空の上半球のみ）
                // ------------------------------------------------
                if (y > 0.02)
                {
                    // 天井平面への投射（視線ベクトルを高さyで割って平面UVを作る）
                    float2 cloudUV = (dir.xz / (y + 0.3)) * _CloudScale;
                    
                    // 時間経過による移動
                    cloudUV += _Time.y * _CloudSpeed.xy;

                    // ノイズで雲の形状を作る
                    float cloudVal = fBm(cloudUV);

                    // 密度閾値と輪郭のスムース化
                    float cloudAlpha = smoothstep(_CloudDensity, _CloudDensity + _CloudSoftness, cloudVal);
                    
                    // 地平線付近で雲を滑らかに消す (Horizon Fade)
                    float horizonFade = smoothstep(0.02, 0.25, y);
                    cloudAlpha *= horizonFade;

                    // 雲の影（簡易的な陰影表現）
                    float shadowVal = fBm(cloudUV + float2(0.05, 0.05));
                    fixed3 finalCloudColor = lerp(_CloudShadowColor.rgb, _CloudColor.rgb, shadowVal);

                    // 空と雲をアルファ合成
                    skyColor = lerp(skyColor, finalCloudColor, cloudAlpha);
                }

                return fixed4(skyColor, 1.0);
            }
            ENDCG
        }
    }
}