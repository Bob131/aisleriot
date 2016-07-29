namespace Aisleriot {
    [CCode (cname = "ArClock", cprefix = "ar_clock_")]
    public class Clock : Gtk.Label {
        public time_t seconds {get;}

        public void start();
        public void stop();
        public void reset();
        public string to_string();
    }
}
