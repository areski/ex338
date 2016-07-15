defmodule Ex338 do
  @moduledoc false

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Ex338.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Ex338.Endpoint, []),
      # Start your own worker by calling: Ex338.Worker.start_link(arg1, arg2)
      # worker(Ex338.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ex338.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Ex338.Endpoint.config_change(changed, removed)
    :ok
  end
end