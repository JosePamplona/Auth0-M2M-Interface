defmodule Auth0.TokenCache do
  @moduledoc """
  
  """

  use Agent

  @doc """
    Start the Agent process
  """
  @spec start_link(opts :: keyword()) :: {:ok, pid()}
  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @doc """
    Get the token in cache.
  """
  @spec get() :: term() | nil
  def get, do: Agent.get(__MODULE__, &Map.get(&1, :token))

  @doc """
    Sets the token in cache and returns it.
  """
  @spec put(term :: term()) :: term()
  def put(term) do
    :ok = Agent.update(__MODULE__, &Map.put(&1, :token, term))
    term
  end
  
  @doc """
    Sets nil in cache.
  """
  @spec clear() :: :ok
  def clear, do: Agent.update(__MODULE__, &Map.put(&1, :token, nil))
end