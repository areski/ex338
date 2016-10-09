defmodule Ex338.RosterPosition do
  @moduledoc false

  use Ex338.Web, :model

  alias Ex338.{FantasyTeam, FantasyPlayer}

  @flex_positions ["Flex1", "Flex2", "Flex3", "Flex4", "Flex5", "Flex6"]

  @positions ["CL", "CBB", "CFB", "CHK", "EPL", "KD", "LLWS", "MTn", "MLB",
              "NBA", "NFL", "NHL", "PGA", "WTn"] ++ @flex_positions

  @status_options ["active", "dropped", "traded"]

  schema "roster_positions" do
    belongs_to :fantasy_team, FantasyTeam
    field :position, :string
    belongs_to :fantasy_player, FantasyPlayer
    field :status, :string
    field :released_at, Ecto.DateTime

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:position, :fantasy_team_id, :fantasy_player_id, :status,
                     :released_at])
    |> validate_required([:fantasy_team_id])
  end

  def positions, do: @positions

  def flex_positions, do: @flex_positions

  def status_options, do: @status_options

  def active_positions(query) do
    from r in query,
      where: r.status == "active",
      preload: [fantasy_player: :sports_league]
  end

  def update_position_status(query, team_id, player_id, released_at, status) do
    from r in query,
      where: r.fantasy_team_id   == ^team_id,
      where: r.fantasy_player_id == ^player_id,
      update: [set: [released_at: ^released_at]],
      update: [set: [status:      ^status]]
  end
end
