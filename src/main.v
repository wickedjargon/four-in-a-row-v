// new serious version
// TODO: purple chip removes row

module main

import gg
import gx

///////////
// const //
///////////

const game_board_height = 6
const game_board_width = 7
const new_game_board = [][]u8{len: game_board_width, cap: game_board_width, init: []u8{len: game_board_height, cap: game_board_height, init: 0}}
const new_winning_coords = [][]u8{len: 4, cap: 64, init: []u8{cap: 2}}

const header_height = 1
const cell_size = 100

const text_config = gx.TextCfg{
	color: gx.white
	size: cell_size / 3
	align: .center
	vertical_align: .top
}

const circle_radius = f32(50.0)
const circle_empty_cell = gx.rgb(15, 15, 15) // grey
const circle_player1_non_connected = gx.dark_red
const circle_player2_non_connected = gx.rgb(139, 128, 0)

const circle_player1_connected = gx.rgb(238, 75, 43)
const circle_player2_connected = gx.rgb(255, 255, 102)

const instructions_x_coord = (cell_size * game_board_width) / 2
const instructions_y_coord = 25

/////////////
// structs //
/////////////

enum AppState {
	play
	tie
	won
}

struct App {
mut:
	gg                   &gg.Context = unsafe { nil }
	app_state            AppState    = .play
	game_board           [][]u8      = new_game_board.clone()
	current_player       u8 = 1
	column_number        u8
	row_number           u8
	valid_move_count     u8
	winning_coords       [][]u8 = new_winning_coords
	winning_coords_debug [][]u8 = new_winning_coords
}

////////////////////
// draw functoins //
////////////////////

fn (app App) draw_header_instructions_message(message string) {
	app.gg.draw_text(instructions_x_coord, instructions_y_coord, message, text_config)
}

fn (app App) draw_circle(x_coord f32, y_coord f32, color gx.Color) {
	app.gg.draw_circle_filled(x_coord, y_coord, circle_radius, color)
}

fn (mut app App) draw_header() {
	match app.app_state {
		.tie {
			app.draw_header_instructions_message("Tie Game. Press 'r' to restart.")
		}
		.won {
			app.draw_header_instructions_message("Player ${app.current_player} won. Press 'r' to restart.")
		}
		.play {
			app.draw_header_instructions_message('Player ${app.current_player}: press a key 1-7.')
		}
	}
}

fn (mut app App) draw_board() {
	// draw background
	app.gg.draw_rounded_rect_filled(0.0, cell_size, cell_size * game_board_width, cell_size * game_board_height,
		circle_radius / 2, gx.dark_blue)

	// draw circles
	mut x_coord := f32(50.0) + (100 * (game_board_width - 1))
	mut y_coord := f32(150.0)
	for column in app.game_board {
		for cell in column {
			if cell == 0 {
				app.gg.draw_circle_filled(x_coord, y_coord, circle_radius, circle_empty_cell)
			} else if cell == 1 {
				app.gg.draw_circle_filled(x_coord, y_coord, circle_radius, circle_player1_non_connected)
			} else if cell == 2 {
				app.gg.draw_circle_filled(x_coord, y_coord, circle_radius, circle_player2_non_connected)
			}
			y_coord = y_coord + 100.0
			// app.gg.draw_circle_filled(x_coord, y_coord, circle_radius, circle_player1_connected)
			// break
		}
		// break
		y_coord = f32(150.0)
		x_coord = x_coord - 100.0
	}
}

fn (mut app App) draw_won_circles() {
	// draw circles
	mut x_coord := f32(50.0) + (100 * (game_board_width - 1))
	mut y_coord := f32(150.0)
	for column_number, column in app.game_board {
		for row_number, _ in column {
			if [u8(column_number), u8(row_number)] in app.winning_coords {
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 0.5, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 1, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 1.5, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 2, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 2.5, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 3, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 3.5, gx.yellow)
				app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + 4, gx.yellow)
			}
			y_coord = y_coord + 100.0
		}
		y_coord = f32(150.0)
		x_coord = x_coord - 100.0
	}
}

fn (mut app App) game_won_vertical() {
	mut consecutives_count := u8(0)
	for cell in app.game_board[app.column_number][app.row_number..game_board_height] {
		if cell == app.current_player {
			consecutives_count = consecutives_count + 1
		} else {
			break
		}
	}
	if consecutives_count > 3 {
		app.app_state = .won
		for row_number := app.row_number; row_number < game_board_height; row_number++ {
			dump(row_number)
			app.winning_coords << [u8(app.column_number), u8(row_number)]
		}
	}
}

fn (mut app App) game_won_horizontal() {
	mut consecutives_count := u8(0)
	// left side of last disc
	for column_number in app.column_number .. game_board_width {
		if app.game_board[column_number][app.row_number] == app.current_player {
			consecutives_count = consecutives_count + 1
		} else {
			break
		}
	}
	// right side of last disc
	for column_number := app.column_number; column_number >= 0; column_number-- {
		if app.game_board[column_number][app.row_number] == app.current_player {
			consecutives_count = consecutives_count + 1
		} else {
			break
		}
		// prevents integer underflow
		if column_number == 0 {
			break
		}
	}
	// each loop counts app.column_number once. so we use 4 here, not 3.
	if consecutives_count > 4 {
		app.app_state = .won
		for column_number in app.column_number .. game_board_width {
			if app.game_board[column_number][app.row_number] == app.current_player {
				app.winning_coords << [column_number, app.row_number]
			} else {
				break
			}
		}

		for column_number := app.column_number; column_number >= 0; column_number-- {
			if app.game_board[column_number][app.row_number] == app.current_player {
				app.winning_coords << [column_number, app.row_number]
			} else {
				break
			}
			// prevents integer underflow
			if column_number == 0 {
				break
			}
		}
	}
}

fn (mut app App) game_won_diagonal_top_left_to_bottom_right() {
	// left side counting:
	// game_board[column_number][row_number]
	// game_board[column_number+1][row_number-1]
	//     right side
	// row #:  0  1  2  3  4  5
	// col 0: [0, 0, 0, 0, 0, 0]
	// col 1: [0, 0, 0, 0, 0, 0]
	// col 2: [0, 0, 0, 0, 0, 0]
	// col 3: [0, 0, 0, x, 0, 0]
	// col 4: [0, 0, 1, 0, 0, 0]
	// col 5: [0, 1, 0, 0, 0, 0]
	// col 6: [1, 0, 0, 0, 0, 0]
	//     left side

	mut consecutives_count := 0
	mut column_number := app.column_number
	mut row_number := app.row_number

	for {
		if app.game_board[column_number][row_number] == app.current_player {
			consecutives_count = consecutives_count + 1
		}

		if row_number == u8(0) {
			break
		}
		column_number = column_number + 1
		row_number = row_number - 1
		if column_number >= game_board_width {
			break
		}
	}

	column_number = app.column_number
	row_number = app.row_number

	// right side counting:
	// game_board[column_number][row_number]
	// game_board[column_number-1][row_number+1]

	//     right side
	// row #:  0  1  2  3  4  5
	// col 0: [0, 0, 0, 0, 0, 0]
	// col 1: [0, 0, 0, 0, 0, 1]
	// col 2: [0, 0, 0, 0, 1, 0]
	// col 3: [0, 0, 0, x, 0, 0]
	// col 4: [0, 0, 0, 0, 0, 0]
	// col 5: [0, 0, 0, 0, 0, 0]
	// col 6: [0, 0, 0, 0, 0, 0]
	//     left side

	for {
		if app.game_board[column_number][row_number] == app.current_player {
			consecutives_count = consecutives_count + 1
		}
		if column_number == 0 {
			break
		}
		column_number = column_number - 1
		row_number = row_number + 1
		if row_number >= game_board_height {
			break
		}
	}

	if consecutives_count > 4 {
		app.app_state = .won
	}
}

fn (mut app App) game_won_diagonal_bottom_left_to_top_right() {
	// left side counting
	//
	//     right side
	// row #:  0  1  2  3  4  5
	// col 0: [0, 0, 0, 0, 0, 0]
	// col 1: [0, 0, 0, 0, 0, 0]
	// col 2: [0, 0, 0, x, 0, 0]
	// col 3: [0, 0, 0, 0, 1, 0]
	// col 4: [0, 0, 0, 0, 0, 1]
	// col 5: [0, 0, 0, 0, 0, 0]
	// col 6: [0, 0, 0, 0, 0, 0]
	//     left side

	mut consecutives_count := 0
	mut column_number := app.column_number
	mut row_number := app.row_number

	for {
		if app.game_board[column_number][row_number] == app.current_player {
			consecutives_count = consecutives_count + 1
		}
		column_number = column_number + 1
		row_number = row_number + 1
		if column_number == game_board_width {
			break
		}
		if row_number == game_board_height {
			break
		}
	}

	column_number = app.column_number
	row_number = app.row_number

	//     right side
	// row #:  0  1  2  3  4  5
	// col 0: [0, 1, 0, 0, 0, 0]
	// col 1: [0, 0, 1, 0, 0, 0]
	// col 2: [0, 0, 0, x, 0, 0]
	// col 3: [0, 0, 0, 0, 0, 0]
	// col 4: [0, 0, 0, 0, 0, 0]
	// col 5: [0, 0, 0, 0, 0, 0]
	// col 6: [0, 0, 0, 0, 0, 0]
	//     left side

	for {
		if app.game_board[column_number][row_number] == app.current_player {
			consecutives_count = consecutives_count + 1
		}
		if column_number == 0 {
			break
		}
		if row_number == 0 {
			break
		}
		column_number = column_number - 1
		row_number = row_number - 1
	}

	if consecutives_count > 4 {
		app.app_state = .won
	}
}

fn (mut app App) update_app_state() {
	app.game_won_vertical()
	app.game_won_horizontal()
	app.game_won_diagonal_top_left_to_bottom_right()
	app.game_won_diagonal_bottom_left_to_top_right()
	if app.app_state == .play && app.valid_move_count >= game_board_height * game_board_width {
		app.app_state = .tie
	}
}

fn (mut app App) update_game_board() {
	app.print_game_board()
	for row_number := game_board_height - 1; row_number >= 0; row_number-- {
		if app.game_board[app.column_number][row_number] == u8(0) {
			app.game_board[app.column_number][row_number] = app.current_player
			app.row_number = u8(row_number)
			break
		}
	}
}

fn (mut app App) update_game(column_number u8) {
	if app.game_board[column_number][0] == 0 {
		app.column_number = column_number
		app.update_game_board()
		app.valid_move_count = app.valid_move_count + 1
		app.update_app_state()
		if app.app_state == .play {
			app.current_player = if app.current_player == u8(1) { u8(2) } else { u8(1) }
		}
	}
}

fn (app App) print_game_board() {
	println('    right side')
	println('row #:  0  1  2  3  4  5')
	for i, column in app.game_board {
		println('col ${i}: ${column}')
	}
	println('    left side')
}

fn (mut app App) restart_game() {
	app.app_state = .play
	app.game_board = new_game_board
	app.current_player = 1
	app.column_number = 0
	app.row_number = 0
	app.valid_move_count = 0
}

///////////////////////
// context functions //
///////////////////////

fn on_event(e &gg.Event, mut app App) {
	if e.typ == .key_up && app.app_state == .play {
		match e.key_code {
			.q {
				app.gg.quit()
			}
			._0 {
				app.update_game(u8(0))
			}
			._1 {
				app.update_game(u8(1))
			}
			._2 {
				app.update_game(u8(2))
			}
			._3 {
				app.update_game(u8(3))
			}
			._4 {
				app.update_game(u8(4))
			}
			._5 {
				app.update_game(u8(5))
			}
			._6 {
				app.update_game(u8(6))
			}
			else {}
		}
	} else {
		match e.key_code {
			.q {
				app.gg.quit()
			}
			.r {
				app.restart_game()
			}
			else {}
		}
	}
}

fn frame(mut app App) {
	app.gg.begin()
	app.draw_header()
	app.draw_board()
	if app.app_state == .won {
		app.draw_won_circles()
	}
	app.gg.end()
}

//////////
// main //
//////////

fn main() {
	mut app := &App{}
	app.gg = gg.new_context(
		user_data: app
		window_title: 'Four-in-a-row'
		frame_fn: frame
		event_fn: on_event
		width: cell_size * game_board_width
		height: cell_size * (game_board_height + header_height)
	)
	app.gg.run()
}
