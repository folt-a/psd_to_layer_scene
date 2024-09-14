// use gdnative::api::{Directory, File};
use godot::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::fmt::Display;
use std::fs::{self};
use std::fs::{File};
use std::io::Write;
use std::io::{BufWriter};
use std::ffi::OsStr;
use image::error::{EncodingError, ImageFormatHint};
use image::{ImageError, RgbaImage};
use psd::{Psd, PsdGroup, PsdLayer};

#[derive(GodotClass)]
#[class(init, base = Node)]
struct PsdDataExport {
    #[export]
    psd_dir: GString,
    #[export]
    export_dir: GString,
    #[export]
    is_overwrite: bool,
    #[export]
    ignore_file_paths: godot::builtin::PackedStringArray, // godot::core_types::StringArray,
    #[export]
    image_extension: GString,
    #[export]
    quality_factor: f32,

    base: Base<Node>, 
}

// // NOTE: #[derive(GodotClass)] で #[class(init)] が指定されているとinit()を生成するため、これに加えて手動でinit()を書くと多重定義に陥る
// #[godot_api]
// impl INode for PsdDataExport{
//     fn init(base: Base<Node>) -> Self {
//         PsdDataExport {
//             psd_dir: GString::from(""),
//             export_dir: GString::from(""),
//             is_overwrite: false,
//             ignore_file_paths: PackedStringArray::new(),
//             image_extension: GString::from(""),
//             quality_factor: 0.0,
//             base: base,
//         }
//     }
// }

#[godot_api]
impl PsdDataExport {

    #[func]
    fn execute(&self, export_options : godot::builtin::Dictionary) {
        let dir_path = GString::to_string(&self.psd_dir);
        let mut psd_files: Vec<String> = Vec::new();

        // 再帰処理関数 ディレクトリ内のPSDファイル抽出
        self.recursive_psd_files(dir_path, psd_files.as_mut());

        for psd_file_path in psd_files {
            match self.export(psd_file_path.as_str(), &export_options) {
                Ok(_) => {
                    // do nothing
                },
                Err(err) => {
                    godot::global::push_error(&[err.to_string().to_variant()]);
                }
            }
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
                        .contains(&GString::from(psd_path.to_str().unwrap()));

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

    fn export(&self, file_name: &str, export_options : &Dictionary) -> Result<(), PsdExportError> {
        godot_print!("{}", file_name);

        let psd_dir_path = GString::to_string(&self.psd_dir);
        let psd_path = std::path::Path::new(&psd_dir_path);
        let psd_path = &psd_path.join(file_name.to_string() + ".psd");
        let bytes = fs::read(psd_path).unwrap();
        let psd = Psd::from_bytes(&bytes).unwrap(); // ここで落ちている？？

        let export_dir_path = GString::to_string(&self.export_dir);

        let mut groups_json: Vec<Group> = Vec::new();
        let mut layers_json: Vec<Layer> = Vec::new();

        let mut groups: Vec<&PsdGroup> = psd.group_ids_in_order()
            .iter()
            .map(|x| { psd.groups().get(x).unwrap() })
            .collect();
        // groups.sort_by_key(|x1| { x1.order_id() });
        // groups.sort_by_key(|x1| { x1.parent_id() });
        groups.sort_by_key(|x1| { x1.id() });

        for (i, group) in groups.iter().enumerate() {
            // println!("{}", i);
            // let (_, group) = psd.groups()
            //     .iter()
            //     .find(|(id, _)| *id == i)
            //     .unwrap();

            let group_model = Group {
                id: group.id(),
                parent_id: group.parent_id(),
                visible: group.visible(),
                opacity: group.opacity(),
                name: group.name().to_string(),
                left: group.layer_left(),
                right: group.layer_right(),
                top: group.layer_top(),
                bottom: group.layer_bottom(),
                width: group.width(),
                height: group.height(),
                blending_mode: group.blend_mode() as u8,
                // order_id: group.order_id(), // group.order_id() は存在しなくなっている
                order_id: i32::try_from(i).unwrap(),
            };
            groups_json.push(group_model);
        }
        
        let layers: Vec<&PsdLayer> = psd.layers()
            .iter()
            .collect();
        // layers.sort_by_key(|x1| { x1.order_id() });
        // layers.sort_by_key(|x1| { x1.parent_id() }); // レイヤーはpsdクレート側で既に表示順に並べられている

        for (i, layer) in layers.iter().enumerate() {
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
                // order_id: layer.order_id(),
                order_id: i32::try_from(i).unwrap(),
            };
            layers_json.push(layer_model);
        }

        // ドキュメント全体のレイヤー等名の重複チェック
        if !Self::get_export_option_value(export_options, "append_suffix_by_order", false) {
            let mut doc_member_names : std::collections::HashSet<String> = std::collections::HashSet::new();
            for group in groups.iter() {
                let group_name_string : String = group.name().to_string();
                if !doc_member_names.insert(group_name_string) { // insert で存在確認する
                    return Err(PsdExportError::new(
                        PsdExportErrorKind::new_duplication(
                            group.name().to_string(), 
                            DuplicationScope::Document
                        ),
                        file_name.to_owned(), 
                    ));
                }
            }
            for layer in layers.iter() {
                let layer_name_string : String = layer.name().to_string();
                if !doc_member_names.insert(layer_name_string) { // insert で存在確認する
                    return Err(PsdExportError::new(
                        PsdExportErrorKind::new_duplication(
                            layer.name().to_string(), 
                            DuplicationScope::Document
                        ),
                        file_name.to_owned(), 
                    ));
                } 
            }
        }

        // グループごとのレイヤー名の重複チェック
        let mut groups_member_names : Vec<std::collections::HashSet<String>> = Vec::new();
        groups_member_names.resize(groups.len()+1, HashSet::new());
        for group in groups.iter() {
            let parent_id = group.parent_id().unwrap_or(0u32);
            let parent_id_as_usize = usize::try_from(parent_id).unwrap();
            let group_name_string : String = group.name().to_string();
            if !groups_member_names[parent_id_as_usize].insert(group_name_string) { // insert で存在確認する
                return Err(PsdExportError::new(
                    PsdExportErrorKind::new_duplication(
                        group.name().to_string(), 
                        DuplicationScope::Group
                    ),
                    file_name.to_owned(), 
                ));
                // panic!("Duplicated name of Layer or Group in a same group is not allowed. duplicated name: {}", group.name().to_string()); 
            }
        }
        for layer in layers.iter() {
            let parent_id = layer.parent_id().unwrap_or(0u32);
            let parent_id_as_usize = usize::try_from(parent_id).unwrap();
            let layer_name_string : String = layer.name().to_string();
            if !groups_member_names[parent_id_as_usize].insert(layer_name_string) { // insert で存在確認する
                return Err(PsdExportError::new(
                    PsdExportErrorKind::new_duplication(
                        layer.name().to_string(), 
                        DuplicationScope::Group
                    ),
                    file_name.to_owned(), 
                ));
                // panic!("Duplicated name of Layer or Group in a same group is not allowed. duplicated name: {}", layer.name().to_string()); 
            }
        }

        // 出力先PNGのディレクトリ作成
        let export_dir_path = std::path::Path::new(&export_dir_path);
        let export_dir_path = export_dir_path.join(file_name);
        fs::create_dir_all(&export_dir_path).unwrap();

        let groups_json_path = &export_dir_path.join("groups.json");
        fs::write(groups_json_path, serde_json::to_string(&groups_json).unwrap()).unwrap();

        let layer_json_path = &export_dir_path.join("layers.json");
        fs::write(layer_json_path, serde_json::to_string(&layers_json).unwrap()).unwrap();

        let doc_obj = PsdDoc {
            psd_width: psd.width(),
            psd_height: psd.height()
        };
        let doc_path = &export_dir_path.join("doc.json");
        fs::write(doc_path, serde_json::to_string(&doc_obj).unwrap()).unwrap();

        // println!("{}", serde_json::to_string(&layers_json).unwrap());

        // println!("{}", "--------------------");

        for (i, layer) in psd.layers().iter().enumerate() {
            let layer_name: String = layer.name().to_string();
            let psd_width: u32 = psd.width();
            let psd_height: u32 = psd.height();
            let layer_width: u32 = layer.width().into();
            let layer_height: u32 = layer.height().into();
            let layer_x: u32 = layer.layer_left() as u32;
            let layer_y: u32 = layer.layer_top() as u32;

            let mut img = RgbaImage::from_raw(psd_width, psd_height, layer.rgba()).unwrap();
            // PSD全体からレイヤー部分のみクロップする
            let layer_image = image::imageops::crop(&mut img, layer_x, layer_y, layer_width, layer_height);
            let extension = GString::to_string(&self.image_extension);
            let export_image_path =
                if Self::get_export_option_value(export_options, "append_suffix_by_order", false) { 
                    export_dir_path.join(layer_name + "_" + &(format!("{:0>4}", i.to_string())) + "." + GString::to_string(&self.image_extension).as_str())
                } else { 
                    export_dir_path.join(layer_name + "." + GString::to_string(&self.image_extension).as_str())
                };

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

        Ok(())
    }

    fn get_export_option_value<T>(export_options : &Dictionary, key_str : &str, default : T) -> T where T : ToGodot + FromGodot {
        let Some(option_value_variant) = export_options.get(StringName::from(key_str)) else { return default };

        option_value_variant.try_to().unwrap_or(default)
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
        //         gd_panic_hook.call("rust_panic_hook", &[GString::from_str(error_message).to_variant()]);
        //     }
        // }
    }));
}

// fn init(handle: InitHandle) {
//     handle.add_tool_class::<PsdDataExport>();
//     init_panic_hook();
// }

// godot_init!(init);

#[derive(Serialize, Deserialize, Debug)]
struct PsdDoc {
    psd_width : u32,
    psd_height : u32
}

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

#[derive(Debug)]
struct PsdExportError {
    kind : PsdExportErrorKind,
    psd_name : String,
}

#[derive(Debug)]
enum PsdExportErrorKind {
    NameDuplication(NameDuplicationError)
}

#[derive(Debug)]
struct NameDuplicationError {
    duplicated_element_name : String,
    scope : DuplicationScope,
}

#[derive(Debug)]
enum DuplicationScope { Document, Group }

impl std::error::Error for PsdExportError {}

impl Display for PsdExportError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match &self.kind {
            PsdExportErrorKind::NameDuplication(error) => {
                match error.scope {
                    DuplicationScope::Document => {
                        f.write_str(format!("Duplicated name of Layer or Group in a document is not allowed unless append_suffix_by_order is enabled. duplicated name: {}, psd_name: {}", error.duplicated_element_name, self.psd_name).as_str())
                    },
                    DuplicationScope::Group => {
                        f.write_str(format!("Duplicated name of Layer or Group in a same group is not allowed. duplicated name: {}, psd_name: {}", error.duplicated_element_name, self.psd_name).as_str())
                    }
                }
            }
        }
    }
}

impl PsdExportError {
    fn new(kind : PsdExportErrorKind, psd_name : String) -> PsdExportError {
        return PsdExportError {kind, psd_name};
    }
}

impl PsdExportErrorKind {
    fn new_duplication(duplicated_element_name : String, scope : DuplicationScope) -> PsdExportErrorKind {
        return Self::NameDuplication(NameDuplicationError {duplicated_element_name, scope})
    }
}


// エントリーポイント
struct LibEntry;

#[gdextension]
unsafe impl ExtensionLibrary for LibEntry {
    fn min_level() -> InitLevel { InitLevel::Core }

    #[allow(clippy::single_match)] // 将来的にInitLevel::Core以外のInitLevel::Coreで何かする可能性を考慮している
    fn on_level_init(level: InitLevel){
        match level {
            InitLevel::Core => { init_panic_hook(); }, // FIXME: ちゃんと効いてるかわからない 多分効いてない
            _ => {} // 何もしない
        }
    }
}
