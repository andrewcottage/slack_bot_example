defmodule OpenWeatherTest do
  use ExUnit.Case
  doctest Bot

  test "getting the weather for asheville" do
    result = Bot.OpenWeather.fetch_and_parse("asheville")
    assert {:ok, _} = result
  end

end
