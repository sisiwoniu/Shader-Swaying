Shader "Unlit/Swaying"
{
    Properties
    {
		[PerRendererData]
        _MainTex ("Texture", 2D) = "white" {}

		_Color ("Color", Color) = (1, 1, 1, 1)

		//揺れ速度
		_Speed ("Speed", Range(20, 50)) = 25

		//これが小さくすると「液体」っぽくなる
		//割り算の分母になるので、小さくすると揺れの係数が大きくなる
		_Rigidness("Rigidness", Range(1, 50)) = 25

		//揺れの最大強度
		_SwayMax("Sway Max", range(0, 0.1)) = 0.005

		//モデル空間のY座標で使うオフセット
		//設定値以下の頂点全員揺れない
		_YOffset("Y Offset", Range(-1, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "DisableBatching"="True" }
        
        Blend SrcAlpha OneMinusSrcAlpha

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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
			
            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed4 _Color;
			half _Speed;
			half _Rigidness;
			half _SwayMax;
			half _YOffset;

            v2f vert (appdata v)
            {
                v2f o;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                UNITY_TRANSFER_FOG(o,o.vertex);

				//モデル変換して、ワールド空間で座標計算
				float3 pos = mul(unity_ObjectToWorld, v.vertex).xyz;

				//v.vertex.y - _YOffsetって頂点のYにより適用できる強さを指定する
				float x = sin(pos.x / _Rigidness + (_Time.x * _Speed)) * (v.vertex.y - _YOffset) * 5;

				float z = sin(pos.z / _Rigidness + (_Time.x * _Speed)) * (v.vertex.y - _YOffset) * 5;

				//YOffsetの設定値より、頂点座標のYが小さい場合,揺れ強さを0にする
				fixed t = step(0, v.vertex.y - _YOffset);

				//頂点に計算済み係数を代入する
				v.vertex.x = t * x * _SwayMax + v.vertex.x;

				v.vertex.z = t * z * _SwayMax + v.vertex.z;

				//最後にプロジェクション空間変換
				o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
