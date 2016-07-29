using Aisleriot;

class QueueWrap : Object {
    Queue<int?> q = new Queue<int?>();

    public bool empty {get {return q.is_empty();}}

    public signal void changed();

    public void push(int? val) {
        changed();
        q.push_head(val);
    }

    public int? pop() {
        changed();
        return q.pop_head();
    }
}

class Solver : Object {
    public static bool find_win = false;
    public static bool debug = false;

    public bool quit = false;

    public Game game = new Game.get_default();

    public Window window =
        (Window) ((Gtk.Application) Application.get_default()).active_window;

    SList<unowned Slot>? foundation;
    SList<unowned Slot>? tableau;
    unowned Slot? stock;

    QueueWrap moves = new QueueWrap();

    async bool backtrack() {
        while (true) {
            game.undo_move();
            if (debug)
                Timeout.add(1000, backtrack.callback);
            else
                Idle.add(backtrack.callback);
            yield;

            var index = moves.pop();

            if (moves.empty)
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
            moves.push(index);
            return true;
        }

        if (game.can_deal) {
            if (debug) {
                window.board.selection_slot = stock;
                Timeout.add(2000, make_move.callback);
                yield;
            }
            game.deal_cards();
            moves.push(null);
            return true;
        }

        return false;
    }

    public async void solver_loop() {
        window.clock.start();

        window.counter.show();

        uint64 moves_made = 0;
        moves.changed.connect(() => {moves_made++;});

        int[] scores = {0};

        var cont = true;
        while (cont && !quit) {
            Idle.add(solver_loop.callback);
            yield;

            yield make_move();

            if (game.score > scores[scores.length - 1])
                scores[scores.length - 1] = game.score;

            if (game.state == GameState.WON)
                break;

            if (game.state == GameState.OVER)
                if (!moves.empty)
                    cont = yield backtrack();
                else
                    cont = false;

            if (!cont && find_win) {
                cont = true;
                game.new_game();
                scores += 0;
            }
        }

        show_results_dialog(moves_made, scores);
    }

    int align = 0;
    [PrintfFormat]
    Gtk.Label label(string format, ...) {
        // toggle between start/end
        align++;
        align %= 2;

        var ret = new Gtk.Label(format.vprintf(va_list()));
        // add one since Gtk.Align[0] is FILL
        ret.halign = (Gtk.Align) align + 1;
        return ret;
    }

    void show_results_dialog(uint64 moves_made, int[] scores) {
        window.clock.stop();

        var table = new Gtk.Grid();
        table.column_spacing = 6;

        table.attach(label("Run time:"), 0, 1);
        table.attach(label(window.clock.to_string()), 1, 1);

        table.attach(label("Games played:"), 0, 2);
        table.attach(label("%u", window.counter.count), 1, 2);
        window.counter.hide();

        table.attach(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), 0, 3, 2);

        table.attach(label("Moves per second:"), 0, 4);
        table.attach(label("%llu", moves_made / window.clock.seconds), 1, 4);

        table.attach(label("Average game length:"), 0, 5);
        table.attach(label("%us",
            (uint) window.clock.seconds / window.counter.count), 1, 5);

        table.attach(label("Average game score:"), 0, 6);
        var sum = 0;
        foreach (var score in scores)
            sum += score;
        table.attach(label("%d", sum / scores.length), 1, 6);

        window.clock.reset();

        var dialog = new Gtk.MessageDialog.with_markup(window,
            Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.CLOSE,
            "<b>%s</b>", game.state == GameState.WON ?
                "Solution found!" :
                "No solution found");
        ((Gtk.Box) dialog.message_area).add(table);
        dialog.response.connect(() => {dialog.close();});
        dialog.show_all();
    }

    ulong window_state_signal;
    ulong window_g_new_signal;

    ~Solver() {
        if (window_state_signal != 0)
            SignalHandler.unblock(game, window_state_signal);
        if (window_g_new_signal != 0)
            SignalHandler.unblock(game, window_g_new_signal);
    }

    public Solver() {
        Object();

        window_state_signal = SignalHandler.find(game,
            SignalMatchType.ID|SignalMatchType.DETAIL,
            Signal.lookup("notify", typeof(Game)), Quark.from_string("state"),
            null, null, null);
        if (window_state_signal != 0)
            SignalHandler.block(game, window_state_signal);

        window_g_new_signal = SignalHandler.find(game,
            SignalMatchType.ID|SignalMatchType.DATA,
            Signal.lookup("game-new", typeof(Game)), (Quark) null, null, null,
            window);
        if (window_g_new_signal != 0)
            SignalHandler.block(game, window_g_new_signal);

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
