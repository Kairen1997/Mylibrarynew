defmodule Mylibrarynew.Library.Loan do
  use Ecto.Schema
  import Ecto.Changeset

  alias Mylibrarynew.Library.Book
  alias Mylibrarynew.Accounts.User

  schema "loans" do
    field :borrowed_at, :naive_datetime
    field :due_at, :naive_datetime
    field :returned_at, :naive_datetime

    belongs_to :user, User
    belongs_to :book, Book

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(loan, attrs) do
    loan
    |> cast(attrs, [:user_id, :book_id, :borrowed_at, :due_at, :returned_at])
    |> validate_required([:user_id, :book_id, :borrowed_at, :due_at,])
    |> cast_assoc(:user)
    |> cast_assoc(:book)
  end
end
