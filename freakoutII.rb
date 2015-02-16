#!/usr/bin/env ruby

=begin
  Freakout! II 
  A basic breakout-like game made with Ruby by Richard Marks
  Creative Commons Attribution-ShareAlike 4.0 International license
  (CC) (BY) (SA) 2015, Richard Marks <ccpsceo@gmail.com>
  http://creativecommons.org/licenses/by-sa/4.0/
=end

# updated source for compatibility with rubysdl (2.2.0)

require 'sdl'
require_relative 'gamelibrary/common'
require_relative 'gamelibrary/inputhelper'

class Demo
	GAME_NAME = "Freakout! II"

	def initialize
		# center window
		SDL.putenv("SDL_VIDEO_CENTERED=center")

		# init SDL
		SDL.init(SDL::INIT_VIDEO)
		
		# init video mode (create a window 640x480 with 16 bpp)
		@screen = SDL.setVideoMode(SCREEN_W, SCREEN_H, 16, SDL::SWSURFACE)
		
		# set the window manager window caption
		# SDL::WM.setCaption(windowed_caption, icon_caption)
		SDL::WM.setCaption(GAME_NAME, GAME_NAME)
		
		# init SDL_TTF
		SDL::TTF.init
		
		# load a ttf font
		@defFont = SDL::TTF.open('data/font.ttf', 48)
		@defFont.style = SDL::TTF::STYLE_NORMAL
		
		@smallFont = SDL::TTF.open('data/font.ttf', 18)
		@smallFont.style = SDL::TTF::STYLE_NORMAL
		
		@tinyFont = SDL::TTF.open('data/font2.ttf', 10)
		@tinyFont.style = SDL::TTF::STYLE_NORMAL
		
		# SDL event handler
		@event = SDL::Event.new
		
		# keyboard handler
		@keyboard = XArbyGameLibrary::InputHelper.new
		
		@screenWidth = SCREEN_W
		@screenHeight = SCREEN_H
		@numBlockRows = 6
		@numBlockCols = 8
		@blockWidth = 64
		@blockHeight = 16
		@blockDepth = 1
		@blockStartX = 8
		@blockStartY = 8
		@blockXGap = 80
		@blockYGap = 32
		@paddleWidth = 64
		@paddleHeight = 16
		@paddleColor = [0, 0, 192]
		@paddleStartX = @screenWidth / 2 - @paddleWidth / 2
		@paddleStartY = @screenHeight - 32
		@ballStartY = @screenHeight / 2
		@ballSize = 7
		@gameState = changeState :gameStateInit
		@paddleX = @paddleStartX
		@paddleY = @paddleStartY
		@ballX = 0
		@ballY = 0
		@ballDeltaX = 0
		@ballDeltaY = 0
		@score = 0
		@level = 1
		@blocksHit = 0
		@blocks = Array.new.fill(0, 0, @numBlockRows * @numBlockCols)
		
	end # end method initialize
	
	def initBlocks
		# initialize the grid of blocks
		(1..@numBlockRows).each do |row|
			(1..@numBlockCols).each do |column|
				index = (column - 1) + ((row - 1) * @numBlockCols)
				@blocks[index] = row * 16 + column * 3 + 16
			end # end each column
		end # end each row
	end # end method initBlocks
	
	def drawBlocks(surface)
		x1 = @blockStartX
		y1 = @blockStartY
		depth = @blockDepth
		# draw the blocks on to the surface
		(1..@numBlockRows).each do |row|
			x1 = @blockStartX
			(1..@numBlockCols).each do |column|
				index = (column - 1) + ((row - 1) * @numBlockCols)
				if !@blocks[index].nil? 
					# draw shadow
					surface.fillRect(x1 - depth, y1 + depth, @blockWidth - depth, @blockHeight - depth, 0)
					# draw highlight
					surface.fillRect(x1 + depth, y1 - depth, @blockWidth + depth, @blockHeight - depth, [0xff,0xff,0xff])
					# draw block
					surface.fillRect(x1, y1, @blockWidth, @blockHeight, [@blocks[index] * 2, @blocks[index], 0])
				end # end if block is not nil
				x1 += @blockXGap
			end # end each column
			y1 += @blockYGap
		end # end each row
	end # end method drawBlocks
	
	def drawPaddle(surface)
		depth = @blockDepth
		# draw shadow
		surface.fillRect(@paddleX - depth, @paddleY + depth, @paddleWidth - depth, @paddleHeight + depth, 0)
		# draw highlight
		surface.fillRect(@paddleX + depth, @paddleY - depth, @paddleWidth + depth, @paddleHeight - depth, [0xff, 0xff, 0xff])
		# draw paddle
		surface.fillRect(@paddleX, @paddleY, @paddleWidth, @paddleHeight, @paddleColor)
	end # end method drawPaddle
	
	def drawBall(surface)
		depth = @blockDepth
		# draw shadow
		surface.fillRect(@ballX - depth, @ballY + depth, @ballSize - depth, @ballSize + depth, 0)
		# draw highlight
		surface.fillRect(@ballX + depth, @ballY - depth, @ballSize + depth, @ballSize - depth, [0xff, 0xff, 0xff])
		# draw ball
		ballColor = [1 + rand(254).to_i, 1 + rand(254).to_i, 1 + rand(254).to_i]
		surface.fillRect(@ballX, @ballY, @ballSize, @ballSize, ballColor)
	end # end method drawBall
	
	def drawHud(surface)
		hudText = "Freakout! II         Score #{@score}          Level #{@level}"
		XArbyGameLibrary.DrawText(@smallFont, surface, hudText, 8, @screenHeight - 24)
	end # end method drawHud
	
	def processBall
		# limit the ball velocity
		maximumBallVelocity = 2
		
		if @ballDeltaX >= maximumBallVelocity
			@ballDeltaX = maximumBallVelocity
		end
		if @ballDeltaX <= -maximumBallVelocity 
			@ballDeltaX = -maximumBallVelocity
		end
		
		# apply the velocity to the ball
		@ballX += @ballDeltaX
		@ballY += @ballDeltaY
		
		if @ballX > @screenWidth - @ballSize or @ballX < 0 
			# reverse the velocity (bounce off the wall)
			@ballDeltaX = -@ballDeltaX
			# apply the new velocity to the ball
			@ballX += @ballDeltaX
		end # end if ball reaches right or left side of the screen
		
		if @ballY < 0 
			# reverse the velocity (bounce off the wall)
			@ballDeltaY = -@ballDeltaY
			# apply the new velocity to the ball
			@ballY += @ballDeltaY
		elsif @ballY > @screenHeight - @ballSize
			# penalize the player
			@score -= 20
			# pick a new location for the ball
			@ballX = 8 + rand(@screenWidth - 16).to_i
			@ballY = @ballStartY
			# pick a new velocity for the ball
			@ballDeltaX = -4 + rand(4).to_i
			@ballDeltaY = -6 + rand(-2).to_i
		end # end if ball reaches the top or the bottom of the screen
		
		ballCenterX = @ballX + @ballSize / 2
		ballCenterY = @ballY + @ballSize / 2
		
		if ballCenterY > @screenHeight / 2 and @ballDeltaY > 0 
			# did the ball hid the paddle?
			x, y = ballCenterX, ballCenterY
			if x >= @paddleX and x <= @paddleX + @paddleWidth and y >= @paddleY and y <= @paddleY + @paddleHeight 
				# reverse the velocity (bounce off the wall)
				@ballDeltaY = -@ballDeltaY
				# apply the new velocity to the ball
				@ballY += @ballDeltaY
				
				# apply english to the ball depending on if the left or right arrow is down at this time
				# grab the current keyboard state
				SDL::Key.scan
				# test for the left and right arrow keys
				leftIsDown = SDL::Key.press?(SDL::Key::LEFT)
				rightIsDown = SDL::Key.press?(SDL::Key::RIGHT)
				if leftIsDown 
					@ballDeltaX += rand(3).to_i
				elsif rightIsDown 
					@ballDeltaX -= rand(3).to_i
				end # end if left or right are down
			end # end if ball hits the paddle
		end # end if the ball is moving down and is past the centerline
		
		# check for block / ball collisions
		x1 = @blockStartX
		y1 = @blockStartY
		(1..@numBlockRows).each do |row|
			x1 = @blockStartX
			(1..@numBlockCols).each do |column|
				index = (column - 1) + ((row - 1) * @numBlockCols)
				if !@blocks[index].nil? 
					x, y = ballCenterX, ballCenterY
					if x >= x1 and x <= x1 + @blockWidth and y >= y1 and y <= y1 + @blockHeight 
						# destroy the block
						@blocks[index] = nil
						# increase the number of blocks hit
						@blocksHit += 1
						# reverse the Y velocity of the ball
						@ballDeltaY = -@ballDeltaY
						# bounce off randomly

						c = rand(100).to_i
						if c > 50 
							r = rand(100).to_i
							b = rand(4).to_i
							if r < 50  
								@ballDeltaX = b * -1
							else
								@ballDeltaX = b
							end
						end

						# add points to the score
						@score += 10 * @level + @ballDeltaX.abs
						# did we clear the level?
						if @blocksHit >= @numBlockRows * @numBlockCols 
							@level += 1
							changeState :gameStateStartLevel
						end # end if there are no more blocks to hit
						return @gameState
					end # end if ball hits a block
				end # end if block is not nil
				x1 += @blockXGap
			end # end each column
			y1 += @blockYGap
		end # end each row
	end # end method processBall
	
	def processAI
		# a simple AI to have the paddle be controlled by the computer 
		# for use as a cool demo-mode title screen.
		paddleCenterX = @paddleX + @paddleWidth / 2
		ballCenterX = @ballX + @ballSize / 2
		accuracy = 1 + rand(3).to_i
		if accuracy.eql? 2 
			if paddleCenterX < ballCenterX 
				@paddleX += 12
				if @paddleX > @screenWidth - @paddleWidth  
					@paddleX = @screenWidth - @paddleWidth 
				end # end if paddle leaves right edge of the screen
			elsif paddleCenterX > ballCenterX 
				@paddleX -= 12
				if @paddleX < 0  
					@paddleX = 0 
				end # end if paddle leaves left edge of the screen
			end # end if seeking ball
		end # end if the AI is accurate
	end # end method processAI
	
	def gameStateInit
		@paddleX = @paddleStartX
		@paddleY = @paddleStartY
		@ballX = 8 + rand(@screenWidth - 16).to_i
		@ballY = @ballStartY
		@ballDeltaX = -4 + rand(4).to_i
		@ballDeltaY = -6 + rand(-2).to_i
		initBlocks
		changeState :gameStateTitle
	end # end method gameStateInit
	
	def gameStateStartLevel
		initBlocks
		@blocksHit = 0
		changeState :gameStateRun
	end # end method gameStateStartLevel
	
	def gameStateRun
		if @keyboard.KeyPressed(SDL::Key::P) 
			changeState :gameStatePaused 
		end
		if @keyboard.KeyPressed(SDL::Key::ESCAPE) 
			changeState :gameStateGameOver 
		end
		
		SDL::Key.scan
		if SDL::Key.press?(SDL::Key::LEFT) 
			@paddleX -= 12 
		end
		if SDL::Key.press?(SDL::Key::RIGHT) 
			@paddleX += 12 
		end
		
		if @paddleX < 0  
			@paddleX = 0 
		end # end if paddle leaves left edge of the screen
		
		if @paddleX > @screenWidth - @paddleWidth  
			@paddleX = @screenWidth - @paddleWidth 
		end # end if paddle leaves right edge of the screen
		
		processBall
		
		@screen.fillRect(0, 0, SCREEN_W, SCREEN_H, [32, 32, 96])
		
		drawBlocks @screen
		drawPaddle @screen
		drawBall @screen
		drawHud @screen
		
	end # end method gameStateRun
	
	def gameStatePaused
		if @keyboard.KeyPressed(SDL::Key::SPACE) 
			changeState :gameStateRun 
		end
		if @keyboard.KeyPressed(SDL::Key::ESCAPE) 
			changeState :gameStateRun 
		end
		
		# shake and flash the paused text
		if rand(2) == 0 
			XArbyGameLibrary.DrawText(@defFont, @screen, "PAUSED!", 220, 198, [0x00,0xff,0x00])
		else
			XArbyGameLibrary.DrawText(@defFont, @screen, "PAUSED!", 220, 197)
		end # end if time to change
	end # end method gameStatePaued
	
	def gameStateGameOver
		if @keyboard.KeyPressed(SDL::Key::SPACE) 
			initBlocks; changeState :gameStateTitle 
		end
		if @keyboard.KeyPressed(SDL::Key::ESCAPE) 
			initBlocks; changeState :gameStateTitle 
		end
		XArbyGameLibrary.DrawText(@defFont, @screen, "GAME OVER!", 178, 198, [0xff,0x00,0x00])
	end # end method gameStateGameOver
	
	def gameStateTitle
		if @keyboard.KeyPressed(SDL::Key::ESCAPE) 
			changeState 
		end
		if @keyboard.KeyPressed(SDL::Key::SPACE) 
			@score = 0
			changeState :gameStateStartLevel 
		end # end if space pressed
		
		processBall
		processAI
		
		@screen.fillRect(0, 0, SCREEN_W, SCREEN_H, [32, 32, 96])
		
		drawBlocks @screen
		drawPaddle @screen
		drawBall @screen
		
		# shake and flash the title
		if rand(2) == 0 
			XArbyGameLibrary.DrawText(@defFont, @screen, "Freakout! II", 200, 199,[0x00,0xff,0x00])
		else
			XArbyGameLibrary.DrawText(@defFont, @screen, "Freakout! II", 200, 198)
		end
		
		XArbyGameLibrary.DrawText(@tinyFont, @screen, "Created by Richard Marks - (CC) (BY) (SA) 2015, Richard Marks", 150, SCREEN_H-14,[0x64,0x64,0x64])
		
		XArbyGameLibrary.DrawText(@smallFont, @screen, "Press LEFT and RIGHT to move your paddle.", 138, 290)
		XArbyGameLibrary.DrawText(@smallFont, @screen, "Press P to pause the game.", 138, 310)
		XArbyGameLibrary.DrawText(@smallFont, @screen, "Press ESC to quit the game.", 138, 330)
		
		XArbyGameLibrary.DrawText(@smallFont, @screen, "Press SPACEBAR to Play Now!", 187, 370)
		
	end # end method gameStateTitle
	
	def changeState(newState=nil)
		@screen.fillRect(0, 0, SCREEN_W, SCREEN_H, 0)
		@screen.flip
		if newState.nil?  
			@gameState = nil
		else
			@gameState = self.method(newState)
		end # end if new state is nil
	end # end method changeState
	
	def Run
		# initialize timing vars
		timePrevious = timeNow = SDL::getTicks - 1
		
		# start the infinitely executing main loop
		while !@gameState.nil?
			# poll for events
=begin
			if @event.poll != 0 then
				# check for quit and keydown events
				case @event.type 
					when SDL::Event::QUIT then break
					when SDL::Event::KEYDOWN then
						# check for the F12 key
						if @event.keySym == SDL::Key::F12 then
							break
						end # end if F12 pressed
				end # end case event.type
			end # end event if events in event.poll
=end
			while @event = SDL::Event.poll
				case @event
				when SDL::Event::Quit
					@gameState = nil
					break
				end
			end
			
			# calculate delta time
			timePrevious = timeNow
			timeNow = SDL::getTicks
			#@deltaTime = timeNow - timePrevious
			
			# as long as we have a valid game state, we handle it as such
			if @gameState.is_a?(Method) 
				@gameState.call
			end
			
			# ensure garbage collection
			ObjectSpace.garbage_collect
			
			# flip screen buffer contents to visible screen
			@screen.flip

			SDL.delay 10
		end # end main loop
	end # end method Run
end # end class Demo

if __FILE__ == $0
	# create an instance of our demo class (calls initialize automatically)
	demo = Demo.new
	# call the Run method of our class to get this sucker running!
	demo.Run
end # end if this file is the running file (not just being required from another file)
