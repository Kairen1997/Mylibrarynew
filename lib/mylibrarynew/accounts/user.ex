defmodule Mylibrarynew.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :age, :integer

    has_many :loans, Mylibrarynew.Library.Loan

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:loan, :name, :age,])
    |> validate_required([:name, :age,])
  end
end
