# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
if config_env() == :test, do: import_config "test.exs"
