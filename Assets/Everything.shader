Shader "Everything" {
	Properties {
		_Color ("Base Color", Color) = (1,1,1,1)
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always

		Tags { "RenderType"="Opaque" }
		
		Pass
        {
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#define STEPS 64
			#define MIN_DISTANCE 0.001

			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			float4 _Color;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f 
			{
				float4 pos : SV_POSITION; // Clip space
				float3 wPos : TEXCOORD1; // World position
			};

			// Vertex function
			v2f vert (appdata v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz; 
				return o;
			}

			fixed4 simpleLambert (fixed3 normal) 
			{
				fixed3 lightDir = -_WorldSpaceLightPos0.xyz;	// Light direction
				fixed3 lightCol = _LightColor0.rgb;		// Light color

				fixed NdotL = max(dot(normal, lightDir),0);
				fixed4 c;
				c.rgb = _Color * lightCol * NdotL;
				c.a = 1;
				return c;
			}

			float sphere(float3 position, float3 origin, float radius)
			{
				return distance(position, origin) - radius;
			}

			float scene(float3 position)
			{
				float ball = sphere(position, float3(0, 0, 0), 1);

				return ball;
			}

			float3 normal (float3 p)
			{
				const float eps = 0.01;

				return normalize(	
					float3(
						scene(p + float3(eps, 0, 0)	) - scene(p - float3(eps, 0, 0)),
						scene(p + float3(0, eps, 0)	) - scene(p - float3(0, eps, 0)),
						scene(p + float3(0, 0, eps)	) - scene(p - float3(0, 0, eps))
					)
				);
			}

			fixed4 renderSurface(float3 p)
			{
				float3 n = normal(p);
				return simpleLambert(n);
			}

			fixed4 raycast(float3 position, float3 direction)
			{
				for(int i = 0; i < STEPS; i++){
					float distance = sphere(position, float3(0, 0, 0), 1);
					if(distance < MIN_DISTANCE)
						return renderSurface(position);
					
					position += distance * direction;
				}
				return 0;
			}

			fixed4 frag (v2f i) : SV_TARGET
			{
				float3 worldPosition = _WorldSpaceCameraPos;
				float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
				
				fixed4 col = raycast(worldPosition, viewDirection);
				return col;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
