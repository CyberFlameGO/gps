-----------------------------------------------------------------------
--                                GPS                                --
--                                                                   --
--                     Copyright (C) 2001-2002                       --
--                            ACT-Europe                             --
--                                                                   --
-- GPS is  free software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with Glib;
with Gdk.Color;
with Gdk.Event;
with Gdk.GC;
with Gdk.Pixbuf;
with Gdk.Rectangle;
with Gdk.Window;
with Gtkada.Canvas;
with Glide_Kernel;
with Glib.Object;
with Gtk.Box;
with Gtk.Hbutton_Box;
with Gtk.Menu;
with Gtk.Widget;
with Pango.Layout;
with Ada.Unchecked_Deallocation;

package Browsers.Canvas is

   Margin : constant := 2;
   --  Margin used when drawing the items, to leave space around the arrows and
   --  the actual contents of the item

   type General_Browser_Record is new Gtk.Box.Gtk_Box_Record with private;
   type General_Browser is access all General_Browser_Record'Class;

   type Browser_Link_Record is new Gtkada.Canvas.Canvas_Link_Record
     with private;
   type Browser_Link is access all Browser_Link_Record'Class;
   --  The type of links that are put in the canvas. These are automatically
   --  highlighted if they connect a selected item to another one.

   procedure Initialize
     (Browser : access General_Browser_Record'Class;
      Kernel  : access Glide_Kernel.Kernel_Handle_Record'Class;
      Create_Toolbar : Boolean);
   --  Initialize a new browser.
   --  It sets up all the contextual menu for this browser, as well as the key
   --  shortcuts to manipulate the browser.
   --  If Create_Toolbar is True, then a button_bar is added at the bottom.

   function Get_Toolbar (Browser : access General_Browser_Record)
      return Gtk.Hbutton_Box.Gtk_Hbutton_Box;
   --  Return the toolbar at the bottom of the browser. This returns null if no
   --  toolbar was created in the call to Initialize.

   procedure Setup_Default_Toolbar (Browser : access General_Browser_Record);
   --  Add the default buttons to the toolbar of browser. Nothing is done if no
   --  toolbar was created.

   function Get_Canvas (Browser : access General_Browser_Record)
      return Gtkada.Canvas.Interactive_Canvas;
   --  Return the canvas embedded in Browser

   function Get_Kernel (Browser : access General_Browser_Record)
      return Glide_Kernel.Kernel_Handle;
   --  Return the kernel associated with the browser

   function To_Brower
     (Canvas : access Gtkada.Canvas.Interactive_Canvas_Record'Class)
      return General_Browser;
   --  Return the browser that contains Canvas.

   function Selected_Item (Browser : access General_Browser_Record)
      return Gtkada.Canvas.Canvas_Item;
   --  Return the currently selected item, or null if there is none.

   procedure Select_Item
     (Browser : access General_Browser_Record;
      Item    : access Gtkada.Canvas.Canvas_Item_Record'Class);
   --  Select Item. By default, no visual feedback is provided.

   procedure Unselect_All (Browser : access General_Browser_Record);
   --  Unselect all items

   procedure Highlight_Item_And_Siblings
     (Browser : access General_Browser_Record;
      Item    : access Gtkada.Canvas.Canvas_Item_Record'Class;
      Old     : Gtkada.Canvas.Canvas_Item := null);
   --  Call Refresh on Item and all its siblings. If the selection status has
   --  changed, this will result in a change of background color for these
   --  items.
   --  If Old is not null, then it is also refreshed along with all its
   --  siblings. This subprogram is optimized so that the items are refreshed
   --  only once.
   --  The item is not selected.
   --  This subprogram should be overriden if the items should not appear
   --  differently when they are selected. You also need to make sure that if
   --  the item is refreshed later on, it isn't drawn with a different
   --  background. Overriding Highlight_Item_And_Siblings is just for
   --  efficiency.

   procedure Layout
     (Browser : access General_Browser_Record;
      Force : Boolean := False);
   --  Recompute the layout of items in the browser.
   --  If Force is true, then even the items that have been moved manually by
   --  the user are recomputed.

   ------------------
   -- Active areas --
   ------------------
   --  The items have a general mechanism to define active areas and nested
   --  active areas. When the user clicks in the item, the appropriate callback
   --  is called. The one chosen is the inner most one.
   --  The callback chosen is undefined if two areas only partially overlap.

   type Active_Area_Callback is abstract tagged null record;
   type Active_Area_Cb is access all Active_Area_Callback'Class;
   function Call (Callback : Active_Area_Callback;
                  Event    : Gdk.Event.Gdk_Event)
     return Boolean is abstract;
   --  A callback for the active areas. Event is the mouse event that started
   --  the chain that lead to callback.
   --  This type provides an easy encapsulation for any user data you might
   --  need.
   --  Should return True if the event was handler, False otherwise. In the
   --  latter case, the even is transmitted to the parent area

   procedure Destroy (Callback : in out Active_Area_Callback);
   --  Destroy the callback

   procedure Unchecked_Free is new Ada.Unchecked_Deallocation
     (Active_Area_Callback'Class, Active_Area_Cb);

   -----------
   -- Items --
   -----------

   type Browser_Item_Record is new Gtkada.Canvas.Buffered_Item_Record
     with private;
   type Browser_Item is access all Browser_Item_Record'Class;
   --  The type of items that are put in the canvas. They are associated with
   --  contextual menus, and also allows hiding the links to and from this
   --  item.

   procedure Initialize
     (Item    : access Browser_Item_Record'Class;
      Browser : access General_Browser_Record'Class);
   --  Associate the item with a browser.

   procedure Set_Title
     (Item : access Browser_Item_Record'Class;  Title : String := "");
   --  Set a title for the item. This is displayed in a special title bar, with
   --  a different background color.
   --  If Title is the empty string, no title bar is shown

   function Contextual_Factory
     (Item  : access Browser_Item_Record;
      Browser : access General_Browser_Record'Class;
      Event : Gdk.Event.Gdk_Event;
      Menu  : Gtk.Menu.Gtk_Menu) return Glide_Kernel.Selection_Context_Access;
   --  Return the selection context to use when an item is clicked on.
   --  The coordinates in Event are relative to the upper-left corner of the
   --  item.
   --  If there are specific contextual menu entries that should be used for
   --  this item, they should be added to Menu.
   --  null should be return if there is no special contextual for this
   --  item. In that case, the context for the browser itself will be used.
   --
   --  You shoud make sure that this function can be used with a null event and
   --  a null menu, which is the case when creating a current context for
   --  Glide_Kernel.Get_Current_Context.

   procedure Refresh (Item : access Browser_Item_Record'Class);
   --  Non dispatching variant of the Resize_And_Draw.
   --  You need to refresh the screen by calling either Item_Updated or
   --  Refresh_Canvas.

   function Get_Background_GC
     (Item : access Browser_Item_Record) return Gdk.GC.Gdk_GC;
   --  Return the graphic context to use for the background of the item. This
   --  can be used to draw the selected item with a different color for
   --  instance (the default behavior)

   procedure Resize_And_Draw
     (Item                        : access Browser_Item_Record;
      Width, Height               : Glib.Gint;
      Width_Offset, Height_Offset : Glib.Gint;
      Xoffset, Yoffset            : in out Glib.Gint);
   --  Resize the item, and then redraw it.
   --  The chain of events should be the following:
   --   - Compute the desired size for the item
   --   - Merge it with Width, Height, Width_Offset and Height_Offset.
   --
   --            xoffset
   --     |------|------------------------|------|
   --     |      |    child               |      |
   --     |      |------------------------|      |
   --     |          item                        |
   --     |------|------------------------|------|
   --
   --     Width is the size of the part where the child will be drawn. It
   --     should be computed by taking the maximum of the item's desired size
   --     and the Width parameter
   --     Width_Offset is the total width on each size of the child. It should
   --     be computed by adding the new desired offset to Width_Offset. The
   --     addition to Width_Offset will generally be the same as Xoffset
   --
   --   - Call the parent's Size_Request_And_Draw procedure. This will
   --     ultimately resize the item.
   --   - Draw the item at coordinates Xoffset, Yoffset in the double-buffer.
   --   - Modify Xoffset, Yoffset to the position that a child of item should
   --     be drawn at.

   procedure Draw_Title_Bar_Button
     (Item   : access Browser_Item_Record;
      Num    : Glib.Gint;
      Pixbuf : Gdk.Pixbuf.Gdk_Pixbuf;
      Cb     : Active_Area_Callback'Class);
   --  Draw the nth title bar button. They are numbered from right to left:
   --       |--------------------------|
   --       |  Title         [2][1][0] |
   --       |--------------------------|
   --  You can draw as many buttons as you want. However, make sure you have
   --  reserved enough space (through Get_Last_Button_Number) or the buttons
   --  will override the title itself.  Cb is called when the button is
   --  pressed.
   --
   --  An item should use button numbers from the parent's
   --  Get_Last_Button_Number + 1 upward.
   --
   --  The button (and its callback) will be destroyed the next time
   --  Resize_And_Draw is called for the item.
   --  All buttons are assumed to have the size Gtk.Enums.Icon_Size_Menu.
   --
   --  No button is drawn if no title was set for the item.

   function Get_Last_Button_Number (Item : access Browser_Item_Record)
      return Glib.Gint;
   --  Return the last number of the button set by this item. This function is
   --  used to make sure that no two items set the same button.

   procedure Reset (Browser : access General_Browser_Record'Class;
                    Item : access Browser_Item_Record);
   --  Reset the internal state of the item, as if it had never been expanded,
   --  analyzed,... This is called for instance after the item has been defined
   --  as the root of the canvas (and thus all other items have been removed).
   --  It doesn't need to redraw the item

   function Get_Browser (Item : access Browser_Item_Record'Class)
      return General_Browser;
   --  Return the browser associated with this item

   procedure On_Button_Click
     (Item  : access Browser_Item_Record;
      Event : Gdk.Event.Gdk_Event_Button);
   --  See doc for inherited subprogram

   procedure Add_Active_Area
     (Item      : access Browser_Item_Record;
      Rectangle : Gdk.Rectangle.Gdk_Rectangle;
      Callback  : Active_Area_Callback'Class);
   --  Define a new clickable active area in the item. Callback will be called
   --  whenever the user clicks in Rectangle, provided there is no smaller area
   --  that also contains the click location.

   procedure Activate
     (Item  : access Browser_Item_Record;
      Event : Gdk.Event.Gdk_Event);
   --  Calls the callback that is activated when the user clicks in the
   --  item. The coordinates returned by Get_X and Get_Y in Event should be
   --  relative to the top-left corner of the Item.

   procedure Reset_Active_Areas (Item : access Browser_Item_Record);
   --  Remove all active areas in Item

   ---------------
   -- Item area --
   ---------------

   type Item_Active_Callback is access
     procedure (Event : Gdk.Event.Gdk_Event;
                User : access Browser_Item_Record'Class);
   type Item_Active_Area_Callback is new Active_Area_Callback with private;
   --  A special instanciation of the callback for cases where the user data is
   --  a widget.

   function Build (Cb : Item_Active_Callback;
                   User : access Browser_Item_Record'Class)
      return Item_Active_Area_Callback'Class;
   --  Build a new callback

   ---------------
   -- Text_Item --
   ---------------

   type Text_Item_Record is new Browser_Item_Record with private;
   type Text_Item is access all Text_Item_Record'Class;
   --  A special kind of item that contains some text. The text is displayed as
   --  a single block, centered in the item.

   procedure Initialize
     (Item    : access Text_Item_Record'Class;
      Browser : access General_Browser_Record'Class;
      Text    : String);
   --  Initialize a new item, that displays Text. Text can be a multi-line text

   procedure Set_Text
     (Item    : access Text_Item_Record'Class;
      Text    : String);
   --  Add Text to the current text at the end of the current text. No newline
   --  is appended between the two.
   --  The double-buffer for the item is immediately redrawn, but the item is
   --  not refresh on the screen. You need to call Item_Updated or
   --  Refresh_Canvas for this.

   ---------------------------
   -- Text_Item with arrows --
   ---------------------------
   --  This item is a standard text item, but displays one arrow on each side
   --  of the text. Clicking on any of these arrow triggers a call to one of
   --  the primitive subprograms.

   type Text_Item_With_Arrows_Record is abstract new
     Text_Item_Record with private;
   type Text_Item_With_Arrows is access all Text_Item_With_Arrows_Record'Class;

   function Get_Left_Arrow (Item : access Text_Item_With_Arrows_Record)
      return Boolean;
   --  Return True if the left arrow is displayed for this item

   function Get_Right_Arrow (Item : access Text_Item_With_Arrows_Record)
      return Boolean;
   --  Return True if the right arrow is displayed for this item

   procedure Set_Left_Arrow
     (Item : access Text_Item_With_Arrows_Record; Display : Boolean);
   --  Change the status of the left arrow

   procedure Set_Right_Arrow
     (Item : access Text_Item_With_Arrows_Record; Display : Boolean);
   --  Change the status of the right arrow

   procedure Button_Click_On_Left (Item : access Text_Item_With_Arrows_Record)
      is abstract;
   --  Handles button clicks on the left arrow.
   --  This is not called if you override On_Button_Click

   procedure Button_Click_On_Right (Item : access Text_Item_With_Arrows_Record)
      is abstract;
   --  Handles button clicks on the right arrow
   --  This is not called if you override On_Button_Click

   -----------
   -- Links --
   -----------

   procedure Draw_Link
     (Canvas      : access Gtkada.Canvas.Interactive_Canvas_Record'Class;
      Link        : access Browser_Link_Record;
      Window      : Gdk.Window.Gdk_Window;
      Invert_Mode : Boolean;
      GC          : Gdk.GC.Gdk_GC;
      Edge_Number : Glib.Gint);
   --  Override the drawing of links (so that links can be drawn in different
   --  colors when an item is selected).

   ----------------------
   -- Graphic contexts --
   ----------------------

   function Get_Text_GC
     (Browser : access General_Browser_Record) return Gdk.GC.Gdk_GC;
   --  Return the graphic context to use to draw the text in the items.

   function Get_Default_Item_Background_GC
     (Browser : access General_Browser_Record) return Gdk.GC.Gdk_GC;
   --  Return the default graphic context to use for unselected items'
   --  background.

   ----------------------
   -- Contextual menus --
   ----------------------

   function Default_Browser_Context_Factory
     (Kernel       : access Glide_Kernel.Kernel_Handle_Record'Class;
      Event_Widget : access Gtk.Widget.Gtk_Widget_Record'Class;
      Object       : access Glib.Object.GObject_Record'Class;
      Event        : Gdk.Event.Gdk_Event;
      Menu         : Gtk.Menu.Gtk_Menu)
      return Glide_Kernel.Selection_Context_Access;
   --  Return the context to use for a contextual menu in the canvas.
   --  This version takes care of checking whether the user clicked on an item,
   --  and adds the standard menu entries

private
   type General_Browser_Record is new Gtk.Box.Gtk_Box_Record with record
      Canvas    : Gtkada.Canvas.Interactive_Canvas;
      Kernel    : Glide_Kernel.Kernel_Handle;
      Toolbar   : Gtk.Hbutton_Box.Gtk_Hbutton_Box;

      Selected_Link_Color   : Gdk.Color.Gdk_Color;
      Default_Item_GC       : Gdk.GC.Gdk_GC;
      Selected_Item_GC      : Gdk.GC.Gdk_GC;
      Parent_Linked_Item_GC : Gdk.GC.Gdk_GC;
      Child_Linked_Item_GC  : Gdk.GC.Gdk_GC;
      Text_GC               : Gdk.GC.Gdk_GC;
      Title_GC              : Gdk.GC.Gdk_GC;

      Selected_Item : Gtkada.Canvas.Canvas_Item;

      Close_Pixmap : Gdk.Pixbuf.Gdk_Pixbuf;
      Left_Arrow, Right_Arrow : Gdk.Pixbuf.Gdk_Pixbuf;
   end record;

   type Browser_Link_Record is new Gtkada.Canvas.Canvas_Link_Record
     with null record;

   type Active_Area_Tree_Record;
   type Active_Area_Tree is access Active_Area_Tree_Record;
   type Active_Area_Tree_Array is array (Natural range <>) of Active_Area_Tree;
   type Active_Area_Tree_Array_Access is access Active_Area_Tree_Array;
   type Active_Area_Tree_Record is record
      Rectangle : Gdk.Rectangle.Gdk_Rectangle;
      Callback  : Active_Area_Cb;
      Children  : Active_Area_Tree_Array_Access;
   end record;

   type Browser_Item_Record is new Gtkada.Canvas.Buffered_Item_Record
   with record
      Hide_Links : Boolean := False;
      Browser    : General_Browser;

      Title_Layout : Pango.Layout.Pango_Layout;
      --  Handling of the title bar. No title bar is shown if no title was
      --  set. In this case, Title_Layout is null.

      Active_Areas : Active_Area_Tree;
   end record;

   type Text_Item_Record is new Browser_Item_Record  with
   record
      Layout : Pango.Layout.Pango_Layout;
   end record;

   procedure Resize_And_Draw
     (Item             : access Text_Item_Record;
      Width, Height    : Glib.Gint;
      Width_Offset, Height_Offset : Glib.Gint;
      Xoffset, Yoffset : in out Glib.Gint);
   procedure Destroy (Item : in out Text_Item_Record);
   --  See doc for inherited subprograms

   type Text_Item_With_Arrows_Record is abstract new
     Text_Item_Record with
   record
      Left_Arrow, Right_Arrow : Boolean := True;
   end record;

   procedure Resize_And_Draw
     (Item             : access Text_Item_With_Arrows_Record;
      Width, Height    : Glib.Gint;
      Width_Offset, Height_Offset : Glib.Gint;
      Xoffset, Yoffset : in out Glib.Gint);
   procedure On_Button_Click
     (Item  : access Text_Item_With_Arrows_Record;
      Event : Gdk.Event.Gdk_Event_Button);
   procedure Reset (Browser : access General_Browser_Record'Class;
                    Item : access Text_Item_With_Arrows_Record);
   --  See doc for inherited Reset

   type Item_Active_Area_Callback is new Active_Area_Callback with record
      User_Data : Browser_Item;
      Cb        : Item_Active_Callback;
   end record;
   function Call (Callback : Item_Active_Area_Callback;
                  Event    : Gdk.Event.Gdk_Event) return Boolean;
   --  See doc for inherited Call

   pragma Inline (Get_Canvas);
end Browsers.Canvas;
