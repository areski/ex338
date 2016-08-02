defmodule Ex338.FantasyPlayer do
  @moduledoc false

  use Ex338.Web, :model

  alias Ex338.{SportsLeague, RosterPosition, TransactionLineItem, DraftPick,
               Waiver}

  schema "fantasy_players" do
    field :player_name, :string
    belongs_to :sports_league, SportsLeague
    has_many :roster_positions, RosterPosition
    has_many :fantasy_teams, through: [:roster_positions, :fantasy_team]
    has_many :transaction_line_items, TransactionLineItem
    has_many :roster_transactions, through: [:transaction_line_items,
                                             :roster_transaction]
    has_many :draft_picks, DraftPick
    has_many :waiver_adds, Waiver, foreign_key: :add_fantasy_player_id
    has_many :waivers_drops, Waiver, foreign_key: :drop_fantasy_player_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:player_name, :sports_league_id])
    |> validate_required([:player_name, :sports_league_id])
  end
end
