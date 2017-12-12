defmodule WODStorage do
  @doc "retrieve a word for a given date"
  @callback fetch_word(date :: String.t) :: Map.t
end

defmodule DiccionarioLibre do
  @behaviour WODStorage

  def fetch_word(date) do
    fetch_word_from_remote_link date
  end

  def fetch_word_from_local_storage(_date) do
    raise "not implemented"
  end

  def fetch_word_from_remote_link(date, remote_link \\ "http://diccionariolibre.com/diario.php") do
    case HTTPoison.get(remote_link) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        days = body |> Floki.find(".daily_box")
        case date do
          "today" ->
            from_days(days)
          "yesterday" ->
            from_days(days, 1)
          _ ->
            {:error, "not a valid date"}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "#{remote_link} doesn't exist"}
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "#{status_code}: #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "#{reason}"}
    end
  end

  def from_days(days, 0) do
    from_days(days)
  end

  def from_days(days, days_before) do
    days |> tl |> from_days(days_before - 1)
  end

  def from_days(days) do
    daily_box = days |> hd

    [{"div", [{"class", "month"}], [date]} | _] = daily_box |> Floki.find(".month")

    [{"a", [{"href", _}], [word]} | _] = daily_box |> Floki.find(".big_title a")

    [{"p", _, [definition | _]} | _example_raw] = daily_box |> Floki.find(".daily_main_box p")

    {:ok, %{
      date: String.downcase(date),
      word: String.downcase(word),
      definition: String.downcase(definition),
    }}
  end
end
