defmodule Ex338.User do
  @moduledoc false
  use Ecto.Schema
  use Ex338Web, :model
  use Coherence.Schema

  alias Ex338.User

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:admin, :boolean)
    has_many(:owners, Ex338.Owner)
    has_many(:submitted_trades, Ex338.Trade, foreign_key: :submitted_by_user_id)
    has_many(:trade_votes, Ex338.TradeVote)
    has_many(:fantasy_teams, through: [:owners, :fantasy_team])
    coherence_schema()

    timestamps()
  end

  def alphabetical(query), do: from(u in query, order_by: u.name)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :admin] ++ coherence_fields())
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(
      params,
      ~w(password password_confirmation reset_password_token reset_password_sent_at)
    )
    |> validate_coherence_password_reset(params)
  end

  def admin_emails do
    from(
      u in User,
      where: u.admin == true,
      select: {u.name, u.email}
    )
  end
end
