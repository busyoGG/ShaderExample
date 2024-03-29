Shader "Custom/Outline"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _OutlineWidth ("OutlineWidth", Range(0,1)) = 0.1
        _OutlineColor ("OutlineColor", Color) = (0,0,0,1)
    }
    SubShader
    {
        Pass
        {
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;

            sampler2D _MainTex;

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 uv : TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                //顶点转为裁剪空间坐标
                o.pos = UnityObjectToClipPos(v.vertex);
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
        Pass
        {
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            float _OutlineWidth;
            fixed4 _OutlineColor;

            v2f vert(appdata_tan v)
            {
                v2f o;
                //把顶点转换到世界空间
                float4 pos = UnityObjectToClipPos(v.vertex);
                //把法线转换到ndc空间
                float3 ndcNormal = normalize(mul((float3x3)unity_MatrixMVP, v.tangent.xyz)) * pos.w;
                //将近裁剪面右上角位置的顶点变换到观察空间
                float4 nearUpperRight = mul(unity_CameraInvProjection, float2(1, 1));
                //求得屏幕宽高比
                const float aspect = abs(nearUpperRight.y / nearUpperRight.x);
                //使法线方向正确适配屏幕宽高比
                ndcNormal.x *= aspect;
                //顶点扩张
                pos.xy += 0.1 * _OutlineWidth * ndcNormal.xy;
                o.pos = pos;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}