# PSD To Layer Scene (GodotEngine addon)

![psdtolayer](https://user-images.githubusercontent.com/32963227/174834872-9b256891-c9ff-455a-9e10-6a7f06fe4c03.png)


GodotEngine 3.4~ Addon.

Convert PSD file to Godot scene with layers info and export layer Images.

日本語のREADMEは下のほうにあります。(Japanese READ ME is below)

---

![psdtolayer2](https://user-images.githubusercontent.com/32963227/174835421-35970f7f-31a7-434b-965f-62e8206bb954.png)

---


## Overview

add-on for Godot Engine.

it converts PSD to Godot scene, keep PSD layer's tree and transparency

Outputs the layer image to the directory specified by PNG, WebP, BMP.

The output image read from the created scene.

** This add-on does not need to be included in the game itself. ** 

(Because it only creates scenes and images)

reading PSD feature is in GDNative (Rust).

## PSD to Godot

Layers and layer groups in PSD are the hierarchy of the node tree.

Layers smaller than the PSD canvas converts their position to Godot's position.

The transparency of the layer goes into modulate.a.

** Group transparency, filter, mask layer, layer composition mode, etc. are not supported. ** **

## Import layer image as a Sprite node or Polygon 2D node
### Sprite

By default, layer images are converted to Sprite.

### Polygon2D

If you add ** _P ** to the end of the layer name, that layer will be converted to Polygon2D.

This Polygon2D is not drawn when you open the exported scene.

This is because the texture is set, but the UV is not set.

Set a point from the UV editor on the top menu of Polygon2D.

![174841959-43c44884-8c01-4d8b-b07d-b7120accbfd3](https://user-images.githubusercontent.com/32963227/174844863-65bfa0ba-2f85-4c2a-9662-e42b8e7f3c5f.png)

"UV" button

![174842114-98cb0de7-cf9f-4b23-a3fc-07ae66395fcd](https://user-images.githubusercontent.com/32963227/174844891-8bf16c8b-add9-4c0a-b5e7-d3369acd41ec.png)

It's not a good way to polygon mesh, but I'm displaying it for the time being.

> Reference: https://www.youtube.com/watch?v=irN6b8ESrH4

### Convert from Sprite to Polygon2D

If you add ** _AP ** to the end of the layer name, the layer will be converted to Sprite, but it will be placed at a slightly offset position.

This is for using "Convert to Polygon 2D" in Sprite's top menu.

![image](https://user-images.githubusercontent.com/32963227/174844245-f1b63e3e-3fc6-4f33-bb66-9548478e7fd7.png)

1. Execute "Convert to Polygon2D" to convert to Polygon2D.
2. In the upper menu UV editor of Polygon2D, select "Edit"-> "Copy UV to Polygon2D" to place it in the correct position.

To get the same appearance as Sprite, the position of Sprite and the position of Polygon2D are shifted by half of the layer image, so the position is adjusted by shifting.


## How to use

The installation is the same as a normal Godot add-on.

Arrange so that it becomes addons / psd_to_layer_scene. ☑ This add-on in Project Settings → Plugins.

Windows and Linux. 

Mac is not yet supported.

The Rust panic error in PSD → image processing is written in Godot's Output tab.

---

thank you for GDNative（Rust）crate

https://github.com/folt-a/psd_to_layer_scene/blob/native/LICENSE.json

---

LICENSE　MIT

---

## このアドオンについて

GodotEngineのアドオンです。

PSDのレイヤー構造・透明度を保持してGodotのシーンに変換します。

レイヤー画像をPNG, WebP, BMP で指定したディレクトリへ出力します。

出力した画像を作成したシーンから読み込んでいます。

**このアドオンはゲーム本体に含める必要はありません。**　（シーンと画像を作るだけなので）

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

![174841959-43c44884-8c01-4d8b-b07d-b7120accbfd3](https://user-images.githubusercontent.com/32963227/174844863-65bfa0ba-2f85-4c2a-9662-e42b8e7f3c5f.png)

「UV」ボタン

![174842114-98cb0de7-cf9f-4b23-a3fc-07ae66395fcd](https://user-images.githubusercontent.com/32963227/174844891-8bf16c8b-add9-4c0a-b5e7-d3369acd41ec.png)


よくない割り方ですがとりあえず表示させています。

> 参考: https://www.youtube.com/watch?v=irN6b8ESrH4

### Spriteからの変換でPolygon2D

レイヤー名の末尾に **_AP** とつけると、そのレイヤーはSpriteに変換されますが、少しずれた位置に配置します。

これは、Spriteの上部メニューの「Polygon2Dに変換する」を使用するためのものです。

![image](https://user-images.githubusercontent.com/32963227/174844245-f1b63e3e-3fc6-4f33-bb66-9548478e7fd7.png)

1. 「Polygon2Dに変換する」を実行するとPolygon2Dに変換されます。
2. Polygon2Dの上部メニューUVエディタにて「編集」→「UVをPolygon2Dにコピー」で正しい位置に配置されます。

Spriteと同じ見え方の配置にするには、SpriteのpositionとPolygon2Dのpositionはレイヤー画像の半分ずれているので、ずらして位置を調整しています。（苦しい）


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



