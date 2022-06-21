# PSD To Layer Scene (GodotEngine addon)

GodotEngine 3.4~ Addon.

Convert PSD file to Godot scene with layers info and export layer Images.

---

GodotEngineのアドオンです。

PSDのレイヤー構造・透明度を保持してGodotのシーンに変換します。

レイヤー画像をPNG, WebP, BMP で指定したディレクトリへ出力します。

出力した画像を作成したシーンから読み込んでいます。



PSDでのレイヤー・レイヤーグループはノードツリーの階層となります。

PSDキャンバスサイズより小さいレイヤーは、その位置をGodotのpositionに変換され、配置されます。

透明度はmodulate.a に入ります。

マスクレイヤー・レイヤーの合成モードなどは非対応です。



レイヤー画像はSpriteに変換されます。

ただし、レイヤー名の末尾に **_P** とつけると、そのレイヤーはPolygon2Dに変換されます。

このPolygon2Dは、シーンを開いた状態では描画されていません。Polygon2Dの上部メニューUVエディタより点を設定してください。

textureが設定されていますが、UVが設定されていない状態になっているためです。



また、レイヤー名の末尾に **_AP** とつけると、そのレイヤーはSpriteに変換されますが、少しずれた位置に配置します。

これは、Spriteの上部メニューの「Polygon2Dに変換する」を使用するためのものです。

「Polygon2Dに変換する」を実行するとPolygon2Dに変換され、正しい位置に配置されます。

Spriteと同じ見え方の配置にするためには、SpriteのpositionとPolugon2Dのpositionはレイヤー画像の半分ずれているのが原因です。



使い方

ふつうのアドオンと同じです。

addons/psd_to_layer_scene となるように配置します。



Windows, LinuxのみGDNativeを書き出しているのでMacは非対応です。
Macのネイティブ部分のビルドがめんどくさいのでやっていません。


---

LICENSE　MIT



