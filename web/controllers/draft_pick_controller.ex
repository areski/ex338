defmodule Ex338.DraftPickController do
  use Ex338.Web, :controller

  alias Ex338.{FantasyLeague, DraftPick, DraftPickAdmin, FantasyPlayer,
               NotificationEmail, Mailer, Owner}

  def index(conn, %{"fantasy_league_id" => league_id}) do
    fantasy_league = FantasyLeague |> Repo.get(league_id)

    draft_picks = DraftPick
                  |> FantasyLeague.by_league(league_id)
                  |> preload([:fantasy_league, :fantasy_team,
                             [fantasy_player: :sports_league]])
                  |> DraftPick.ordered_by_position
                  |> Repo.all

    render(conn, "index.html", fantasy_league: fantasy_league,
                               draft_picks: draft_picks)
  end

  def edit(conn, %{"id" => id}) do
    draft_pick = DraftPick
                 |> preload([:fantasy_team])
                 |> Repo.get!(id)

    players = FantasyPlayer.available_players(draft_pick.fantasy_league_id)
                      |> Repo.all
                      |> FantasyPlayer.format_players_for_select

    changeset = DraftPick.changeset(draft_pick)

    render(conn, "edit.html", draft_pick: draft_pick,
                              fantasy_players: players,
                              changeset: changeset)
  end

  def update(conn, %{"id" => id, "draft_pick" => params}) do
    draft_pick = DraftPick
                 |> preload([:fantasy_team])
                 |> Repo.get!(id)

    result = draft_pick
             |> DraftPickAdmin.draft_player(params)
             |> Repo.transaction

    case result do
      {:ok,  %{draft_pick: draft_pick}} ->
        conn
        |> email_notification(draft_pick)
        |> put_flash(:info, "Draft pick successfully submitted.")
        |> redirect(to: fantasy_league_draft_pick_path(conn, :index,
                    draft_pick.fantasy_league_id))
      {:error, _, changeset, _} ->
        players = FantasyPlayer.available_players(draft_pick.fantasy_league_id)
                  |> Repo.all
                  |> FantasyPlayer.format_players_for_select

        render(conn, "edit.html", draft_pick: draft_pick,
                                  fantasy_players: players,
                                  changeset: changeset)
    end
  end

  defp email_notification(conn, %{fantasy_league_id: id}) do
    league = FantasyLeague |> Repo.get(id)
    emails = Owner |> Owner.email_recipients_for_league(id) |> Repo.all
    last_picks = DraftPick |> DraftPick.last_picks(id) |> Repo.all
    next_picks = DraftPick |> DraftPick.next_picks(id) |> Repo.all

    NotificationEmail.draft_update(conn, league, last_picks, next_picks, emails)
      |> Mailer.deliver
      |> case do
        {:ok, _result} ->
          conn
        {:error, _reason} ->
          conn
      end
  end
end