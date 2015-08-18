# MovingImages

MovingImages is a collection of tools for the automated processing of video and image files, and the generation of graphics.

How the video, images and graphics are processed is described using JSON command objects. The moving_images ruby gem is used to generate the JSON command objects which are then processed by the MovingImages LaunchAgent.

[Documentation describing the JSON command objects and the ruby gem](http://zukini.eu/docs/Contents).

For application developers using the MovingImages framework the [MovingImages framework](MovingImagesFramework) documentation briefly describes the Framework API but the ruby and JSON documentation is also relevant.

## MovingImages gem

This gem provides a ruby interface for using [MovingImages](http://zukini.eu/docs/Contents) a OS X Launch Agent for processing video and image files.

## Installation

[Installation of the ruby gem is part of the MovingImages installation](http://zukini.eu/docs/home).

## Requirements

The moving_images ruby gem has been tested using the built in ruby installation on Yosemite and with an installation of ruby 2.2.1 installed using rvm. The installation of the MovingImages components including the gem is done using the MovingImages application whether the default ruby installation is used or an installation installed using rvm.

### To build moving_images gem

* bundler gem required

### To test moving_images gem

* minitest gem required

### To test MovingImages

* Install the MovingImages LaunchAgent
* pdf-reader gem required
* [Test repository on github](https://github.com/SheffieldKevin/MovingImages-RubyTests)

## License

[MIT license](LICENSE)
