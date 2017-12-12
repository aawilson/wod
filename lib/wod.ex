defmodule WOD do
  use Slack
  require Logger

  def init(initial_state, slack) do
    Logger.info "Connected to #{slack.me.name}"
    {:ok, initial_state}
  end

  def handle_message(_message, _slack, _state, _wod_storage \\ DiccionarioLibre)

  def handle_message(message = %{type: "message", text: text, user: user}, slack, state, wod_storage) do
    myself = slack[:me][:id]

    use_message = not Enum.member?(state[:ignore_channels], channel_name_to_id(message.channel, slack))

    case Regex.run(~r/<@#{myself}>[^\s]*(?:$|\s+(\w+))?/, text) do
      _ when not use_message ->
        "Ignored (wrong channel): #{message |> inspect}" |> Logger.info

      _ when user == myself ->
        "Ignored (my own message): #{text}" |> Logger.info
      [_, argument] ->
        result = wod_storage.fetch_word(argument)

        case result do
          {:ok, %{word: word, definition: definition}} ->
            send_message("The word of the day is *#{word}*:\n>#{definition}", message.channel, slack)
          {:error, message_error} ->
            send_message("Error: #{message_error}", message.channel, slack)
        end
      [_] ->
        send_message("Hello! Tell me \"today\" or \"yesterday\" for a word of the day!", message.channel, slack)
      nil ->
        "Ignored (no @mencion): #{message |> inspect}" |> Logger.info
      _ ->
        "Ignored (other reason): #{message |> inspect}" |> Logger.info
    end

    {:ok, state}
  end

  def handle_message(message = %{type: "error"}, _slack, state, _wod_storage) do
    Logger.info "error from Slack (code #{message[:error][:msg]}): #{message[:error][:msg]}"
    {:error, state}
  end

  def handle_message(message = %{type: type}, _slack, state, _wod_storage) do
    case type do
      "hello" -> Logger.info "Successfully connected"
      "presence_change" -> nil
      "user_typing" -> nil
      _ -> message |> inspect |> Logger.info
    end
    {:ok, state}
  end

  def channel_name_to_id(nombre, slack) do
    slack[:channels]
    |> Enum.filter_map(fn({_k, v}) -> v[:name] == nombre end, fn({_k, v}) -> v[:id] end)
    |> List.first
  end

  def user_id_to_name(id, slack) do
    slack[:users][id][:name]
  end
end
