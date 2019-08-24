defmodule Ex338.FantasyTeam.StandingsHistoryTest do
  use Ex338.DataCase
  alias Ex338.{FantasyTeam.StandingsHistory}

  describe "get_dates_for_league/1" do
    test "returns list of dates with 1st of the month for a league" do
      league = %{year: 2018}
      {:ok, expected_datetime, _} = DateTime.from_iso8601("2018-01-01T00:00:00Z")

      result = StandingsHistory.get_dates_for_league(league)

      assert List.first(result) == expected_datetime
      assert Enum.map(result, & &1.month) == Enum.map(1..12, & &1)
    end
  end

  describe "get_date_range_for_league/1" do
    test "returns list of dates with 1st of the month for a league" do
      {:ok, start_datetime, _} = DateTime.from_iso8601("2018-08-01T00:00:00Z")
      {:ok, end_datetime, _} = DateTime.from_iso8601("2019-07-31T00:00:00Z")
      league = %{championships_start_at: start_datetime, championships_end_at: end_datetime}

      result = StandingsHistory.get_date_range_for_league(league)

      assert List.first(result) == start_datetime
      assert Enum.map(result, & &1.month) == [8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8]
    end
  end

  describe "group_by_team/1" do
    test "returns list teams with points formatted" do
      standings_by_month = [
        [
          %{team_name: "A", points: 0},
          %{team_name: "B", points: 0}
        ],
        [
          %{team_name: "A", points: 5},
          %{team_name: "B", points: 0}
        ],
        [
          %{team_name: "A", points: 10},
          %{team_name: "B", points: 5}
        ]
      ]

      results = StandingsHistory.group_by_team(standings_by_month)

      assert results == [
               %{team_name: "A", points: [0, 5, 10]},
               %{team_name: "B", points: [0, 0, 5]}
             ]
    end
  end
end
