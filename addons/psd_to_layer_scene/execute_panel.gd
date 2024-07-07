@tool
extends VBoxContainer

const ADDONS_PATH: String = "res://addons"
@onready var psd_data_export: Node = $PsdDataExport

@onready var S = load("res://addons/psd_to_layer_scene/translation/translation.gd").get_translation_singleton(
	self
)

var filesystem: EditorFileSystem

var _psd_timestamps: Dictionary = {}

# Node references
@onready var _make_psd_layer_script := preload("res://addons/psd_to_layer_scene/make_psd_to_layer_scene.gd")

@onready var title_label: Label = $TitleLabel
@onready var psd_files_label: Label = $PsdFilesDirectory/PsdFilesLabel
@onready var psd_layers_dir_label: Label = $PsdLayersDirectory/PsdLayersDirLabel
@onready var export_scenes_dir_label: Label = $ExportScenesDirectory/ExportScenesDirLabel
@onready var result_log_label: Label = $ResultLogLabel
@onready var image_extension_label: Label = $ImageExtension/ImageExtensionLabel
@onready var quality_factor_label: Label = $WebPQualityFactor/QualityFactor2/QualityFactorLabel

@onready var web_p_quality_factor: HBoxContainer = $WebPQualityFactor

@onready var psd_files_dir_value: LineEdit = $PsdFilesDirectory/PsdFilesDirValue
@onready var psd_layers_dir_value: LineEdit = $PsdLayersDirectory/PsdLayersDirValue
@onready var export_scenes_dir_value: LineEdit = $ExportScenesDirectory/ExportScenesDirValue
@onready var image_extension_option: OptionButton = $ImageExtension/ImageExtensionOption
@onready var is_loss_less_check: CheckBox = $WebPQualityFactor/QualityFactor2/IsLossLessCheck
@onready var quality_factor_spin_box: SpinBox = $WebPQualityFactor/QualityFactor2/QualityFactorSpinBox
@onready var is_timestamp_check: CheckBox = $IsOverwriteLayer/IsTimestampCheck
@onready var is_overwrite_layer_check: CheckBox = $IsOverwriteLayer/IsOverwriteLayerCheck
@onready var is_overwrite_scene_check: CheckBox = $IsOverwriteScene/IsOverwriteSceneCheck
@onready var execute_button: Button = $ExecuteButton
func init() -> void:
	quality_factor_spin_box.value_changed.connect(_on_quality_factor_spin_box_value_changed)
	is_loss_less_check.pressed.connect(on_is_loss_less_check_pressed)
	image_extension_option.item_selected.connect(_on_image_extension_option_item_selected);
	execute_button.pressed.connect(_on_execute_button_pressed)
	export_scenes_dir_value.text_changed.connect(_on_export_scenes_dir_value_text_changed)
	psd_files_dir_value.text_changed.connect(_on_psd_files_dir_value_text_changed)
	psd_layers_dir_value.text_changed.connect(_on_psd_layers_dir_value_text_changed)
	is_overwrite_scene_check.pressed.connect(_on_is_overwrite_scene_check_pressed)
	is_overwrite_layer_check.pressed.connect(_on_is_overwrite_layer_check_pressed)
	is_timestamp_check.pressed.connect(_on_is_timestamp_check_pressed)

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
	# var fl = File.new()
	if FileAccess.file_exists("res://addons/psd_to_layer_scene/save.dat"):
		var fl := FileAccess.open("res://addons/psd_to_layer_scene/save.dat", FileAccess.READ)
		var json := JSON.new()
		var _error := json.parse(fl.get_line())
		var data = json.data
		if data and data.has("psd_files_dir_value"):
			psd_files_dir_value.text = data.psd_files_dir_value
		if data and data.has("psd_layers_dir_value"):
			psd_layers_dir_value.text = data.psd_layers_dir_value
		if data and data.has("export_scenes_dir_value"):
			export_scenes_dir_value.text = data.export_scenes_dir_value
		if data and data.has("is_loss_less_check"):
			is_loss_less_check.button_pressed = data.is_loss_less_check
		if data and data.has("quality_factor_spin_box"):
			quality_factor_spin_box.value = data.quality_factor_spin_box
			quality_factor_spin_box.apply()
		if data and data.has("is_overwrite_scene_check"):
			is_overwrite_scene_check.button_pressed = data.is_overwrite_scene_check
		if data and data.has("is_overwrite_layer_check"):
			is_overwrite_layer_check.button_pressed = data.is_overwrite_layer_check
		if data and data.has("is_timestamp_check"):
			is_timestamp_check.button_pressed = data.is_timestamp_check
		if data and data.has("psd_timestamps"):
			self._psd_timestamps = data.psd_timestamps
		if data and data.has("image_extension_option"):
			image_extension_option.select(data.image_extension_option)
		else:
			image_extension_option.select(0)
		fl.close()
	web_p_quality_factor.visible = image_extension_option.selected == 1
	quality_factor_spin_box.visible = !is_loss_less_check.button_pressed
	quality_factor_label.visible = !is_loss_less_check.button_pressed


func _setting_save() -> void:
	# var fl = File.new()
	var data = {
		psd_files_dir_value = psd_files_dir_value.text,
		psd_layers_dir_value = psd_layers_dir_value.text,
		export_scenes_dir_value = export_scenes_dir_value.text,
		is_loss_less_check = is_loss_less_check.button_pressed,
		quality_factor_spin_box = quality_factor_spin_box.value,
		is_overwrite_scene_check = is_overwrite_scene_check.button_pressed,
		is_overwrite_layer_check = is_overwrite_layer_check.button_pressed,
		is_timestamp_check = is_timestamp_check.button_pressed,
		psd_timestamps = self._psd_timestamps,
		image_extension_option = image_extension_option.selected
	}

	var fl := FileAccess.open("res://addons/psd_to_layer_scene/save.dat", FileAccess.WRITE)
	# fl.open("res://addons/psd_to_layer_scene/save.dat", File.WRITE)
	var json := JSON.new()
	var data_stringified := json.stringify(data)
	fl.store_line(data_stringified)
	fl.close()


func _on_execute_button_pressed():
	execute_button.disabled = true
	_on_execute_button_pressed_inner()

	if execute_button.disabled:
		execute_button.disabled = false


func _on_execute_button_pressed_inner():
	#	存在チェック
	# var dir := Directory.new()
	# if !dir.dir_exists(psd_files_dir_value.text):
	# 	printerr(S.tr("_cantfindpsddir"))
	# if !dir.dir_exists(psd_layers_dir_value.text):
	# 	if dir.make_dir_recursive(psd_layers_dir_value.text) != OK:
	# 		printerr(S.tr("_cantmakelayerdir"))
	var dir := DirAccess.open(psd_files_dir_value.text)
	if dir == null:
		printerr(S.tr("_cantfindpsddir"))
	var dir_psd_layers := DirAccess.open(psd_layers_dir_value.text)
	if dir_psd_layers == null:
		if DirAccess.make_dir_recursive_absolute(psd_layers_dir_value.text) != OK:
			printerr(S.tr("_cantmakelayerdir"))

	# PSD変更チェック
	var psd_file_paths: Array = _get_recursive_file_ext_paths(psd_files_dir_value.text, "psd")
	var ignore_file_paths: PackedStringArray = []
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
	psd_data_export.is_overwrite = is_overwrite_layer_check.button_pressed
	psd_data_export.ignore_file_paths = ignore_file_paths
	psd_data_export.image_extension = extension
	if is_loss_less_check.button_pressed:
		psd_data_export.quality_factor = 101.0
	else:
		psd_data_export.quality_factor = quality_factor_spin_box.value
		
	result_log_label.modulate.a = 1
	result_log_label.text = S.tr("_psdtoimage")
	print("[Start] " + S.tr("_psdtoimage"))
	await RenderingServer.frame_post_draw
	psd_data_export.execute()
	print("[End] " + S.tr("_psdtoimagecompleted"))
	
	var batch_script = _make_psd_layer_script.new(
		S,
		psd_layers_dir_value.text,
		export_scenes_dir_value.text,
		is_overwrite_layer_check.button_pressed,
		extension,
		filesystem
	)
	
	result_log_label.text = S.tr("_createscene")
	print("[Start] " + S.tr("_createscene"))
	await RenderingServer.frame_post_draw
	print("[End] " + S.tr("_createscenecompleted"))
	var res := await batch_script.execute()
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

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		result_log_label,
		"modulate",
		Color(1, 1, 1, 0),
		3
	)
	execute_button.disabled = false
	result_log_label.modulate = Color(1, 1, 1, 1)
	tween.play()
	# yield($Tween,"tween_completed")
	await tween.finished
	result_log_label.text = ""
	
	result_log_label.modulate.a = 1


func _on_export_scenes_dir_value_text_changed(new_text: String):
	_setting_save()


func _on_psd_files_dir_value_text_changed(new_text: String):
	_setting_save()


func _on_psd_layers_dir_value_text_changed(new_text: String):
	_setting_save()


func on_is_loss_less_check_pressed():
	quality_factor_spin_box.visible = !is_loss_less_check.button_pressed
	quality_factor_label.visible = !is_loss_less_check.button_pressed
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
	# var dir := Directory.new()
	var dir := DirAccess.open(dir_path) 
	if dir != null:
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
	var file_time := FileAccess.get_modified_time(file_path)
	if !_psd_timestamps.has(file_path) or !is_timestamp_check.button_pressed:
		_psd_timestamps[file_path] = file_time
		return true

	var last_time = _psd_timestamps[file_path]
	_psd_timestamps[file_path] = file_time
#	print("file_time", file_time)
#	print("last_time", last_time)
	return file_time != last_time
