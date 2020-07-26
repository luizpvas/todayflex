defmodule Todayflex.Repo do
  use Ecto.Repo,
    otp_app: :todayflex,
    adapter: Ecto.Adapters.Postgres
end
