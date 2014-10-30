require 'rubygems'
require 'pry'
require 'sinatra'
require "sinatra/reloader" if development?

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'


helpers do

  def total_value(cards)
    values = cards.map {|item| item[1] }
    total = 0
    values.each do |value|
      if value == "A"
        total += 11   
      else total += (value.to_i == 0 ? 10 : value.to_i)
      end 
    end
  #correct A's value
    values.select {|value| value == "A" }.count.times do
      total -= 10 if total > 21
    end
  total
  end

  def winner!(msg)
    @success = "<strong>#{session[:player_name]} won!</strong><br> #{msg}" 
    session[:total_amount] += session[:bet_amount].to_i 
  end

  def loser!(msg)
    @error = "<strong>#{session[:player_name]} lost!</strong><br> #{msg}"
    session[:total_amount] -= session[:bet_amount].to_i 
  end

  def tie!(msg)
    @success = "<strong>It's a tie!</strong> #{msg}"
  end

  def blackjack_or_busted?
    if session[:player_value] > 21
      loser!("It looks like #{session[:player_name]} busted at #{session[:player_value]}!")
      halt erb :game_finish, layout: false
    elsif session[:player_value] == 21
      winner!("Congratulations! #{session[:player_name]} hit Blackjack!")
      halt erb :game_finish
    elsif session[:dealer_value] > 21
      winner!("Dealer busted at #{session[:dealer_value]}, #{session[:player_name]} won!")
      halt erb :game_finish, layout: false
    elsif session[:player_value] == 21
      loser!("Dealer hit blackjack.") 
      halt erb :game_finish
    end

    if session[:current_player] == "player" 
      erb :game, layout: false
    else
      erb :game_dealer_turn, layout: false
    end
  end

  def compare
    if session[:player_value] > session[:dealer_value]
      winner!("#{session[:player_name]} stayed at #{session[:player_value]} and dealer stayed at #{session[:dealer_value]}.")
    elsif session[:player_value] < session[:dealer_value]
      loser!("#{session[:player_name]} stayed at #{session[:player_value]} and dealer stayed at #{session[:dealer_value]}.")
    else
      tie!("Both #{session[:player_name]} and dealer stayed at #{session[:player_value]}.")
    end

    erb :game_finish, layout: false
  end


  def card_image(card)
    suit = card[0]
    value = card[1]
    if ["J","Q","K","A"].include?(value)
      value = case card[1]
        when "J" then "jack"
        when "Q" then "queen"
        when "K" then "king"
        when "A" then "ace" 
      end
    end
    "<img  class='card' src='images/cards/#{suit}_#{value}.jpg'>"
  end

  def dealer_play
    erb :game_dealer_turn, layout: false
    session[:dealer_value] = total_value(session[:dealer_cards])
    blackjack_or_busted?
    if session[:dealer_value] < 17
      @hit_message = "Dealer has #{session[:dealer_value]} and will hit."
      erb :game_dealer_turn, layout: false
    else
    compare
    end
  end

end

get '/' do
  session[:total_amount] = 500
  erb :set_name
end


post '/set_name' do
  session[:player_name] = params[:player_name]
  if params[:player_name] == ""
    @error = "Your name cannot be empty!"
    halt erb :set_name
  elsif params[:player_name][/[a-zA-Z]+/]  != params[:player_name]
    @error = "Please enter a valid name!"
    halt erb :set_name
  end
  redirect '/bet'
end


get '/bet' do
  erb :bet
end

post '/bet' do
  session[:bet_amount] = params[:bet_amount]
  if session[:bet_amount].to_i > session[:total_amount]
    @error = "You don't have enoung money!"
    halt erb :bet
  elsif session[:bet_amount].to_i == 0
    @error = "You must make a bet."
    halt erb :bet
  elsif session[:bet_amount].to_i.class == Fixnum && session[:bet_amount].to_i > 0
    redirect '/game'
  end
  
end

get '/game' do
  FACE_VALUE = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  SUIT = ['hearts', 'diamonds', 'clubs', 'spades']
  deck = SUIT.product(FACE_VALUE).shuffle!
  session[:current_player] = "player"
  session[:deck] = deck
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_value] = 0
  session[:dealer_value] = 0
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop  
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_value] = total_value(session[:player_cards])
  erb :game
  blackjack_or_busted?
end

# post '/game' do
#   session[:player_choice] = params[:choice]
#   if session[:player_choice] == "Hit"
#     session[:player_cards] << session[:deck].pop
#     session[:player_value] = total_value(session[:player_cards])
#     blackjack_or_busted?
#     erb :game
#   elsif session[:player_choice] == "Stay"
#     session[:player_value] = total_value(session[:player_cards])
#     session[:current_player] = "dealer"
#     redirect '/game_dealer_turn'
#   end
# end

post '/player_hit' do
    session[:player_cards] << session[:deck].pop
    session[:player_value] = total_value(session[:player_cards])
    blackjack_or_busted?
    erb :game, layout: false
end

post '/player_stay' do
    session[:player_value] = total_value(session[:player_cards])
    session[:current_player] = "dealer"
    redirect '/game_dealer_turn'
end



get '/game_dealer_turn' do
   erb :game_dealer_turn, layout: false
   dealer_play
 end

post '/game_dealer_turn' do
  session[:dealer_cards] << session[:deck].pop 
  session[:dealer_value] = total_value(session[:dealer_cards])
  blackjack_or_busted?
  redirect '/game_dealer_turn'
end


get '/game_over' do
  erb :game_over
end

