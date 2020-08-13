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

{:ok, luiz} = Todayflex.Auth.register(%{
  name: "Luiz Paulo",
  email: "luiz@todayflex.com",
  password: "1234"
})

aloweb = Todayflex.Repo.insert!(%Todayflex.Auth.Project{
  creator_id: luiz.id,
  name: "Aloweb",
  description: "Atendimento ao consumidor"
})

# aloweb |> Todayflex.Repo.preload(:users) |> Ecto.Changeset.change() |> Ecto.Changeset.put_assoc(:users, [luiz]) |> Todayflex.Repo.update!()
