# Auth0-M2M-Interface

Interface module for authenticate Auth0 Machine-to-Machine applications and perform requests to the Auth0 Management API.

- Uses Finch
- Uses Jason

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `auth0` to your list of dependencies in `mix.exs`:

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

## Development

The test suite can be executed as follows:

```sh
mix test
```

The test suite can be executed as follows:

```sh
mix test --exclude http
```
