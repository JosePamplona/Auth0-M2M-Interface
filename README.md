# Auth0-M2M-Interface

[![License](https://img.shields.io/github/license/JosePamplona/Auth0-M2M-Interface)](https://github.com/JosePamplona/Auth0-M2M-Interface/blob/main/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/JosePamplona/Auth0-M2M-Interface.svg)](https://github.com/JosePamplona/Auth0-M2M-Interface/commits/main)

This module is an interface for external API consumption which is an account authentication service: [Auth0](https://auth0.com/).

## Installation

The package can be installed by adding `auth0` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:auth0, git: "https://github.com/JosePamplona/Auth0-M2M-Interface"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/auth0>.

## Configuration

To integrate the authentication service, it is required to have an account on Auth0. Within it create an application with *Machine-to-Machine* type, configure its scopes.

The configuration of the module will require the client application `tenant`,
`client_id`, and `client_secret` values, which will be used to connect, authenticate, and finally make requests the **Auth0 Management API** ([Docs](https://auth0.com/docs/api/management/v2/introduction)).

```elixir
# config/config.exs

config :auth0,
  tenant: "dev-ypiPDELRvbhyDRLO.us.auth0.com",
  client_id: "k4GTwihwfbqmko2ew5fneNN3dPDT5n67",
  client_secret: "8HRHeB501D9bqC_jhBlcrCyU4ypiPDELneNN3dPDT5gcsquPWRLGieM6BQsL0BOS",
  request_opts: [
    pool_timeout: 5_000,
    receive_timeout: 15_000,
    request_timeout: :infinity
  ]
```

## Usage

### Obtaining tokens

Access tokens can be obtained using `Auth0.request_token/1`:

```elixir
{:ok, token} = Auth0.request_token()
```

### Perform requests

To make request to the Auth0 Management API, use `Auth0.request/1` indicating the method and the path of the request.

```elixir
{:ok, %{
  "user_id"    => "auth0|abcdef123456",
  "name"       => "John Doe",
  "identities" => [
    %{
      "connection" => "Username-Password-Authentication",
      "isSocial"   => false,
      "provider"   => "auth0",
      "user_id"    => "abcdef123456"
    }
  ]
}} = Auth0.request(:get, ["users", "auth0|abcdef123456"])
```

## Development

The test suite can be executed as follows:

```sh
mix test --exclude http
```

To include the tests that actually makes HTTP requests, it is required to set some enviroment variables:

```sh
# This credentials are for setting an main application to test request on.
export AUTH0_TEST_TENANT="dev-ypiPDELRvbhyDRLO.us.auth0.com"
export AUTH0_TEST_CLIEND_ID="k4GTwihwfbqmko2ew5fneNN3dPDT5n67"
export AUTH0_TEST_CLIENT_SECRET="8HRHeB501D9bqC_jhBlcrCyU4ypiPDEL..."

# This application must have no scopes configured, to test its error mesagges.
export AUTH0_NO_SCOPES_TENANT="dev-ypiPDELRvbhyDRLO.us.auth0.com"
export AUTH0_NO_SCOPES_CLIENT_ID="k4GTwihwfbqmko2ew5fneNN3dPDT5n67"
export AUTH0_NO_SCOPES_CLIENT_SECRET="8HRHeB501D9bqC_jhBlcrCyU4ypiPDEL..."
```

Once settled, run all tests:

```sh
mix test
```
