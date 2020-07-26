defmodule Todayflex.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :email, :string
      timestamps()
    end

    create index(:users, [:email], unique: true)
  end
end
