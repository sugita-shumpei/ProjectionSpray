Shader "Unlit/reference/plastic"
{
    Properties
    {
        _MainTex("Cube Texture", Cube) = "white" {}
        _Diffuse("Diffuse Color",Color) = (1,1,1,1)
        _Specular("Specular Color",Color) = (1,1,1,1)
        _IOR("Refractive Index", Range(0.5,2.0)) = 1.0
        _Thickness("Thickness", Range(0.0,1.0)) = 0.1
        _Depth("Recursive Depth",int) = 1

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
                #pragma target 5.0


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

                samplerCUBE _MainTex;
                float4 _MainTex_ST;
                float _IOR, _Thickness;
                float3 _Diffuse, _Specular;
                int _Depth;

                void calc_thin_plastic(inout float3 rayOrg, inout float3 rayDir, float3 tangent, float3 binormal, float3 normal, inout float3 col, inout float3 transmittance, inout uint state)
                {
                    float cos1 = abs(dot(rayDir, normal));
                    float dist1 = _Thickness / cos1;

                    float cosTheta = sqrt(Random1f(state));
                    float sinTheta = sqrt(max(1 - cosTheta * cosTheta, 0.0));

                    float phi = 2.0 * UNITY_PI * Random1f(state);
                    float cosPhi = cos(phi);
                    float sinPhi = sin(phi);

                    float3 scatDir = normalize(sinTheta * cosPhi * tangent + sinTheta * sinPhi * binormal + cosTheta * normal);
                    transmittance *= _Diffuse;

                    float cos2 = abs(dot(scatDir, normal));
                    float dist2 = _Thickness / cos2;

                    float reflDir = normalize(reflect(scatDir, -normal));
                    float refrDir = normalize(refract(scatDir, -normal, _IOR));

                    rayOrg += dist1 * rayDir + dist2 * scatDir;
                    rayDir = reflDir;

                    float cosIn  = dot(scatDir, normal);
                    float sinIn  = sqrt(max(1.0 - cosIn * cosIn, 0.0));
                    float sinOut = sinIn * _IOR;
                    float cosOut = sqrt(max(1.0 - sinOut * sinOut,0.0));

                    bool isReflect = false;
                    if (sinOut < 1.0){
                        float fresnel1_base = (cosIn - _IOR * cosOut) / (cosIn  + _IOR * cosOut);
                        float fresnel2_base = (cosOut - _IOR * cosIn) / (cosOut + _IOR * cosIn);

                        //if (isnan(cosOut)) {
                        //    col = float3(1000, 0, 0);
                        //    return;
                        //}
                        //if (isnan(cosIn)) {
                        //    col = float3(0, 0, 100);
                        //    return;
                        //}
                        float fresnel1 = fresnel1_base * fresnel1_base;
                        float fresnel2 = fresnel2_base * fresnel2_base;
                        float fresnel = (fresnel1 + fresnel2) * 0.5;

                        //if (isnan(fresnel)) {
                        //    col = float3(0, 0, 100);
                        //    return;
                        //}
                        col += transmittance * (1.0 - fresnel) * texCUBE(_MainTex,rayOrg + 500.0 * refrDir);
                        transmittance *= (fresnel* _Specular);
                    }
                }

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.pos = mul(unity_ObjectToWorld,float4(v.vertex.xyz,1.0));
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    UNITY_TRANSFER_FOG(o,o.vertex);
                    o.normal = UnityObjectToWorldNormal(v.normal);
                    o.tangent.xyz = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                    o.tangent.w = v.tangent.w;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    uint seed = uint(_ScreenParams.x) * uint(_ScreenParams.y * i.uv.y) + uint(_ScreenParams.x * i.uv.x);
                    uint state = Hash_Wang(seed);

                    float3 camEye = _WorldSpaceCameraPos;
                    float3 dir = normalize(i.pos.xyz - camEye);

                    float3 normal = i.normal;//‚»‚Ì‚Ü‚Ü
                    float3 binormal = cross(normal, i.tangent.xyz);
                    float3 tangent = normalize(cross(binormal, normal));
                    binormal = normalize(binormal * i.tangent.w * unity_WorldTransformParams.w);
                    
                    float3 refl_dir = normalize(reflect(dir, normal));
                    float3 refr_dir = normalize(refract(dir, normal, 1.0 / _IOR));

                    fixed4 refr_col = fixed4(0.0, 0.0, 0.0, 1.0);
                    fixed4 refl_col = fixed4(0.0, 0.0, 0.0, 1.0);

                    float cos_in = abs(dot(dir, normal));
                    float sin_in = sqrt(1 - cos_in * cos_in);
                    float sin_out = sin_in / _IOR;

                    if (sin_out > 1.0)
                    {
                        refl_col = texCUBE(_MainTex, i.pos.xyz + 100.0f * refl_dir);
                        return refl_col;
                    }

                    float cos_out = sqrt(max(1 - sin_out * sin_out,0.0));
                    float len = _Thickness / cos_out;

                    float3 refl_dir2 = reflect(refr_dir, normal);

                    float3 v1 = i.pos.xyz;
                    float3 v2 = v1 + len * refr_dir;
                    float3 v3 = v2 + len * refl_dir2;

                    float fresnel1 = ((cos_in  - _IOR * cos_out) * (cos_in - _IOR * cos_out)) / ((cos_in + _IOR * cos_out) * (cos_in + _IOR * cos_out));
                    float fresnel2 = ((cos_out - _IOR *  cos_in) * (cos_out - _IOR * cos_in)) / ((cos_out + _IOR * cos_in) * (cos_out + _IOR * cos_in));
                    float fresnel = (fresnel1 + fresnel2) * 0.5;

                    float3 color1 = fresnel * _Specular * texCUBE(_MainTex, v1 + 500.0 * refl_dir);
                    float3 color2 = float3(0.0, 0.0, 0.0);
                    float3 transmittance;

                    float3 rayOrg;
                    float3 rayDir;
                    
                    const int NUM_SAMPLES = 100;
                    for (int j = 0; j < NUM_SAMPLES; ++j)
                    {
                        rayOrg = i.pos.xyz; 
                        rayDir = refr_dir;
                        transmittance = 1.0 - fresnel;
                        [loop]
                        for (int k = 0; k < _Depth; ++k) {
                            calc_thin_plastic(rayOrg, rayDir, tangent, binormal, normal, color2, transmittance, state);
                        }
                    }

                    color2 /= NUM_SAMPLES;

                    return fixed4(color1 + color2, 1.0);
                }

                ENDCG
            }
        }
}
