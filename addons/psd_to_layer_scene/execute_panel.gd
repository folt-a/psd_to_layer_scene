tool
extends VBoxContainer

const ADDONS_PATH: String = "res://addons"
onready var psd_data_export: Node = $PsdDataExport

onready var S = load("res://addons/psd_to_layer_scene/translation/translation.gd").get_translation_singleton(
	self
)

var filesystem: EditorFileSystem

var _psd_timestamps: Dictionary = {}

# Node references
onready var _make_psd_layer_script := preload("res://addons/psd_to_layer_scene/make_psd_to_layer_scene.gd")

onready var title_label: Label = $TitleLabel
onready var psd_files_label: Label = $PsdFilesDirectory/PsdFilesLabel
onready var psd_layers_dir_label: Label = $PsdLayersDirectory/PsdLayersDirLabel
onready var export_scenes_dir_label: Label = $ExportScenesDirectory/ExportScenesDirLabel
onready var result_log_label: Label = $ResultLogLabel
onready var image_extension_label: Label = $ImageExtension/ImageExtensionLabel
onready var quality_factor_label: Label = $WebPQualityFactor/QualityFactor2/QualityFactorLabel

onready var web_p_quality_factor: HBoxContainer = $WebPQualityFactor

onready var psd_files_dir_value: LineEdit = $PsdFilesDirectory/PsdFilesDirValue
onready var psd_layers_dir_value: LineEdit = $PsdLayersDirectory/PsdLayersDirValue
onready var export_scenes_dir_value: LineEdit = $ExportScenesDirectory/ExportScenesDirValue
onready var image_extension_option: OptionButton = $ImageExtension/ImageExtensionOption
onready var is_loss_less_check: CheckBox = $WebPQualityFactor/QualityFactor2/IsLossLessCheck
onready var quality_factor_spin_box: SpinBox = $WebPQualityFactor/QualityFactor2/QualityFactorSpinBox
onready var is_timestamp_check: CheckBox = $IsOverwriteLayer/IsTimestampCheck
onready var is_overwrite_layer_check: CheckBox = $IsOverwriteLayer/IsOverwriteLayerCheck
onready var is_overwrite_scene_check: CheckBox = $IsOverwriteScene/IsOverwriteSceneCheck
onready var execute_button: Button = $ExecuteButton
func init() -> void:
	quality_factor_spin_box.connect("value_changed",self,"_on_quality_factor_spin_box_value_changed")
	is_loss_less_check.connect("pressed",self,"on_is_loss_less_check_pressed")
	image_extension_option.connect("item_selected", self, "_on_image_extension_option_item_selected");
	execute_button.connect("pressed", self, "_on_execute_button_pressed")
	export_scenes_dir_value.connect(
		"text_changed", self, "_on_export_scenes_dir_value_text_changed"
	)
	psd_files_dir_value.connect("text_changed", self, "_on_psd_files_dir_value_text_changed")
	psd_layers_dir_value.connect("text_changed", self, "_on_psd_layers_dir_value_text_changed")
	is_overwrite_scene_check.connect("pressed", self, "_on_is_overwrite_scene_check_pressed")
	is_overwrite_layer_check.connect("pressed", self, "_on_is_overwrite_layer_check_pressed")
	is_timestamp_check.connect("pressed", self, "_on_is_timestamp_check_pressed")
	
	image_extension_option.clear()
	image_extension_option.add_item('PNG',0)
	image_extension_option.add_item('WebP',1)
#	image_extension_option.add_item('JPEG',2)
#	image_extension_option.add_item('GIF',3)
#	image_extension_option.add_item('BMP',4)

	title_label.text = S.tr("title_label")
	psd_files_label.text = S.tr("psd_files_label")
	psd_layers_dir_label.text = S.tr("psd_layers_dir_label")
	export_scenes_dir_label.text = S.tr("export_scenes_dir_label")
	image_extension_label.text = S.tr("image_extension_label")
	quality_factor_label.text = S.tr("quality_factor_label")
	is_loss_less_check.text = S.tr("is_loss_less_check")
	is_overwrite_layer_check.text = S.tr("is_overwrite_layer_check")
	is_overwrite_scene_check.text = S.tr("is_overwrite_scene_check")
	is_timestamp_check.text = S.tr("is_timestamp_check")
	execute_button.text = S.tr("execute_button")

	_setting_load()


func _setting_load():
	var fl = File.new()
	if fl.file_exists("res://addons/psd_to_layer_scene/save.dat"):
		fl.open("res://addons/psd_to_layer_scene/save.dat", File.READ)
		var data = JSON.parse(fl.get_line()).result
		if data and data.has("psd_files_dir_value"):
			psd_files_dir_value.text = data.psd_files_dir_value
		if data and data.has("psd_layers_dir_value"):
			psd_layers_dir_value.text = data.psd_layers_dir_value
		if data and data.has("export_scenes_dir_value"):
			export_scenes_dir_value.text = data.export_scenes_dir_value
		if data and data.has("is_loss_less_check"):
			is_loss_less_check.pressed = data.is_loss_less_check
		if data and data.has("quality_factor_spin_box"):
			quality_factor_spin_box.value = data.quality_factor_spin_box
			quality_factor_spin_box.apply()
		if data and data.has("is_overwrite_scene_check"):
			is_overwrite_scene_check.pressed = data.is_overwrite_scene_check
		if data and data.has("is_overwrite_layer_check"):
			is_overwrite_layer_check.pressed = data.is_overwrite_layer_check
		if data and data.has("is_timestamp_check"):
			is_timestamp_check.pressed = data.is_timestamp_check
		if data and data.has("psd_timestamps"):
			self._psd_timestamps = data.psd_timestamps
		if data and data.has("image_extension_option"):
			image_extension_option.select(data.image_extension_option)
		else:
			image_extension_option.select(0)
		fl.close()
	web_p_quality_factor.visible = image_extension_option.selected == 1
	quality_factor_spin_box.visible = !is_loss_less_check.pressed
	quality_factor_label.visible = !is_loss_less_check.pressed


func _setting_save() -> void:
	var fl = File.new()
	var data = {
		psd_files_dir_value = psd_files_dir_value.text,
		psd_layers_dir_value = psd_layers_dir_value.text,
		export_scenes_dir_value = export_scenes_dir_value.text,
		is_loss_less_check = is_loss_less_check.pressed,
		quality_factor_spin_box = quality_factor_spin_box.value,
		is_overwrite_scene_check = is_overwrite_scene_check.pressed,
		is_overwrite_layer_check = is_overwrite_layer_check.pressed,
		is_timestamp_check = is_timestamp_check.pressed,
		psd_timestamps = self._psd_timestamps,
		image_extension_option = image_extension_option.selected
	}

	fl.open("res://addons/psd_to_layer_scene/save.dat", File.WRITE)
	fl.store_line(to_json(data))
	fl.close()


func _on_execute_button_pressed():
	execute_button.disabled = true
	
#	存在チェック
	var dir := Directory.new()
	if !dir.dir_exists(psd_files_dir_value.text):
		printerr(S.tr("_cantfindpsddir"))
	if !dir.dir_exists(psd_layers_dir_value.text):
		if dir.make_dir_recursive(psd_layers_dir_value.text) != OK:
			printerr(S.tr("_cantmakelayerdir"))

	# PSD変更チェック
	var psd_file_paths: Array = _get_recursive_file_ext_paths(psd_files_dir_value.text, "psd")
	var ignore_file_paths: PoolStringArray = []
	for psd_file_path in psd_file_paths:
		if !_is_modified(psd_file_path):
			print("[Ignore] " + psd_file_path + S.tr("_isnotmodified"))
			ignore_file_paths.append(psd_file_path)
	_setting_save()

	var extension := ""
	match image_extension_option.selected:
		0:
			extension = 'png'
		1:
			extension = 'webp'
#		2:
#			extension = 'jpg'
#		3:
#			extension = 'gif'
#		4:
#			extension = 'bmp'
			
#	画像出力、JSON出力
	psd_data_export.psd_dir = ProjectSettings.globalize_path(psd_files_dir_value.text)
	psd_data_export.export_dir = ProjectSettings.globalize_path(psd_layers_dir_value.text)
	psd_data_export.is_overwrite = is_overwrite_layer_check.pressed
	psd_data_export.ignore_file_paths = ignore_file_paths
	psd_data_export.image_extension = extension
	if is_loss_less_check.pressed:
		psd_data_export.quality_factor = 101.0
	else:
		psd_data_export.quality_factor = quality_factor_spin_box.value
		
	result_log_label.modulate.a = 1
	result_log_label.text = S.tr("_psdtoimage")
	print("[Start] " + S.tr("_psdtoimage"))
	yield(VisualServer, "frame_post_draw")
	psd_data_export.execute()
	print("[End] " + S.tr("_psdtoimagecompleted"))
	
	var batch_script = _make_psd_layer_script.new(
		S,
		psd_layers_dir_value.text,
		export_scenes_dir_value.text,
		is_overwrite_layer_check.pressed,
		extension,
		filesystem
	)
	
	result_log_label.text = S.tr("_createscene")
	print("[Start] " + S.tr("_createscene"))
	yield(VisualServer, "frame_post_draw")
	var batch_state: GDScriptFunctionState = batch_script.execute()
	print("[End] " + S.tr("_createscenecompleted"))
	
	var res: int = yield(batch_state, "completed")
	filesystem.scan_sources()
	if res == OK:
		result_log_label.text = S.tr("_finishoutput")
		print("[Completed] " + S.tr("_finishoutput"))
	elif res == -1:
		result_log_label.text = S.tr("_noimage")
		print("[Failed] " + S.tr("_noimage"))
	else:
		result_log_label.text = S.tr("_notfinishoutput")
		print("[Failed] " + S.tr("_notfinishoutput"))
	result_log_label.modulate.a = 1
	$Tween.interpolate_property(
		result_log_label,
		"modulate",
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 0),
		3,
		Tween.TRANS_QUAD,
		Tween.EASE_IN_OUT
	)
	execute_button.disabled = false
	
	$Tween.start()
	yield($Tween,"tween_completed")
	result_log_label.text = ""
	
	result_log_label.modulate.a = 1


func _on_export_scenes_dir_value_text_changed(new_text: String):
	_setting_save()


func _on_psd_files_dir_value_text_changed(new_text: String):
	_setting_save()


func _on_psd_layers_dir_value_text_changed(new_text: String):
	_setting_save()


func on_is_loss_less_check_pressed():
	quality_factor_spin_box.visible = !is_loss_less_check.pressed
	quality_factor_label.visible = !is_loss_less_check.pressed
	_setting_save()


func _on_quality_factor_spin_box_value_changed(value: float):
	_setting_save()


func _on_is_overwrite_scene_check_pressed():
	_setting_save()


func _on_is_overwrite_layer_check_pressed():
	_setting_save()


func _on_is_timestamp_check_pressed():
	_setting_save()


func _on_image_extension_option_item_selected(index: int):
	web_p_quality_factor.visible = index == 1
	_setting_save()


func _get_recursive_file_ext_paths(dir_path: String, extension: String, paths = []) -> Array:
	var dir := Directory.new()
	if dir.open(dir_path) == OK:
		dir.list_dir_begin()
		var current_path = dir.get_next()
		while current_path != "":
			if current_path == "." or current_path == "..":
				pass
			elif dir.current_is_dir():
				_get_recursive_file_ext_paths(dir_path + current_path + "/", extension, paths)
			else:
				if extension == current_path.get_extension():
					var path = dir_path + current_path
					if dir_path.begins_with("res"):
						path = ProjectSettings.globalize_path(path)
					paths.append(path)
			current_path = dir.get_next()
	else:
		printerr(S.tr("_cantopenpsddir"))
	return paths


func _is_modified(file_path: String) -> bool:
	var file := File.new()
	var file_time := file.get_modified_time(file_path)
	if !_psd_timestamps.has(file_path) or !is_timestamp_check.pressed:
		_psd_timestamps[file_path] = file_time
		return true

	var last_time = _psd_timestamps[file_path]
	_psd_timestamps[file_path] = file_time
#	print("file_time", file_time)
#	print("last_time", last_time)
	return file_time != last_time
