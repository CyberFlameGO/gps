-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                  Copyright (C) 2008-2010, AdaCore                 --
--                                                                   --
-- GPS is Free  software;  you can redistribute it and/or modify  it --
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

--  ??? missing description of this package

with Glib.Object;
with Gtk.Menu;

with GNATCOLL.Projects; use GNATCOLL.Projects;
with GNATCOLL.VFS;      use GNATCOLL.VFS;

with Gdk.Color;
private with Default_Preferences;
with GPS.Kernel;   use GPS.Kernel;
with GPS.Kernel.Modules;
private with GPS.Kernel.Styles;
with GPS.Kernel.MDI;
with Code_Analysis;

private with Code_Peer.Summary_Reports;

package Code_Peer.Module is

   type Module_Id_Record
     (Kernel : access GPS.Kernel.Kernel_Handle_Record'Class) is
     new GPS.Kernel.Modules.Module_ID_Record with private;

   type Code_Peer_Module_Id is access all Module_Id_Record'Class;
   --  ??? missing comments on all types and procedures of this package

   procedure Load
     (Self : access Module_Id_Record'Class;
      File : Virtual_File);
   --  Loads code review results from file, creates CodePeer Report window
   --  and display loaded results.

   procedure Review_Message
     (Self    : access Module_Id_Record'Class;
      Message : Code_Peer.Message_Access);

   procedure Review_Message
     (Self    : access Module_Id_Record'Class;
      Message : Code_Peer.Message_Access;
      File    : Virtual_File);

   type Submenu_Factory_Record
     (Module : access Module_Id_Record'Class) is
     new GPS.Kernel.Modules.Submenu_Factory_Record with null record;

   overriding procedure Append_To_Menu
     (Factory : access Submenu_Factory_Record;
      Object  : access Glib.Object.GObject_Record'Class;
      Context : GPS.Kernel.Selection_Context;
      Menu    : access Gtk.Menu.Gtk_Menu_Record'Class);

   procedure Register_Module
     (Kernel : access GPS.Kernel.Kernel_Handle_Record'Class);
   --  Register the module

   function Get_Color
     (Probability : Code_Peer.Message_Probability_Level)
      return Gdk.Color.Gdk_Color;

private

   type Message_Probability_Color_Preference_Array is
     array (Code_Peer.Message_Probability_Level)
       of Default_Preferences.Color_Preference;

   type Message_Probability_Style_Array is
     array (Code_Peer.Message_Probability_Level)
       of GPS.Kernel.Styles.Style_Access;

   type CodePeer_Action is
     (None, Run_All, Run_Project, Run_File, Quick_Run, Load_UI);
   --  Various actions related to codepeer handling:
   --   - None: no action registered
   --   - Run_All: run "Run CodePeer" target on the whole project tree
   --   - Run_Project: run "Run CodePeer" target on the root project
   --   - Run_File: run "Run CodePeer" target on the current file
   --   - Quick_Run: run "Run CodePeer Quickly" target
   --   - Load_UI: load CodePeer UI

   type Module_Id_Record
     (Kernel : access GPS.Kernel.Kernel_Handle_Record'Class) is
     new GPS.Kernel.Modules.Module_ID_Record with record
      Tree             : Code_Analysis.Code_Analysis_Tree;
      Report_Subwindow : GPS.Kernel.MDI.GPS_MDI_Child;
      Report           : Code_Peer.Summary_Reports.Summary_Report;
      Annotation_Color : Default_Preferences.Color_Preference;
      Annotation_Style : GPS.Kernel.Styles.Style_Access;
      Message_Colors   : Message_Probability_Color_Preference_Array;
      Message_Styles   : Message_Probability_Style_Array;

      --  Global messages filter

      Filter_Criteria  : Code_Peer.Message_Filter_Criteria;

      Action           : CodePeer_Action := None;
      --  Indicate possible action to be performed when a build target is
      --  finished.

      File             : GNATCOLL.VFS.Virtual_File := GNATCOLL.VFS.No_File;
      --  If Action is Run_File, indicates which file should be analyzed
   end record;

   procedure Update_Location_View (Self : access Module_Id_Record'Class);

   function Codepeer_Output_Directory
     (Project : Project_Type) return GNATCOLL.VFS.Virtual_File;
   --  Returns directory which is used by CodePeer for output inspection
   --  results.

   function Codepeer_Database_Directory
     (Project : Project_Type) return GNATCOLL.VFS.Virtual_File;
   --  Returns directory which is used by CodePeer for store SQLite database
   --  files.

   function Codepeer_Library_File_Name
     (Project : Project_Type) return GNATCOLL.VFS.Virtual_File;
   --  Returns name of the library description file for CodePeer invocation.

   function Use_CodePeer_Subdir (Kernel : Kernel_Handle) return Boolean;
   --  Returns True if 'codepeer' directory is present in the current object
   --  directory. This means we need to switch build target to 'codepeer'
   --  before doing any operations.

   --  Style names to be used by children packages

   Annotation_Style_Name                : constant String
     := "CodePeer editor annotations";
   High_Probability_Style_Name          : constant String
     := "CodePeer high messages";
   Medium_Probability_Style_Name        : constant String
     := "CodePeer medium messages";
   Low_Probability_Style_Name           : constant String
     := "CodePeer low messages";
   Informational_Probability_Style_Name : constant String
     := "CodePeer informational messages";
   Suppressed_Probability_Style_Name    : constant String
     := "CodePeer suppressed messages";

   Module : Code_Peer_Module_Id;
   --  Global variable for store CodePeer plugin module. Used in the main menu
   --  callbacks.

end Code_Peer.Module;
