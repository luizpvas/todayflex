defmodule Todayflex.Auth.UserAssoc do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_assocs" do
    belongs_to :user, Todayflex.Auth.User
    belongs_to :project, Todayflex.Auth.Project
    timestamps()
  end
end
