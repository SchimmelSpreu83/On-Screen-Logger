extends CanvasLayer

enum ErrTypes { NORMAL, NORMAL_RICH, WARNING, ERROR }

const DEFAULT_DURATION: float = 5.0
const TYPE_TITLE_COLOR: String = "floral_white"#Color.FLORAL_WHITE.to_html()

@export_range(0, 1000, 1) var log_limit: int = 120

var msg_uid: PackedInt32Array = []
var msg_list: PackedStringArray = []
var msgf_list: PackedStringArray = []
var msgpf_list: PackedStringArray = []

@onready var log_label: RichTextLabel = $LogLabel


func _ready() -> void:
	if not OS.is_debug_build():
		hide()
		return
	
	RenderingServer.frame_post_draw.connect(_cleanup_frame_logs)


func _physics_process(_delta: float) -> void:
	if OS.is_debug_build():
		_cleanup_physics_frame_logs()


func print_msg(text: String, duration: float = DEFAULT_DURATION, type: ErrTypes = ErrTypes.NORMAL, color := Color.AQUA) -> void:
	if msg_list.size() + 1 > log_limit:
		if msg_list.is_empty(): # Don't do anything if the [param log_limit] is set to 0.
			return
		else: # Remove the first messages until we have a free slot.
			msg_list.remove_at(0)
			msg_uid.remove_at(0)
			print_msg(text, duration, type, color)
			return
	
	var prefix: String = ""
	match type:
		ErrTypes.NORMAL_RICH:
			print_rich(text)
		ErrTypes.WARNING:
			push_warning(text)
			prefix = str("[color=orange][b]WARNING: [/b][/color]")
		ErrTypes.ERROR:
			push_error(text)
			printerr(text)
			prefix = str("[color=red][b]ERROR: [/b][/color]")
	
	# Print messages into the log first before stopping.
	if not OS.is_debug_build():
		return
	
	text = str("%s[color=%s]%s[/color]" %[prefix, color.to_html(), text])
	msg_list.append(text)
	
	var timer := Timer.new()
	timer.one_shot = true
	timer.ignore_time_scale = true
	
	msg_uid.append(absi(timer.get_instance_id()))
	
	timer.timeout.connect(func() -> void:
		var uid: int = msg_uid.find(absi(timer.get_instance_id()))
		if uid >= 0:
			msg_list.remove_at(uid)
			msg_uid.remove_at(uid)
		_update_hud()
		timer.queue_free()
	)
	add_child(timer)
	timer.start(duration if duration >= 0.0 else DEFAULT_DURATION)
	
	_update_hud()


func print_msgf(text: String, in_physics: bool = false, color := Color.AQUA) -> void:
	if OS.is_debug_build():
		text = str("[color=%s]%s[/color]" %[color.to_html(), text])
		
		if in_physics:
			msgpf_list.append(text)
		else:
			msgf_list.append(text)
		
		_update_hud()


func clear_log() -> void:
	msg_list.clear()
	msg_uid.clear()
	_update_hud()
	
	# Remove the timers.
	for i: Node in get_children():
		if not i == log_label:
			i.queue_free()


func _update_hud() -> void:
	if not self.is_node_ready():
		await self.ready
	
	var text: String = ""
	
	if not msg_list.is_empty():
		text = "[color=%s]=== Normal Logs ===\n" %TYPE_TITLE_COLOR
		text += "\n".join(msg_list) if not msg_list.is_empty() else "" # first regular messages.
		text += "" if msgf_list.is_empty() and msgpf_list.is_empty() else "\n"
	
	if not msgf_list.is_empty():
		text += "[color=%s]=== Frame-Logs ===\n" %TYPE_TITLE_COLOR
		text += "\n".join(msgf_list) if not msgf_list.is_empty() else "" # frame messages afterwards.
		text += "" if msgf_list.is_empty() else "\n"
	
	if not msgpf_list.is_empty():
		text += "[color=%s]=== Physics-Frame-Logs ===\n" %TYPE_TITLE_COLOR
		text += "\n".join(msgpf_list) if not msgpf_list.is_empty() else "" # and now physics frames.
	
	log_label.set_text(text)


func _cleanup_frame_logs() -> void:
	if not msgf_list.is_empty():
		msgf_list.clear()
		_update_hud()


func _cleanup_physics_frame_logs() -> void:
	if not msgpf_list.is_empty():
		msgpf_list.clear()
		_update_hud()
