using Aisleriot;

class Solver : Object {
    public Game game {construct; get;}

    ulong window_state_signal;

    SList<unowned Slot>? foundation;
    SList<unowned Slot>? tableau;

    Queue<int?> moves = new Queue<int?>();

    bool backtrack() {
        while (true) {
            message("backtrack");
            game.undo_move();
            var index = moves.pop_head();

            if (moves.is_empty())
                return false;

            if (index == null)
                continue;

            if (make_play(index + 1))
                return true;
        }
    }

    bool make_play(int index = 0) {
        unowned SList<unowned Slot> in_play = tableau;
        unowned SList<unowned Slot> founder = foundation;
        if ((in_play == null || in_play.data == null)
                || (founder == null || founder.data == null))
            return false;

        (unowned Slot)[] available_choices = {};

        while (true) {
            if (game.drop_valid(in_play.data, founder.data))
                available_choices += in_play.data;
            founder = founder.next;
            if (founder == null) {
                founder = foundation;
                in_play = in_play.next;
                if (in_play == null)
                    break;
            }
        }

        message("index: %d, avail: %d", index, available_choices.length);

        if (available_choices.length > index) {
            message("move");
            game.activate(available_choices[index]);
            moves.push_head(index);
            return true;
        }

        // are we missing solutions here?
        if (game.can_deal && index == 0) {
            message("deal");
            game.deal_cards();
            moves.push_head(null);
            return true;
        }

        message("fail");

        return false;
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
            if (game.state == GameState.OVER)
                if (!moves.is_empty())
                    return backtrack();
                else if (find_win) {
                    game.new_game();
                    populate_lists();
                } else
                    return false;
            return true;
        });
    }
}

public void solve_cb() {
    new Solver();
}
