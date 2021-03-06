defmodule Ex338Web.ChampionshipLive do
  @moduledoc false
  use Ex338Web, :live_view

  alias Ex338.{Championship, FantasyLeague, InSeasonDraftPick, User}
  alias Ex338Web.ChampionshipView

  def mount(_params, session, socket) do
    if connected?(socket), do: InSeasonDraftPick.Store.subscribe()

    %{
      "championship_id" => championship_id,
      "fantasy_league_id" => fantasy_league_id,
      "current_user_id" => current_user_id
    } = session

    socket =
      socket
      |> assign_new(:championship, fn ->
        Championship.Store.get_championship_by_league(
          championship_id,
          fantasy_league_id
        )
      end)
      |> assign_new(:current_user, fn -> User.Store.get_user!(current_user_id) end)
      |> assign_new(:fantasy_league, fn -> FantasyLeague.Store.get(fantasy_league_id) end)

    # need to clear flash from controller so not displayed twice
    socket = clear_flash(socket)

    {:ok, socket}
  end

  def render(assigns) do
    ChampionshipView.render("draft_table.html", assigns)
  end

  def handle_info({"in_season_draft_pick", [:in_season_draft_pick | _], _}, socket) do
    championship =
      Championship.Store.get_championship_by_league(
        socket.assigns.championship.id,
        socket.assigns.fantasy_league.id
      )

    socket = put_flash(socket, :info, "New pick!")

    {:noreply, assign(socket, :championship, championship)}
  end
end
