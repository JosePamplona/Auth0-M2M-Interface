defmodule Auth0.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Auth0 token chache
      Auth0.TokenCache,
      # Start the Finch HTTP client for sending requests
      {Finch, name: Auth0.Finch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Auth0.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
