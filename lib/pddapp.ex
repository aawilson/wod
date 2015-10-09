defmodule PDDApp do
  use Application
  import Supervisor.Spec
  require Logger

  def start(_type, _args) do
    Logger.info "starting PDD"

    children = [worker(PDD, [
      Application.get_env(:slack, :token),
      %{ignore_channels: Application.get_env(:slack, :ignore_channels)}
    ])]

    {:ok, _pid} = Supervisor.start_link children, strategy: :one_for_one
  end
end
