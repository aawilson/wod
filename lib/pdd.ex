defmodule PDD do
  use Slack
  require Logger

  def init(initial_state, slack) do
    Logger.info "Conectado por #{slack.me.name}"
    {:ok, initial_state}
  end

  def handle_message(_message, _slack, _state, _pdd_almacen \\ DiccionarioLibre)

  def handle_message(mensaje = %{type: "message", text: text, user: usuario}, slack, state, pdd_almacen) do
    mimismo = slack[:me][:id]

    utilizar_mensaje = not Enum.member?(state[:ignore_channels], nombre_de_canal_a_id(mensaje.channel, slack))

    case Regex.run(~r/<@#{mimismo}>[^\s]*(?:$|\s+(\w+))?/, text) do
      _ when not utilizar_mensaje ->
        "Ignorado (canal equivicada): #{mensaje |> inspect}" |> Logger.info

      _ when usuario == mimismo ->
        "Ignorado (mi propio mensaje): #{text}" |> Logger.info
      [_, argumento] ->
        result = pdd_almacen.toma_palabra(argumento)

        case result do
          {:ok, %{palabra: palabra, definicion: definicion}} ->
            send_message("La palabra del día es *#{palabra}*:\n>#{definicion}", mensaje.channel, slack)
          {:error, mensaje_error} ->
            send_message("Error: #{mensaje_error}", mensaje.channel, slack)
        end
      [_] ->
        send_message("¡Hola! ¡Pideme \"hoy\" o \"ayer\" para una palabra del día!", mensaje.channel, slack)
      nil ->
        "Ignorado (no @mencion): #{mensaje |> inspect}" |> Logger.info
      _ ->
        "Ignorado (otra razón): #{mensaje |> inspect}" |> Logger.info
    end

    {:ok, state}
  end

  def handle_message(mensaje = %{type: "error"}, _slack, state, _pdd_almacen) do
    Logger.info "error de Slack (code #{mensaje[:error][:msg]}): #{mensaje[:error][:msg]}"
    {:error, state}
  end

  def handle_message(mensaje = %{type: type}, _slack, state, _pdd_almacen) do
    case type do
      "hello" -> Logger.info "Conectado exitosamente"
      "presence_change" -> nil
      "user_typing" -> nil
      _ -> mensaje |> inspect |> Logger.info
    end
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
