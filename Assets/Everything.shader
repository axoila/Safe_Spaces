// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Everything" {
	Properties {
		
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always

		Tags { "RenderType"="Opaque" }
		
		Pass
        {
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

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

			#define STEPS 64
			#define MIN_DISTANCE 0.001

			float sphere(float3 position, float3 origin, float radius)
			{
				return distance(position, origin) - radius;
			}

			float scene(float3 position)
			{
				float ball = sphere(position, float3(0, 0, 0), 1);

				return ball;
			}

			fixed4 raycast(float3 position, float3 direction)
			{
				for(int i = 0; i < STEPS; i++){
					float distance = sphere(position, float3(0, 0, 0), 1);
					if(distance < MIN_DISTANCE)
						return i / (float)STEPS;
					
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
