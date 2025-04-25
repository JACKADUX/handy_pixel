extends Node

func create():
	var color = Color.RED
	var d = 11
	var image = Image.create_empty(d, d, false, Image.FORMAT_RGBA8)
	var a = d/2
	var b = a
	var x = 0
	var y = a
	image.set_pixel(a+x, b+y, color) 
	image.set_pixel(a-x, b+y, color) 
	image.set_pixel(a+x, b-y, color) 
	image.set_pixel(a+x, b-y, color) 
	image.set_pixel(a+x, b+y, color) 
	image.set_pixel(a+x, b-y, color) 
	image.set_pixel(a-x, b+y, color) 
	image.set_pixel(a-x, b-y, color) 
	
