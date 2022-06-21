// use gdnative::api::{Directory, File};
// use serde::{Deserialize, Serialize};
// use gdnative::prelude::*;
// use std::fs;
// use std::ffi::OsStr;
// use image::RgbaImage;
// use psd::{ColorMode, Psd, PsdChannelCompression, PsdChannelKind};
// 
// fn main() {
//     execute()
// }
// 
// fn execute() {
//     let dir_path = "/home/folta/godot/folta-tachie/a/";
//     if let Ok(entries) = fs::read_dir(dir_path) {
//         for entry in entries {
//             if let Ok(entry) = entry {
//                 // TODO recycle
//                 if entry.path().is_dir() {
//                     continue;
//                 }
//                 let extension = entry.path().extension().and_then(OsStr::to_str).unwrap().to_string();
//                 if extension != "psd" {
//                     continue;
//                 }
// 
//                 let psdpath = entry.path();
//                 let filename = psdpath.file_stem().unwrap().to_str().unwrap().to_string();
// 
//                 // godot_print!("{}",&filename);
// 
//                 export(filename.as_str());
//             }
//         }
//     }
// }
// 
// fn export(file_name: &str) {
//     let psd_dir_path = "/home/folta/godot/folta-tachie/a/";
//     let psd_path = std::path::Path::new(&psd_dir_path);
//     let psd_path = &psd_path.join(file_name.to_string() + ".psd");
//     let bytes = fs::read(psd_path).unwrap();
//     let psd = Psd::from_bytes(&bytes).unwrap();
// 
//     let export_dir_path = "/home/folta/godot/folta-tachie/export2";
// 
//     let mut groups_json: Vec<Group> = Vec::new();
//     let mut layers_json: Vec<Layer> = Vec::new();
// 
//     for i in psd.group_ids_in_order().iter() {
//         // println!("{}", i);
//         let (_, group) = psd.groups()
//             .iter()
//             .find(|(id, x)| *id == i)
//             .unwrap();
// 
//         let group_model = Group {
//             id: *i,
//             parent_id: group.parent_id(),
//             visible: group.visible(),
//             opacity: group.opacity(),
//             name: group.name().to_string(),
//             left: group.layer_left(),
//             right: group.layer_right(),
//             top: group.layer_top(),
//             bottom: group.layer_bottom(),
//             width: group.width(),
//             height: group.height(),
//             blending_mode: group.blend_mode() as u8,
//         };
//         groups_json.push(group_model);
// 
//         let layers = psd.get_group_sub_layers(i).unwrap();
//         for layer in layers {
//             // println!("{}", layer.name());
//             let layer_model = Layer {
//                 parent_id: layer.parent_id(),
//                 visible: layer.visible(),
//                 opacity: layer.opacity(),
//                 name: layer.name().to_string(),
//                 left: layer.layer_left(),
//                 right: layer.layer_right(),
//                 top: layer.layer_top(),
//                 bottom: layer.layer_bottom(),
//                 width: layer.width(),
//                 height: layer.height(),
//                 blending_mode: layer.blend_mode() as u8,
//             };
//             layers_json.push(layer_model);
//         }
//     }
// 
//     // 出力先PNGのディレクトリ作成
//     let export_dir_path = std::path::Path::new(&export_dir_path);
//     let export_dir_path = export_dir_path.join(file_name);
//     fs::create_dir_all(&export_dir_path).unwrap();
// 
//     let groups_json_path = &export_dir_path.join("groups.json");
//     fs::write(groups_json_path, serde_json::to_string(&groups_json).unwrap()).unwrap();
// 
//     let layer_json_path = &export_dir_path.join("layers.json");
//     fs::write(layer_json_path, serde_json::to_string(&layers_json).unwrap()).unwrap();
// 
//     // println!("{}", serde_json::to_string(&groups_json).unwrap());
//     // println!("{}", serde_json::to_string(&layers_json).unwrap());
// 
//     println!("{}", "--------------------");
// 
//     for layer in psd.layers().iter() {
//         let layer_name: String = layer.name().to_string();
//         let psd_width: u32 = psd.width();
//         let psd_height: u32 = psd.width();
//         let layer_width: u32 = layer.width().into();
//         let layer_height: u32 = layer.height().into();
//         let layer_x: u32 = layer.layer_left() as u32;
//         let layer_y: u32 = layer.layer_top() as u32;
// 
//         let mut img = RgbaImage::from_raw(psd_width, psd_height, layer.rgba()).unwrap();
//         // PSD全体からレイヤー部分のみクロップする
//         let layer_image = image::imageops::crop(&mut img, layer_x, layer_y, layer_width, layer_height);
//         let png_path = &export_dir_path.join(layer_name + ".png");
//         layer_image
//             .to_image()
//             .save_with_format(png_path, image::ImageFormat::Png)
//             .unwrap();
//     }
// }
// 
// 
// #[derive(Serialize, Deserialize, Debug)]
// struct Group {
//     id: u32,
//     parent_id: Option<u32>,
//     visible: bool,
//     opacity: u8,
//     name: String,
//     left: i32,
//     right: i32,
//     top: i32,
//     bottom: i32,
//     width: u16,
//     height: u16,
//     blending_mode: u8,
// }
// 
// #[derive(Serialize, Deserialize, Debug)]
// struct Layer {
//     // id: u32,
//     parent_id: Option<u32>,
//     visible: bool,
//     opacity: u8,
//     name: String,
//     left: i32,
//     right: i32,
//     top: i32,
//     bottom: i32,
//     width: u16,
//     height: u16,
//     blending_mode: u8,
// }
// 
// #[derive(Debug, Clone, Copy)]
// pub enum BlendMode {
//     PassThrough = 0,
//     Normal = 1,
//     Dissolve = 2,
//     Darken = 3,
//     Multiply = 4,
//     ColorBurn = 5,
//     LinearBurn = 6,
//     DarkerColor = 7,
//     Lighten = 8,
//     Screen = 9,
//     ColorDodge = 10,
//     LinearDodge = 11,
//     LighterColor = 12,
//     Overlay = 13,
//     SoftLight = 14,
//     HardLight = 15,
//     VividLight = 16,
//     LinearLight = 17,
//     PinLight = 18,
//     HardMix = 19,
//     Difference = 20,
//     Exclusion = 21,
//     Subtract = 22,
//     Divide = 23,
//     Hue = 24,
//     Saturation = 25,
//     Color = 26,
//     Luminosity = 27,
// }
