defmodule Todayflex.Project.Widget do
  use Ecto.Schema
  import Ecto.Changeset

  schema "widgets" do
    field :searchable_text
    field :data, :map
    timestamps()

    belongs_to :project, Todayflex.Project.Project
  end

  @doc false
  def changeset(widget, attrs) do
    widget
    |> cast(attrs, [:searchable_text, :data])
    |> validate_required([:data])
  end
end
