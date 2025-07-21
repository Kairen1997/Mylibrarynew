defmodule Mylibrarynew.AuthenticationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Mylibrarynew.Authentication` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Mylibrarynew.Authentication.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def unique_credential_email, do: "credential#{System.unique_integer()}@example.com"
  def valid_credential_password, do: "hello world!"

  def valid_credential_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_credential_email(),
      password: valid_credential_password()
    })
  end

  def credential_fixture(attrs \\ %{}) do
    {:ok, credential} =
      attrs
      |> valid_credential_attributes()
      |> Mylibrarynew.Authentication.register_credential()

    credential
  end

  def extract_credential_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
