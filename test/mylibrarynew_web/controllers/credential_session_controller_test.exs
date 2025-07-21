defmodule MylibrarynewWeb.CredentialSessionControllerTest do
  use MylibrarynewWeb.ConnCase, async: true

  import Mylibrarynew.AuthenticationFixtures

  setup do
    %{credential: credential_fixture()}
  end

  describe "POST /credentials/log_in" do
    test "logs the credential in", %{conn: conn, credential: credential} do
      conn =
        post(conn, ~p"/credentials/log_in", %{
          "credential" => %{"email" => credential.email, "password" => valid_credential_password()}
        })

      assert get_session(conn, :credential_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ credential.email
      assert response =~ ~p"/credentials/settings"
      assert response =~ ~p"/credentials/log_out"
    end

    test "logs the credential in with remember me", %{conn: conn, credential: credential} do
      conn =
        post(conn, ~p"/credentials/log_in", %{
          "credential" => %{
            "email" => credential.email,
            "password" => valid_credential_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_mylibrarynew_web_credential_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the credential in with return to", %{conn: conn, credential: credential} do
      conn =
        conn
        |> init_test_session(credential_return_to: "/foo/bar")
        |> post(~p"/credentials/log_in", %{
          "credential" => %{
            "email" => credential.email,
            "password" => valid_credential_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, credential: credential} do
      conn =
        conn
        |> post(~p"/credentials/log_in", %{
          "_action" => "registered",
          "credential" => %{
            "email" => credential.email,
            "password" => valid_credential_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, credential: credential} do
      conn =
        conn
        |> post(~p"/credentials/log_in", %{
          "_action" => "password_updated",
          "credential" => %{
            "email" => credential.email,
            "password" => valid_credential_password()
          }
        })

      assert redirected_to(conn) == ~p"/credentials/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/credentials/log_in", %{
          "credential" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/credentials/log_in"
    end
  end

  describe "DELETE /credentials/log_out" do
    test "logs the credential out", %{conn: conn, credential: credential} do
      conn = conn |> log_in_credential(credential) |> delete(~p"/credentials/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :credential_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the credential is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/credentials/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :credential_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
