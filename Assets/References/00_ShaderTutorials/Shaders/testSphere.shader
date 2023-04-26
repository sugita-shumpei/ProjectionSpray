Shader "Unlit/reference/testSphere"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SphereCenter("Sphere Center", Vector) = (0,0,0,0)
        _SphereRadius("Sphere Radius", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull off
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _SphereCenter;
            float _SphereRadius;

            float intersect_sphere(float3 rayOrigin, float3 rayDirection, float tMin, float tMax)
            {
                // |o + t * d - c| = r
                // t^2 + 2 * dot(o-c,d) * t +  |o-c|^2 - r^2 = 0
                float3 oc = rayOrigin - _SphereCenter;
                float  b = dot(oc, rayDirection);
                float  c = dot(oc, oc) - _SphereRadius * _SphereRadius;
                float  D = b * b - c;
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
                o.vertex = float4(2.0 * v.vertex.xy, 1.0, 1.0);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.y = 1.0 - o.uv.y;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 cameraPos = _WorldSpaceCameraPos;
                float3 screenPos = float3(2.0 * i.uv - 1.0,1.0);
                float3 direction = mul(unity_CameraInvProjection, float4(screenPos, 1.0)).xyz;

                direction = mul(UNITY_MATRIX_I_V, float4(direction, 0.0f)).xyz;
                direction = normalize(direction);

                float dist = intersect_sphere(cameraPos, direction, 0.001, 1.0e10);

                fixed4 col = fixed4(0, 0, 0, 1);
                if (dist > 0.0) {
                    float3 rayPos  = cameraPos + dist * direction;
                    float3 normal = normalize(rayPos - _SphereCenter);
                    col = fixed4(0.5*normal+0.5,1);
                }

                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
