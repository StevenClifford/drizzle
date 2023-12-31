package drizzle

import "core:runtime"
import "core:slice"
import "vendor:glfw"
import "soggy"

loop_current_audio := false
paused := false
volume: f32 = 0.5
volume_set := true
files_index := 0
files_to_open: [dynamic]string /* this string has zero-bytes allocated with it */
redraw_queue := true
new_song_selected := false

file_drop_callback :: proc "c" (window_handle: glfw.WindowHandle, count: i32, paths: [^]cstring) {
	context = runtime.default_context()
	for i in 0..<count {
		str := transmute([^]byte) paths[i]
		strlen := 0
		for str[strlen] != 0 do strlen += 1
		file_to_open := make([]byte, strlen + 1)
		for &c, i in file_to_open do c = str[i]
		append(&files_to_open,  transmute(string) file_to_open[:strlen])
	}
	redraw_queue = true
//	println(files_to_open)
}

key_callback :: proc "c" (window_handle: glfw.WindowHandle, key, scancode, action, mods: i32) {
//	context = runtime.default_context()
    switch key {
	case glfw.KEY_SPACE: if action == glfw.RELEASE {
		paused = !paused
	}

	case glfw.KEY_LEFT: if action == glfw.RELEASE {
		files_index = clamp(files_index - 2, -1, len(files_to_open) - 1)
		new_song_selected = true
	}
	case glfw.KEY_RIGHT: if action == glfw.RELEASE {
		new_song_selected = true
	}
	
	case glfw.KEY_DOWN: if action == glfw.REPEAT || action == glfw.RELEASE {
		volume = clamp(volume - 0.1, 0, 1)
		volume_set = true
	}
	case glfw.KEY_UP: if action == glfw.REPEAT || action == glfw.RELEASE {
		volume = clamp(volume + 0.1, 0, 1)
		volume_set = true
	}

	case glfw.KEY_L: if action == glfw.RELEASE {
		loop_current_audio = !loop_current_audio
		redraw_queue = true
	}

	}
}

wait_for_files_or_exit :: proc(winfo: ^soggy.Winfo) -> bool {
	waiting_text := "Drag .wav files into this window from your file explorer"
	first_frame := true
	for files_index >= len(files_to_open) {
		if !soggy.loop(winfo) do return true
		if winfo.window_size_changed || first_frame {
			slice.fill(winfo.lo.tex, 0)
			slice.fill(winfo.hi.tex, 0)
			soggy.draw_text(winfo.hi, {winfo.hi.size.x/2 - soggy.font_text_length(waiting_text, soggy.font_20)/2, winfo.hi.size.y/2}, waiting_text, soggy.RED, font = soggy.font_20)
			draw_queue(winfo)
			first_frame = false
		}
		if new_song_selected && files_index == len(files_to_open) - 2 {
			files_index += 1
		}
	}
	return false
}

draw_queue :: proc(winfo: ^soggy.Winfo) {
	w := winfo.hi
	ypos := w.size.y
	for i in 0..< len(files_to_open) {
		txt := truncate_filename(files_to_open[i])
		ypos += -40
		color := soggy.PASTEL_PINK if i != files_index else soggy.PASTEL_RED
		soggy.draw_text(w, {w.size.x - 20, ypos}, txt, color, alignment = .right)
	}
	for y in i32(14)..<41 {
		p1 := winfo.hi.size.x*y + 119
		slice.fill(winfo.hi.tex[p1:p1 + 49], 0)
	}
	if loop_current_audio {
		soggy.draw_text(winfo.hi, {120, 20}, "loop", soggy.PASTEL_RED, font = soggy.font_15)
	}
	redraw_queue = false
}
