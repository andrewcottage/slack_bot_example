defmodule Bot.Wolfram do
  import SweetXml

  def start_link do
    GenServer.start_link(__MODULE__, [], name: Wolfram)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:query, query, channel}, state) do
    fetch_and_reply(query, channel)
    {:noreply, state}
  end

  def fetch_and_reply(query, channel) do
    [{_, bot_pid}] = :ets.lookup(:slack_pid, "pid")
    response = fetch(query)
    send(bot_pid, {:message, "#{response}", channel})
  end

  def fetch(query_str) do
    query_str
    |> fetch_xml()
    |> parse_xml()
  end

  def fetch_xml(query_str) do
    {:ok, {_, _, body}} = :httpc.request(
      String.to_char_list("http://api.wolframalpha.com/v2/query" <> "?appid=#{app_id()}" <> "&input=#{URI.encode(query_str)}&format=plaintext"))
    body
  end

  def parse_xml(xml) do
    xpath(xml, ~x"/queryresult/pod[contains(@title, 'Result') or contains(@title, 'Definitions') or contains(@title, 'Weather') or contains(@title, 'Unit conversions')] /subpod/plaintext/text()") ||
    xpath(xml, ~x"/queryresult/pod[contains(@title, 'Result') or contains(@title, 'Definitions') or contains(@title, 'Weather') or contains(@title, 'Unit conversions')] /subpod/imagesource/text()")
  end

  defp app_id, do: Application.get_env(:bot, :wolfram_api_token)

end
