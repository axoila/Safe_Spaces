Shader "Everything" {
	Properties {
		_Color ("Base Color", Color) = (1,1,1,1)
		_SafeColor("Safe-Zone Color", Color) = (1,1,1,1)
		_MarkerColor("Marker Color", Color) = (1,1,1,1)

		_Gloss ("Gloss", float) = 1
		_SpecularPower ("Specular", float) = 1
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

			#define PI 3.14159265
			#define TAU (2*PI)
			#define PHI (sqrt(5)*0.5 + 0.5)

			float4 _Color;
			float _Gloss;
			float _SpecularPower;

			fixed4 _SafeColor;
			fixed4 _MarkerColor;

			uniform float _HeadBubble;
			uniform float4 _HeadPos;

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

			float mod(float x, float mod){
				return ((x % mod)+mod)%mod;
			}

			fixed4 simpleLambert (fixed3 normal, fixed3 viewDirection, fixed4 color) 
			{
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;	// Light direction
				fixed3 lightCol = _LightColor0.rgb;		// Light color

				fixed NdotL = dot(normal, lightDir);
				NdotL = 0.2 + NdotL * (NdotL < 0 ? 0.2 : 0.8);

				// Specular
				fixed3 h = (lightDir - viewDirection) / 2.;
				fixed s = max(pow( dot(normal, h), _SpecularPower) * _Gloss, 0);

				fixed4 c;
				c.rgb = color * lightCol * NdotL + s * lightCol + color * unity_AmbientSky;
				c.a = 1;
				return c;
			}

			float pModPolar(inout float2 p, float repetitions, float offset = 0) {
				float angle = 2*PI/repetitions;
				float a = atan2(p.y, p.x) + angle/2  + offset;
				float r = length(p);
				float c = floor(a/angle);
				a = mod(a, angle) - angle/2;
				p = float2(cos(a), sin(a))*r;
				// For an odd number of repetitions, fix cell index of the cell in -x direction
				// (cell index would be e.g. -5 and 5 in the two halves of the cell):
				if (abs(c) >= (repetitions/2)) c = abs(c);
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

			float smoothMerge(float shape1, float shape2, float smooth){
				float res = exp(-smooth*shape1) + exp(-smooth*shape2);
 				return -log(max(0.0001,res)) / smooth;
			}

			float roundMerge(float shape1, float shape2, float radius) {
				float2 u = max(float2(radius - shape1,radius - shape2), float2(0, 0));
				return max(radius, min (shape1, shape2)) - length(u);
			}

			float intersect(float shape1, float shape2)
			{
				return max(shape1, shape2);
			}

			float smoothIntersect(float shape1, float shape2, float smooth){
				float res = exp(smooth * shape1) + exp(smooth * shape2);
				return log(max(0.0001,res)) / smooth;
			}

			float roundIntersect(float shape1, float shape2, float radius){
				float2 u = max(float2(radius + shape1,radius + shape2), float2(0, 0));
				return min(-radius, max (shape1, shape2)) + length(u);
			}

			float sphere(float3 position, float3 origin, float radius)
			{
				return distance(position, origin) - radius;
			}

			float cylinder(float3 p, float r, float height) {
				float d = length(p.xz) - r;
				d = max(d, abs(p.y) - height);
				return d;
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

			float fBox(float3 p, float3 b) {
				float3 d = abs(p) - b;
				return length(max(d, 0)) + vmax(min(d, 0));
			}

			float quickBox(float3 position, float3 center, float3 size)
			{
				return vmax(abs(position-center) - size);
			}

			float marker(float3 position, float3 markerBase){
				position -= markerBase;

				float size = 5;
				float c = 0;

				float guard = cylinder(position, 0.25, 2);
				if(guard > 1)
					return guard;

				float cyl = cylinder(position, .15, 1.7);
				float ball = sphere(position, float3(0, 1.7, 0), 0.3);

				float base = roundMerge(cyl, ball, .1);
				
				c = pModPolar(position.xz,5, _Time.y); 
				position.x -= 0.25;
				
				// the repeated geometry:
				float balls = sphere(position, float3(0, 1.2, 0), .1);


				float mark = smoothMerge(balls, base, 50);

				return mark;
			}

			float getMarkers(float3 position){
				float allMarkers = marker(position, float3(0, 0, 6));
				allMarkers = merge(allMarkers, marker(position, float3(3, 0, 10)));
				allMarkers = merge(allMarkers, marker(position, float3(8, 0, 15)));
				allMarkers = merge(allMarkers, marker(position, float3(14, 0, 15)));
				allMarkers = merge(allMarkers, marker(position, float3(20, 0, 17)));

				return allMarkers;
			}

			float getSafeZones(float3 position)
			{
				float3 roomSize = float3(10, 5, 10);
				float rooms = -box(position, float3(0, 2.5, 0), roomSize);
				rooms = intersect(rooms, -box(position, float3(30, 2.5, 20), roomSize));

				return rooms;
			}

			float scene(float3 position)
			{
				float playerBubble = min(-sphere(position, _HeadPos, _HeadBubble), position.y);
				float zones = getSafeZones(position);

				float scene = smoothIntersect(playerBubble, zones, 5);
				
				float markers = getMarkers(position);
				scene = merge(scene, markers);

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
				float zones = getSafeZones(position);
				float markers = getMarkers(position);
				fixed4 col = lerp(_SafeColor, _Color, saturate(-zones > 0 ? pow(-zones * 0.25, .5) : -zones));
				col = lerp(_MarkerColor, col, saturate(markers*10));
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
