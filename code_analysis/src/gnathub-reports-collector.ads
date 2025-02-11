------------------------------------------------------------------------------
--                               GNAT Studio                                --
--                                                                          --
--                     Copyright (C) 2011-2021, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

--  Collector for all GNAThub's reports which organizes all reports
--  as a tabs in one notebook

with GPS.Kernel;
with GNAThub.Module;
with GNAThub.Reports.Messages;
with Generic_Views;
with Gtk.Scrolled_Window;
with Gtk.Menu;

package GNAThub.Reports.Collector is

   type GNAThub_Report_Collector is new Generic_Views.View_Record with private;
   type GNAThub_Report_Collector_Access is
     access all GNAThub_Report_Collector'Class;

   overriding procedure Create_Menu
     (Self : not null access GNAThub_Report_Collector;
      Menu : not null access Gtk.Menu.Gtk_Menu_Record'Class);

   procedure Register_Module
     (Kernel : not null access GPS.Kernel.Kernel_Handle_Record'Class);
   --  Register the actions related with the GNAThub report collector.

   function Get_Or_Create_View
     (Kernel  : access GPS.Kernel.Kernel_Handle_Record'Class;
      Module  : not null access GNAThub.Module.GNAThub_Module_Id_Record'Class;
      Created : out Boolean)
      return GNAThub_Report_Collector_Access;
   --  Get or create a report collector view.
   --  Created is set to True if the view has been created.

   procedure Close_View
     (Kernel : not null access GPS.Kernel.Kernel_Handle_Record'Class);
   --  Close the report collector view.

private

   type GNAThub_Report_Collector is new Generic_Views.View_Record  with record
      Scrolled        : Gtk.Scrolled_Window.Gtk_Scrolled_Window;
      Messages_Report : GNAThub.Reports.Messages.GNAThub_Report_Messages;
   end record;

end GNAThub.Reports.Collector;
