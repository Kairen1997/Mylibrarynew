defmodule MylibrarynewWeb.CredentialSettingsLiveTest do
  use MylibrarynewWeb.ConnCase, async: true

  alias Mylibrarynew.Authentication
  import Phoenix.LiveViewTest
  import Mylibrarynew.AuthenticationFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_credential(credential_fixture())
        |> live(~p"/credentials/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if credential is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/credentials/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credentials/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_credential_password()
      credential = credential_fixture(%{password: password})
      %{conn: log_in_credential(conn, credential), credential: credential, password: password}
    end

    test "updates the credential email", %{conn: conn, password: password, credential: credential} do
      new_email = unique_credential_email()

      {:ok, lv, _html} = live(conn, ~p"/credentials/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "credential" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Authentication.get_credential_by_email(credential.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credentials/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "credential" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, credential: credential} do
      {:ok, lv, _html} = live(conn, ~p"/credentials/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "credential" => %{"email" => credential.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_credential_password()
      credential = credential_fixture(%{password: password})
      %{conn: log_in_credential(conn, credential), credential: credential, password: password}
    end

    test "updates the credential password", %{conn: conn, credential: credential, password: password} do
      new_password = valid_credential_password()

      {:ok, lv, _html} = live(conn, ~p"/credentials/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "credential" => %{
            "email" => credential.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/credentials/settings"

      assert get_session(new_password_conn, :credential_token) != get_session(conn, :credential_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Authentication.get_credential_by_email_and_password(credential.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credentials/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "credential" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/credentials/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "credential" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      credential = credential_fixture()
      email = unique_credential_email()

      token =
        extract_credential_token(fn url ->
          Authentication.deliver_credential_update_email_instructions(%{credential | email: email}, credential.email, url)
        end)

      %{conn: log_in_credential(conn, credential), token: token, email: email, credential: credential}
    end

    test "updates the credential email once", %{conn: conn, credential: credential, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/credentials/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credentials/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Authentication.get_credential_by_email(credential.email)
      assert Authentication.get_credential_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/credentials/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credentials/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, credential: credential} do
      {:error, redirect} = live(conn, ~p"/credentials/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credentials/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Authentication.get_credential_by_email(credential.email)
    end

    test "redirects if credential is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/credentials/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/credentials/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
