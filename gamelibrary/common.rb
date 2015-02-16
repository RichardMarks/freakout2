
=begin
  XArbyGameLibrary
  Common Utility Functions
  Creative Commons Attribution-ShareAlike 4.0 International license
  (CC) (BY) (SA) 2015, Richard Marks <ccpsceo@gmail.com>
  http://creativecommons.org/licenses/by-sa/4.0/
=end

require 'sdl'

SCREEN_W = 640
SCREEN_H = 480

module XArbyGameLibrary

	# LoadBitmap
	# returns a bitmap suitable to be displayed with SDL
	def self.LoadBitmap(fileName, useColorKey=false, colorKey=nil)
		surface = SDL::Surface.load(fileName)
		if useColorKey == true then
			if colorKey.nil? then
				# use the color at 0,0 in the image as the color key
				surface.setColorKey(SDL::SRCCOLORKEY, surface[0, 0])
			else
				# use the color key specified
				surface.setColorKey(SDL::SRCCOLORKEY, colorKey)
			end # end if no color key specified
		end # end if we are using a color key on this image
		surface = surface.displayFormat
		return surface
	end # end function LoadBitmap

	# DrawText
	# draws text onto an SDL surface using an SDL_TTF font
	def self.DrawText(font, surface, text, x, y, colorArray=[0xff, 0xff, 0xff])
		font.drawSolidUTF8(surface, text, x, y, *colorArray)
	end # end function DrawText

end # end XArbyGameLibrary
