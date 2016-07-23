defmodule Ex338.DraftPick do
  @moduledoc false

  use Ex338.Web, :model

  schema "draft_picks" do
    field :draft_position, :float, scale: 3
    belongs_to :fantasy_league, Ex338.FantasyLeague
    belongs_to :fantasy_team, Ex338.FantasyTeam
    belongs_to :fantasy_player, Ex338.FantasyPlayer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:draft_position, :fantasy_league_id, :fantasy_team_id,
                     :fantasy_player_id])
    |> validate_required([:draft_position, :fantasy_league_id])
  end

  def convert_position_to_round(draft_position) do
    Float.round(draft_position - 0.5)
  end

  def ordered_by_position(query) do
    from d in query, order_by: d.draft_position
  end
end
