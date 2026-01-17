defmodule MiniRDBMSWeb.Bootstrap do
  @moduledoc """
  Domain bootstrap for the web application.

  Declares application-level tables required by the payments domain.

  This runs once at application startup.
  """

  def init_domain! do
    MiniRDBMS.create_table(
      :merchants,
      %{
        id: :int,
        name: :text,
        email: :text,
        active: :bool
      },
      primary_key: :id,
      unique: [:email]
    )
  end
end
