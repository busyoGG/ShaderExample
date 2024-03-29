Shader "Unlit/Progress"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Progress ("Progress",Range(0,1)) = 0
        _BackgroundColor ("BackgroundColor",Color) = (0,0,0,0)
        _ForegroundColor ("ForegroundColor",Color) = (0,1,0,1)
        [Toggle(_True)]_Forward("Forward", Int) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha // 使用标准的透明混合模式

        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 pos: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Progress;
            float4 _BackgroundColor;
            float4 _ForegroundColor;
            int _Forward;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.pos = v.vertex.xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //贴图采样 只用贴图的a通道
                fixed4 col = tex2D(_MainTex, i.uv);
                //计算前景色和背景色的透明度和
                fixed4 final = fixed4(0, 0, 0, 0);
                final.a = step(1 - col.a, 0.5) == 1 ? _ForegroundColor.a + _BackgroundColor.a : 0;
                
                //计算原点到坐标点相对于x轴的角度
                float angle = atan2(i.pos.z, i.pos.x) * (180 / 3.14159);
                //计算顺时针和逆时针角度
                angle = _Forward == 1 ? (angle < 0 ? angle + 360 : angle) : abs(angle > 0 ? angle - 360 : angle);
                
                const float curAngle = _Progress * 360;
                //根据当前坐标角度和目标角度的大小关系渲染进度条
                final.rgb = curAngle >= angle ? _ForegroundColor.xyz * _ForegroundColor.a + _BackgroundColor.a * _BackgroundColor.xyz *
                    (1 - _ForegroundColor.a) :  _BackgroundColor.xyz;
                //重新单独计算进度条未覆盖部分的透明度
                final.a = curAngle >= angle ? final.a : final.a * _BackgroundColor.a;

                return final;
            }
            ENDCG
        }
    }
}