namespace Aisleriot {
    [CCode (cname = "ArSlotType", cprefix = "AR_SLOT_", has_type_id = false)]
    public enum SlotType {
        UNKNOWN,
        CHOOSER,
        FOUNDATION,
        RESERVE,
        STOCK,
        TABLEAU,
        WASTE
    }

    [Compact]
    [CCode (cname = "ArSlot", cprefix = "ar_slot_")]
    public class Slot {
        public int id;
        [CCode (cname = "type")]
        SlotType _type;
        GLib.ByteArray cards;
        uint exposed;

        public SlotType type {
            [CCode (cname = "ar_slot_get_slot_type")]
            get;
        }

        public Card[] exposed_cards {owned get {
            if (cards == null || cards.len < 1)
                return {Card((uint8) 0-1)};
            Card[] ret = {};
            foreach (var card in cards.data[cards.len - exposed : cards.len])
                ret += Card(card);
            return ret;
        }}
    }


    [CCode (cprefix = "GAME_")]
    public enum GameState {
        UNINITIALISED,
        LOADED,
        BEGIN,
        RUNNING,
        OVER,
        WON,
        [CCode (cprefix = "")]
        LAST_GAME_STATE
    }

    public class Game : GLib.Object {
        public GLib.GenericArray<Slot> slots {get;}
        public string game_module {get;}
        public GameState state {get;}
        public bool can_deal {get {
            var ret = GLib.Value(typeof(bool));
            this.get_property("can-deal", ref ret);
            return (bool) ret;
        }}

        unowned string get_score();
        public int score {
            [CCode (cname = "aisleriot_game_get_score_wrapper")]
            get {
                return int.parse(get_score());
            }}

        public void deal_cards();
        public void new_game();

        public signal void game_new();

        [CCode (cname = "aisleriot_game_drop_valid")]
        private bool _drop_valid(int start_slot, int end_slot, Card[] cards);
        [CCode (cname = "aisleriot_game_drop_valid_wrapper")]
        public bool drop_valid(Slot start, Slot end) {
            return _drop_valid(start.id, end.id, start.exposed_cards);
        }

        public void undo_move();
        private void record_move(int slot_id, uint8[]? cards);
        private void end_move();
        private void discard_move();

        private bool button_double_clicked_lambda(int slot_id);
        private void test_end_of_game();

        public bool activate(Slot slot) {
            record_move(-1, null);
            var ret = button_double_clicked_lambda(slot.id);
            if (ret)
                end_move();
            else
                discard_move();
            test_end_of_game();
            return ret;
        }

        public Game.get_default();
    }
}
