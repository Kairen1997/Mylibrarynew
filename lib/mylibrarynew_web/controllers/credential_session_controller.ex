defmodule MylibrarynewWeb.CredentialSessionController do
  use MylibrarynewWeb, :controller

  alias Mylibrarynew.Authentication
  alias MylibrarynewWeb.CredentialAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:credential_return_to, ~p"/credentials/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"credential" => credential_params}, info) do
    %{"email" => email, "password" => password} = credential_params

    if credential = Authentication.get_credential_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> CredentialAuth.log_in_credential(credential, credential_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/credentials/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> CredentialAuth.log_out_credential()
  end
end
