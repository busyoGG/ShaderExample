Shader "Custom/Plant"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _SwingStrength("SwingStrength",Range(0,10)) = 2.0
        _SwingTime("SwingTime",Range(0.01,10)) = 5.0
        _BendRate("BendRate",Range(0,2)) = 1.0
        _WindStrength("WindStrength",Range(0,45)) = 0.0
        _WindDirection("WindDirection",Range(0,360)) = 0.0
    }
    SubShader
    {
        Pass
        {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;

            sampler2D _MainTex;

            float _SwingTime;
            float _SwingStrength;
            float _BendRate;
            float _WindStrength;
            float _WindDirection;

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 uv : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                //时间 0-1秒循环
                float time = (_Time.y / _SwingTime * (1 - _WindStrength * 0.5)) % 1;
                //偏移量 根据时间在 sin(0) 到 sin(2π) 之间切换
                float offset = sin(time * 360 * UNITY_PI / 180);
                //计算旋转角度
                float angle = _SwingStrength * offset + _WindStrength;
                float bendRate = (v.vertex.y - v.vertex.y * _WindStrength * 0.02) * _BendRate;
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
                float radWind = _WindDirection * UNITY_PI / 180;
                const float4x4 rotY = float4x4(
                    cos(radWind),0,  sin(radWind), 0,
                    0, 1, 0, 0,
                    -sin(radWind),0, cos(radWind),  0,
                    0, 0, 0, 1
                );
                //顶点转为裁剪空间坐标
                float3 pos = mul(rotZ, v.vertex);
                pos = mul(rotY,pos);

                o.pos = UnityObjectToClipPos(pos);
                o.uv = v.texcoord;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                //texture采样
                const fixed4 color = tex2D(_MainTex, i.uv);
                return color * _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}