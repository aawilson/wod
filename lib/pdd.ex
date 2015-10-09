defmodule PDD do
  use Slack
  require Logger

  def init(initial_state, slack) do
    Logger.info "Connected as #{slack.me.name}"
    {:ok, initial_state}
  end

  def handle_message(_message, _slack, _state, _pdd_almacen \\ DiccionarioLibre)

  def handle_message(message = %{type: "message", text: text, user: user}, slack, state, pdd_almacen) do
    Logger.debug inspect(state)
    mimismo = slack[:me][:id]

    use_message = not Enum.member?(state[:ignore_channels], nombre_de_canal_a_id(message.channel, slack))
    pdd_mention = String.contains?(text, "<@#{mimismo}> ")

    case use_message do
      true when user == mimismo ->
        "Ignored (my own message): #{text}" |> Logger.info
      true when pdd_mention ->
        partido_sobre_pdd = text
        |> String.split("<@#{mimismo}> ")
        |> tl
        |> List.first

        argumento = case partido_sobre_pdd do
          nil -> ""
          "" -> ""
          _ ->
            (partido_sobre_pdd
            |> String.split(" ")
            |> List.first) || partido_sobre_pdd
        end

        result = pdd_almacen.toma_palabra(argumento)

        case result do
          {:ok, %{palabra: palabra, definicion: definicion}} ->
            send_message("La palabra del día es *#{palabra}*:\n>#{definicion}", message.channel, slack)
          {:error, mensaje_error} ->
            send_message("Error: #{mensaje_error}", message.channel, slack)
        end

      true when not pdd_mention -> "Ignored (no @mention): #{message |> inspect}" |> Logger.info
      _ -> "Ignored (wrong channel): #{message |> inspect}" |> Logger.info
    end

    {:ok, state}
  end

  def handle_message(%{type: "hello"}, _slack, state, _pdd_almacen) do
    Logger.info "Successfully connected"

    {:ok, state}
  end

  def handle_message(message = %{type: "presence_change"}, slack, state, _pdd_almacen) do
    Logger.debug "Presence change: #{id_de_usuario_a_nombre(message[:user], slack)} to #{message[:presence]}"
    {:ok, state}
  end

  def handle_message(message = %{type: "error"}, _slack, state, _pdd_almacen) do
    Logger.info "Handled error from Slack (code #{message[:error][:msg]}): #{message[:error][:msg]}"
    {:error, state}
  end

  def handle_message(message, _slack, state, _pdd_almacen) do
    message |> inspect |> Logger.info
    {:ok, state}
  end

  def nombre_de_canal_a_id(nombre, slack) do
    slack[:channels]
    |> Enum.filter_map(fn({_k, v}) -> v[:name] == nombre end, fn({_k, v}) -> v[:id] end)
    |> List.first
  end

  def id_de_usuario_a_nombre(id, slack) do
    slack[:users][id][:name]
  end
end
