Shader "Unlit/reference/diffuse"
{
    Properties
    {
        _MainTex("Cube Texture", Cube) = "white" {}
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _MaxSamples("Max Samples",int) = 100
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

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal: NORMAL;
                    float4 tangent: TANGENT;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    UNITY_FOG_COORDS(1)
                    float4 vertex : SV_POSITION;
                    float3 position : POSITION1;
                    float3 normal: NORMAL;
                    float4 tangent: TANGENT;
                };

                samplerCUBE _MainTex;
                float4 _MainTex_ST;
                float3 _Diffuse;
                int _MaxSamples;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.position = mul(unity_ObjectToWorld, v.vertex);
                    o.normal = UnityObjectToWorldNormal(v.normal);
                    o.tangent.xyz = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                    o.tangent.w = v.tangent.w;
                    UNITY_TRANSFER_FOG(o,o.vertex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    uint seed = uint(_ScreenParams.x) * uint(_ScreenParams.y * i.uv.y) + uint(_ScreenParams.x * i.uv.x);
                    uint state = Hash_Wang(seed);
                    float3 normal = i.normal;//‚»‚Ì‚Ü‚Ü
                    float3 binormal = cross(normal, i.tangent.xyz);
                    float3 tangent = normalize(cross(binormal, normal));
                    binormal = normalize(binormal * i.tangent.w * unity_WorldTransformParams.w);
                    float3 camEye = _WorldSpaceCameraPos;
                    float3 direction = normalize(i.position - camEye);
                    float3 refl_dir = normalize(reflect(direction, normal));
                    // sample the texture
                    fixed4 col = fixed4(0, 0, 0, 1);
                    [loop]
                    for (int j = 0; j < _MaxSamples; ++j) {
                        float rnd_u1 = Random1f(state);
                        float  cos_t = sqrt(rnd_u1);
                        float  sin_t = sqrt(max(1 - rnd_u1, 0));
                        float  phi = 2.0 * UNITY_PI * Random1f(state);
                        float3 dir = normalize(sin_t * cos(phi) * tangent + sin_t * sin(phi) * binormal + cos_t * normal);
                        col.xyz += _Diffuse * texCUBE(_MainTex, camEye + 100.0 * dir);
                    }
                    col.xyz /= _MaxSamples;
                    // apply fog
                    UNITY_APPLY_FOG(i.fogCoord, col);
                    return col;
                }
                ENDCG
            }
        }
}
