defmodule Ex338Web.WaiverViewTest do
  use Ex338Web.ConnCase, async: true
  alias Ex338.{CalendarAssistant}
  alias Ex338Web.{WaiverView}

  describe "sort_most_recent/1" do
    test "returns struct sorted by most recent first" do
      waivers = [
        %{
          fantasy_team: "a",
          process_at: CalendarAssistant.days_from_now(-5)
        },
        %{
          fantasy_team: "c",
          process_at: CalendarAssistant.days_from_now(-1)
        },
        %{
          fantasy_team: "b",
          process_at: CalendarAssistant.days_from_now(-3)
        }
      ]

      result = WaiverView.sort_most_recent(waivers)

      assert Enum.map(result, & &1.fantasy_team) == ["c", "b", "a"]
    end
  end

  describe "after_now?/1" do
    test "returns true if date is after now" do
      three_days_from_now = CalendarAssistant.days_from_now(3)

      result = WaiverView.after_now?(three_days_from_now)

      assert result == true
    end

    test "returns false if date is before now" do
      three_days_before_now = CalendarAssistant.days_from_now(-3)

      result = WaiverView.after_now?(three_days_before_now)

      assert result == false
    end
  end

  describe "display_name/1" do
    test "hides name if sport is hiding waiver claims" do
      player = %{player_name: "Michigan", sports_league: %{hide_waivers: true}}

      result = WaiverView.display_name(player)

      assert result == "*****"
    end

    test "displays name if sport is not hiding waiver claims" do
      player = %{player_name: "Michigan", sports_league: %{hide_waivers: false}}

      result = WaiverView.display_name(player)

      assert result == "Michigan"
    end
  end
end
