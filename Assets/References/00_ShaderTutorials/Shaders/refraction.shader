Shader "Unlit/reference/refraction"
{
    Properties
    {
        _MainTex("Cube Texture", Cube) = "white" {}
        _Transmittance ("Transmittance Color", Color) = (1,1,1,1)
        _IOR ("Refractive Index", Range(0.5,2.0)) = 1.0
        _Thickness ("Thickness", Range(0.1,1.0)) = 0.1
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Cull Off
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

            samplerCUBE _MainTex;
            float4 _MainTex_ST;
            float _IOR, _Thickness;
            float4 _Transmittance;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld,float4(v.vertex.xyz,1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 camEye   = _WorldSpaceCameraPos;
                float3 dir      = normalize(i.pos.xyz - camEye);
                float3 refl_dir = reflect(dir, i.normal);
                float3 refr_dir = refract(dir, i.normal, 1.0/_IOR);
                fixed4 refr_col = fixed4(0.0, 0.0, 0.0, 1.0);
                fixed4 refl_col = fixed4(0.0, 0.0, 0.0, 1.0);

                float cos_in  = abs(dot(dir, i.normal));
                float sin_in  = sqrt(1 - cos_in * cos_in);
                float sin_out = sin_in/_IOR;

                if (sin_out > 1.0)
                {
                    float3 pos = normalize(i.pos.xyz + 100.0f * refl_dir);
                    refl_col = texCUBE(_MainTex, pos);
                    return refl_col;
                }

                float cos_out = sqrt(1 - sin_out * sin_out);
                float len = _Thickness / cos_out;

                float3 refl_dir2 = reflect(refr_dir, i.normal);

                float3 v1 = i.pos.xyz;
                float3 v2 = v1 + len * refr_dir;
                float3 v3 = v2 + len * refl_dir2;

                float fresnel1 = ((cos_in  - _IOR * cos_out)* (cos_in  - _IOR * cos_out)) / ((cos_in  + _IOR * cos_out) * (cos_in + _IOR * cos_out));
                float fresnel2 = ((cos_out - _IOR * cos_in) * (cos_out - _IOR * cos_in)) /  ((cos_out + _IOR * cos_in) * (cos_out + _IOR * cos_in));
                float fresnel  = (fresnel1 + fresnel2) * 0.5;

                float4 r1 = fresnel;
                float4 t1 = (1 - fresnel);
                float4 r2 = t1 * _Transmittance * fresnel;
                float4 t2 = t1 * _Transmittance * (1 - fresnel);
                float4 r3 = r2 * _Transmittance * fresnel;
                float4 t3 = r2 * _Transmittance * (1 - fresnel);

                fixed4 color1 = texCUBE(_MainTex,v1 + 100.0 * refl_dir);
                fixed4 color2 = texCUBE(_MainTex, v2 + 100.0 * dir);
                fixed4 color3 = texCUBE(_MainTex, v3 + 100.0 * refl_dir);

                return r1 * color1 + t2 * color2 + t3 * color3;
            }
            ENDCG
        }
    }
}
