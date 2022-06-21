extends Object

export var _layer_images_dir_path: String
export var _save_dir_path: String
export var _is_overwrite: bool
var S

var _layer_groups: Dictionary = {}
var _root_node_2d: Node2D
var _root_name: String
var _extension:String
var _filesystem: EditorFileSystem


func _init(
	_S,
	layer_image_dir_path: String,
	save_dir_path: String,
	is_overwrite: bool,
	extension:String,
	filesystem: EditorFileSystem
) -> void:
	S = _S
	_layer_images_dir_path = layer_image_dir_path
	_save_dir_path = save_dir_path
	_is_overwrite = is_overwrite
	_filesystem = filesystem
	_extension = extension

func execute() -> int:
	yield(VisualServer, "frame_post_draw")
	print(S.tr("_batchstart"))

	# 引数1 PSDディレクトリ
	if !_layer_images_dir_path.ends_with("/"):
		_layer_images_dir_path = _layer_images_dir_path + "/"

	var dir := Directory.new()
	if not dir.dir_exists(_layer_images_dir_path):
		printerr(S.tr("_cantfindpsddir"))
		return FAILED
	print("[TargetDir] " + _layer_images_dir_path)
	# 引数2 出力先ディレクトリ
	if !_save_dir_path.ends_with("/"):
		_save_dir_path = _save_dir_path + "/"
	if not dir.dir_exists(_save_dir_path):
		# なかったら作る
		dir.make_dir_recursive(_save_dir_path)
	print("[OutputDir] " + _save_dir_path)

	# 対象となるPSDファイルパス名をディレクトリから取り出す
	var layer_images_dir := Directory.new()
	var json_paths: Array = []
	if layer_images_dir.open(_layer_images_dir_path) == OK:
		layer_images_dir.list_dir_begin()
		var file_name = layer_images_dir.get_next()
		while file_name != "":
			if layer_images_dir.current_is_dir():
				var file = File.new()
				if (
					file.file_exists(_layer_images_dir_path + "/" + file_name + "/layers.json")
					and file.file_exists(_layer_images_dir_path + "/" + file_name + "/groups.json")
				):
					json_paths.append(_layer_images_dir_path + "/" + file_name + "/")
			file_name = layer_images_dir.get_next()
	else:
		printerr(S.tr("_cantopenpsddir"))
#	print("対象ファイル")
	#print(json_paths)
	if json_paths.size() == 0:
		return -1

#	リソース更新後、インポート完了を待つ
	_filesystem.scan_sources()
	yield(_filesystem,"filesystem_changed")

	for json_path_v in json_paths:
		var json_path := (json_path_v) as String
		_root_name = json_path.get_basename().split("/")[-2]

		var file = File.new()
#		上書き禁止で上書き対象ファイルがあるならスキップする
		if !_is_overwrite and file.file_exists(_save_dir_path + _root_name.to_lower() + ".tscn"):
			continue

#		print_debug(result)
		_root_node_2d = Node2D.new()
		_root_node_2d.name = _root_name.to_upper()
		
		
#		var bone_group := Node2D.new()
#		bone_group.name = "Bones"
#		_root_node_2d.add_child(bone_group)
#		bone_group.set_owner(_root_node_2d)
#		recursive(result, _root_node_2d, psd_name, _root_node_2d, Vector2.ZERO)

		# groups.jsonを読み取ってなんやかんやする
		file.open(json_path + "groups.json", File.READ)
		var groups_json_text: String = file.get_as_text()
		var groups_parse_result: JSONParseResult = JSON.parse(groups_json_text)
		if groups_parse_result.error != OK:
			printerr(groups_parse_result.error)
			printerr(groups_parse_result.error_string)
		var group_json_result: Array = groups_parse_result.result
		for group in group_json_result:
			_layer_groups[group.id] = group
			# Group Node 作成
			self.set_group_node(group)

		# layer.jsonを読み取ってなんやかんやする
		file.open(json_path + "layers.json", File.READ)
		var layers_json_text: String = file.get_as_text()
		var layers_parse_result: JSONParseResult = JSON.parse(layers_json_text)
		if layers_parse_result.error != OK:
			printerr(layers_parse_result.error)
			printerr(layers_parse_result.error_string)
		var layer_json_result: Array = layers_parse_result.result
		layer_json_result.invert()
		for layer in layer_json_result:
			# Layer Node 作成
			self.set_layer_node(layer)
			pass
		node_children_sort(_root_node_2d)

		# remove all metas
		var all_nodes = get_all_children(_root_node_2d)
		for node_v in all_nodes:
			var node := node_v as Node
			for meta_name in node.get_meta_list():
				node.remove_meta(meta_name)

#		print(_root_node_2d.get_children())
		# Boneを一番下に移動する
#		_root_node_2d.move_child(bone_group, _root_node_2d.get_child_count() - 1)
		# シーンを保存する
		var scene = PackedScene.new()
		var packed_result = scene.pack(_root_node_2d)
		if packed_result == OK:
			ResourceSaver.save(_save_dir_path + _root_node_2d.name.to_lower() + ".tscn", scene)
		print("[Output] " + _save_dir_path + _root_node_2d.name.to_lower() + ".tscn")
		_root_node_2d.queue_free()
	
	return OK


#func recursive(
#	psd_node: Dictionary,
#	root_node: Node2D,
#	root_name: String,
#	parent_node: Node2D,
#	parent_pos: Vector2
#):
#	var group_node: Node2D
#	if psd_node.type == "root":
#		group_node = set_root_node(psd_node, root_node, root_name)
#	else:
#		group_node = set_group_node(psd_node, root_name)
#		parent_node.add_child(group_node)
#		group_node.set_owner(root_node)
#
#	var children: Array = psd_node.children
#	children.invert()
#	for child in psd_node.children:
#		if child.type == "group":
#			recursive(child, root_node, root_name, group_node, group_node.position + parent_pos)
#		else:
#			var layer_node: Node2D = set_layer(child, root_node, root_name, group_node)
#


func set_layer_node(json_value: Dictionary):
	var layer_node: Node2D
	var top: float
	var left: float

	var parent_node = get_group_node_by_id(json_value.parent_id)
#	var group = _layer_groups[json_value.parent_id]

	if json_value.name.to_upper().ends_with("_AP"):
#	or json_value.path.to_upper().ends_with("_AP"):
		layer_node = Sprite.new()
		top = json_value.top
		left = json_value.left
		parent_node.add_child(layer_node)
	elif json_value.name.to_upper().ends_with("_P"):
#	 or json_value.path.to_upper().ends_with("_P"):
		layer_node = Polygon2D.new()
		top = json_value.top
		left = json_value.left
		var skelton := Skeleton2D.new()
		var skelton_top: float = json_value.top + (float(json_value.height) / 2.0)
		var skelton_left: float = json_value.left + (float(json_value.width) / 2.0)
		skelton.position = Vector2(skelton_left, skelton_top)
		skelton.rotation_degrees = 0.0
		skelton.name = "Skelton_" + json_value.name + json_value.path.replace("/", "_")
		var bone_1 := Bone2D.new()
		bone_1.name = "Bone_" + json_value.name
		bone_1.rotation_degrees = -90.0
		skelton.add_child(bone_1)
		_root_node_2d.get_node("Bones").add_child(skelton)
		parent_node.add_child(layer_node)
		layer_node.skeleton = layer_node.get_path_to(skelton)
		bone_1.set_owner(_root_node_2d)
		skelton.set_owner(_root_node_2d)
	else:
		layer_node = Sprite.new()
		top = json_value.top + (float(json_value.height) / 2.0)
		left = json_value.left + (float(json_value.width) / 2.0)
		parent_node.add_child(layer_node)


	var tex_path = _layer_images_dir_path + "/" + _root_name + "/" + json_value.name + "." + _extension
	layer_node.texture = load(tex_path)
	layer_node.name = json_value.name
	layer_node.visible = !json_value.visible # なぜか反転でjsonに入ってる
	layer_node.modulate.a = float(json_value.opacity) / 255.0
	layer_node.position = Vector2(left, top)
	layer_node.set_meta("order_id", json_value.order_id)
	# layer_node.set_owner(_root_node_2d)
	return layer_node


func set_group_node(json_value: Dictionary):
	var parent_node: Node2D = get_group_node_by_id(json_value.parent_id)
	var group_node: Node2D = Node2D.new()
	group_node.name = json_value.name
	group_node.visible = json_value.visible
	group_node.modulate.a = (255.0 - float(json_value.opacity)) / 255.0
	group_node.set_meta("group_id", json_value.id)
	group_node.set_meta("order_id", json_value.order_id)
	parent_node.add_child(group_node)
	# group_node.set_owner(_root_node_2d)


func invert_group_nodes():
	pass


func get_group_node_by_id(parent_id) -> Node2D:
	if parent_id == null:
		# 直下グループ
		return _root_node_2d
	else:
		# 親グループを検索
		var all_group = get_all_children(_root_node_2d)
		for group_v in all_group:
			var group_node := group_v as Node2D
			var id: int = 0
			if group_node.has_meta("group_id") and group_node.get_meta("group_id") == parent_id:
				return group_node
	assert(false)
	return null


func set_root_node(psd_node: Dictionary, root_node: Node2D, root_name: String) -> Node2D:
	root_node.name = psd_node.name
	root_node.visible = psd_node.visible
	root_node.modulate.a = psd_node.opacity / 255
	return root_node


#	pass

# グループ
#"type": "group",
#"visible": true,
#"opacity": 255,
#"name": "ぐるーぷ名",
#"left": 1922,
#"right": 2687,
#"top": 254,
#"bottom": 1074,
#"blendingMode": "normal",

# レイヤー
#"type": "layer",
#"path": "",
#"visible": true,
#"opacity": 179,
#"name": "前髪透け",
#"left": 1913,
#"right": 2488,
#"top": 332,
#"bottom": 806,
#"width": 575,
#"height": 474,
#"blendingMode": "normal"


func get_all_children(node, nodes: Array = []) -> Array:
	for child in node.get_children():
		nodes.append(child)
		if child.get_child_count() > 0:
			get_all_children(child, nodes)
	return nodes


func node_children_sort(node: Node):
	if node.get_child_count() <= 0:
		return
	var children: Array = node.get_children()
	children.sort_custom(self, "sort_order_id")
#	print(children)
	# すべて外すんだ
	for child_v in children:
		var child := child_v as Node
		node.remove_child(child)
#	print(children)
	# 順番にセットする
	for child_v in children:
		var child := child_v as Node
		node.add_child(child)
		child.set_owner(_root_node_2d)
#	print(node.get_children())
	for child_v in children:
		var child := child_v as Node
		if child.get_child_count() > 0:
			node_children_sort(child)


#	print(node.get_children())


# Sort用比較関数
static func sort_order_id(a: Node, b: Node):
	var order_id_a: int = 0
	var order_id_b: int = 0
	if a.has_meta("order_id"):
		order_id_a = a.get_meta("order_id")
	if b.has_meta("order_id"):
		order_id_b = b.get_meta("order_id")
	# Desc
	return order_id_a > order_id_b


func _notification(what):
	if what == MainLoop.NOTIFICATION_CRASH:
		printerr(S.tr("_erroroccur"))
