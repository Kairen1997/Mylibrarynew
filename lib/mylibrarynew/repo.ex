defmodule Mylibrarynew.Repo do
  use Ecto.Repo,
    otp_app: :mylibrarynew,
    adapter: Ecto.Adapters.Postgres
end
