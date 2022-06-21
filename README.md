# PSD To Layer Scene (GodotEngine addon)

![psdtolayer](https://user-images.githubusercontent.com/32963227/174834872-9b256891-c9ff-455a-9e10-6a7f06fe4c03.png)


GodotEngine 3.4~ Addon.

Convert PSD file to Godot scene with layers info and export layer Images.

---

![psdtolayer2](https://user-images.githubusercontent.com/32963227/174835421-35970f7f-31a7-434b-965f-62e8206bb954.png)

## このアドオンについて

GodotEngineのアドオンです。

PSDのレイヤー構造・透明度を保持してGodotのシーンに変換します。

レイヤー画像をPNG, WebP, BMP で指定したディレクトリへ出力します。

出力した画像を作成したシーンから読み込んでいます。

PSDの読み込みは、GDNative(Rust)内にて行われています。



## Godotに持っていけるデータ

PSDでのレイヤー・レイヤーグループはノードツリーの階層となります。

PSDキャンバスサイズより小さいレイヤーは、その位置をGodotのpositionに変換され、配置されます。

レイヤーの透明度はmodulate.a に入ります。

**グループの透明度・塗り・フィルター・マスクレイヤー・レイヤーの合成モードなどは非対応です。**



## レイヤー画像をSpriteノードまたはPolygon2Dノードとして読み込む
### Sprite

デフォルトではレイヤー画像はSpriteに変換されます。

### Polygon2D

レイヤー名の末尾に **_P** とつけると、そのレイヤーはPolygon2Dに変換されます。

このPolygon2Dは、シーンを開いた状態では描画されていません。

textureが設定されていますが、UVが設定されていない状態になっているためです。

Polygon2Dの上部メニューUVエディタより点を設定してください。

![image](https://user-images.githubusercontent.com/32963227/174841959-43c44884-8c01-4d8b-b07d-b7120accbfd3.png)

「UV」ボタン

![image](https://user-images.githubusercontent.com/32963227/174842114-98cb0de7-cf9f-4b23-a3fc-07ae66395fcd.png)

とりあえず表示させています。よくわからないですがもっといい感じに割ってください。

> 参考: https://www.youtube.com/watch?v=irN6b8ESrH4

### Spriteからの変換でPolygon2D

レイヤー名の末尾に **_AP** とつけると、そのレイヤーはSpriteに変換されますが、少しずれた位置に配置します。

これは、Spriteの上部メニューの「Polygon2Dに変換する」を使用するためのものです。

1. 「Polygon2Dに変換する」を実行するとPolygon2Dに変換されます。
2. Polygon2Dの上部メニューUVエディタにて「編集」→「UVをPolygon2Dにコピー」で正しい位置に配置されます。

Spriteと同じ見え方の配置にするためには、SpriteのpositionとPolygon2Dのpositionはレイヤー画像の半分ずれているので、ずらして位置を調整しています。（苦しい）



## 使い方

インストールについては、ふつうのアドオンと同じです。

addons/psd_to_layer_scene となるように配置します。プロジェクト設定→プラグインでこのアドオンを☑します。

Windows, LinuxのみGDNativeを書き出しているのでMacは非対応です。

PSD→画像 の処理でのpanicエラーはGodotの「出力」タブに内容が書かれます。


---

GDNative（Rust）使用crate

https://github.com/folt-a/psd_to_layer_scene/blob/native/LICENSE.json

---

LICENSE　MIT



