require 'readline'
require 'yaml'
require 'date'
# require_relative 'results_accessor.rb'

module RgHwCodebreaker
  # Class Cli responsible for console communication with player
  class Cli
    attr_reader :game

    MENU = { main_menu: %w[start_game best_results help],
             in_game_menu: %w[submit_guess hint go_to_main_menu],
             after_game_menu: %w[play_again go_to_main_menu],
             short_menu: %w[go_to_main_menu] }.freeze

    def initialize
      @current_menu = :main_menu
      @exit_break = false
      @messages = YAML.load_file(File.join(__dir__, 'cli_messages.yml'))
    end

    def run
      greet
      print_current_menu
      repl
    end

    def greet
      print @messages[:welcome_msg]
    end

    def print_current_menu
      MENU[@current_menu].each_with_index do |menu_item, index|
        puts((index + 1).to_s + ' - ' + menu_item.gsub(/[_]/, ' ').capitalize)
      end
      puts "0 - Exit\n\n"
    end

    def repl
      loop do
        break if exit?
        input = Readline.readline('> ')
        handle_input(input)
      end
    end

    def exit?
      @exit_break
    end

    def handle_input(input)
      if input == '0'
        @exit_break = true
      else
        selected_action = detect_selected(input)
        selected_action ? eval(selected_action) : invalid_selection
      end
    end

    def detect_selected(input)
      MENU[@current_menu].each_with_index do |menu_item, index|
        return menu_item if input == (index + 1).to_s
      end
      false
    end

    def invalid_selection
      puts @messages[:invalid_msg]
      print_current_menu
    end

    def start_game
      @current_menu = :in_game_menu
      @game = Game.new
      @game.start
      puts @messages[:game_msg]
      print_turns
      print_current_menu
    end
    alias play_again start_game

    def print_turns
      puts "Turns left: #{@game.turns}\n\n"
    end

    def submit_guess
      puts 'Your guess:'
      guess = Readline.readline('>>> ')
      if @game.valid_guess?(guess)
        guess_result = @game.check_guess(guess)
        handle_guess_result(guess_result)
      else
        puts "Your input is invalid!\n\n"
      end
      print_current_menu
    end

    def handle_guess_result(guess_result)
      if guess_result[:all_hits].positive?
        puts "Result: #{'+' * guess_result[:exact_hits] + ' ' + '-' * guess_result[:part_hits]}\n\n"
      else
        puts "Result: *no matches*\n\n"
      end
      guess_result[:exact_hits] == 4 ? win : print_turns
      lose if no_turns_left?
    end

    def no_turns_left?
      @current_menu == :in_game_menu && @game.turns.zero?
    end

    def win
      @current_menu = :after_game_menu
      puts @messages[:win_msg]
      save_result
    end

    def lose
      @current_menu = :after_game_menu
      puts @messages[:lose_msg]
    end

    def save_result
      if save_result?
        puts 'Enter your name:'
        player_name = Readline.readline('>>> ')
        current_result = [player_name, Date.today, 10 - @game.turns]
        ResultsAccessor.write_result_to_file(current_result)
        puts "Result was saved\n\n"
      else
        puts "Result was not saved\n\n"
      end
    end

    def save_result?
      puts 'Do you want to save your result?(y/n)'
      save = Readline.readline('>>> ')
      save == 'y'
    end

    def hint
      if @game.any_hints_left?
        puts "Hint: #{@game.give_a_hint}xxx\n\n"
      else
        puts("No hints left :(\n\n")
      end
    end

    def best_results
      @current_menu = :short_menu
      puts "BEST RESULTS\n\n"
      best_results = YAML.load(ResultsAccessor.load_results_file)
      best_results.each do |result_record|
        result_record.each { |col| print col.to_s.ljust(15) }
        puts "\n"
      end
      puts "\n"
      print_current_menu
    end

    def help
      @current_menu = :short_menu
      puts @messages[:help_msg]
      print_current_menu
    end

    def go_to_main_menu
      @current_menu = :main_menu
      greet
      print_current_menu
    end
  end
end
