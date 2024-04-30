defmodule Auth0.TokenCacheTest do
  use ExUnit.Case

  alias Auth0.TokenCache
  
  describe "Auth0.TokenCacheTest start_link/1" do
    test "Verify supervision link to ensure it started correctly"
    do
      assert \
      {TokenCache, _pid, :worker, _module} =
        Auth0.Supervisor
        |> Supervisor.which_children()
        |> Enum.find(fn {name, _pid, _type, _module} -> name == TokenCache end)
    end
  end
  
  describe "Auth0.TokenCacheTest get/0" do
    test "Get the stored token term"
    do
      Agent.update(TokenCache, &Map.put(&1, :token, "token"))

      assert TokenCache.get() == "token"
    end
  end
  
  describe "Auth0.TokenCacheTest put/1" do
    test "Update the stored token term"
    do
      assert token = TokenCache.put("token")
      assert token == Agent.get(TokenCache, &Map.get(&1, :token))
    end
  end
  
  describe "Auth0.TokenCacheTest clear/0" do
    test "Clear the stored token term"
    do
      assert :ok = TokenCache.clear()
      assert is_nil(Agent.get(TokenCache, &Map.get(&1, :token)))
    end
  end
end
