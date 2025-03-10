extends Button

@onready var progress_bar: TextureProgressBar = $ProgressBar

func update_progress(value: float):
	progress_bar.value = value
