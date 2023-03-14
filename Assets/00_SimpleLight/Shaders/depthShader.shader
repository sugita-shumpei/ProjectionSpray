Shader "Unlit/depthRender"
// Shader "シェーダー名"
{
    // Properties(省略可能): 定義したシェーダ内で利用可能な追加の変数を定義可能, Properties { Property... }と, 
    // Propertyは基本的に [attribute] name ("display name", Type) = Specific Value Representaionとかける
    // nameはUnityでは一般的に_(アンダーバー)から始める, attributeは必要に応じて設定し, 省略可能である
    // 今回は使用しない
    //
    // 以下では種類ごとにプロパティの記述例を示す
    // 
    // 数字とスライダー(巣から値を定義)
    // Float:
    // name ("display name", Range (min, max))  = number
    // name ("display name", Float) = number
    // Int:
    // name ("display name", Integer) = number
    //
    // カラーとベクトル(4Dベクトルを定義)
    // Color:
    // name ("display name", Color) = (number,number,number,number)
    // Vector:
    // name ("display name", Vector) = (number,number,number,number)
    //
    // テクスチャ
    // Texture2D:
    // name ("display name", 2D) = "" {}
    // name ("display name", 2D) = "red" {}
    // Texture2DArray
    // name ("display name", 2DArray) = "defaulttexture" {}
    // Texture3D
    // name ("display name", 3D) = "defaulttexture" {}
    // Cubemap
    // name ("display name", Cube) = "defaulttexture" {}
    // CubemapArray
    // name ("display name", CubeArray) = "defaulttexture" {}
    // 
    //       "defaulttexture"で定義するのは空文字列か
    //          "White"((RGBA:1,1,1,1))
    //          "Black"((RGBA:0,0,0,0))
    //          "gray"((RGBA:0.5,0.5,0.5,1))
    //          "bump"((RGBA:0.5,0.5,1,0.5))
    //          "red"((RGBA:1,0,0,0))
    //       のカラーテクスチャ, 空文字列の場合"gray"と同じ値になる
    //
    //       シェーダ内ではnameで設定した値にアクセスできる
    //       またShaderLabコマンドに設定した値を渡す場合 [name]のようにする
    //       例) Offsetコマンド
    //       Offset 0, [_OffsetUnitScale]
    //
    //       スクリプトから値を設定する場合, Material.SetFloat関数などを利用する
    //
    // 属性: 各プロパティ宣言に属性を追加することで, 各値をUnityがどのように取り扱うか設定可能
    // 以下では各属性について説明する
    // 
    // [Gamma]: float, Vectorの値がSRGB値として認識される(=自動的にガンマ変換してくれる)
    // [HDR]: テクスチャ, カラーにHDRの値を使用可能
    // [HideInInspector]: Inspector で隠す
    // [MainTexture]: Material のメインテクスチャに設定, Material.mainTextureでアクセス可能
    //                デフォルトでは, _MainTexのプロパティ名をもつものをメインテクスチャと認識
    //                この属性は最初に設定されたもののみ有効となる
    // [MainColor]: Material のメインカラーに設定, Material.mainColorでアクセス可能
    //              デフォルトでは, _Colorのプロパティ名をもつものをメインカラーと認識
    //[NoScaleOffset]: テクスチャプロパティのタイリングとオフセットのフィールドをエディタ上で隠す
    //[Normal]: テクスチャを法線マップとして設定, 不適合な場合は警告を表示
    //[PerRendererData]: テクスチャプロパティが, MaterialPropertyBlock の形でRendererごとに個別の値が設定される
    //
    //他にもEditor上で値を設定するため以下の属性をサポートする
    // [Toggle(toggle_name)]: エディタ上でtoggle_nameのToggleダイアログを追加, toggleが無効な場合、プロパティは削除される
    //                        また有効な場合 キーワード(toggle_name_ON)が設定される
    //                        #pragma multi_compile __ toggle_name_ONと#ifを使うことでシェーダのvariantが可能
    // [Toggle]: [Toggle(uppercase(property_name)_ON)]と同一
    // [KeywordEnum(state1,state2,state3)]: エディタ上にstateを選択するpop menuを追加, 選択されたstateによってキーワード(uppercase(property_name)_uppercase(state))が設定される
    //                                      #pragma multi_compile __ uppercase(property_name)_uppercase(state1) ... と#ifを使うことでシェーダのvariantが可能
    // [Enum(EnumType)] or [Enum(Value)]  : エディタ上にEnum値を選択するpop menuを追加, 選択されたenum値がFloatのプロパティ値に設定される
    // [PowerSlider(Float Value)]: エディタ上にRangeシェーダープロパティーに対する線形でない反応曲線のスライダーを表示
    // [IntRange (IntValue)]: エディタ上にInt型のRangeシェーダープロパティーに対する線形でない反応曲線のスライダーを表示
    // [Header(message)]: エディタ上に表示する際, 追加のmessageを表示することが可能
    Properties {

    }
    // SubShader: シェーダの実体, Unityはクロスプラットフォームでの動作を前提としており, 特定のプラットフォームで動作しないシェーダもサポートする必要がある
    //            そのため, 複数のSubShaderを持っておき, Engine側が最適なものを選択する
    //            また, LODの値によって, 描画に使用するシェーダを簡略化できる場合, 異なるLODの値を紐づけたSubShaderを用意しておくことで, 
    //            エンジン側に最適なShaderを利用させることができる
    SubShader
    {
        //Tags: SubShaderのレンダリングの設定を指定, Tags{ "キー"="値",... }とかける
        //
        //以下ではよく使うTagのキーについて記述する
        //
        //キー＝"Queue"
        //説明: レンダリング順序を指定, 特に半透明ではレンダリングの実行順序によって描画結果が大きく変わるため必要になる
        //      Background->Geometry->AlphaTest->Transparent->Overlayの順に実行
        //      実際には特定の値に変換されて比較する
        //      Background(1000), Geometry(2000), AlphaTest(2450), Transparent(3000), Overlay(4000)
        //      そこで, BackgroundやGeometry同士で順序付けする際に+数値による加算が可能
        //      Geometry+0(=Geometry) ~ Geometry+500(=2500)までが不透明と判定
        //      それ以降は透明なオブジェクトとして判定される
        //値: Backrgound(最初に実行, 背景描画用) 
        //    Geometry(Default, 不透明なオブジェクト用), 
        //    AlphaTest(アルファテスト用, 全ての不透明オブジェクトの処理後に実行するため),
        //    Transparent(アルファブレンディング用, 全ての不透明オブジェクト、エフェクトはこれを利用)
        //    Overlay(レンズフレアなどポストエフェクト用)
        //
        //キー＝"RenderingType"
        //説明: シェーディングのグループ分けに利用（ビルトインではプリセットで定義), 基本的に不透明ならOpaque, 透明ならTransparentでいい
        //値: Opaque(ほとんどのシェーダー(Normal、Self Illuminated、Reflective、Terrain シェーダー))
        //    Transparent(ほとんどの部分が透過なシェーダー(Transparent、パーティクル、フォント、Terrain 追加パスシェーダー))
        //    TransparentCutout(マスキングされた透過シェーダー(Transparent Cutout、2 パス植生シェーダー))
        //    Background(Skybox シェーダー)
        //    Overlay(ハロー、フレアシェーダー)
        //    TreeOpaque(Terrain エンジン Tree の樹皮)
        //    TreeTransparentCutout(Terrain エンジン Tree 葉っぱ)
        //    TreeBillboard(Terrain エンジンビルボードの 木)
        //    Grass(Terrain エンジンの 草)
        //    GrassBillboard(Terrain エンジンビルボードの 草)
        //その他については説明を省略
        Tags { "RenderType"="Opaque" }
        // LOD(Level Of Detail, 詳細度)を設定する. 異なるLOD値をもつ複数のSubShaderを設定しておくことで詳細度に応じたシェーダ呼び出しが可能
        LOD 100
        Pass
        {
            //Tags(省略可能): Pass内のレンダリングの設定を指定, Tags{ "キー"="値",... }とかける, 今回は使用しない
            //
            //以下ではTagのキーについて記述する
            //
            //キー＝"LightMode"
            //説明: ライティングパイプラインでのパスの役割を定義. 手動で使用されることは稀で、ライティングと相互作用のあるほとんどのシェーダーは サーフェスシェーダー で記述され, その中で処理される
            //値: Always(常にレンダリングされ, ライティングは適用されません)
            //    ForwardBase(フォワードレンダリングで利用, 環境光、メインのディレクショナルライト、頂点/SH ライト、ライトマップが適用)
            //    ForwardAdd(フォワードレンダリングで利用, 付加的なピクセルごとのライトが、ライトごとに1パス適用)
            //    Deferred(ディファードシェーディングで利用,g-bufferを描画)
            //    ShadowCaster(オブジェクトの深度をシャドウマップや深度テクスチャに描画)
            //    MotionVectors(オブジェクトごとのモーションベクターを計算)
            //    その他互換性のための値が存在
            Tags {}
            //CGPROGAM: HLSL(=DirectXのシェーディング言語)の記述を始めるマーカー
            CGPROGRAM
            // 頂点シェーダをvert関数で定義
            #pragma vertex vert
            //ピクセルシェーダをfrag関数で定義
            #pragma fragment frag
            // GeometryShaderをgeom関数で定義、今回は使用しない
            //#pragma geometry geom
            // 標準シェーダライブラリをinclude(具体的な内容はCGIncludes/UnityCG.cgincを参照)
            #include "UnityCG.cginc"
            //頂点シェーダの出力＝ピクセルシェーダの入力用構造体
            //一つのメンバのSEMANTICSがSV_POSITIONとして設定されている必要有り
            struct v2f
            {
                float  depth : TEXCOORD0; // 特にTEXCOORDは高精度で保持する際に利用する(COLORの場合[0,1]の低精度データに利用)
                float4 vertex : SV_POSITION; // VertexShaderにおける頂点出力のSEMANTICS
            };

            v2f vert (float4 pos:POSITION)
            {
                v2f o;
                o.vertex   = UnityObjectToClipPos(pos);    //Unityの組み込み関数(CGIncludes/UnityShaderUtilities.cgincを参照)
                o.depth    = abs(UnityObjectToViewPos(pos).z);
                return o;
            }

            float frag (v2f i) : SV_Target//出力を表すSEMANTICS, 一つの場合 SV_Target, 複数の場合, 構造体の各要素にSV_Target0, SV_Target1とつける
            {
                // sample the texture
                return i.depth;
            }
            //ENDCG: HLSL(=DirectXのシェーディング言語)の記述を終了するマーカー
            ENDCG
        }
    }
}
