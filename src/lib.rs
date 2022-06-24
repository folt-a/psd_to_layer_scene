// use gdnative::api::{Directory, File};
use gdnative::prelude::*;
use serde::{Deserialize, Serialize};
use std::fs;
use std::fs::{File};
use std::io::Write;
use std::io::{BufWriter};
use std::ffi::OsStr;
use image::error::{EncodingError, ImageFormatHint};
use image::{ImageError, RgbaImage};
use psd::{Psd, PsdGroup, PsdLayer};

#[derive(NativeClass)]
#[inherit(Node)]
struct PsdDataExport {
    #[property]
    psd_dir: GodotString,
    #[property]
    export_dir: GodotString,
    #[property]
    is_overwrite: bool,
    #[property]
    ignore_file_paths: gdnative::core_types::StringArray,
    #[property]
    image_extension: GodotString,
    #[property]
    quality_factor: f32,
}

#[methods]
impl PsdDataExport {
    fn new(_owner: &Node) -> Self {
        PsdDataExport {
            psd_dir: GodotString::from(""),
            export_dir: GodotString::from(""),
            is_overwrite: false,
            ignore_file_paths: StringArray::new(),
            image_extension: GodotString::from(""),
            quality_factor: 0.0,
        }
    }

    #[export]
    fn execute(&self, _owner: &Node) {
        let dir_path = GodotString::to_string(&self.psd_dir);
        let mut psd_files: Vec<String> = Vec::new();

        // 再帰処理関数 ディレクトリ内のPSDファイル抽出
        self.recursive_psd_files(dir_path, psd_files.as_mut());

        for psd_file_path in psd_files {
            self.export(psd_file_path.as_str());
        }
    }

    fn recursive_psd_files(&self, dir_path: String, vec_files: &mut Vec<String>) {
        if let Ok(entries) = fs::read_dir(dir_path) {
            for entry in entries {
                if let Ok(entry) = entry {
                    if entry.path().is_dir() {
                        // ディレクトリ内再帰処理
                        self.recursive_psd_files(entry.path().to_str().unwrap().to_string(), vec_files);
                        continue;
                    }
                    let extension = entry.path().extension().and_then(OsStr::to_str).unwrap().to_string();
                    if extension != "psd" {
                        continue;
                    }

                    let psd_path = entry.path();
                    let filename = psd_path.file_stem().unwrap().to_str().unwrap();

                    let is_ignore = self.ignore_file_paths
                        .to_vec()
                        .contains(&GodotString::from_str(psd_path.to_str().unwrap()));

                    // godot_print!("is_ignore: {}",psd_path.to_str().unwrap());
                    // godot_print!("is_ignore: {}",is_ignore);
                    if is_ignore {
                        // godot_print!("continue{}","");
                        continue;
                    }

                    vec_files.push(filename.to_string());

                    // godot_print!("{}",&filename);
                }
            }
        }
    }

    fn export(&self, file_name: &str) {
        let psd_dir_path = GodotString::to_string(&self.psd_dir);
        let psd_path = std::path::Path::new(&psd_dir_path);
        let psd_path = &psd_path.join(file_name.to_string() + ".psd");
        let bytes = fs::read(psd_path).unwrap();
        let psd = Psd::from_bytes(&bytes).unwrap();

        let export_dir_path = GodotString::to_string(&self.export_dir);

        let mut groups_json: Vec<Group> = Vec::new();
        let mut layers_json: Vec<Layer> = Vec::new();

        let mut groups: Vec<&PsdGroup> = psd.group_ids_in_order()
            .iter()
            .map(|x| { psd.groups().get(x).unwrap() })
            .collect();
        groups.sort_by_key(|x1| { x1.order_id() });
        groups.sort_by_key(|x1| { x1.parent_id() });

        for group in groups.iter() {
            // println!("{}", i);
            // let (_, group) = psd.groups()
            //     .iter()
            //     .find(|(id, _)| *id == i)
            //     .unwrap();

            let group_model = Group {
                id: group.id(),
                parent_id: group.parent_id(),
                visible: !group.visible(),
                opacity: group.opacity(),
                name: group.name().to_string(),
                left: group.layer_left(),
                right: group.layer_right(),
                top: group.layer_top(),
                bottom: group.layer_bottom(),
                width: group.width(),
                height: group.height(),
                blending_mode: group.blend_mode() as u8,
                order_id: group.order_id(),
            };
            groups_json.push(group_model);
        }

        let mut layers: Vec<&PsdLayer> = psd.layers()
            .iter()
            .collect();
        layers.sort_by_key(|x1| { x1.order_id() });
        layers.sort_by_key(|x1| { x1.parent_id() });

        for layer in layers.iter() {
            // println!("{}", layer.name());
            let layer_model = Layer {
                parent_id: layer.parent_id(),
                visible: layer.visible(),
                opacity: layer.opacity(),
                name: layer.name().to_string(),
                left: layer.layer_left(),
                right: layer.layer_right(),
                top: layer.layer_top(),
                bottom: layer.layer_bottom(),
                width: layer.width(),
                height: layer.height(),
                blending_mode: layer.blend_mode() as u8,
                order_id: layer.order_id(),
            };
            layers_json.push(layer_model);
        }

        // 出力先PNGのディレクトリ作成
        let export_dir_path = std::path::Path::new(&export_dir_path);
        let export_dir_path = export_dir_path.join(file_name);
        fs::create_dir_all(&export_dir_path).unwrap();

        let groups_json_path = &export_dir_path.join("groups.json");
        fs::write(groups_json_path, serde_json::to_string(&groups_json).unwrap()).unwrap();

        let layer_json_path = &export_dir_path.join("layers.json");
        fs::write(layer_json_path, serde_json::to_string(&layers_json).unwrap()).unwrap();

        // println!("{}", serde_json::to_string(&layers_json).unwrap());

        // println!("{}", "--------------------");

        for layer in psd.layers().iter() {
            let layer_name: String = layer.name().to_string();
            let psd_width: u32 = psd.width();
            let psd_height: u32 = psd.width();
            let layer_width: u32 = layer.width().into();
            let layer_height: u32 = layer.height().into();
            let layer_x: u32 = layer.layer_left() as u32;
            let layer_y: u32 = layer.layer_top() as u32;

            let mut img = RgbaImage::from_raw(psd_width, psd_height, layer.rgba()).unwrap();
            // PSD全体からレイヤー部分のみクロップする
            let layer_image = image::imageops::crop(&mut img, layer_x, layer_y, layer_width, layer_height);
            let extension = GodotString::to_string(&self.image_extension);
            let export_image_path = &export_dir_path.join(layer_name + "." + GodotString::to_string(&self.image_extension).as_str());
            match &*extension {
                "png" => {
                    layer_image
                        .to_image()
                        .save_with_format(export_image_path, image::ImageFormat::Png)
                        .unwrap();
                }
                "webp" => {
                    let w = File::create(export_image_path).unwrap();
                    let mut writer = BufWriter::new(w);
                    const LOSSLESS: f32 = 101.0;
                    if &self.quality_factor == &LOSSLESS {
                        let buf = libwebp::WebPEncodeLosslessRGBA(&layer_image.to_image(), layer_width, layer_height, layer_width * 4)
                            .map_err(|_| EncodingError::new(ImageFormatHint::Unknown, "Webp Format Error".to_string()))
                            .map_err(ImageError::Encoding)
                            .unwrap();
                        writer.write_all(&buf).unwrap();
                        // godot_print!("{0}","lossless");
                    } else {
                        let buf = libwebp::WebPEncodeRGBA(&layer_image.to_image(), layer_width, layer_height, layer_width * 4, self.quality_factor)
                            .map_err(|_| EncodingError::new(ImageFormatHint::Unknown, "Webp Format Error".to_string()))
                            .map_err(ImageError::Encoding)
                            .unwrap();
                        writer.write_all(&buf).unwrap();
                        // godot_print!("{0}","not lossless");
                    }
                    // libwebp_image::webp_write_rgba(&layer_image.to_image(), &mut writer).unwrap();
                }
                "jpg" => {
                    layer_image
                        .to_image()
                        .save_with_format(export_image_path, image::ImageFormat::Jpeg)
                        .unwrap();
                }
                "gif" => {
                    layer_image
                        .to_image()
                        .save_with_format(export_image_path, image::ImageFormat::Gif)
                        .unwrap();
                }
                "bmp" => {
                    layer_image
                        .to_image()
                        .save_with_format(export_image_path, image::ImageFormat::Bmp)
                        .unwrap();
                }
                _ => panic!(),
            }
        }
    }
}

pub fn init_panic_hook() {
    // To enable backtrace, you will need the `backtrace` crate to be included in your cargo.toml, or 
    // a version of Rust where backtrace is included in the standard library (e.g. Rust nightly as of the date of publishing)
    // use backtrace::Backtrace;
    // use std::backtrace::Backtrace;
    let old_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        let loc_string;
        if let Some(location) = panic_info.location() {
            loc_string = format!("file '{}' at line {}", location.file(), location.line());
        } else {
            loc_string = "unknown location".to_owned()
        }

        let error_message;
        if let Some(s) = panic_info.payload().downcast_ref::<&str>() {
            error_message = format!("[RUST] {}: panic occurred: {:?}", loc_string, s);
        } else if let Some(s) = panic_info.payload().downcast_ref::<String>() {
            error_message = format!("[RUST] {}: panic occurred: {:?}", loc_string, s);
        } else {
            error_message = format!("[RUST] {}: unknown panic occurred", loc_string);
        }
        godot_error!("{}", error_message);
        // Uncomment the following line if backtrace crate is included as a dependency
        // godot_error!("Backtrace:\n{:?}", Backtrace::new());
        (*(old_hook.as_ref()))(panic_info);

        // unsafe {
        //     if let Some(gd_panic_hook) = gdnative::api::utils::autoload::<gdnative::api::Node>("rust_panic_hook") {
        //         gd_panic_hook.call("rust_panic_hook", &[GodotString::from_str(error_message).to_variant()]);
        //     }
        // }
    }));
}

fn init(handle: InitHandle) {
    handle.add_tool_class::<PsdDataExport>();
    init_panic_hook();
}

godot_init!(init);

#[derive(Serialize, Deserialize, Debug)]
struct Group {
    id: u32,
    parent_id: Option<u32>,
    visible: bool,
    opacity: u8,
    name: String,
    left: i32,
    right: i32,
    top: i32,
    bottom: i32,
    width: u16,
    height: u16,
    blending_mode: u8,
    order_id: i32,
}

#[derive(Serialize, Deserialize, Debug)]
struct Layer {
    // id: u32,
    parent_id: Option<u32>,
    visible: bool,
    opacity: u8,
    name: String,
    left: i32,
    right: i32,
    top: i32,
    bottom: i32,
    width: u16,
    height: u16,
    blending_mode: u8,
    order_id: i32,
}