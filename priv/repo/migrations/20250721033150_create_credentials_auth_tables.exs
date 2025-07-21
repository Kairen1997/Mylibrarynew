defmodule Mylibrarynew.Repo.Migrations.CreateCredentialsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:credentials) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:credentials, [:email])

    create table(:credentials_tokens) do
      add :credential_id, references(:credentials, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:credentials_tokens, [:credential_id])
    create unique_index(:credentials_tokens, [:context, :token])
  end
end
