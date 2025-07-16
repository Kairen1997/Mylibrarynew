defmodule Mylibrarynew.Library.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :title, :string
    field :author, :string
    field :isbn, :string
    field :publised_at, :date

    has_many :loan, Mylibrarynew.Library.Loan
    has_many :borrowers, through: [:loan, :user]
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :author, :isbn, :publised_at])
    |> validate_required([:title, :author, :isbn, :publised_at])
  end
end
