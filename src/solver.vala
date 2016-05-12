using Aisleriot;

class Solver : Object {
    public Game game {construct; get;}

    ulong window_state_signal;

    List<unowned Slot>? foundation;
    List<unowned Slot>? tableau;

    void make_play() {
        unowned List<unowned Slot> in_play = tableau;
        unowned List<unowned Slot> founder = foundation;
        if ((in_play == null || in_play.data == null)
                || (founder == null || founder.data == null))
            return;

        var success = false;
        while (!success) {
            if (game.drop_valid(in_play.data, founder.data))
                success = game.activate(in_play.data);
            founder = founder.next;
            if (founder == null) {
                founder = foundation;
                in_play = in_play.next;
                if (in_play == null)
                    break;
            }
        }
        if (!success && game.can_deal)
            game.deal_cards();
    }

    void populate_lists() {
        foreach (unowned Slot slot in game.slots.data) {
            if (slot.type == SlotType.FOUNDATION)
                foundation.prepend(slot);
            else if (slot.type == SlotType.TABLEAU)
                tableau.prepend(slot);
        }

        debug("Foundation slots found: %u", foundation.length());
        debug("Tableau slots found: %u", tableau.length());
    }

    ~Solver() {
        if (window_state_signal != 0)
            SignalHandler.unblock(game, window_state_signal);
        if (game.state >= GameState.OVER)
            game.notify_property("state");
    }

    public Solver(bool find_win = false) {
        Object(game: get_app_game());

        window_state_signal = SignalHandler.find(game,
            SignalMatchType.ID|SignalMatchType.DETAIL,
            Signal.lookup("notify", typeof(Game)), Quark.from_string("state"),
            null, null, null);
        if (window_state_signal != 0)
            SignalHandler.block(game, window_state_signal);

        game.game_cleared.connect(() => {
            foundation = null;
            tableau = null;
        });

        populate_lists();

        Idle.add(() => {
            make_play();
            if (game.state == GameState.OVER && find_win) {
                game.new_game();
                populate_lists();
            }
            // if find_win is true, keep going until GameState.WON
            return game.state < GameState.OVER + (int) find_win;
        });
    }
}

public void solve_cb() {
    new Solver();
}
