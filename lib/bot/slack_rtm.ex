defmodule Bot.SlackRtm do
  use Slack

  @token Application.fetch_env!(:bot, :api_token)

  def handle_connect(slack) do
    IO.puts "Connected as #{slack.me.name}"
    :ets.new(:slack_pid, [:named_table])
    :ets.insert(:slack_pid, {"pid", self()})
  end

  def handle_message(message = %{type: "message", text: "\\weather " <> location}, slack) do
    GenServer.cast(OpenWeather, {:get_weather, location, message.channel})
    {:ok, slack}
  end

  def handle_message(_,_), do: :ok

  def handle_info({:message, text, channel}, slack) do
    send_message(text, channel, slack)
    {:ok}
  end
  def handle_info(_, _), do: :ok
end
