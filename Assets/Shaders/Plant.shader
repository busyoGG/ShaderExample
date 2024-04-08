Shader "Custom/Plant"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SwingStrength("SwingStrength",Range(0,10)) = 2.0
        _SwingTime("SwingTime",Range(0.01,10)) = 5.0
        _BendRate("BendRate",Range(0,2)) = 1.0
        _WindStrength("WindStrength",Range(0,45)) = 0.0
        _WindDirection("WindDirection",Range(0,360)) = 0.0
        _Random("Random (RGB)",2D) = "black" {}
        _RandomRate("RandomRate",Range(0,10)) = 1
        _GlobalPos("GlobalPos",Vector) = (0,0,0)
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            sampler2D _MainTex;
            sampler2D _Random;

            float _SwingTime;
            float _SwingStrength;
            float _BendRate;
            float _WindStrength;
            float _WindDirection;
            float _RandomRate;

            float3 _GlobalPos;


            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 uv : TEXCOORD0;
                fixed4 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                float2 offsetPos = worldPos.xz;
                float4 random = tex2Dlod(_Random, float4(offsetPos, 0, 0));
                //时间 0-1秒循环
                float time = ((_Time.y + random * _RandomRate) / _SwingTime * (1 - _WindStrength * 0.5)) % 1;
                //偏移量 根据时间在 sin(0) 到 sin(2π) 之间切换
                float offset = sin(time * 360 * UNITY_PI / 180);
                // //判断方向
                // float direct = offset > 0 ? -1 : 1;

                //计算交互方向
                float2 interactiveVec = worldPos.xz - _GlobalPos.xz;
                float3 worldAxis = UnityObjectToWorldNormal(float3(1,0,0));
                float direct = dot(interactiveVec,worldAxis) >= 0 ? -1 : 1;
                
                //计算顶点与交互物体坐标的距离
                float dist = length(interactiveVec);
                //计算交互距离比率
                float distRatio = clamp(0,1,dist / 1);
                
                //计算旋转角度
                float radWind = _WindDirection * UNITY_PI / 180;
                float angle = _SwingStrength * offset + _WindStrength * cos(radWind);
                float bendRate = (v.vertex.y - v.vertex.y * _WindStrength * 0.02) * _BendRate;
                
                //计算交互弯曲角度
                float interactiveAngle = 90 * (1 - distRatio) * (1 - normalize(v.vertex).y) * direct;
                //获得弯曲角度和交互弯曲角度中较大的一方
                angle = angle + interactiveAngle;
                
                float anglePlus = _SwingStrength == 0 ? 0 : (angle / _SwingStrength);
                angle += _SwingStrength * 0.5 * bendRate * anglePlus;

                // angle = clamp(-90,90,angle);
                //角度转弧度
                const float rad = angle * UNITY_PI / 180;
                //计算旋转矩阵
                const float4x4 rotZ = float4x4(
                    cos(rad), -sin(rad), 0, 0,
                    sin(rad), cos(rad), 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                );

                //计算风力旋转
                float radBendWind = (_WindDirection % 180) * 0.2 * sin(radWind) * (v.vertex.y * _WindStrength * 0.02) *
                    UNITY_PI / 180;
                const float4x4 rotX = float4x4(
                    1, 0, 0, 0,
                    0, cos(radBendWind), -sin(radBendWind), 0,
                    0, sin(radBendWind), cos(radBendWind), 0,
                    0, 0, 0, 1
                );


                //顶点转为裁剪空间坐标
                float3 pos = mul(rotZ, v.vertex);
                pos = mul(rotX, pos);

                v.vertex.xyz = pos;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.worldPos = worldPos;
                o.worldNormal = UnityObjectToWorldNormal(mul(rotX, mul(rotZ, v.normal)));

                TRANSFER_SHADOW(o);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                //texture采样
                fixed4 color = tex2D(_MainTex, i.uv);
                // color *= _Diffuse;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                fixed atten = 1.0; //光照衰减

                fixed shadow = SHADOW_ATTENUATION(i);

                return fixed4(color.xyz * (ambient + (diffuse + specular) * atten * shadow), 1.0);
            }
            ENDCG
        }

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
                // float4 pos : SV_POSITION;
                // float3 worldPos : TEXCOORD0;
            };

            float _SwingTime;
            float _SwingStrength;
            float _BendRate;
            float _WindStrength;
            float _WindDirection;
            sampler2D _Random;
            float _RandomRate;


            v2f vert(appdata_base v)
            {
                v2f o;
                //噪声随机摆动
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float2 offsetPos = worldPos.xz;
                float4 random = tex2Dlod(_Random, float4(offsetPos, 0, 0));
                //时间 0-1秒循环
                float time = ((_Time.y + random * _RandomRate) / _SwingTime * (1 - _WindStrength * 0.5)) % 1;
                //偏移量 根据时间在 sin(0) 到 sin(2π) 之间切换
                float offset = sin(time * 360 * UNITY_PI / 180);
                //计算旋转角度
                float radWind = _WindDirection * UNITY_PI / 180;
                float angle = _SwingStrength * offset + _WindStrength * cos(radWind);
                float bendRate = (v.vertex.y - v.vertex.y * _WindStrength * 0.02) * _BendRate;
                float anglePlus = _SwingStrength == 0 ? 0 : (angle / _SwingStrength);
                angle += _SwingStrength * 0.5 * bendRate * anglePlus;

                //角度转弧度
                const float rad = angle * UNITY_PI / 180;
                //计算沿z轴变换矩阵
                const float4x4 rotZ = float4x4(
                    cos(rad), -sin(rad), 0, 0,
                    sin(rad), cos(rad), 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                );

                //计算沿x轴变换矩阵
                float radBendWind = (_WindDirection % 180) * 0.2 * sin(radWind) * (v.vertex.y * _WindStrength * 0.02) *
                    UNITY_PI / 180;
                const float4x4 rotX = float4x4(
                    1, 0, 0, 0,
                    0, cos(radBendWind), -sin(radBendWind), 0,
                    0, sin(radBendWind), cos(radBendWind), 0,
                    0, 0, 0, 1
                );


                //顶点转为裁剪空间坐标
                float3 pos = mul(rotZ, v.vertex);
                pos = mul(rotX, pos);

                v.vertex.xyz = pos;

                TRANSFER_SHADOW_CASTER(o);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}