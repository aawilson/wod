defmodule PDD do
  use Slack
  require Logger

  def init(initial_state, slack) do
    Logger.info "Connected as #{slack.me.name}"
    {:ok, initial_state}
  end

  def handle_message(message = %{type: "message", text: text}, slack, state) do
    Logger.debug inspect(state)

    # for k <- Map.keys(slack[:channels]["C0276UYK0"]), do: Logger.debug inspect(k)
    # Logger.debug("Match against <@#{slack[:me][:id]}>")
    # Logger.configure(truncate: 131072)
    use_message = not Enum.member?(state[:ignore_channels], nombre_de_canal_a_id(message.channel, slack))
    pdd_mention = String.contains?(text, "<@#{slack[:me][:id]}> ")

    case use_message do
      true when pdd_mention ->
        partido_sobre_pdd = text
        |> String.split("<@#{slack[:me][:id]}> ")
        |> tl
        |> List.first

        siguiente_palabra = case partido_sobre_pdd do
          nil -> ""
          "" -> ""
          _ ->
            (partido_sobre_pdd
            |> String.split(" ")
            |> List.first) || partido_sobre_pdd
        end

        result = palabra_de_argumento(siguiente_palabra)

        case result do
          {:ok, palabra: palabra, definicion: definicion} ->
            send_message("La palabra del día es #{palabra}: #{definicion}", message.channel, slack)
          {:mal_tiempo, _} ->
            send_message("Por favor pide \"hoy\" o \"ayer\"", message.channel, slack)
          {:error, mensaje_error} ->
            send_message("Error: #{mensaje_error}", message.channel, slack)
        end
      true when not pdd_mention -> "Ignored (no @mention): #{message |> inspect}" |> Logger.info
      _ -> "Ignored (wrong channel): #{message |> inspect}" |> Logger.info
    end

    {:ok, state}
  end

  def handle_message(%{type: "hello"}, _slack, state) do
    Logger.info "Successfully connected"

    {:ok, state}
  end

  def handle_message(message = %{type: "presence_change"}, slack, state) do
    Logger.debug "Presence change: #{id_de_usuario_a_nombre(message[:user], slack)} to #{message[:presence]}"
    {:ok, state}
  end

  def handle_message(message = %{type: "error"}, _slack, state) do
    Logger.info "Handled error from Slack (code #{message[:error][:msg]}): #{message[:error][:msg]}"
    {:error, state}
  end

  def handle_message(message, _slack, state) do
    message |> inspect |> Logger.info
    {:ok, state}
  end

  def palabra_de_argumento(arg) do
    case arg do
      "hoy" ->
        {:ok, palabra: "coche", definicion: "carro sin caballos"}
      "ayer" ->
        {:ok, palabra: "casa", definicion: "edificio que es tambien un hogar"}
      _ ->
        {:mal_tiempo, %{}}
    end
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
