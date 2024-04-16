Shader "Custom/Plant"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _WindStrength("WindStrength",Range(0,45)) = 0.0
        _Random("Random (RGB)",2D) = "black" {}
        _RandomScale("RandomScale",Range(0,100)) = 1.0
        _GlobalPos("GlobalPos",Vector) = (0,0,0)
        _Bottom("Bottom",Range(-1,0)) = 0.0
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
            
            float _WindStrength;
            float _RandomScale;

            float3 _GlobalPos;
            float _Bottom;

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

                float2 offsetPos = (worldPos.xz * 1 / _RandomScale) * _Time.x;
                //采样
                float4 random = tex2Dlod(_Random, float4(offsetPos, 0, 0));

                float bottom = v.vertex.y - _Bottom;

                float bendRate = bottom;

                float2 offset = random.xz * bendRate * _WindStrength;

                v.vertex.xz += offset * 0.1;

                v.vertex.y -= random.y * bendRate * 0.1 * _WindStrength;

                float3 newWoldPos = mul(unity_ObjectToWorld, v.vertex);
                //计算交互方向
                float2 interactiveVec = newWoldPos.xz - _GlobalPos.xz;
                
                //计算顶点与交互物体坐标的距离
                float dist = length(interactiveVec);
                //计算交互距离比率
                float distRatio = clamp(0, 1, dist / 1);

                float2 interactiveOffset = normalize(interactiveVec.xy);
                float2 interactiveOffsetFinal = clamp(0,0.4,interactiveOffset * (1 - distRatio) * bendRate);
                
                v.vertex.xz += interactiveOffsetFinal;
                v.vertex.y -= bottom * (1 - distRatio);
                    
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.worldPos = worldPos;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // o.worldNormal = UnityObjectToWorldNormal(mul(rotX, mul(rotZ, v.normal)));

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

            sampler2D _Random;
            
            float _WindStrength;
            float _RandomScale;

            float3 _GlobalPos;
            float _Bottom;

            v2f vert(appdata_base v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                float2 offsetPos = (worldPos.xz * 1 / _RandomScale) * _Time.x;
                //采样
                float4 random = tex2Dlod(_Random, float4(offsetPos, 0, 0));

                float bottom = v.vertex.y - _Bottom;

                float bendRate = bottom;

                float2 offset = random.xz * bendRate * _WindStrength;

                v.vertex.xz += offset * 0.1;

                v.vertex.y -= random.y * bendRate * 0.1 * _WindStrength;

                float3 newWoldPos = mul(unity_ObjectToWorld, v.vertex);
                //计算交互方向
                float2 interactiveVec = newWoldPos.xz - _GlobalPos.xz;
                
                //计算顶点与交互物体坐标的距离
                float dist = length(interactiveVec);
                //计算交互距离比率
                float distRatio = clamp(0, 1, dist / 1);

                float2 interactiveOffset = normalize(interactiveVec.xy);
                float2 interactiveOffsetFinal = clamp(0,0.4,interactiveOffset * (1 - distRatio) * bendRate);
                
                v.vertex.xz += interactiveOffsetFinal;
                v.vertex.y -= bottom * (1 - distRatio);
                    
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