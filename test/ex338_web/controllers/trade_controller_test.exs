defmodule Ex338Web.TradeControllerTest do
  use Ex338Web.ConnCase

  import Swoosh.TestAssertions

  alias Ex338.{Trade, TradeVote}

  setup %{conn: conn} do
    user = %Ex338.User{name: "test", email: "test@example.com", id: 1}
    {:ok, conn: assign(conn, :current_user, user), user: user}
  end

  describe "index/2" do
    test "lists all trades in a league", %{conn: conn} do
      player = insert(:fantasy_player)

      league = insert(:fantasy_league)
      team_a = insert(:fantasy_team, team_name: "Brown", fantasy_league: league)
      team_b = insert(:fantasy_team, team_name: "Axel", fantasy_league: league)
      trade = insert(:trade)

      insert(
        :trade_line_item,
        trade: trade,
        gaining_team: team_a,
        losing_team: team_b,
        fantasy_player: player
      )

      other_league = insert(:fantasy_league)

      team_c =
        insert(
          :fantasy_team,
          team_name: "Another Team",
          fantasy_league: other_league
        )

      team_d =
        insert(
          :fantasy_team,
          team_name: "Other Team",
          fantasy_league: other_league
        )

      other_trade = insert(:trade)

      insert(
        :trade_line_item,
        trade: other_trade,
        gaining_team: team_c,
        losing_team: team_d,
        fantasy_player: player
      )

      conn = get(conn, fantasy_league_trade_path(conn, :index, league.id))

      assert html_response(conn, 200) =~ ~r/Trades/
      assert String.contains?(conn.resp_body, team_a.team_name)
      assert String.contains?(conn.resp_body, team_b.team_name)
      assert String.contains?(conn.resp_body, player.player_name)
      refute String.contains?(conn.resp_body, team_c.team_name)
    end
  end

  describe "new/2" do
    test "renders a form to submit a trade", %{conn: conn} do
      league = insert(:fantasy_league)

      team = insert(:fantasy_team, fantasy_league: league)
      insert(:owner, fantasy_team: team, user: conn.assigns.current_user)
      player_a = insert(:fantasy_player)
      insert(:roster_position, fantasy_player: player_a, fantasy_team: team)

      team_b = insert(:fantasy_team, fantasy_league: league)
      player_b = insert(:fantasy_player)
      insert(:roster_position, fantasy_player: player_b, fantasy_team: team_b)

      conn = get(conn, fantasy_team_trade_path(conn, :new, team.id))

      assert html_response(conn, 200) =~ ~r/Submit New Trade/
      assert String.contains?(conn.resp_body, team.team_name)
    end

    test "redirects to root if user is not owner", %{conn: conn} do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      player_a = insert(:fantasy_player)
      _player_b = insert(:fantasy_player)
      insert(:roster_position, fantasy_player: player_a, fantasy_team: team)

      conn = get(conn, fantasy_team_trade_path(conn, :new, team.id))

      assert html_response(conn, 302) =~ ~r/redirected/
    end
  end

  describe "create/2" do
    test "creates a trade & trade vote and redirects", %{conn: conn} do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      insert(:owner, fantasy_team: team, user: conn.assigns.current_user)
      team_b = insert(:fantasy_team, fantasy_league: league)
      sport = insert(:sports_league)
      insert(:league_sport, fantasy_league: league, sports_league: sport)
      insert(:championship, sports_league: sport)
      player_a = insert(:fantasy_player, sports_league: sport)
      player_b = insert(:fantasy_player, sports_league: sport)
      player_c = insert(:fantasy_player, sports_league: sport)
      player_d = insert(:fantasy_player, sports_league: sport)
      insert(:roster_position, fantasy_player: player_a, fantasy_team: team)
      insert(:roster_position, fantasy_player: player_b, fantasy_team: team_b)
      insert(:roster_position, fantasy_player: player_c, fantasy_team: team)
      insert(:roster_position, fantasy_player: player_d, fantasy_team: team_b)

      attrs = %{
        "additional_terms" => "more",
        "trade_line_items" => %{
          "0" => %{
            "fantasy_player_id" => player_a.id,
            "gaining_team_id" => team_b.id,
            "losing_team_id" => team.id
          },
          "1" => %{
            "fantasy_player_id" => player_b.id,
            "gaining_team_id" => team.id,
            "losing_team_id" => team_b.id
          },
          "2" => %{
            "fantasy_player_id" => player_c.id,
            "gaining_team_id" => team_b.id,
            "losing_team_id" => team.id
          },
          "3" => %{
            "fantasy_player_id" => player_d.id,
            "gaining_team_id" => team.id,
            "losing_team_id" => team_b.id
          }
        }
      }

      conn = post(conn, fantasy_team_trade_path(conn, :create, team.id, trade: attrs))

      %{status: status, trade_line_items: line_items} =
        Trade
        |> Trade.preload_assocs()
        |> Repo.one!()

      trade_vote = Repo.one!(TradeVote)

      assert redirected_to(conn) == fantasy_team_path(conn, :show, team.id)
      assert status == "Proposed"
      assert Enum.count(line_items) == 4
      assert_email_sent(subject: "#{team.team_name} proposed a 338 trade")
      assert trade_vote.fantasy_team_id == team.id
      assert trade_vote.approve == true
    end

    test "redirects to root if user is not owner", %{conn: conn} do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      team_b = insert(:fantasy_team, fantasy_league: league)
      player_a = insert(:fantasy_player)
      player_b = insert(:fantasy_player)
      player_c = insert(:fantasy_player)
      player_d = insert(:fantasy_player)
      insert(:roster_position, fantasy_player: player_a, fantasy_team: team)
      insert(:roster_position, fantasy_player: player_b, fantasy_team: team_b)
      insert(:roster_position, fantasy_player: player_c, fantasy_team: team)
      insert(:roster_position, fantasy_player: player_d, fantasy_team: team_b)

      attrs = %{
        "additional_terms" => "more",
        "trade_line_items" => %{
          "0" => %{
            "fantasy_player_id" => player_a.id,
            "gaining_team_id" => team_b.id,
            "losing_team_id" => team.id
          },
          "1" => %{
            "fantasy_player_id" => player_b.id,
            "gaining_team_id" => team.id,
            "losing_team_id" => team_b.id
          },
          "2" => %{
            "fantasy_player_id" => player_c.id,
            "gaining_team_id" => team_b.id,
            "losing_team_id" => team.id
          },
          "3" => %{
            "fantasy_player_id" => player_d.id,
            "gaining_team_id" => team.id,
            "losing_team_id" => team_b.id
          }
        }
      }

      conn = post(conn, fantasy_team_trade_path(conn, :create, team.id, trade: attrs))

      assert html_response(conn, 302) =~ ~r/redirected/
    end
  end

  describe "update/2" do
    test "processes an approved trade", %{conn: conn} do
      conn = put_in(conn.assigns.current_user.admin, true)
      league = insert(:fantasy_league)

      team_a = insert(:fantasy_team, fantasy_league: league)
      player_a = insert(:fantasy_player)
      insert(:roster_position, fantasy_team: team_a, fantasy_player: player_a)

      team_b = insert(:fantasy_team, fantasy_league: league)
      player_b = insert(:fantasy_player)
      insert(:roster_position, fantasy_team: team_b, fantasy_player: player_b)

      trade = insert(:trade, status: "Pending", submitted_by_team: team_a)

      insert(
        :trade_line_item,
        gaining_team: team_b,
        losing_team: team_a,
        fantasy_player: player_a,
        trade: trade
      )

      insert(
        :trade_line_item,
        gaining_team: team_a,
        losing_team: team_b,
        fantasy_player: player_b,
        trade: trade
      )

      params = %{"trade" => %{"status" => "Approved"}}

      conn =
        patch(
          conn,
          fantasy_team_trade_path(
            conn,
            :update,
            team_a.id,
            trade.id,
            params
          )
        )

      assert redirected_to(conn) ==
               fantasy_league_trade_path(conn, :index, team_a.fantasy_league_id)

      assert Repo.get!(Trade, trade.id).status == "Approved"
    end

    test "returns error if position is missing", %{conn: conn} do
      conn = put_in(conn.assigns.current_user.admin, true)
      league = insert(:fantasy_league)

      team_a = insert(:fantasy_team, fantasy_league: league)
      player_a = insert(:fantasy_player)
      insert(:roster_position, fantasy_team: team_a, fantasy_player: player_a)

      team_b = insert(:fantasy_team, fantasy_league: league)
      player_b = insert(:fantasy_player)
      insert(:roster_position, fantasy_team: team_b, fantasy_player: player_b, status: "dropped")

      trade = insert(:trade, status: "Pending", submitted_by_team: team_a)

      insert(
        :trade_line_item,
        gaining_team: team_b,
        losing_team: team_a,
        fantasy_player: player_a,
        trade: trade
      )

      insert(
        :trade_line_item,
        gaining_team: team_a,
        losing_team: team_b,
        fantasy_player: player_b,
        trade: trade
      )

      params = %{"trade" => %{"status" => "Approved"}}

      conn =
        patch(
          conn,
          fantasy_team_trade_path(
            conn,
            :update,
            team_a.id,
            trade.id,
            params
          )
        )

      assert redirected_to(conn) ==
               fantasy_league_trade_path(conn, :index, team_a.fantasy_league_id)

      assert get_flash(conn, :error) == "\"One or more positions not found\""
      assert Repo.get!(Trade, trade.id).status == "Pending"
    end

    test "redirects to root if user is not admin and status is Approved", %{conn: conn} do
      league = insert(:fantasy_league)

      team_a = insert(:fantasy_team, fantasy_league: league)
      insert(:owner, fantasy_team: team_a, user: conn.assigns.current_user)

      trade = insert(:trade, status: "Pending", submitted_by_team: team_a)

      params = %{"trade" => %{"status" => "Approved"}}

      conn =
        patch(
          conn,
          fantasy_team_trade_path(
            conn,
            :update,
            team_a.id,
            trade.id,
            params
          )
        )

      assert redirected_to(conn) == "/"
    end

    test "processes a canceled trade", %{conn: conn} do
      league = insert(:fantasy_league)

      team_a = insert(:fantasy_team, fantasy_league: league)
      insert(:owner, fantasy_team: team_a, user: conn.assigns.current_user)

      trade = insert(:trade, status: "Proposed", submitted_by_team: team_a)

      params = %{"trade" => %{"status" => "Canceled"}}

      conn =
        patch(
          conn,
          fantasy_team_trade_path(
            conn,
            :update,
            team_a.id,
            trade.id,
            params
          )
        )

      assert redirected_to(conn) ==
               fantasy_league_trade_path(conn, :index, team_a.fantasy_league_id)

      assert Repo.get!(Trade, trade.id).status == "Canceled"
      assert_email_sent(subject: "#{team_a.team_name} canceled its proposed 338 trade")
    end

    test "does not processes a canceled trade when already Approved", %{conn: conn} do
      league = insert(:fantasy_league)

      team_a = insert(:fantasy_team, fantasy_league: league)
      insert(:owner, fantasy_team: team_a, user: conn.assigns.current_user)

      trade = insert(:trade, status: "Approved", submitted_by_team: team_a)

      params = %{"trade" => %{"status" => "Canceled"}}

      conn =
        patch(
          conn,
          fantasy_team_trade_path(
            conn,
            :update,
            team_a.id,
            trade.id,
            params
          )
        )

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) == "Can only update a proposed trade"
      assert Repo.get!(Trade, trade.id).status == "Approved"
    end

    test "does not processes a canceled trade when user not owner or admin", %{conn: conn} do
      league = insert(:fantasy_league)

      team_a = insert(:fantasy_team, fantasy_league: league)
      player_a = insert(:fantasy_player)
      insert(:roster_position, fantasy_team: team_a, fantasy_player: player_a)

      team_b = insert(:fantasy_team, fantasy_league: league)
      player_b = insert(:fantasy_player)
      insert(:roster_position, fantasy_team: team_b, fantasy_player: player_b)

      trade = insert(:trade, status: "Proposed", submitted_by_team: team_a)

      insert(
        :trade_line_item,
        gaining_team: team_b,
        losing_team: team_a,
        fantasy_player: player_a,
        trade: trade
      )

      insert(
        :trade_line_item,
        gaining_team: team_a,
        losing_team: team_b,
        fantasy_player: player_b,
        trade: trade
      )

      params = %{"trade" => %{"status" => "Canceled"}}

      conn =
        patch(
          conn,
          fantasy_team_trade_path(
            conn,
            :update,
            team_a.id,
            trade.id,
            params
          )
        )

      assert redirected_to(conn) == "/"

      assert Repo.get!(Trade, trade.id).status == "Proposed"
    end
  end
end
