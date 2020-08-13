defmodule Todayflex.Repo.Migrations.CreateWidgets do
  use Ecto.Migration

  def change do
    create table(:widgets) do
      add :project_id,      references(:projects, on_delete: :delete_all), null: false
      add :searchable_text, :string, null: true
      add :data,            :jsonb
      timestamps()
    end
  end
end
