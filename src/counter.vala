public class Aisleriot.Counter : Gtk.Box {
    public uint count {private set; get;}

    public Counter() {
        Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 12);

        this.add(new Gtk.Label("Games played:"));

        var display = new Gtk.Label("0");
        this.notify["count"].connect(() => {
            display.label = count.to_string();
        });
        this.add(display);

        ulong game_signal = 0;

        this.show.connect(() => {
            this.show_all(); // show children

            count = 1;

            assert (game_signal == 0);
            var game = new Game.get_default();
            game_signal = game.game_new.connect(() => {count++;});
        });

        this.hide.connect(() => {
            assert (game_signal > 0);
            var game = new Game.get_default();
            game.disconnect(game_signal);
            game_signal = 0;
        });
    }
}
