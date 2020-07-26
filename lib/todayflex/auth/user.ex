defmodule Todayflex.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name
    field :email
    timestamps()

    many_to_many :projects, Todayflex.Auth.Project, join_through: "user_assocs" 
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
