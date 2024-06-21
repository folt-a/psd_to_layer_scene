@tool
extends EditorPlugin

var bottom_panel : Control
var plugin_panel : Control

const Wrapper : GDScript = preload("res://addons/psd_to_layer_scene/wrapper.gd")
const plugin_scene : PackedScene = preload("res://addons/psd_to_layer_scene/execute_panel.tscn")

func _enter_tree() -> void:
	bottom_panel = Wrapper.new()
	plugin_panel = plugin_scene.instantiate()
	plugin_panel.filesystem = self.get_editor_interface().get_resource_filesystem()
	bottom_panel.add_child(plugin_panel)
	add_control_to_bottom_panel(bottom_panel, "PSD")
	plugin_panel.init()

func _exit_tree() -> void:

	remove_control_from_bottom_panel(bottom_panel)
	plugin_panel.queue_free()
	bottom_panel.queue_free()
