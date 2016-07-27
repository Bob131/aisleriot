namespace Aisleriot {
    [CCode (cname = "Card")]
    [SimpleType]
    public struct Card {
        [CCode (cname = "value")]
        public uint8 @value;
        [CCode (cname = "ar_card_get_locale_name")]
        public unowned string to_string();

        [CCode (cname = "CARD")]
        public Card(uint8 c);
    }
}
