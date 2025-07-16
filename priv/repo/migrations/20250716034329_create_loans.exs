defmodule Mylibrarynew.Repo.Migrations.CreateLoans do
  use Ecto.Migration

  def change do
    create table(:loans) do
      add :borrowed_at, :naive_datetime
      add :due_at, :naive_datetime
      add :returned_at, :naive_datetime
      add :user_id, references(:users, on_delete: :nothing)
      add :book_id, references(:books, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:loans, [:user_id])
    create index(:loans, [:book_id])
  end
end
