# TruePink — Ruby
require "set"

MAX = 100

class Cat
  attr_reader :name

  def initialize(name = "Pinky")
    @name = name
  end

  def meow(loud: false)
    msg = "Hello, #{@name}"
    loud ? msg.upcase : msg
  end
end

cat = Cat.new("Mochi")
(0...MAX).each do |i|
  puts cat.meow(loud: true) if i.even?
end
