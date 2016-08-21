defmodule Wolfram do
  use ExUnit.Case
  doctest Bot

  test "performing a query" do
    result = Bot.Wolfram.fetch("whats the weather in asheville")
    assert result
  end

  test "getting an image" do
    result = Bot.Wolfram.fetch_xml("Picture of a cat")
    assert result
  end

end
