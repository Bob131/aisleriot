using Aisleriot;

class Solver : Object {
    public static bool find_win = false;
    public static bool debug = false;

    public bool quit = false;

    Game game = new Game.get_default();

    Window window = (Window) ((Gtk.Application) Application.get_default())
        .active_window;

    SList<unowned Slot>? foundation;
    SList<unowned Slot>? tableau;
    unowned Slot? stock;

    Queue<int?> moves = new Queue<int?>();

    async bool backtrack() {
        while (true) {
            game.undo_move();
            if (debug)
                Timeout.add(1000, backtrack.callback);
            else
                Idle.add(backtrack.callback);
            yield;

            var index = moves.pop_head();

            if (moves.is_empty())
                return false;

            if (index == null)
                continue;

            if (yield make_move(index + 1))
                return true;
        }
    }

    async bool make_move(int index = 0) {
        unowned SList<unowned Slot> in_play = tableau;
        unowned SList<unowned Slot> founder = foundation;
        if ((in_play == null || in_play.data == null)
                || (founder == null || founder.data == null))
            return false;

        (unowned Slot)[] available_choices = {};

        while (true) {
            if (!(in_play.data in available_choices) &&
                    game.drop_valid(in_play.data, founder.data))
                available_choices += in_play.data;
            founder = founder.next;
            if (founder == null) {
                founder = foundation;
                in_play = in_play.next;
                if (in_play == null)
                    break;
            }
        }

        if (debug) {
            if (available_choices.length > 1)
                foreach (var choice in available_choices) {
                    window.board.selection_slot = choice;
                    Timeout.add(500, make_move.callback);
                    yield;
                }

            window.board.selection_slot = null;
            Timeout.add(200, make_move.callback);
            yield;
        }

        if (available_choices.length > index) {
            if (debug) {
                window.board.selection_slot = available_choices[index];
                Timeout.add(2000, make_move.callback);
                yield;
            }
            game.activate(available_choices[index]);
            moves.push_head(index);
            return true;
        }

        if (game.can_deal) {
            if (debug) {
                window.board.selection_slot = stock;
                Timeout.add(2000, make_move.callback);
                yield;
            }
            game.deal_cards();
            moves.push_head(null);
            return true;
        }

        return false;
    }

    public async void solver_loop() {
        var cont = true;
        while (cont && !quit) {
            Idle.add(solver_loop.callback);
            yield;

            yield make_move();

            if (game.state == GameState.WON)
                return;

            if (game.state == GameState.OVER)
                if (!moves.is_empty())
                    cont = yield backtrack();
                else
                    cont = false;

            if (!cont && find_win) {
                message("Game lost, starting anew");
                cont = true;
                game.new_game();
            }
        }
    }

    ulong window_state_signal;

    ~Solver() {
        if (window_state_signal != 0)
            SignalHandler.unblock(game, window_state_signal);
        if (game.state >= GameState.OVER)
            game.notify_property("state");
    }

    public Solver() {
        Object();

        window_state_signal = SignalHandler.find(game,
            SignalMatchType.ID|SignalMatchType.DETAIL,
            Signal.lookup("notify", typeof(Game)), Quark.from_string("state"),
            null, null, null);
        if (window_state_signal != 0)
            SignalHandler.block(game, window_state_signal);

        window.destroy.connect(() => {quit = true;});

        game.game_new.connect(() => {
            foundation = null;
            tableau = null;
            stock = null;

            foreach (unowned Slot slot in game.slots.data)
                switch (slot.type) {
                    case SlotType.FOUNDATION:
                        foundation.prepend(slot);
                        break;
                    case SlotType.TABLEAU:
                        tableau.prepend(slot);
                        break;
                    case SlotType.STOCK:
                        // this will probably break for most games
                        assert (stock == null);
                        stock = slot;
                        break;
                }

            GLib.debug("Foundation slots found: %u", foundation.length());
            GLib.debug("Tableau slots found: %u", tableau.length());
        });

        game.game_new();
    }
}

Solver? instance = null;

public void solve_cb(Gtk.ToggleAction action) {
    if (action.active) {
        assert (instance == null);
        instance = new Solver();
        instance.solver_loop.begin(() => {
            action.active = false;
        });
    } else {
        assert (instance != null);
        ((!) instance).quit = true;
        instance = null;
    }
}

public void debug_solver_cb(Gtk.ToggleAction action) {
    Solver.debug = action.active;
}

public void solve_until_win_cb(Gtk.ToggleAction action) {
    Solver.find_win = action.active;
}
