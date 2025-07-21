defmodule MylibrarynewWeb.CredentialForgotPasswordLiveTest do
  use MylibrarynewWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mylibrarynew.AuthenticationFixtures

  alias Mylibrarynew.Authentication
  alias Mylibrarynew.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/credentials/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/credentials/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/credentials/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_credential(credential_fixture())
        |> live(~p"/credentials/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{credential: credential_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, credential: credential} do
      {:ok, lv, _html} = live(conn, ~p"/credentials/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", credential: %{"email" => credential.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Authentication.CredentialToken, credential_id: credential.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credentials/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", credential: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Authentication.CredentialToken) == []
    end
  end
end
