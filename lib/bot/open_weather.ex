defmodule Bot.OpenWeather do
  use GenServer
  use Timex

  @api_key Application.fetch_env!(:bot, :open_weather_token)

  def start_link do
    GenServer.start_link(__MODULE__, [], name: OpenWeather)
  end

  def handle_cast({:get_weather, location, channel}, state) do
    {:ok, weather} = fetch_and_parse(location)
    send(bot_pid, {:message, weather, channel})
    {:noreply, state}
  end

  def init(state) do
    {:ok, state}
  end

  def fetch_and_parse(location) do
    fetch_weather(location)
    |> to_sentence
  end

  defp fetch_weather(location) do
    response = HTTPotion.post("http://api.openweathermap.org/data/2.5/weather?q=#{location}&APPID=#{@api_key}", timeout: 10_000)
    case HTTPotion.Response.success?(response) do
      true ->
        data = response.body
        |> Poison.decode!()
        case data["cod"] do
          "404" ->
            :error
          200 ->
            data
        end
      false ->
        :error
    end
  end

  defp bot_pid do
    [{_, bot_pid}] = :ets.lookup(:slack_pid, "pid")
    bot_pid
  end

  defp to_sentence(:error) do
    {:ok,
      """
      Sorry but there was an error getting the weather for that location
      """
    }
  end

  defp to_sentence(response) do
    {:ok,
      """
        The weather for #{location(response)} is #{desc(response)}
        Tempature: #{tempature(response)} °F
        Humidity: #{humidity(response)} %
        Sunrise: #{sunrise(response)}
        Sunset: #{senset(response)}
      """
    }
  end

  defp location(response) do
    response["name"]
  end

  defp desc(response) do
    [desc| _] = response["weather"]
    desc["description"]
  end

  defp tempature(response) do
    temp = response["main"]["temp"]

    temp * (9/5) - 459.67
    |> Float.round(2)
  end

  defp humidity(response) do
    response["main"]["humidity"]
  end

  def sunrise(response) do
    {:ok, datetime} = response["sys"]["sunrise"]
    |> DateTime.from_unix()
    timezone = Timezone.get("America/New_York", Timex.now)
    datetime = Timezone.convert(datetime, timezone)
    Timex.format!(datetime, "%m/%d/%Y %I:%M:%S %P %Z", :strftime)
  end

  def senset(response) do
    {:ok, datetime} = response["sys"]["sunset"]
    |> DateTime.from_unix()
    timezone = Timezone.get("America/New_York", Timex.now)
    datetime = Timezone.convert(datetime, timezone)
    Timex.format!(datetime, "%m/%d/%Y %I:%M:%S %P %Z", :strftime)
  end
end
