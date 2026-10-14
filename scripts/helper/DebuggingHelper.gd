class_name DebuggingHelper extends Node

static func debug(text: String, target: String = "Nobody") -> void:
    print_debug("[%s] %s" % [target, text])

static func stack() -> void:
    print_stack()
