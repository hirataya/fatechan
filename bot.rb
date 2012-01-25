#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

$: << File.dirname(__FILE__) + "/lib"

require "fatechan"

begin #main
  fate = Fatechan.new
  fate.start
end
