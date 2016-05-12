Aisleriot
=========

Aisleriot is a collection of patience games written in guile scheme.

This fork contains a couple of commits that add a brute-force game solver to the
Aisleriot UI.

## Compiling / Usage

Aisleriot's makefiles don't use pkg-config to get the required compile flags, so
it's recommended you either provide these yourself via the relevant environment
variables or use the `--with-platform` configure switch.

Assuming you're after this fork particularly, you likely aren't interested in
installing this into your system prefix. But Aisleriot will look in the
configured prefix for the scheme files, so the following setup is recommended:

```
git clone https://github.com/Bob131/aisleriot.git
cd aisleriot
./autogen.sh
./configure --prefix=$HOME/.local --with-platform=gtk-only
make
make install
```

Following this, running `src/sol` should net you an Aisleriot window with an
extra toolbar button.
