use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex338, Ex338.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :ex338, Ex338.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ex338_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Make sure Phoenix is setup to serve endpoints
config :ex338, Ex338.Endpoint,
  server: true

config :ex338, :sql_sandbox, true