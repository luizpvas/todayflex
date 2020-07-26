defmodule Todayflex.Auth.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name
    field :description
    timestamps()

    belongs_to :creator, Todayflex.Auth.User
    many_to_many :users, Todayflex.Auth.User, join_through: Todayflex.Auth.UserAssoc
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [])
    |> validate_required([])
  end
end
