defmodule Ex338.FantasyTeam.StandingsHistory do
  @moduledoc """
  Functions to generate league standings history
  """

  @months ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]

  def get_dates_for_league(league) do
    %{year: year} = league
    Enum.map(@months, &format_date(&1, year))
  end

  def get_date_range_for_league(league) do
    %{championships_start_at: start_datetime, championships_end_at: end_datetime} = league

    start_date = DateTime.to_date(start_datetime)
    end_date = DateTime.to_date(end_datetime)

    calculate_date_range(start_date, end_date)
  end

  def group_by_team(standings_by_month) do
    standings_by_month
    |> List.flatten()
    |> Enum.group_by(& &1.team_name)
    |> Enum.map(&format_team_data/1)
  end

  ## Helpers

  ## get_date_range_for_league

  defp calculate_date_range(start_date, end_date) do
    days_in_season = Date.diff(end_date, start_date)
    months_in_season = div(days_in_season, 30)

    %{dates: dates} =
      Enum.reduce_while(
        0..months_in_season,
        %{dates: [start_date], end_date: end_date},
        &add_months/2
      )

    dates
    |> Enum.map(&format_date/1)
    |> Enum.reverse()
  end

  defp add_months(_num_months, %{dates: dates, end_date: end_date} = acc) do
    last_date = List.first(dates)
    days_in_month = Date.days_in_month(last_date)
    next_date = Date.add(last_date, days_in_month)
    end_date_plus_month = Date.add(end_date, 30)

    if Date.compare(next_date, end_date_plus_month) == :lt do
      {:cont, %{acc | dates: [next_date | dates]}}
    else
      {:halt, acc}
    end
  end

  defp format_date(date) do
    iso_datetime = "#{date.year}-#{format_month(date.month)}-01T00:00:00Z"
    {:ok, datetime, _} = DateTime.from_iso8601(iso_datetime)
    datetime
  end

  defp format_month(month) when month < 10, do: "0#{month}"
  defp format_month(month), do: month

  ## get_dates_for_league

  defp format_date(month, year) do
    iso_datetime = "#{year}-#{month}-01T00:00:00Z"
    {:ok, datetime, _} = DateTime.from_iso8601(iso_datetime)
    datetime
  end

  ## group_by_team

  defp format_team_data({_team, data}) do
    Enum.reduce(data, %{}, fn data, acc ->
      acc
      |> Map.put_new(:team_name, data.team_name)
      |> Map.update(:points, [data.points], &(&1 ++ [data.points]))
    end)
  end
end
