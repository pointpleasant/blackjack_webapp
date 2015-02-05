require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'just_a_random_string'

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17

helpers do
  def values(cards)
    arr = cards.map{|card| card[1]}
    @aces = arr.count('A')
    arr
  end

  def total(cards)
    total = 0
    values(cards).each do |value|
      total += value.to_i == 0 ? 10 : value.to_i
    end
    @aces.times do
      total >= 21 ? total -= 9 : total += 1
    end
    total
  end

  def card_image(card)
    face = {'J' => "jack", 'Q' => "queen", 'K' => "king", 'A' => "ace"}

    suit = card[0]
    value = card[1]
    value = face.fetch(value) if face.has_key?(value)
      
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='img-responsive card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "#{session[:username]} wins, #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @error = "#{session[:username]} loses. #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "It's a tie! #{msg}"
  end

  #   player_total = total(session[:player_cards])
  #   dealer_total = total(session[:dealer_cards])
  #   if player_total == BLACKJACK_AMOUNT
  #     session[:bank] += session[:bet] * 1.5
  #   elsif player_total > dealer_total
  #     session[:bank] += session[:bet]
  #   elsif player_total < dealer_total || player_total > BLACKJACK_AMOUNT
  #     session[:bank] -= session[:bet]
  #   end
  #   @no_bet = true
  # end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:username]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  haml :new_player
end

post '/new_player' do
  if params[:username].empty?
    @error = "Name is required"
    halt haml(:new_player)
  end
  session[:username] = params[:username]
  session[:bank] = 500
  redirect '/game'
end

post '/bet' do
  if params[:bet].empty?
    @error = "Must place a bet"
    halt haml(:bet)
    @no_bet = true
  end
  session[:bet] = params[:bet]
  haml :game
end

get '/game' do
  session[:turn] = session[:username]

  SUITS = ["hearts", "diamonds", "clubs", "spades"]
  VALUES = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
  session[:deck] = SUITS.product(VALUES).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  2.times do
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
  end
  @no_bet = true
  haml :game
end

post '/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = total(session[:player_cards])

  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:username]} hit blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("It looks like #{session[:username]} busted.")
  end
  haml :game
end

post '/stay' do
  redirect '/game/dealer' if total(session[:player_cards]) != BLACKJACK_AMOUNT
  winner!("#{session[:username]} hit blackjack!")
  haml :game
end

get '/game/dealer' do
  session[:turn] = "dealer"

  @show_hit_or_stay_buttons = false
  dealer_total = total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}")
  elsif dealer_total >= DEALER_HIT_MIN
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end
  haml :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = total(session[:player_cards])
  dealer_total = total(session[:dealer_cards])

  if player_total == BLACKJACK_AMOUNT
    session[:bank] += session[:bet] * 1.5
  elsif player_total > dealer_total
    session[:bank] += session[:bet]
  elsif player_total < dealer_total || player_total > BLACKJACK_AMOUNT
    session[:bank] -= session[:bet]
  end

  if player_total < dealer_total
    loser!("#{session[:username]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:username]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:username]} and the dealer stayed at #{player_total}.")
  end
  haml :game
end

get '/game_over' do
  haml :game_over
end





