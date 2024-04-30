import Config

config :auth0,
  tenant: (
    System.get_env("AUTH0_TEST_TENANT") ||
      raise "environment variable AUTH0_TEST_TENANT is missing."
  ),
  client_id: (
    System.get_env("AUTH0_TEST_CLIEND_ID") ||
      raise "environment variable AUTH0_TEST_CLIEND_ID is missing."
  ),
  client_secret: (
    System.get_env("AUTH0_TEST_CLIENT_SECRET") ||
      raise "environment variable AUTH0_TEST_CLIENT_SECRET is missing."
  ),
  extras: [
    no_scopes: %{
      tenant: (
        System.get_env("AUTH0_NO_SCOPES_TENANT") ||
          raise "environment variable AUTH0_NO_SCOPES_TENANT is missing."
      ),
      client_id: (
        System.get_env("AUTH0_NO_SCOPES_CLIENT_ID") ||
          raise "environment variable AUTH0_NO_SCOPES_CLIENT_ID is missing."
      ),
      client_secret: (
        System.get_env("AUTH0_NO_SCOPES_CLIENT_SECRET") ||
          raise "environment variable AUTH0_NO_SCOPES_CLIENT_SECRET is missing."
      )
    }
  ]

# Print only warnings and errors during test
config :logger, level: :warning