Shader "Unlit/reference/reflection/phong"
{
    Properties
    {
        _MainTex("Cube Texture", Cube) = "white" {}
        _Specular ("Specular",Color) = (1,1,1,1)
        _Shininess ("Shininess",Range(1.0,10000.0)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "random.hlsl"


            float rand(float2 co) //引数はシード値と呼ばれる　同じ値を渡せば同じものを返す
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 pos : POSITION1;
                float4 projPos:POSITION2;
                float3 normal : NORMAL1;
            };


            samplerCUBE _MainTex;
            float4 _MainTex_ST;

            float _Shininess;
            fixed4 _Specular;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld,float4(v.vertex.xyz,1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.projPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 projUv = i.projPos.xy / i.projPos.w;
                uint seed = uint(_ScreenParams.x) * uint(_ScreenParams.y * i.projPos.y) + uint(_ScreenParams.x * i.projPos.x); 
                uint state = Hash_Wang(seed);

                float3 camEye = _WorldSpaceCameraPos;
                float3 in_dir = normalize(i.pos.xyz - camEye);
                float3 refl_dir = normalize(reflect(in_dir, i.normal));

                // sample the texture
                fixed4 col = fixed4(0.0f, 0.0f, 0.0f, 1.0f);

                const int ITERATIONS = 40;
                for (int j = 0;j< ITERATIONS;++j)
                {

                    float cos_theta = pow(Random1f(state), 1.0 / (_Shininess + 1.0));
                    float sin_theta = sqrt(max(1 - cos_theta * cos_theta,0.0));

                    float phi = 2.0 * 3.14159265f * Random1f(state);
                    float cos_phi = cos(phi);
                    float sin_phi = sin(phi);

                    float3 w = refl_dir;
                    float3 u = cross(float3(0.0, 1.0, 0.0), w);
                    float3 v = cross(w, u);

                    float3 out_dir  = normalize(sin_theta * cos_phi * u + sin_theta * sin_phi * v + cos_theta * w);

                    col += _Specular * (_Shininess+1)/(_Shininess +2) * texCUBE(_MainTex,i.pos.xyz + 100.0f * out_dir);
                }
                col.xyz /= ITERATIONS;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
