defmodule Todayflex.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :creator_id,  references(:users, on_delete: :delete_all), null: false
      add :name,        :string,                                    null: false
      add :description, :string,                                    null: true
      timestamps()
    end
  end
end
