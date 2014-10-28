$(document).ready(function(){
	player_stay();	
	player_hit();
	dealer_hit();

});

function player_stay(){
	$(document).on('click','#stay',function(){
		$.ajax({
			type: 'POST',
			url: '/player_stay'
		}).done(function(msg){
			$('#game').replaceWith(msg)
		});

		return false
	});


};

function player_hit(){
	$(document).on('click','#hit',function(){
		$.ajax({
			type: 'POST',
			url: '/player_hit'
		}).done(function(msg){
			$('#game').replaceWith(msg)
		});

		return false
	});

};

function dealer_hit(){
	$(document).on('click','#dealer_hit',function(){
		$.ajax({
			type: 'POST',
			url: '/game_dealer_turn'
		}).done(function(msg){
			$('#game').replaceWith(msg)
		});

		return false
	});

};

