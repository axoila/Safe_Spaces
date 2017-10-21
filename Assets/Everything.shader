Shader "Everything" {
	Properties {
		_Color ("Base Color", Color) = (1,1,1,1)
		_SafeColor("Safe-Zone Color", Color) = (1,1,1,1)

		_Gloss ("Gloss", float) = 1
		_SpecularPower ("Specular", float) = 1

		_HeadBubble("BubbleRadius", float) = 1
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always

		Tags { "RenderType"="Opaque" }
		
		Pass
        {
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#define STEPS 256
			#define MIN_DISTANCE 0.01

			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			float4 _Color;
			float _Gloss;
			float _SpecularPower;

			float4 _SafeColor;

			float _HeadBubble;

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

			fixed4 simpleLambert (fixed3 normal, fixed3 viewDirection, fixed4 color) 
			{
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;	// Light direction
				fixed3 lightCol = _LightColor0.rgb;		// Light color

				fixed NdotL = max(dot(normal, lightDir),0);

				// Specular
				fixed3 h = (lightDir - viewDirection) / 2.;
				fixed s = pow( dot(normal, h), _SpecularPower) * _Gloss;

				fixed4 c;
				c.rgb = color * lightCol * NdotL + s + _Color * unity_AmbientSky;
				c.a = 1;
				return c;
			}

			float vmax(float3 v)
			{	
 				return max(max(v.x, v.y), v.z);
			}

			float merge(float shape1, float shape2)
			{
				return min(shape1, shape2);
			}

			float roundMerge(float shape1, float shape2, float radius) {
				float2 u = max(float2(radius - shape1,radius - shape2), float2(0, 0));
				return max(radius, min (shape1, shape2)) - length(u);
			}

			float intersect(float shape1, float shape2)
			{
				return max(shape1, shape2);
			}

			float roundIntersect(float shape1, float shape2, float radius){
				float2 u = max(float2(radius + shape1,radius + shape2), float2(0, 0));
				return min(-radius, max (shape1, shape2)) + length(u);
			}

			float sphere(float3 position, float3 origin, float radius)
			{
				return distance(position, origin) - radius;
			}

			float box(float3 position, float3 center, float3 size)
			{
				float x = max
				(   position.x - center.x - float3(size.x / 2., 0, 0),
					center.x - position.x - float3(size.x / 2., 0, 0)
				);
			
				float y = max
				(   position.y - center.y - float3(size.y / 2., 0, 0),
					center.y - position.y - float3(size.y / 2., 0, 0)
				);
				
				float z = max
				(   position.z - center.z - float3(size.z / 2., 0, 0),
					center.z - position.z - float3(size.z / 2., 0, 0)
				);
			
				float d = x;
				d = max(d,y);
				d = max(d,z);
				return d;
			}

			float quickBox(float3 position, float3 center, float3 size)
			{
				return vmax(abs(position-center) - size);
			}

			float safeZones(float3 position)
			{
				float room = -quickBox(position, float3(0, 2, 0), float3(3, 2, 3));

				return room;
			}

			float scene(float3 position)
			{
				float playerBubble = min(-sphere(position, _WorldSpaceCameraPos, _HeadBubble), position.y);
				float zones = safeZones(position);

				float scene = intersect(playerBubble, zones);

				return scene;
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

			fixed4 color(float3 position){
				float zones = safeZones(position);
				fixed4 col = lerp(_SafeColor, _Color, saturate(abs(zones)));
				return col;
			}

			fixed4 renderSurface(float3 p, float3 dir)
			{
				float3 n = normal(p);
				return simpleLambert(n, dir, color(p));
			}

			fixed4 raycast(float3 position, float3 direction)
			{
				for(int i = 0; i < STEPS; i++){
					float distance = scene(position);
					if(distance < MIN_DISTANCE)
						break;
					
					position += distance * direction;
				}
				return renderSurface(position, direction);
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
