ExUnit.start()
Application.put_env(:phoenix_test, :base_url, MigrationFixtureWeb.Endpoint.url())
Application.put_env(:cerberus, :base_url, MigrationFixtureWeb.Endpoint.url())
