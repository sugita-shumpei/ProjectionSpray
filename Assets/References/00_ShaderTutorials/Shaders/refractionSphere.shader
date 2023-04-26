Shader "Unlit/reference/refraction/sphere"
{
    Properties
    {
        _MainTex ("Cube Texture", Cube) = "white" {}
        _IOR("Refractive Index", Range(0.5,2.0)) = 1.0
        _SphereCenter("Sphere Center", Vector) = (0,0,0,0)
        _SphereRadius("Sphere Radius", Float) = 1.0
        _Depth("Recursion Depth",Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull off
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            samplerCUBE _MainTex;
            float4 _MainTex_ST;

            float3 _SphereCenter;
            float  _IOR, _SphereRadius;
            int _Depth;
            // 
            // 0: ‹…‚ÌŠO•”—Ìˆæ
            // 1: ‹…‚Ì“à•”—Ìˆæ
            // 
            // —á‚Ìó‘Ô‚ð•ª—Þ
            // 
            #define RAY_STATE_0_TO_1 0 // ‘Š‘Î‹üÜ—¦   IOR
            #define RAY_STATE_1_TO_1 1 // ‘Š‘Î‹üÜ—¦ 1/IOR
            #define MAX_DEPTH 5
            // 
            // ó‘Ô‘JˆÚ
            // 
            // 0_TO_1 -> 1_TO_1 or END
            // 1_TO_1 -> 1_TO_1 or END
            // 

            float intersect_sphere(float3 rayOrigin, float3 rayDirection, float tMin, float tMax)
            {
                // |o + t * d - c| = r
                // t^2 + 2 * dot(o-c,d) * t +  |o-c|^2 - r^2 = 0
                float3 oc = rayOrigin - _SphereCenter;
                float  b  = dot(oc, rayDirection);
                float  c  = dot(oc, oc) - _SphereRadius * _SphereRadius;
                float  D  = b * b - c;
                D = sqrt(D);

                if (D < 0.0) return -1;

                float t1 = -b - D;
                float t2 = -b + D;

                if ((t1 > tMin) && (t1 < tMax)) return t1;
                if ((t2 > tMin) && (t2 < tMax)) return t2;

                return -1;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(2.0*v.vertex.xy,1.0,1.0);
                o.uv = v.uv;
                o.uv.y = 1.0 - o.uv.y;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                uint seed = uint(_ScreenParams.x) * uint(_ScreenParams.y * i.uv.y) + uint(_ScreenParams.x * i.uv.x);
                uint state = Hash_Wang(seed);
                // sample the texture
                float3 cameraPos = _WorldSpaceCameraPos;
                float3 screenPos = float3(2.0 * i.uv - 1.0,1.0);
                float3 direction = mul(unity_CameraInvProjection, float4(screenPos, 1.0)).xyz;

                direction = mul(UNITY_MATRIX_I_V, float4(direction, 0.0f)).xyz;
                direction = normalize(direction);

                //res color
                fixed4 col = fixed4(0.0,0.0,0.0, 1.0);
                //initial ray origin, direction, state
                float3 rayOrg = cameraPos;
                float3 rayDir = direction;
                int   rayState = RAY_STATE_0_TO_1;
                //normal
                float3 normal = float3(0.0, 0.0, 0.0);
                //normal sign
                float norm_sign = 1.0;
                //real refractive index
                float ior = 1.0;
                //recursive depth
                //num sampling
                const int NUM_SAMPLES = 60;
                //target sphere radius
                float dist = 0.0;
                // dir
                float3 refl_dir = float3(0.0, 0.0, 0.0);
                float3 refr_dir = float3(0.0, 0.0, 0.0);
                bool isReflect = false;
                for (int j = 0; j < NUM_SAMPLES; ++j)
                {
                    // init state
                    rayOrg =  cameraPos; 
                    rayDir =  direction;
                    rayState = RAY_STATE_0_TO_1;
                    for (int k = 0; k < MAX_DEPTH; ++k)
                    {
                        if (k > _Depth)
                        {
                            break;
                        }

                        if (rayState == RAY_STATE_0_TO_1)
                        {
                            ior          = _IOR;
                            norm_sign    = 1.0;
                        }
                        else
                        {
                            ior          = 1.0/_IOR;
                            norm_sign    =-1.0;
                        }


                        dist = intersect_sphere(rayOrg, rayDir, 0.01, 1e10);

                        if (dist < 0.0)
                        {
                            if ((rayState == RAY_STATE_0_TO_1))
                            {
                                col.xyz += texCUBE(_MainTex,rayOrg + 500.0 * rayDir).xyz;
                            }
                            break;
                        }

                        rayOrg += dist * rayDir;
                        normal = norm_sign * normalize(rayOrg - _SphereCenter);

                        refl_dir = normalize(reflect(rayDir, normal));
                        refr_dir = normalize(refract(rayDir, normal, 1.0/ior));

                        float cos_in = abs(dot(rayDir, normal));
                        float sin_in = sqrt(1.0 - cos_in * cos_in);

                        float sin_out = sin_in / ior;
                        float cos_out = sqrt(1.0 - sin_out * sin_out);


                        if (sin_out > 1.0)
                        {
                            // total internal reflection
                            isReflect = true;
                        }
                        else
                        {
                            float fresnel1 = ((cos_in - ior * cos_out) * (cos_in - ior * cos_out)) / ((cos_in + ior * cos_out) * (cos_in + ior * cos_out));
                            float fresnel2 = ((cos_out - ior * cos_in) * (cos_out - ior * cos_in)) / ((cos_out + ior * cos_in) * (cos_out + ior * cos_in));
                            float fresnel  = (fresnel1 + fresnel2)*0.5;
                            if (fresnel > Random1f(state))
                            {
                                isReflect = true;
                            }
                            else {
                                isReflect = false;
                            }
                        }

                        if (isReflect)
                        {
                            rayOrg += 0.01 * normal;
                            rayDir = refl_dir;
                        }
                        else {
                            rayOrg -= 0.01 * normal;
                            rayDir = refr_dir;
                        }

                        if (rayState == RAY_STATE_0_TO_1) {
                            if (isReflect) {
                                col.xyz += texCUBE(_MainTex,rayOrg + 500.0 * rayDir).xyz;
                                break;
                            }
                            else {
                                rayState = RAY_STATE_1_TO_1;
                            }
                        }
                        else
                        {
                            if (!isReflect) {
                                col.xyz += texCUBE(_MainTex, rayOrg + 500.0 * rayDir).xyz;
                                break;
                            }
                            else {
                                rayState = RAY_STATE_1_TO_1;
                            }
                        }

                    }
                    
                }
                col.xyz /= NUM_SAMPLES;
                //col.xyz = sample_for_sphere_map(cameraPos + 500.0 * direction).xyz;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
