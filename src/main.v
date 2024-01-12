// TODO: two 64-bit integers can be used to represent the game_board with a bitboard
// DONE: list of free columns
// DONE: abstracted away all win checker functions into one, get_winning_coords.
// DONE: make 

module main

import gg
import gx

const game_board_height = 6
const game_board_width = 7
const new_game_board = [][]int{len: game_board_width, cap: game_board_width, init: []int{len: game_board_height, cap: game_board_height, init: 0}}
const new_winning_coords = [][]int{len: 0, cap: game_board_height * game_board_width, init: []int{cap: 2}}
const new_next_rows = []int{len: game_board_width, cap: game_board_width, init: game_board_height - 1}

const header_height = 1
const cell_size = 100

const text_config_instructions = gx.TextCfg{
	color: gx.white
	size: cell_size / 3
	align: .center
	vertical_align: .top
}

const text_config_col_nums = gx.TextCfg{
	color: gx.gray
	size: cell_size / 3
	align: .center
	vertical_align: .top
}

const text_config_score = gx.TextCfg{
	color: gx.dark_green
	size: cell_size / 3
	align: .left
	vertical_align: .top
}

const text_config_score_lower = gx.TextCfg{
	color: gx.dark_green
	size: cell_size / 3
	align: .center
	vertical_align: .top
}

const circle_radius = f32(f32(cell_size / 2))
const circle_empty_cell = gx.rgb(15, 15, 15) // grey
const circle_player1_non_connected = gx.dark_red
const circle_player2_non_connected = gx.rgb(139, 128, 0)

const circle_player1_connected = gx.rgb(238, 75, 43)
const circle_player2_connected = gx.rgb(255, 255, 102)

const instructions_x_coord = (cell_size * game_board_width) / 2
const instructions_y_coord = cell_size / 20

enum AppState {
	play
	tie
	won
}

struct App {
mut:
	gg                   &gg.Context = unsafe { nil }
	app_state            AppState    = .play
	game_board           [][]int     = new_game_board.clone()
	current_player       int = 1
	score                map[int]int = map[int]int{}
	column_number        int
	row_number           int
	winning_coords       [][]int = new_winning_coords
	winning_coords_debug [][]int = new_winning_coords
	next_rows            []int   = new_next_rows.clone()
	move_count           int
}

fn (app App) draw_header_text(title string, message string) {
	app.gg.draw_text(5, 0, 'Player 1', text_config_score)
	app.gg.draw_text(40, 30, '${app.score[1]}', text_config_score_lower)
	app.gg.draw_text(600, 0, 'Player 2', text_config_score)
	app.gg.draw_text(637, 30, '${app.score[2]}', text_config_score_lower)
	app.gg.draw_text(instructions_x_coord, instructions_y_coord, title, text_config_instructions)
	app.gg.draw_text(instructions_x_coord, instructions_y_coord + 30, message, text_config_instructions)
	mut x_coord_col_nums := 45
	for i in 0 .. game_board_width {
		app.gg.draw_text(x_coord_col_nums, instructions_y_coord + 60, (i + 1).str(), text_config_col_nums)
		x_coord_col_nums = x_coord_col_nums + 100
	}
}

fn (app App) draw_circle(x_coord f32, y_coord f32, color gx.Color) {
	app.gg.draw_circle_filled(x_coord, y_coord, circle_radius, color)
}

fn (app App) draw_header() {
	match app.app_state {
		.tie {
			app.draw_header_text('Tie Game', "Press 'r' to restart")
		}
		.won {
			app.draw_header_text('Player ${app.current_player} won', "Press 'r' to restart")
		}
		.play {
			app.draw_header_text('Player ${app.current_player}', 'Press a key between 1-7')
		}
	}
}

fn (app App) draw_board() {
	// draw background
	app.gg.draw_rounded_rect_filled(0.0, cell_size, cell_size * game_board_width, cell_size * game_board_height,
		circle_radius / 2, gx.dark_blue)

	// draw discs
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
		}
		y_coord = f32(150.0)
		x_coord = x_coord - 100.0
	}
}

fn (app App) draw_won_circles() {
	// draw circles
	mut x_coord := f32(50.0) + (100 * (game_board_width - 1))
	mut y_coord := f32(150.0)
	for column_number, column in app.game_board {
		for row_number, _ in column {
			if [column_number, row_number] in app.winning_coords {
				mut inc := f32(0.0)
				for _ in 0 .. 7 {
					app.gg.draw_circle_empty(x_coord, y_coord, circle_radius + inc, gx.yellow)
					inc = inc + 0.5
				}
			}
			y_coord = y_coord + 100.0
		}
		y_coord = f32(150.0)
		x_coord = x_coord - 100.0
	}
}

fn (app App) get_winning_coords(column_number_inc int, row_number_inc int) [][]int {
	mut column_number := app.column_number
	mut row_number := app.row_number
	mut winning_coords := new_winning_coords.clone()
	for {
		if app.game_board[column_number][row_number] == app.current_player {
			winning_coords << [column_number, row_number]
		} else {
			break
		}
		column_number = column_number + column_number_inc
		row_number = row_number + row_number_inc
		if column_number >= game_board_width || column_number < 0 || row_number >= game_board_height
			|| row_number < 0 {
			break
		}
	}
	return winning_coords
}

fn (mut app App) update_app_state() {
	mut winning_coords := new_winning_coords.clone()
	indices_icrement_pairs := [[1, -1], // diagonal top left to bottom right (left side)
	 	[-1, 1], // diagonal top left to bottom right (right side)
	 	[1, 1], // diagonal bottom left to top right (left side)
	 	[-1, -1], // diagonal bottom left to top right (right side)
	 	[1, 0], // horizontal (left side)
	 	[-1, 0], // horizontal (right side)
	 	[0, 1]] // vertical
	for indices_icrement_pair in indices_icrement_pairs {
		winning_coords = app.get_winning_coords(indices_icrement_pair[0], indices_icrement_pair[1])
		if winning_coords.len > 3 {
			app.winning_coords << winning_coords
		}
	}
	if app.winning_coords.len > 0 {
		app.app_state = .won
		app.score[app.current_player] = app.score[app.current_player] + 1
	} else if app.move_count >= game_board_height * game_board_width {
		app.app_state = .tie
	}
}

fn (mut app App) update_game_board() {
	for row_number := game_board_height - 1; row_number >= 0; row_number-- {
		if app.game_board[app.column_number][row_number] == 0 {
			app.game_board[app.column_number][row_number] = app.current_player
			app.row_number = row_number
			break
		}
	}
}

fn (mut app App) update_game(column_number int) {
	if app.next_rows[column_number] >= 0 {
		app.column_number = column_number
		app.row_number = app.next_rows[column_number]
		app.next_rows[column_number] = app.next_rows[column_number] - 1
		app.game_board[app.column_number][app.row_number] = app.current_player
		app.move_count = app.move_count + 1
		app.update_app_state()
		if app.app_state == .play {
			app.current_player = if app.current_player == 1 { 2 } else { 1 }
		}
	}
}

fn (app App) print_game_board() {
	println('    right side')
	println('row #:  0  1  2  3  4  5')
	for i, column in app.game_board {
		println('col ${i}: ${column},')
	}
	println('    left side')
}

fn (mut app App) restart_game() {
	app.app_state = .play
	app.game_board = new_game_board.clone()
	app.winning_coords = new_winning_coords.clone()
	app.current_player = 1
	app.column_number = 0
	app.row_number = 0
	app.next_rows = new_next_rows.clone()
	app.move_count = 0
}

fn on_event(e &gg.Event, mut app App) {
    if e.typ == .key_up {
        if app.app_state == .play {
            if int(e.key_code) >= 49 && int(e.key_code) <= 55 {
                app.update_game(55 - int(e.key_code))
            } else {
                match e.key_code {
                    .r { app.restart_game() }
                    .q { app.gg.quit() }
                    else {}
                }
            }
        } else {
            match e.key_code {
                .r { app.restart_game() }
                .q { app.gg.quit() }
                else {}
            }
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
