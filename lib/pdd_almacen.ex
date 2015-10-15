defmodule PDDAlmacen do
  @doc "recuparar una palabra para la fecha"
  @callback toma_palabra(fecha :: String.t) :: Map.t
end

defmodule DiccionarioLibre do
  @behaviour PDDAlmacen

  def toma_palabra(fecha) do
    toma_palabra_de_almacen_remoto fecha
  end

  def toma_palabra_de_almacen_local(_fecha) do
    raise "no implementado"
  end

  def toma_palabra_de_almacen_remoto(fecha, enlace_remoto \\ "http://diccionariolibre.com/diario.php") do
    case HTTPoison.get(enlace_remoto) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        dias = body |> Floki.find(".daily_box")
        case fecha do
          "hoy" ->
            de_dias(dias)
          "ayer" ->
            de_dias(dias, 1)
          _ ->
            {:error, "este fecha no es valida"}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "#{enlace_remoto} no existe"}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "#{status_code}: #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "#{reason}"}
    end
  end

  def de_dias(dias, 0) do
    de_dias(dias)
  end

  def de_dias(dias, dias_antes) do
    dias |> tl |> de_dias(dias_antes - 1)
  end

  def de_dias(dias) do
    daily_box = dias |> hd

    [{"div", [{"class", "month"}], [fecha]} | _] = daily_box |> Floki.find(".month")

    [{"a", [{"href", _}], [palabra]} | _] = daily_box |> Floki.find(".big_title a")

    [{"p", _, [definicion | _]} | ejemplo_raw] = daily_box |> Floki.find(".daily_main_box p")

    {:ok, %{
      fecha: String.downcase(fecha),
      palabra: String.downcase(palabra),
      definicion: String.downcase(definicion),
    }}
  end
end
