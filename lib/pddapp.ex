defmodule PDDApp do
  use Application
  import Supervisor.Spec
  require Logger

  def start(_type, _args) do
    Logger.info "Iniciando PDD"

    hijos = [worker(PDD, [
      Application.get_env(:slack, :token),
      %{ignore_channels: Application.get_env(:slack, :ignore_channels)}
    ])]

    {:ok, _pid} = Supervisor.start_link hijos, strategy: :one_for_one
  end
end
