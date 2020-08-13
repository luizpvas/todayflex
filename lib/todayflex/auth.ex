defmodule Todayflex.Auth do
  alias Todayflex.Auth.Registration
  alias Todayflex.Repo

  @doc """
  Attempts to register a new user in the app.

  ## Examples

      iex> Todayflex.Auth.register(valid_attributes)
      {:ok, %Todayflex.Auth.Registration{}}

  """
  def register(attributes) do
    Registration.changeset(%Registration{}, attributes)
    |> Todayflex.Repo.insert()
  end

  def authenticate(email, password) do
    case Repo.get_by(Registration, email: email) do
      nil ->
        {:error, :incorrect_email}

      user ->
        if Bcrypt.verify_pass(password, user.password_digest) do
          {:ok, user}
        else
          {:error, :incorrect_password}
        end
    end
  end
end
