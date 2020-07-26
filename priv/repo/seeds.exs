# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Todayflex.Repo.insert!(%Todayflex.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

luiz = Todayflex.Repo.insert!(%Todayflex.Auth.User{
  name: "Luiz Paulo",
  email: "luiz@todayflex.com"
})

aloweb = Todayflex.Repo.insert!(%Todayflex.Auth.Project{
  creator_id: luiz.id,
  name: "Aloweb",
  description: "Atendimento ao consumidor"
})

aloweb |> Todayflex.Repo.preload(:users) |> Ecto.Changeset.change() |> Ecto.Changeset.put_assoc(:users, [luiz]) |> Todayflex.Repo.update!()
