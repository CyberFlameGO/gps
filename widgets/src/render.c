/*********************************************************************
 *                               G P S                               *
 *                                                                   *
 *                         Copyright (C) 2007                        *
 *                              AdaCore                              *
 *                                                                   *
 * GPS is free  software;  you can redistribute it and/or modify  it *
 * under the terms of the GNU General Public License as published by *
 * the Free Software Foundation; either version 2 of the License, or *
 * (at your option) any later version.                               *
 *                                                                   *
 * This program is  distributed in the hope that it will be  useful, *
 * but  WITHOUT ANY WARRANTY;  without even the  implied warranty of *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU *
 * General Public License for more details. You should have received *
 * a copy of the GNU General Public License along with this program; *
 * if not,  write to the  Free Software Foundation, Inc.,  59 Temple *
 * Place - Suite 330, Boston, MA 02111-1307, USA.                    *
 *********************************************************************/

#ifndef _WIN32

#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <cairo-xlib.h>

int
gps_have_render (GdkDrawable *drawable)
{
  int event_base, error_base;

  if (drawable != NULL)
    return XRenderQueryExtension
      (GDK_DISPLAY_XDISPLAY (gdk_drawable_get_display (drawable)),
       &event_base, &error_base);
  else
    return 1;
}

#endif
