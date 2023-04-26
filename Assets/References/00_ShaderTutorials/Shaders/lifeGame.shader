Shader "Unlit/reference/lifeGame"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPos : POSITION1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            int read_state(float x, float y) {
                if (x < 0 || x >= 1.0f) {
                    return 0;
                }
                if (y < 0 || y >= 1.0f) {
                    return 0;
                }
                return tex2D(_MainTex, float2(x, y )).g > 0.5;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //_ScreenParams.x
                float2 uv      = i.screenPos.xy / i.screenPos.w;
                float dx = 1.0 / _ScreenParams.x;
                float dy = 1.0 / _ScreenParams.y;

                int prvState00 = read_state(uv.x    , uv.y);
                int prvStateL0 = read_state(uv.x - dx, uv.y);
                int prvStateR0 = read_state(uv.x + dx, uv.y);

                int prvState0L = read_state(uv.x     , uv.y - dy);
                int prvStateLL = read_state(uv.x - dx, uv.y - dy);
                int prvStateRL = read_state(uv.x + dx, uv.y - dy);

                int prvState0R = read_state(uv.x     , uv.y + dy);
                int prvStateLR = read_state(uv.x - dx, uv.y + dy);
                int prvStateRR = read_state(uv.x + dx, uv.y + dy);

                int prvStateSum = prvStateL0 + prvStateR0 + prvState0L + prvStateLL + prvStateRL + prvState0R + prvStateLR + prvStateRR;

                int curStateAlive = 0;

                if (!prvState00)
                {
                    if (prvStateSum == 3)
                    {
                        curStateAlive = 1;
                    }
                }
                else
                {
                    if ((prvStateSum == 2)|| (prvStateSum == 3))
                    {
                        curStateAlive = 1;
                    }
                }

                fixed4 col = fixed4(0.0f,0.0f,0.0f,1.0f);
                if (curStateAlive)
                {
                    col.g = 1.0;
                }

                // sample the texture
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
