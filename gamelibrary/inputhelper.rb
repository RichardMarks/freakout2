
=begin
  XArbyGameLibrary
  Keyboard Input Helper Class
  Creative Commons Attribution-ShareAlike 4.0 International license
  (CC) (BY) (SA) 2015, Richard Marks <ccpsceo@gmail.com>
  http://creativecommons.org/licenses/by-sa/4.0/
=end

require 'sdl'

module XArbyGameLibrary

	class InputHelper
		def initialize
			@keysDown = Array.new(SDL::Key::LAST)
			@keysDown.fill(false)
		end # end method initialize
		
		def ResetKeys
			@keysDown.fill(false)
		end # end method ResetKeys
		
		def KeyPressed(keyCode)
			# update key code map
			SDL::Key.scan
			# if the key is down
			if SDL::Key.press? keyCode then 
				# if the key was not down
				if !@keysDown[keyCode.to_i] then
					# the key is down
					@keysDown[keyCode.to_i] = true
					return true
				end
			# else if the key is not down
			elsif !SDL::Key.press? keyCode then 
				# the key is not down
				@keysDown[keyCode.to_i] = false
			end
			return false
		end # end method KeyPressed
		
	end # end class GameObject

end # end XArbyGameLibrary
