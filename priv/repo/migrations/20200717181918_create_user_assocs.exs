defmodule Todayflex.Repo.Migrations.CreateUserAssocs do
  use Ecto.Migration

  def change do
    create table(:user_assocs) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: true
      timestamps()
    end
  end
end
