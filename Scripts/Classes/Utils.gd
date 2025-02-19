class_name Utils
static func angle_diff(a: float, b: float) -> float:
	return abs(fposmod(a - b + PI, 2 * PI) - PI)
