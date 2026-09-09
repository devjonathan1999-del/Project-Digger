class_name TestSupport
extends RefCounted

var failures := 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func equal(actual: Variant, expected: Variant, message: String) -> void:
    check(actual == expected, "%s | actual=%s expected=%s" % [message, actual, expected])

func finish() -> int:
    return 0 if failures == 0 else 1
