Shader "Unlit/reference/reflection/ggx"
{
    Properties
    {
        _MainTex("Cube Texture", Cube) = "white" {}
        _Roughness("Roughness",Range(0,1)) = 0.5
        _Fresnel("Fresnel Reflectance at 0deg (F0)",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float2 uv : TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 pos : POSITION1;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
            };

            float cos_theta(float3 w_m) {
                return w_m.z;
            }
            float sin_theta(float3 w_m) {
                return sqrt(max(1.0-w_m.z* w_m.z,0.0));
            }
            float tan_theta(float3 w_m) {
                return sin_theta(w_m)/ cos_theta(w_m);
            }
            float cos_phi(float3 w_m) {
                float sin_t = sin_theta(w_m);
                float deg_g = 1.0;
                if (sin_t < 0.0) {
                    return 0.0;
                }
                return clamp(w_m.x/sin_t,-1,1);
            }
            float sin_phi(float3 w_m) {
                float sin_t = sin_theta(w_m);
                float deg_g = 1.0;
                if (sin_t < 0.0) {
                    return 0.0;
                }
                return clamp(w_m.y / sin_t, -1, 1);
            }
            float tan_phi(float3 w_m) {
                return sin_phi(w_m)/cos_phi(w_m);
            }

            float3 f_ggx(float3 f0, float cos_i_m)
            {
                float d = max(1 - cos_i_m,0);
                return f0 + (1 - f0) * (d * d * d * d * d);
            }
            float d_ggx(float alpha, float3 w_m)
            {
                float alpha2 = alpha * alpha;
                float cos_m  = cos_theta(w_m);
                float cos_2m = cos_m * cos_m;
                float cos_4m = cos_2m * cos_2m;
                float sin_2m = max(1 - cos_2m, 0.0);
                float tan_2m = sin_2m / cos_2m;
                if (isinf(tan_2m)) { return 0.0; }
                float d = (1 + tan_2m / (alpha2));
                // d = (1+tan2m)
                // cos_2m * (1+tan2_m) = 1
                // 1/UNITY_PI
                return 1 / (UNITY_PI * alpha * alpha * cos_4m * d * d);
            }
            float lambda_ggx(float alpha, float3 w)
            {
                float alpha_g = alpha * tan_theta(w);
                // (-1 +1/cos_t)/2
                return  (-1 + sqrt(1 + alpha_g * alpha_g))/2;
            }
            float g1_ggx(float alpha, float3 w)
            {
                //1+tan_2t = (sin_2t + cos_2t)/cos_2t = 1/cos_2t
                // 2/(1/cos_t + 1)
                float alpha_g = alpha * tan_theta(w);
                return 2 / (1+sqrt(1+ alpha_g* alpha_g));
            }
            float g2_ggx(float alpha, float3 w_i, float3 w_o)
            {
                return g1_ggx(alpha, w_i) * g1_ggx(alpha, w_o);
            }
            float g3_ggx(float alpha, float3 w_i, float3 w_o)
            {
                // (-1 +1/cos_i)/2 + (-1+ 1/cos_o)/2 + 1 = (1/cos_i+1/cos_o)/2
                return 1/(lambda_ggx(alpha, w_i) + lambda_ggx(alpha, w_o) + 1);
            }
            float3 bsdf_ggx(float3 f0, float roughness, float3 w_i, float3 w_o, float3 w_m)
            {
                float alpha = roughness * roughness;
                float cos_i_m = abs(dot(w_i, w_m));
                float cos_i = abs(cos_theta(w_i));
                float cos_o = abs(cos_theta(w_o));
                return f_ggx(f0, cos_i_m) * d_ggx(alpha, w_m) * g3_ggx(alpha, w_i, w_o)/(4.0*cos_i*cos_o);
            }
            float3 bsdf_ggx_without_d(float3 f0, float roughness, float3 w_i, float3 w_o, float3 w_m)
            {
                float alpha = roughness * roughness;
                float cos_i_m = abs(dot(w_i, w_m));
                float cos_i = abs(cos_theta(w_i));
                float cos_o = abs(cos_theta(w_o));
                return f_ggx(f0, cos_i_m) * g3_ggx(alpha, w_i, w_o) / (4.0 * cos_i * cos_o);
            }
                
            samplerCUBE _MainTex;
            float4 _MainTex_ST;
            float3 _Fresnel;
            float _Roughness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent.xyz = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                o.tangent.w = v.tangent.w;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                uint seed  = uint(_ScreenParams.x) * uint(_ScreenParams.y * i.uv.y) + uint(_ScreenParams.x * i.uv.x);
                uint state = Hash_Wang(seed);

                float3 normal = i.normal;//‚»‚Ì‚Ü‚Ü
                float3 binormal = cross(normal, i.tangent.xyz);
                float3 tangent = normalize(cross(binormal, normal));
                binormal = normalize(binormal * i.tangent.w * unity_WorldTransformParams.w);

                float3 camEye = _WorldSpaceCameraPos;
                float3 i_dir = normalize(i.pos.xyz - camEye);
                float3 color = float3(0, 0, 0);
                float3 w_i = normalize(float3(dot(i_dir, tangent), dot(i_dir, binormal), dot(i_dir, normal)));

                const int NUM_SAMPLES = 1000;
                for (int j = 0; j < NUM_SAMPLES; ++j) {
                    float u        = Random1f(state);
                    float v        = Random1f(state);
                    float phi      = UNITY_PI * 2.0 * u;
                    float theta    = atan(_Roughness * _Roughness * sqrt(v) / sqrt(1 - v));
                    float cosTheta = cos(theta);
                    float sinTheta = sin(theta);
                    float cosPhi   = cos(phi);
                    float sinPhi   = sin(phi);
                    float3 w_m     = float3(sinTheta * cosPhi, sinTheta * sinPhi, cosTheta);
                    float3 w_o     = reflect(w_i , w_m);
                    float3 o_dir   = normalize(w_o.x * tangent + w_o.y * binormal + w_o.z * normal);
                    color += f_ggx(_Fresnel, abs(dot(w_i, w_m))) * g3_ggx(_Roughness*_Roughness, w_i, w_o) * abs(cos_theta(w_o)) * texCUBE(_MainTex,camEye + 100.0f * o_dir) * abs(dot(w_o, w_m)) / (abs(cos_theta(w_i))* abs(cos_theta(w_o)) * abs(cosTheta));
                }
                color /= NUM_SAMPLES;
                fixed4 col = fixed4(color, 1);
                // sample the texture
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
