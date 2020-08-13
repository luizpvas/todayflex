defmodule Todayflex.Auth.Registration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name,            :string
    field :email,           :string
    field :password_digest, :string
    field :password,        :string, virtual: true
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> unique_constraint(:email)
    |> encrypt_password()
  end

  defp encrypt_password(changeset) do
    case changeset do
      %{valid?: false} ->
        changeset

      %{valid?: true} ->
        password = get_field(changeset, :password)
        put_change(changeset, :password_digest, Bcrypt.hash_pwd_salt(password))
    end
  end
end
