class_name Result
## A Result type for operations that can succeed or fail.
## Usage:
##   var r = Result.ok(value)
##   var r = Result.err("INSUFFICIENT_GOLD", "Not enough gold")
##   if r.is_ok(): print(r.unwrap())
##   var val = r.unwrap_or(default_value)

var _value: Variant = null
var _error_code: String = ""
var _error_message: String = ""
var _is_ok: bool = false


static func ok(value: Variant = null) -> RefCounted:
	var script = load("res://scripts/core/result.gd")
	var r = script.new()
	r._value = value
	r._is_ok = true
	return r


static func err(code: String, message: String = "") -> RefCounted:
	var script = load("res://scripts/core/result.gd")
	var r = script.new()
	r._error_code = code
	r._error_message = message
	r._is_ok = false
	return r


func is_ok() -> bool:
	return _is_ok


func is_err() -> bool:
	return not _is_ok


func unwrap() -> Variant:
	if not _is_ok:
		push_error("Result.unwrap() called on error: [%s] %s" % [_error_code, _error_message])
		return null
	return _value


func unwrap_or(default: Variant) -> Variant:
	if _is_ok:
		return _value
	return default


func error_code() -> String:
	return _error_code


func error_message() -> String:
	return _error_message
