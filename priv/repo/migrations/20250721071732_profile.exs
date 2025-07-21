defmodule Mylibrarynew.Repo.Migrations.Profile do
  use Ecto.Migration

  def change do
    create table(:credential_profiles) do
      add :full_name, :string, null: false
      add :ic, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :phone, :string
      add :address, :text
      add :date_of_birth, :date
      add :credential_id, references(:credentials, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:credential_profiles, [:ic])
    create unique_index(:credential_profiles, [:credential_id])
  end
end
