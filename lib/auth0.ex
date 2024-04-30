defmodule Auth0 do
  @moduledoc """
  
  """

  alias Auth0.TokenCache

  @doc """
    Makes a request to Auth0 Management API with a valid authentication token.
    """
  @spec request(
    method :: :get | :post | :head | :patch | :delete | :options | :put,
    path :: String.t() | [String.t()],
    body :: map() | nil,
    options :: keyword()
  ) :: {:ok, map()} | {:error,
    :access_denied |
    :bad_request |
    :bad_tenant | 
    :forbbiden | 
    :invalid_method |
    :not_found | 
    Mint.TransportError.t()
  }
  def request(method, path, body \\ nil, options \\ [])
  def request(method, path, body, options) when not is_list(path), do:
    request(method, [path], body, options)

  def request(method, path, body, options) when
    method in [:get, :post, :head, :patch, :delete, :options, :put] and
    (is_map(body) or is_nil(body))
  do
    config = config()

    get_access_token()
    |> case do
      {:error, error} -> {:error, error}
      {:ok, token} ->
        Finch.build(
          method,
          URI.encode("#{config.audience}#{Enum.join(path, "/")}"),
          [
            {"content-type", "application/json"},
            {"authorization", "#{token["token_type"]} #{token["access_token"]}"}
          ],
          body && Jason.encode!(body),
          options
        )
        |> Finch.request(Auth0.Finch, config.request_opts)
        |> case do
          {:ok, %{status: 200, body: ""}}   -> {:ok,    nil}
          {:ok, %{status: 200, body: body}} -> {:ok,    Jason.decode!(body)}
          {:ok, %{body: body}}              -> {:error, Jason.decode!(body)}
          {:error, error}                   -> {:error, error}
        end
        |> case do
          {:ok, response} -> {:ok, response}
          {:error, error} ->            
            case error do
              %{
                "error"      => "Bad Request",
                "errorCode"  => "invalid_body",
                "message"    => "Payload validation error: " <> _detail,
                "statusCode" => 400
              } ->
                {:error, :invalid_body}

              %{
                "error"      => "Forbidden",
                "errorCode"  => "insufficient_scope",
                "message"    => _,
                "statusCode" => 403
              } ->
                {:error, :forbbiden}

              %{
                "error"      => "Not Found",
                "message"    =>
                  "CORS error: " <>
                  "Missing Access-Control-Request-Method " <> _method,
                "statusCode" => 404
              } ->
                {:error, :invalid_method}

              %{
                "error"      => "Not Found",
                "message"    => "Not Found",
                "statusCode" => 404
              } ->
                {:error, :not_found}

              # Add here errors to support

              _ ->
                raise RuntimeError, """
                  Auth0 Managament API error not supported:
                  #{inspect(error, pretty: true)}
                  """
            end
        end
    end
  end

  @doc """
    Client credentials exchange to get an access token for Auth0 Management API.
    """
  @spec request_token :: {:ok, map()} | {:error, :bad_tenant | :access_denied}
  def request_token do
    config = config()

    Finch.build(
      :post,
      config.url,
      [{"content-type", "application/json"}],
      Jason.encode!(%{
        client_id: config.client_id,
        client_secret: config.client_secret,
        audience: config.audience,
        grant_type: config.grant_type
      })
    )
    |> Finch.request(Auth0.Finch, config.request_opts)
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {
          :ok,
          body
          |> Jason.decode!()
          |> Map.merge(%{"created_at" => NaiveDateTime.utc_now()})
          |> TokenCache.put()
        }

      {:ok, %{body: body}} -> {:error, Jason.decode!(body)}
      {:error, error}      -> {:error, error}
    end
    |> case do
      {:ok, response} -> {:ok, response}
      {:error, error} ->
        case error do
          %Mint.TransportError{reason: :nxdomain} ->
            {:error, :bad_tenant}

          %{
            "error"             => "access_denied",
            "error_description" => "Unauthorized"
          } ->
            {:error, :access_denied}
            
          # Add here errors to support
          
          _ ->
            raise RuntimeError, """
              Auth0 Authentication API error not supported:
              #{inspect(error, pretty: true)}
              """
        end
    end
  end

  # === Private ================================================================

  defp get_access_token do
    TokenCache.get()
    |> lifetime_check()
    |> case do
      {:ok, token} -> {:ok, token}
      :error       -> request_token()
    end
  end

  defp lifetime_check(nil), do: :error
  defp lifetime_check(%{} = token) do
    config     = config()
    expires_at = NaiveDateTime.add(token["created_at"], token["expires_in"])
    diff       = NaiveDateTime.diff(expires_at, NaiveDateTime.utc_now())
    
    case diff < config.revive_countdown do
      false -> {:ok, token}
      true  -> :error
    end
  end

  # === Config =================================================================

  defp config do
    request_opts = Application.get_env(:auth0, :request_opts, [])
    tenant       = Application.get_env(:auth0, :tenant, "no-tenant")

    %{
      client_id:        Application.get_env(:auth0, :client_id, ""),
      client_secret:    Application.get_env(:auth0, :client_secret, ""),
      revive_countdown: Application.get_env(:auth0, :revive_countdown, 10),
      
      url:        "https://#{tenant}/oauth/token",
      audience:   "https://#{tenant}/api/v2/",
      grant_type: "client_credentials",

      request_opts: [
        pool_timeout:    request_opts[:pool_timeout]    || 5_000,
        receive_timeout: request_opts[:receive_timeout] || 15_000,
        request_timeout: request_opts[:request_timeout] || :infinity
      ]
    }
  end
end