Shader "Unlit/reference/lightMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
         Cull Front //<-
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 pos : POSITION1;
                float3 normal : NORMAL1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 sample_for_sphere_map(float3 pos)
            {
                pos = normalize(pos);
                float coordX = atan2(pos.x, pos.z) / 3.141592653589793;
                float coordY = asin(pos.y) / (3.141592653589793 *0.5);

                float2 uv = float2(coordX, coordY) * float2(0.5, 0.5) + 0.5;
                if (uv.x < 0.0) {
                    uv.x = 1.0;
                }
                if (uv.x > 1.0) {
                    uv.x = 1.0;
                }
                return tex2D(_MainTex, uv);
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.uv.x = 1 - v.uv.x; // <-
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = UnityObjectToWorldNormal(-v.normal);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                fixed4 col = sample_for_sphere_map(i.pos.xyz);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
