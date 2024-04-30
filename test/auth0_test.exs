defmodule Auth0Test do
  use ExUnit.Case
  import Mock

  alias Auth0
  alias Auth0.TokenCache

  @http "[HTTP]"
  
  describe "Auth0 request_token/0" do
    # Test with actual HTTP requests to Auth0 service  -------------------------
    
    @tag :http
    test "#{@http} Validate actual HTTP token request"
    do
      # Actual HTTP request
      assert {:ok, token} = Auth0.request_token()
      assert validate(:token, token)
    end
    
    @tag :http
    test "#{@http} Error when non existing tenant domain is set in config.exs"
    do
      # Temporary change to config parameters
      tenant = Application.get_env(:auth0, :tenant)
      Application.put_env(:auth0, :tenant, "non-existing-tenant")

      # Actual HTTP request
      assert {:error, :bad_tenant} = Auth0.request_token()

      # Reverting config parameters change
      Application.put_env(:auth0, :tenant, tenant)
    end
    
    @tag :http
    test "#{@http} Error when invalid client credentials are set in config.exs"
    do
      # Temporary change to config parameters
      client_id = Application.get_env(:auth0, :client_id)
      Application.put_env(:auth0, :client_id, "invalid-client-id")

      # Actual HTTP request
      assert {:error, :access_denied} = Auth0.request_token()

      # Reverting config parameters change
      Application.put_env(:auth0, :client_id, client_id)
      # Temporary change to config parameters
      client_secret = Application.get_env(:auth0, :client_secret)
      Application.put_env(:auth0, :client_secret, "invalid-client-secret")

      # Actual HTTP request
      assert {:error, :access_denied} = Auth0.request_token()

      # Reverting config parameters change
      Application.put_env(:auth0, :client_secret, client_secret)
    end
    
    # Test with mocked HTTP requests -------------------------------------------

    @token %{
      "token_type"   => "Bearer",
      "access_token" => "eyJhbGciOiJSUzI1NiIsInR5cCI6Ikp...",
      "expires_in"   => 86400,
      "scope"        => "read:users update:users delete:users create:users",
      "created_at"   => ~N[2024-04-27 21:46:30.988000]
    }
    test_with_mock "Validate mocked HTTP token request",
      Finch, [:passthrough], request: &mock_request(200, @token, {&1, &2, &3})
    do
      assert {:ok, token} = Auth0.request_token()
      assert validate(:token, token)
    end
    
    @error %Mint.TransportError{reason: :nxdomain}
    test_with_mock "Error when non existing tenant domain is set in config.exs",
      Finch, [:passthrough], request: fn _, _, _ -> {:error, @error} end
    do
      assert {:error, :bad_tenant} = Auth0.request_token()
    end
    
    @error %{
      "error" => "access_denied",
      "error_description" => "Unauthorized"
    }
    test_with_mock "Error when invalid client credentials are set in config.exs",
      Finch, [:passthrough], request: &mock_request(401, @error, {&1, &2, &3})
    do
      assert {:error, :access_denied} = Auth0.request_token()
    end
    
    # Test every element in the response list for
    # validating all have consistent fields in their structure
    defp validate(:token, %{} = token) do
      assert %{"token_type" => "Bearer"} = token

      assert %{"access_token" => access_token} = token
      assert is_binary(access_token)

      assert %{"scope" => scope} = token
      assert is_binary(scope)

      assert %{"expires_in" => expires_in} = token
      assert is_integer(expires_in)
      assert expires_in >= 0

      assert %{"created_at" => created_at} = token
      assert %NaiveDateTime{} = created_at
    end
  end

  describe "Auth0 request/4" do
    # Test with actual HTTP requests to Auth0 service --------------------------

    @tag :http
    test "#{@http} Validate actual HTTP request: GET users"
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      # Actual HTTP request
      assert {:ok, users} = Auth0.request(:get, "users")
      assert validate(:user, users)
    end
    
    @tag :http
    test "#{@http} If no body is recieved return nil"
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      assert {:ok, nil} = Auth0.request(:head, "users")
    end
    
    @tag :http
    test "#{@http} Error when the Auth0 client set in config.exs has insufficient scopes for the requested resource"
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      # Temporary change to config parameters
      tenant = Application.get_env(:auth0, :tenant)
      client_id = Application.get_env(:auth0, :client_id)
      client_secret = Application.get_env(:auth0, :client_secret)
      extras = Application.get_env(:auth0, :extras)
      Application.put_env(:auth0, :tenant, extras[:no_scopes].tenant)
      Application.put_env(:auth0, :client_id, extras[:no_scopes].client_id)
      Application.put_env(:auth0, :client_secret, extras[:no_scopes].client_secret)

      # Actual HTTP request
      assert {:error, :forbbiden} = Auth0.request(:get, "users")

      # Reverting config parameters change
      Application.put_env(:auth0, :tenant, tenant)
      Application.put_env(:auth0, :client_id, client_id)
      Application.put_env(:auth0, :client_secret, client_secret)
    end
    
    @tag :http
    test "#{@http} Error when no resource found in the given path"
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      assert {:error, :not_found} = Auth0.request(:get, "invalid-path")
    end

    @tag :http
    test "#{@http} Error when requesting a method not available in endpoint"
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      assert {:error, :invalid_method} = Auth0.request(:options, "users")
    end

    @tag :http
    test "#{@http} Error when request body is invalid or missing if required"
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      assert {:error, :invalid_body} = Auth0.request(:post, "users")
      assert {:error, :invalid_body} = Auth0.request(:post, "users", %{})
    end
    
    # Test with mocked HTTP requests -------------------------------------------

    @user %{
      "user_id"    => "auth0|...",
      "name"       => "John Doe",
      "identities" => [
        %{
          "connection" => "Username-Password-Authentication",
          "isSocial"   => false,
          "provider"   => "auth0",
          "user_id"    => "..."
        }
      ]
    }
    test_with_mock "Validate mocked HTTP request: GET users",
      Finch, [:passthrough], request: fn
        (%{path: "/oauth/token"}, _, _)  -> mock_request(200, @token)
        (%{path: "/api/v2/users"}, _, _) -> mock_request(200, [@user])
      end
    do
      assert {:ok, users} = Auth0.request(:get, "users")
      assert validate(:user, users)
    end
    
    test_with_mock "If no body is recieved return nil",
      Finch, [:passthrough], request: fn
        (%{path: "/oauth/token"}, _, _) -> mock_request(200, @token)
        (_, _, _)                       -> mock_request(200, "")
      end
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      assert {:ok, nil} = Auth0.request(:head, "users")
    end
    
    @error %{
      "error" => "Forbidden",
      "errorCode" => "insufficient_scope",
      "message" => "Insufficient scope, expected any of: read:users,read:user_idp_tokens",
      "statusCode" => 403
    }
    test_with_mock "Error when the Auth0 client set in config.exs has insufficient scopes for the requested resource",
      Finch, [:passthrough], request: fn
        (%{path: "/oauth/token"}, _, _)  -> mock_request(200, @token)
        (%{path: "/api/v2/users"}, _, _) -> mock_request(403, @error)
      end
    do      
      assert {:error, :forbbiden} = Auth0.request(:get, "users")
    end
    
    @error %{
      "error" => "Not Found",
      "message" => "Not Found",
      "statusCode" => 404
    }
    test_with_mock "Error when no resource found in the given path",
      Finch, [:passthrough], request: fn
        (%{path: "/oauth/token"}, _, _) -> mock_request(200, @token)
        (%{path: _invalid_path}, _, _)  -> mock_request(404, @error)
      end
    do
      assert {:error, :not_found} = Auth0.request(:get, "invalid-path")
    end

    @error %{
      "error" => "Not Found",
      "message" => "CORS error: Missing Access-Control-Request-Method header",
      "statusCode" => 404
    }
    test_with_mock "Error when requesting a method not available in endpoint",
      Finch, [:passthrough], request: fn
        (%{path: "/oauth/token"}, _, _)  -> mock_request(200, @token)
        (%{path: "/api/v2/users"}, _, _) -> mock_request(404, @error)
      end
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      assert {:error, :invalid_method} = Auth0.request(:options, "users")
    end

    @error %{
      "error" => "Bad Request",
      "errorCode" => "invalid_body",
      "message" =>
        "Payload validation error: 'Missing required property: connection'.",
      "statusCode" => 400
    }
    test_with_mock "Error when request body is invalid or missing if required",
      Finch, [:passthrough], request: fn
        (%{path: "/oauth/token"}, _, _)  -> mock_request(200, @token)
        (%{path: "/api/v2/users"}, _, _) -> mock_request(400, @error)
      end
    do
      # Resetting the cache forces the function to request a valid token.
      :ok = TokenCache.clear()

      assert {:error, :invalid_body} = Auth0.request(:post, "users")
      assert {:error, :invalid_body} = Auth0.request(:post, "users", %{})
    end

    # Test every element in the response list for
    # validating all have consistent fields in their structure
    defp validate(:user, users) when is_list(users), do:
      Enum.map(users, &validate(:user, &1))

    defp validate(:user, %{} = user) do
      assert %{"name" => name} = user
      assert is_binary(name)

      assert %{"user_id"    => user_id} = user
      assert [_user_id, id_head, id_tail] = Regex.run(~r/(.*)\|(.*)/, user_id)

      assert %{"identities" => identities} = user
      Enum.each(identities, fn identity ->
        assert %{"connection" => connection} = identity
        assert connection in [
          "Username-Password-Authentication",
          "google-oauth2",
          "github"
        ]

        assert %{"provider"   => provider} = identity
        assert provider in [
          "auth0",
          "google-oauth2",
          "github"
        ]

        assert %{"user_id"    => user_id} = identity
        assert is_binary(user_id)

        assert %{"isSocial"   => is_social} = identity
        assert is_boolean(is_social)

        assert provider == id_head
        assert user_id == id_tail
      end)
    end
  end

  defp mock_request(code, return, {_, _, _}), do: mock_request(code, return)
  defp mock_request(code, ""), do:
    {:ok, %Finch.Response{status: code, body: ""}}

  defp mock_request(code, return), do:
    {:ok, %Finch.Response{status: code, body: Jason.encode!(return)}}
end
