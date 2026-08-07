Shader "Custom/Skybox/TimeOfDayClouds"
{
    Properties
    {
        [Header(Day Colors)]
        _DayTop ("Day Sky Top", Color) = (0.1, 0.4, 0.85, 1)
        _DayHorizon ("Day Sky Horizon", Color) = (0.6, 0.8, 0.95, 1)
        _DayCloud ("Day Cloud Color", Color) = (1, 1, 1, 1)
        _DayCloudShadow ("Day Cloud Shadow", Color) = (0.7, 0.75, 0.85, 1)

        [Header(Sunset Colors)]
        _SunTop ("Sunset Sky Top", Color) = (0.2, 0.15, 0.35, 1)
        _SunHorizon ("Sunset Sky Horizon", Color) = (0.95, 0.45, 0.15, 1)
        _SunCloud ("Sunset Cloud Color", Color) = (1, 0.6, 0.3, 1)
        _SunCloudShadow ("Sunset Cloud Shadow", Color) = (0.4, 0.2, 0.3, 1)

        [Header(Night Colors)]
        _NightTop ("Night Sky Top", Color) = (0.01, 0.02, 0.05, 1)
        _NightHorizon ("Night Sky Horizon", Color) = (0.05, 0.08, 0.15, 1)
        _NightCloud ("Night Cloud Color", Color) = (0.1, 0.12, 0.18, 1)
        _NightCloudShadow ("Night Cloud Shadow", Color) = (0.03, 0.04, 0.08, 1)
        _StarsIntensity ("Stars Intensity", Range(0, 5)) = 1.5

        [Header(Sun and Moon)]
        _SunColor ("Sun Color", Color) = (1, 0.95, 0.8, 1)
        _SunSize ("Sun Size", Range(0.001, 0.1)) = 0.02
        _MoonColor ("Moon Color", Color) = (0.8, 0.9, 1.0, 1)
        _MoonSize ("Moon Size", Range(0.001, 0.1)) = 0.015

        [Header(Clouds Settings)]
        _CloudScale ("Cloud Scale", Range(0.5, 10)) = 2.5
        _CloudDensity ("Cloud Density", Range(0.0, 1.0)) = 0.45
        _CloudSoftness ("Cloud Softness", Range(0.01, 0.5)) = 0.2
        _CloudSpeed ("Cloud Speed", Vector) = (0.01, 0.005, 0, 0)
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

            // Colors
            fixed4 _DayTop, _DayHorizon, _DayCloud, _DayCloudShadow;
            fixed4 _SunTop, _SunHorizon, _SunCloud, _SunCloudShadow;
            fixed4 _NightTop, _NightHorizon, _NightCloud, _NightCloudShadow;
            fixed4 _SunColor, _MoonColor;

            // Float parameters
            float _StarsIntensity;
            float _SunSize, _MoonSize;
            float _CloudScale, _CloudDensity, _CloudSoftness;
            float4 _CloudSpeed;

            // 擬似乱数
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
                f = f * f * (3.0 - 2.0 * f);

                float bl = hash(i);
                float br = hash(i + float2(1.0, 0.0));
                float tl = hash(i + float2(0.0, 1.0));
                float tr = hash(i + float2(1.0, 1.0));

                return lerp(lerp(bl, br, f.x), lerp(tl, tr, f.x), f.y);
            }

            // fBm ノイズ
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
                // 1. 太陽の角度に基づいて「時間帯（重み）」を判定
                // ------------------------------------------------
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float sunY = lightDir.y; // 太陽の高さ (-1.0 ～ 1.0)

                // 昼・夕・夜のウェイト計算
                float dayWeight = smoothstep(0.05, 0.3, sunY);
                float sunsetWeight = smoothstep(-0.15, 0.05, sunY) * (1.0 - dayWeight);
                float nightWeight = 1.0 - (dayWeight + sunsetWeight);

                // ------------------------------------------------
                // 2. 空のベースカラーブレンド
                // ------------------------------------------------
                fixed3 currentTop = _DayTop.rgb * dayWeight + _SunTop.rgb * sunsetWeight + _NightTop.rgb * nightWeight;
                fixed3 currentHorizon = _DayHorizon.rgb * dayWeight + _SunHorizon.rgb * sunsetWeight + _NightHorizon.rgb * nightWeight;

                fixed3 skyColor;
                if (y > 0.0)
                {
                    skyColor = lerp(currentHorizon, currentTop, pow(y, 0.8));
                }
                else
                {
                    // 地面側は少し暗めの地平線色
                    skyColor = lerp(currentHorizon, currentHorizon * 0.2, pow(-y, 0.8));
                }

                // ------------------------------------------------
                // 3. 星空（夜間のみ表示）
                // ------------------------------------------------
                if (y > 0.0 && nightWeight > 0.0)
                {
                    float2 starUV = dir.xz / (y + 0.1) * 80.0;
                    float starNoise = hash(floor(starUV));
                    
                    // 星の点滅・キラキラ感
                    if (starNoise > 0.985)
                    {
                        float starVal = pow(frac(starNoise * 100.0 + _Time.y * 2.0), 3.0);
                        skyColor += float3(starVal, starVal, starVal) * nightWeight * _StarsIntensity * smoothstep(0.0, 0.2, y);
                    }
                }

                // ------------------------------------------------
                // 4. 太陽と月
                // ------------------------------------------------
                // 太陽
                float sunDot = max(0.0, dot(dir, lightDir));
                float sunDist = 1.0 - sunDot;
                float sunMask = smoothstep(_SunSize + 0.002, _SunSize, sunDist);
                skyColor += _SunColor.rgb * sunMask * (1.0 - nightWeight);

                // 月（太陽の反対方向）
                float moonDot = max(0.0, dot(dir, -lightDir));
                float moonDist = 1.0 - moonDot;
                float moonMask = smoothstep(_MoonSize + 0.002, _MoonSize, moonDist);
                skyColor += _MoonColor.rgb * moonMask * nightWeight;

                // ------------------------------------------------
                // 5. 雲の生成と動的色変化
                // ------------------------------------------------
                if (y > 0.02)
                {
                    float2 cloudUV = (dir.xz / (y + 0.3)) * _CloudScale;
                    cloudUV += _Time.y * _CloudSpeed.xy;

                    float cloudVal = fBm(cloudUV);
                    float cloudAlpha = smoothstep(_CloudDensity, _CloudDensity + _CloudSoftness, cloudVal);
                    
                    // 地平線でのフェードアウト
                    cloudAlpha *= smoothstep(0.02, 0.25, y);

                    // 時間帯ごとの雲の色の計算
                    fixed3 currentCloud = _DayCloud.rgb * dayWeight + _SunCloud.rgb * sunsetWeight + _NightCloud.rgb * nightWeight;
                    fixed3 currentShadow = _DayCloudShadow.rgb * dayWeight + _SunCloudShadow.rgb * sunsetWeight + _NightCloudShadow.rgb * nightWeight;

                    float shadowVal = fBm(cloudUV + float2(0.05, 0.05));
                    fixed3 finalCloudColor = lerp(currentShadow, currentCloud, shadowVal);

                    // 合成
                    skyColor = lerp(skyColor, finalCloudColor, cloudAlpha);
                }

                return fixed4(skyColor, 1.0);
            }
            ENDCG
        }
    }
}