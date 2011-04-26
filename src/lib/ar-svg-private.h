/*
   Copyright © 2004 Richard Hoelscher
   Copyright © 2007 Christian Persch
   
   This library is free software; you can redistribute it and'or modify
   it under the terms of the GNU Library General Public License as published 
   by the Free Software Foundation; either version 3, or (at your option)
   any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.  */

/* Authors:   Richard Hoelscher <rah@rahga.com> */

#include <librsvg/rsvg.h>

struct _ArSvg {
  GObject parent;

  RsvgHandle *rsvg_handle;
  cairo_font_options_t *font_options;
  char *filename;

  gint width;
  gint height;
};
