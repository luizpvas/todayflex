defmodule Todayflex.Project.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name
    field :description
    timestamps()

    belongs_to :creator, Todayflex.Auth.User
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
