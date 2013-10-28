------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2001-2013, AdaCore                     --
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

with System;
with Interfaces.C.Strings;

with Ada.Command_Line;
with Ada.Containers.Vectors;
with Ada.Environment_Variables;
with Ada.Exceptions;            use Ada.Exceptions;
with Ada.Strings.Fixed;         use Ada.Strings.Fixed;
with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
with Ada.Text_IO;               use Ada.Text_IO;
with ALI;

with GNAT.Command_Line;                use GNAT.Command_Line;
pragma Warnings (Off);
with GNAT.Expect.TTY.Remote;           use GNAT.Expect.TTY.Remote;
pragma Warnings (On);
with GNAT.OS_Lib;                      use GNAT.OS_Lib;
with GNATCOLL.Arg_Lists;               use GNATCOLL.Arg_Lists;
with GNATCOLL.Scripts;                 use GNATCOLL.Scripts;
with GNAT.Strings;
with GNATCOLL.Memory;
with GNATCOLL.Projects;                use GNATCOLL.Projects;
with GNATCOLL.Traces;                  use GNATCOLL.Traces;
with GNATCOLL.Utils;                   use GNATCOLL.Utils;
with GNATCOLL.VFS;                     use GNATCOLL.VFS;
with GNATCOLL.VFS_Utils;               use GNATCOLL.VFS_Utils;

with Glib;
with Glib.Application;                 use Glib.Application;
with Glib.Error;                       use Glib.Error;
with Glib.Main;
with Glib.Messages;                    use Glib.Messages;
with Glib.Object;                      use Glib.Object;
with Glib.Option;                      use Glib.Option;
with Glib.Properties;                  use Glib.Properties;

with Gdk.Pixbuf;                       use Gdk.Pixbuf;

with Gtk;                              use Gtk;
with Gtk.Application;                  use Gtk.Application;
with Gtk.Enums;                        use Gtk.Enums;
with Gtk.Image;                        use Gtk.Image;
with Gtk.Handlers;
with Gtk.Settings;                     use Gtk.Settings;
with Gtk.Style_Provider;               use Gtk.Style_Provider;
with Gtk.Window;                       use Gtk.Window;
with Gtk_Utils;                        use Gtk_Utils;

with Gtkada.Application;               use Gtkada.Application;
with Gtkada.Dialogs;                   use Gtkada.Dialogs;
with Gtkada.Intl;
with Gtkada.MDI;                       use Gtkada.MDI;
with Gtkada.Style;

with Config;                           use Config;
with Default_Preferences;              use Default_Preferences;
with GPS.Callbacks;                    use GPS.Callbacks;
with GPS.Intl;                         use GPS.Intl;
with GPS.Kernel;                       use GPS.Kernel;
with GPS.Kernel.Clipboard;             use GPS.Kernel.Clipboard;
with GPS.Kernel.Console;               use GPS.Kernel.Console;
with GPS.Kernel.Contexts;              use GPS.Kernel.Contexts;
with GPS.Kernel.Custom;                use GPS.Kernel.Custom;
with GPS.Kernel.Hooks;                 use GPS.Kernel.Hooks;
with GPS.Kernel.MDI;                   use GPS.Kernel.MDI;
with GPS.Kernel.Messages;              use GPS.Kernel.Messages;
with GPS.Kernel.Messages.Shell;
with GPS.Kernel.Modules;               use GPS.Kernel.Modules;
with GPS.Kernel.Preferences;           use GPS.Kernel.Preferences;
with GPS.Kernel.Project;               use GPS.Kernel.Project;
with GPS.Kernel.Remote;
with GPS.Kernel.Scripts;               use GPS.Kernel.Scripts;
with GPS.Kernel.Standard_Hooks;        use GPS.Kernel.Standard_Hooks;
with GPS.Kernel.Styles.Shell;
with GPS.Kernel.Task_Manager;          use GPS.Kernel.Task_Manager;
with GPS.Kernel.Timeout;               use GPS.Kernel.Timeout;
with GPS.Stock_Icons;
with GPS.Main_Window;                  use GPS.Main_Window;
with GPS.Menu;
with GPS.Search.GUI;
with OS_Utils;                         use OS_Utils;
with Projects;                         use Projects;
with Remote;                           use Remote;
with Src_Editor_Box;                   use Src_Editor_Box;
with String_Utils;
with Task_Manager.GUI;
with Welcome;                          use Welcome;
with Welcome_Page;                     use Welcome_Page;

--  Modules registered by GPS

with Ada_Module;
with Aliases_Module;
with Bookmark_Views;
with Browsers.Call_Graph;
with Browsers.Dependency_Items;
with Browsers.Elaborations;
with Browsers.Entities;
with Browsers.Projects;
with Revision_Views;
with Buffer_Views;
with Builder_Module;
with Builder_Facility_Module;
with Call_Graph_Views;
with Casing_Exceptions;
with Clipboard_Views;
with Code_Analysis_Module;
with CodePeer.Module;
with Codefix_Module;
with Command_Window;
with Cpp_Module;
with Custom_Module;
with Project_Templates.GPS;
with Docgen2_Module;
with External_Editor_Module;
with GNATStack.Module;
with GNATTest_Module;
with GPS.Location_View;
with GVD_Module;
with Help_Module;
with KeyManager_Module;
with KeyManager_Module.Macros;
with Toolchains_Module;
with Ada_Semantic_Tree_Module;
with Navigation_Module;
with Outline_View;
with Project_Explorers;
with Project_Explorers_Files;
with Project_Properties;
with Project_Viewers;
with Python_Module;
with Refactoring_Module;
with Remote.Rsync;
with Remote_Module;
with Scenario_Views;
with Shell_Script;
with Socket_Module;
with Src_Editor_Module;
with Startup_Module;
with Switches_Chooser.Scripts;
with Theme_Manager_Module;
with Toolchains_Editor;
with VCS_Module;
with VFS_Module;
with Vdiff2_Module;
with Vsearch;

procedure GPS.Main is
   use type Glib.Gint;

   Me         : constant Trace_Handle := Create ("GPS");
   Pid_Image  : constant String := String_Utils.Image (Get_Process_Id);
   Gtk_Errors : constant Trace_Handle := Create ("GTK");

   Docgen2_Trace          : constant Trace_Handle :=
                              Create ("MODULE.Docgen2", GNATCOLL.Traces.On);
   Refactor_Trace         : constant Trace_Handle :=
                              Create ("MODULE.Refactor", GNATCOLL.Traces.On);
   Python_Trace           : constant Trace_Handle :=
                              Create ("MODULE.Python", GNATCOLL.Traces.On);
   Call_Graph_Trace       : constant Trace_Handle :=
                              Create ("MODULE.Call_Graph", GNATCOLL.Traces.On);
   Dependency_Trace       : constant Trace_Handle :=
                              Create ("MODULE.Dependency", GNATCOLL.Traces.On);
   Project_Browser_Trace  : constant Trace_Handle :=
                        Create ("MODULE.Project_Browser", GNATCOLL.Traces.On);
   Entities_Browser_Trace : constant Trace_Handle :=
                        Create ("MODULE.Entities_Browser", GNATCOLL.Traces.On);
   Revision_Views_Trace   : constant Trace_Handle :=
                        Create ("MODULE.Revision_Views", GNATCOLL.Traces.On);
   Aliases_Trace          : constant Trace_Handle :=
                        Create ("MODULE.Aliases", GNATCOLL.Traces.On);
   Project_Explorer_Trace : constant Trace_Handle :=
                        Create ("MODULE.Project_Explorer", GNATCOLL.Traces.On);
   Files_Explorer_Trace   : constant Trace_Handle :=
                        Create ("MODULE.Files_Explorer", GNATCOLL.Traces.On);
   External_Editor_Trace  : constant Trace_Handle :=
                        Create ("MODULE.External_Editor", GNATCOLL.Traces.On);
   VCS_Trace              : constant Trace_Handle :=
                        Create ("MODULE.VCS", GNATCOLL.Traces.On);

   Custom_Trace           : constant Trace_Handle :=
                        Create ("MODULE.Custom", GNATCOLL.Traces.On);
   Project_Templates_Trace : constant Trace_Handle :=
                       Create ("MODULE.Project_Templates", GNATCOLL.Traces.On);
   Code_Analysis_Trace    : constant Trace_Handle :=
                        Create ("MODULE.Code_Analysis", GNATCOLL.Traces.On);
   CodePeer_Trace         : constant Trace_Handle :=
                              Create ("MODULE.CodePeer", GNATCOLL.Traces.On);
   GNATStack_Trace        : constant Trace_Handle :=
                              Create ("MODULE.GNATStack", GNATCOLL.Traces.On);
   Codefix_Trace          : constant Trace_Handle :=
                              Create ("MODULE.Codefix", GNATCOLL.Traces.On);
   Builder_Trace          : constant Trace_Handle :=
                              Create ("MODULE.Builder", GNATCOLL.Traces.On);
   GVD_Trace              : constant Trace_Handle :=
                              Create ("MODULE.GVD", GNATCOLL.Traces.On);
   GNATTest_Trace         : constant Trace_Handle :=
                              Create ("MODULE.GNATTest", GNATCOLL.Traces.On);
   Startup_Trace          : constant Trace_Handle :=
                              Create ("MODULE.Startup", GNATCOLL.Traces.On);
   VFS_Trace              : constant Trace_Handle :=
                              Create ("MODULE.VFS", GNATCOLL.Traces.On);
   Help_Trace             : constant Trace_Handle :=
                              Create ("MODULE.Help", GNATCOLL.Traces.On);
   Scenario_View_Trace    : constant Trace_Handle :=
                              Create ("MODULE.SCENARIO", GNATCOLL.Traces.On);
   Project_Viewer_Trace   : constant Trace_Handle :=
                      Create ("MODULE.Project_Viewer", GNATCOLL.Traces.On);
   Project_Properties_Trace : constant Trace_Handle :=
                      Create ("MODULE.Project_Properties", GNATCOLL.Traces.On);
   CPP_Trace              : constant Trace_Handle :=
                              Create ("MODULE.CPP", GNATCOLL.Traces.On);
   Outline_View_Trace     : constant Trace_Handle :=
                              Create ("MODULE.Outline", GNATCOLL.Traces.On);
   Call_Graph_View_Trace  : constant Trace_Handle :=
                      Create ("MODULE.Call_Graph_View", GNATCOLL.Traces.On);
   Clipboard_View_Trace   : constant Trace_Handle :=
                      Create ("MODULE.Clipboard_Vview", GNATCOLL.Traces.On);
   Toolchains_Trace       : constant Trace_Handle :=
                      Create ("MODULE.Toolchains", GNATCOLL.Traces.On);
   Toolchains_Editor_Trace  : constant Trace_Handle :=
                      Create ("MODULE.Toolchains_Editor", GNATCOLL.Traces.On);
   Elaboration_Browser_Trace : constant Trace_Handle :=
     Create ("MODULE.Elaboration_Browser", GNATCOLL.Traces.On);

   --  If any of these debug handles is active, the correponding module
   --  is loaded.

   subtype String_Access is GNAT.Strings.String_Access;

   type File_To_Open is record
      File : Unbounded_String;
      Line : Natural := 1;
      From_Project : Boolean := False;
   end record;

   package File_To_Open_Vectors is new Ada.Containers.Vectors
     (Positive, File_To_Open);

   Home_Dir               : Virtual_File;
   Prefix_Dir             : Virtual_File;
   GPS_Home_Dir           : Virtual_File;
   Batch_File             : String_Access;
   Batch_Script           : String_Access;
   Hide_GPS               : Boolean := False;
   Tools_Host             : String_Access;
   Target                 : String_Access;
   Protocol               : String_Access;
   Debugger_Name          : String_Access;
   Startup_Dir            : String_Access;
   Passed_Project_Name    : String_Access;
   Program_Args           : String_Access;
   Server_Mode            : Boolean := False;
   Port_Number            : Natural := 0;

   Application            : Gtkada_Application;
   Project_Name           : Virtual_File := No_File;
   About_Contents         : String_Access;
   Splash                 : Gtk_Window;
   Files_To_Open          : File_To_Open_Vectors.Vector;
   Cleanup_Needed         : Boolean := False;
   Unexpected_Exception   : Boolean := False;
   Splash_Timeout         : Glib.Guint := 1000;

   Button                 : Message_Dialog_Buttons;
   Timeout_Id             : Glib.Main.G_Source_Id;
   pragma Unreferenced (Button, Timeout_Id);

   procedure Startup_Callback
     (Application : access Gapplication_Record'Class);
   --  Handler for the ::startup signal, emited by the application

   procedure Activate_Callback
     (Application : access Gapplication_Record'Class);
   --  Handler for the ::activate signal, emited by the application

   function Command_Line_Callback
     (Application  : access Gapplication_Record'Class;
      Command_Line : not null access Gapplication_Command_Line_Record'Class)
   return Glib.Gint;
   --  Handler for the ::command-line signal, emited by the application

   procedure Initialize_Environment_Variables
     (Command_Line : not null access Gapplication_Command_Line_Record'Class);
   --  Sanitize, sets and take into account various environment variables, and
   --  initialize GPS according to them.

   procedure Initialize_Low_Level (Status_Code : out Glib.Gint);
   --  Initializes the low-level gtk, python, traces layers
   --  This needs to be performed after environment variable initialisation.

   procedure Read_Command_Line
     (Command_Line : not null access Gapplication_Command_Line_Record'Class;
      Do_Exit      : out Boolean;
      Status_Code  : out Glib.Gint);
   --  Reads and handle the command line as given by the Command_Line object.
   --  Do_Exit is set to True if GPS needs to immediately exit
   --  Status_Code gives the status code to return

   procedure File_Open_Callback
     (Application : Gtkada.Application.Gtkada_Application;
      Files       : Gtkada.Application.GFile_Array);
   --  Handler for the ::open signal, emited by the application

   procedure Shutdown_Callback
     (Application : access Gapplication_Record'Class);

   procedure Set_Project_Name;
   --  Set the project name from the command line switch

   procedure Error_Message (Message : String);
   --  Display the "Fatal error" message

   procedure Display_Splash_Screen;
   --  Display the GPS splash screen

   function Finish_Setup (Data : Process_Data) return Boolean;
   --  Finish the set up of GPS, while the main loop is running

   procedure Execute_Batch (Batch : String; As_File : Boolean);
   --  Execute a batch command (either loading the file Batch if As_File is
   --  true, or as a standard command otherwise).

   procedure Default_Gtk_Mer
     (Occurrence : Ada.Exceptions.Exception_Occurrence);
   --  Called when an Ada callback raises an exception, to log it.

   --------------------------------------
   -- Initialize_Environment_Variables --
   --------------------------------------

   procedure Initialize_Environment_Variables
     (Command_Line : not null access Gapplication_Command_Line_Record'Class)
   is
   begin
      declare
         Tmp  : constant String := Command_Line.Getenv ("GPS_MEMORY_MONITOR");
         Tmp2 : constant String := Command_Line.Getenv ("GPS_MEMORY_CHECK");

      begin
         GNATCOLL.Memory.Configure
           (Activate_Monitor => Tmp /= "",
            Disable_Free     => Tmp2 /= "");
      end;

      --  Reset the environment that was set before GPS was started (since
      --  starting GPS will generally imply a change in LD_LIBRARY_PATH and
      --  PATH to point to the right libraries

      declare
         Tmp : constant String := Command_Line.Getenv ("GPS_STARTUP_PATH");
      begin
         if Tmp /= "" then
            --  We assume that the GPS_STARTUP_PATH variable is only set
            --  through the startup script, and that the PATH is never
            --  empty. Therefore, if GPS_STARTUP_PATH contains something,
            --  this means we're launching through the script, and
            --  GPS_STARTUP_LD_LIBRARY_PATH will also always be set.

            Setenv ("PATH", Tmp);
         end if;
      end;

      declare
         Tmp : constant String :=
                 Command_Line.Getenv ("GPS_STARTUP_LD_LIBRARY_PATH");
      begin
         if Tmp /= "" then
            Setenv ("LD_LIBRARY_PATH", Tmp);
         end if;
      end;

      declare
         Tmp : constant String :=
                 Command_Line.Getenv ("GPS_STARTUP_DYLD_LIBRARY_PATH");
      begin
         if Tmp /= "" then
            Setenv ("DYLD_LIBRARY_PATH", Tmp);
         end if;
      end;

      declare
         Charset : constant String := Command_Line.Getenv ("CHARSET");
      begin
         if Charset = "" then
            --  Gtk+ does not like if CHARSET is not defined.
            --  Need to set CHARSET *before* calling Gtk.Main.Init, so cannot
            --  use Get_Pref here.

            Setenv ("CHARSET", Config.Default_Charset);
         end if;
      end;

      Startup_Dir := new String'(Command_Line.Get_Cwd);

      --  Set the TERM variable to a dummy value, since we only know how to
      --  handle simple terminals

      Setenv ("TERM", "dumb");

      declare
         Home : constant String := Command_Line.Getenv ("GPS_HOME");
      begin
         if Home /= "" then
            Home_Dir := Create (+Home);
         else
            Home_Dir := Get_Home_Directory;
         end if;
      end;

      GPS_Home_Dir := Create_From_Dir (Home_Dir, ".gps");
      Ensure_Directory (GPS_Home_Dir);

      declare
         Prefix : constant String := Command_Line.Getenv ("GPS_ROOT");
      begin
         if Prefix /= "" then
            Prefix_Dir := Create (+Prefix);
         end if;
      end;

      if Prefix_Dir = No_File then
         declare
            Prefix : constant String := Executable_Location;
         begin
            --  Check whether we are running the installed gps, or locally from
            --  the development environment.

            if Prefix'Length < 4
              or else Prefix (Prefix'Last - 3 .. Prefix'Last - 1) /= "obj"
            then
               Prefix_Dir := Create (+Prefix);
            else
               Prefix_Dir := Create (+Config.Prefix);
            end if;

         end;
      end if;

      --  Python startup path

      declare
         Python_Path : constant String := Command_Line.Getenv ("PYTHONPATH");
         New_Val : String_Access;
      begin
         if Python_Path = "" then
            New_Val := new String'
              (+Create_From_Dir (Prefix_Dir, "share/gps/python").Full_Name);
         else
            New_Val := new String'
              (+To_Path
                 (From_Path (+Python_Path) &
                  (1 => Create_From_Dir (Prefix_Dir, "share/gps/python"))));
         end if;

         Setenv ("PYTHONPATH", New_Val.all);
         Trace (Me, "PYTHONPATH=" & New_Val.all);
         Free (New_Val);
      end;

   end Initialize_Environment_Variables;

   --------------------------
   -- Initialize_Low_Level --
   --------------------------

   procedure Initialize_Low_Level (Status_Code : out Glib.Gint)
   is
      Ignored     : Log_Handler_Id;
      pragma Unreferenced (Ignored);

   begin
      Gtkada.Intl.Setlocale;
      Gtkada.Intl.Bind_Text_Domain
        ("gps", +Create_From_Dir (Prefix_Dir, "share/locale").Full_Name);
      Gtkada.Intl.Text_Domain ("gps");

      --  Redirect all default Gtk+ logs to our own trace mechanism

      Ignored := Log_Set_Handler
        ("", Log_Level_Mask, Gtk_Log'Access);
      Ignored := Log_Set_Handler
        ("GLib", Log_Level_Mask, Gtk_Log'Access);
      Ignored := Log_Set_Handler
        ("GLib-GObject", Log_Level_Mask, Gtk_Log'Access);
      Ignored := Log_Set_Handler
        ("Pango", Log_Level_Mask, Gtk_Log'Access);
      Ignored := Log_Set_Handler
        ("Atk", Log_Level_Mask, Gtk_Log'Access);
      Ignored := Log_Set_Handler
        ("GdkPixbuf", Log_Level_Mask, Gtk_Log'Access);
      Ignored := Log_Set_Handler
        ("Gdk", Log_Level_Mask, Gtk_Log'Access);
      Ignored := Log_Set_Handler
        ("Gtk", Log_Level_Mask, Gtk_Log'Access);

      declare
         Plug_Ins           : constant Virtual_File :=
                                Create_From_Dir (GPS_Home_Dir, "plug-ins");
         Gnatinspect_Traces : constant Virtual_File :=
                                Create_From_Dir (GPS_Home_Dir,
                                                 "gnatinspect_traces.cfg");
         Dir_Created        : Boolean := False;
         File               : Writable_File;

      begin
         if not Is_Directory (GPS_Home_Dir) then
            Make_Dir (GPS_Home_Dir);
            Button := Message_Dialog
              ((-"Created config directory ") & GPS_Home_Dir.Display_Full_Name,
               Information, Button_OK, Justification => Justify_Left);
            Dir_Created := True;

            --  Create a default configuration file for the traces.
            --  This should be left while GPS is considered as not fully
            --  stable.

            File := Create_From_Dir (GPS_Home_Dir, "traces.cfg").Write_File;
            Write (File,
                   ">log.$$" & ASCII.LF &
                     "+" & ASCII.LF &
                     "DEBUG.COLORS=no" & ASCII.LF &
                     "DEBUG.ABSOLUTE_TIME=yes" & ASCII.LF &
                     "DEBUG.ELAPSED_TIME=no" & ASCII.LF &
                     "DEBUG.STACK_TRACE=no" & ASCII.LF &
                     "DEBUG.LOCATION=no" & ASCII.LF &
                     "DEBUG.ENCLOSING_ENTITY=no");
            Close (File);
         end if;

         if not Gnatinspect_Traces.Is_Regular_File then
            --  Make sure gnatinspect will never try to write to stdout. This
            --  works around an issue in gnatcoll-traces, where handles that
            --  are enabled by default would write to stdout in no config file
            --  is parsed to override this.
            File := Gnatinspect_Traces.Write_File;
            Write (File, ">log_gnatinspect");
            Close (File);
         end if;

         if not Is_Directory (Plug_Ins) then
            Make_Dir (Plug_Ins);

            if not Dir_Created then
               Button := Message_Dialog
                 ((-"Created plug-ins directory ") &
                  Plug_Ins.Display_Full_Name,
                  Information, Button_OK, Justification => Justify_Left);
            end if;
         end if;

      exception
         when VFS_Directory_Error =>
            Button := Message_Dialog
              ((-"Cannot create config directory ") &
               GPS_Home_Dir.Display_Full_Name & ASCII.LF &
               (-"Exiting..."),
               Error, Button_OK,
               Justification => Justify_Left);

            Status_Code := 1;
            return;
      end;

      declare
         Tmp    : constant Virtual_File := Get_Tmp_Directory;
      begin
         if not Is_Directory (Tmp) then
            Button := Message_Dialog
              ((-"Cannot access temporary directory ") &
               Tmp.Display_Full_Name,
               Error, Button_OK, Justification => Justify_Left);

            Status_Code := 1;
            return;
         end if;
      end;

      --  Initialize the traces

      declare
         File : constant Virtual_File :=
                  Create_From_Dir (GPS_Home_Dir, "traces.cfg");
      begin
         GNATCOLL.Traces.Parse_Config_File
           (Filename     => No_File,
            Default      => File,
            On_Exception => GNATCOLL.Traces.Deactivate);
      exception
         when others =>
            Button := Message_Dialog
              ((-"Cannot access file ") & File.Display_Full_Name & ASCII.LF &
               (-"Exiting..."),
               Error, Button_OK, Justification => Justify_Left);

            Status_Code := 1;
            return;
      end;

      Trace (Me, "GPS " & Config.Version & " (" & Config.Source_Date &
             ") hosted on " & Config.Target);
      Trace (Me, "Gtk+ static version: "
             & String_Utils.Image (Integer (Gtk.Major_Version)) & '.'
             & String_Utils.Image (Integer (Gtk.Minor_Version)) & '.'
             & String_Utils.Image (Integer (Gtk.Micro_Version)));
      Trace (Me, "Gtk+ dynamic version: "
             & String_Utils.Image (Gtk_Major_Version) & '.'
             & String_Utils.Image (Gtk_Minor_Version) & '.'
             & String_Utils.Image (Gtk_Micro_Version));

      GPS.Stock_Icons.Register_Stock_Icons (Prefix_Dir);

      declare
         Global : constant Virtual_File :=
                    Prefix_Dir.Create_From_Dir ("share/gps/gps.css");
         Local  : constant Virtual_File :=
                    GPS_Home_Dir.Create_From_Dir ("gps.css");
      begin
         if Global.Is_Regular_File then
            Trace (Me, "Loading " & Global.Display_Full_Name);
            Gtkada.Style.Load_Css_File
              (Global.Display_Full_Name, Put_Line'Access,
               Priority_Settings);
         end if;

         if Local.Is_Regular_File then
            Trace (Me, "Loading " & Local.Display_Full_Name);
            Gtkada.Style.Load_Css_File
              (Local.Display_Full_Name, Put_Line'Access,
               Priority_User);
         end if;
      end;

      Status_Code := 0;
   end Initialize_Low_Level;

   -----------------------
   -- Read_Command_Line --
   -----------------------

   procedure Read_Command_Line
     (Command_Line : not null access Gapplication_Command_Line_Record'Class;
      Do_Exit      : out Boolean;
      Status_Code  : out Glib.Gint)
   is
      package ICS renames Interfaces.C.Strings;
      use ICS;
      use type Glib.Gboolean;

      Opt_Context : Glib.Option.Goption_Context;
      Err         : Glib.Error.GError;
      Success     : Boolean;
      Line        : Positive := 1;

      function On_Argument
        (Param : String) return Boolean;
      --  Used to parse arguments that do not match the Gtk argument passing
      --  framework, such as -Pproject (Gtk requires a delimiter between the
      --  switch and the argument).

      procedure On_Scenario_Variable
        (Param : String);
      --  Handles an explicit scenario variable passed from the command line

      function On_Switch
        (Option_Name : ICS.chars_ptr;
         Value       : ICS.chars_ptr;
         Data        : System.Address;
         Error       : access Glib.Error.GError) return Glib.Gboolean;
      --  General callback for switch handling from GApplication

      function On_File
        (Option_Name : ICS.chars_ptr;
         Value       : ICS.chars_ptr;
         Data        : System.Address;
         Error       : access Glib.Error.GError) return Glib.Gboolean;
      --  General callback for file opening handling from GApplication

      --        Application_Error : exception;
      function To_Gchar (C : Character) return Glib.Gchar;

      pragma Convention (C, On_Switch);
      pragma Convention (C, On_File);

      -----------------
      -- On_Argument --
      -----------------

      function On_Argument
        (Param : String) return Boolean
      is
      begin
         if Param'Length > 2
           and then Param (Param'First) = '-'
         then
            case Param (Param'First + 1) is
               when 'P' =>
                  Passed_Project_Name :=
                    new String'(Param (Param'First + 2 .. Param'Last));
                  return False;

               when 'X' =>
                  On_Scenario_Variable
                    (Param (Param'First + 2 .. Param'Last));
                  return False;

               when others =>
                  --  Let GOption handle the parameter
                  return True;
            end case;
         end if;

         --  Let GOption handle the parameter
         return True;
      end On_Argument;

      --------------------------
      -- On_Scenario_Variable --
      --------------------------

      procedure On_Scenario_Variable
        (Param : String)
      is
         Set : Boolean := False;
      begin
         for P in Param'First + 1 .. Param'Last - 1 loop
            if Param (P) = '=' then
               Set := True;
               Ada.Environment_Variables.Set
                 (Name  => Param (Param'First .. P - 1),
                  Value => Param (P + 1 .. Param'Last));
               exit;
            end if;
         end loop;

         if not Set then
            raise GNAT.Command_Line.Invalid_Parameter with
              "Invalid value for -X, should be VAR=VALUE";
         end if;
      end On_Scenario_Variable;

      ---------------
      -- On_Switch --
      ---------------

      function On_Switch
        (Option_Name : ICS.chars_ptr;
         Value       : ICS.chars_ptr;
         Data        : System.Address;
         Error       : access Glib.Error.GError) return Glib.Gboolean
      is
         pragma Unreferenced (Data, Error);
         Switch : constant String := ICS.Value (Option_Name);

      begin
         if Switch = "--project" or else Switch = "-P" then
            --  Although this isn't costly, we must not resolve symbolic
            --  links for project names unless Fast Project Loading mode is
            --  disabled. Some users (IA27-014) and SCM have local links
            --  that point to a SCM cache directory (Rational Synergy), but
            --  directory names are still local. These users should use
            --  Trusted mode so that we do not resolve symbolic links

            Passed_Project_Name := new String'(ICS.Value (Value));

         elsif Switch = "--help"
           or else Switch = "-h"
           or else Switch = "--help-all"
         then
            declare
               --  Get_Help (False) will also print options that are not
               --  in the main group (such as Gtk+ options)
               --  Get_Help (True) will only print options from the main
               --  group
               Help : constant String :=
                        "GPS version " &
                        Config.Version & " (" &
                        Config.Source_Date & ") hosted on " &
                        Config.Target & ASCII.LF &
                        ASCII.LF &
                        Opt_Context.Get_Help
                 (Switch /= "--help-all", null);
            begin
               if Config.Can_Output then
                  Put_Line (Help);
               else
                  Button := Message_Dialog
                    (Help, Information, Button_OK,
                     Title         => -"Help",
                     Justification => Justify_Left);
               end if;
            end;

            Do_Exit := True;

         elsif Switch = "--version" or else Switch = "-v" then
            declare
               Version : constant String :=
                           "GPS version " &
                           Config.Version & " (" &
                           Config.Source_Date & ") hosted on " &
                           Config.Target;
            begin
               if Config.Can_Output then
                  Put_Line (Version);
               else
                  Button := Message_Dialog
                    (Version,
                     Information, Button_OK,
                     Title         => -"Version",
                     Justification => Justify_Left);
               end if;
            end;

            Do_Exit := True;

         elsif Switch = "--debug" then
            Free (Program_Args);

            if Value /= ICS.Null_Ptr then
               Program_Args := new String'(ICS.Value (Value));
            else
               Program_Args := new String'("");
            end if;

         elsif Switch = "--debugger" then
            Free (Debugger_Name);
            Debugger_Name := new String'(ICS.Value (Value));

            if Program_Args = null then
               --  --debugger implies --debug
               Program_Args := new String'("");
            end if;

         elsif Switch = "--hide" then
            Hide_GPS := True;

         elsif Switch = "--readonly" then
            Src_Editor_Box.Read_Only_By_Default;

         elsif Switch = "--host" then
            Free (Tools_Host);
            Tools_Host := new String'(ICS.Value (Value));

         elsif Switch = "--load" then
            Free (Batch_File);
            Batch_File := new String'(ICS.Value (Value));

         elsif Switch = "--eval" then
            Free (Batch_Script);
            Batch_Script := new String'(ICS.Value (Value));

         elsif Switch = "--server" then
            begin
               Port_Number := Natural'Value (ICS.Value (Value));
               Server_Mode := True;
            exception
               when Constraint_Error =>
                  return 0;
            end;

         elsif Switch = "--target" then
            declare
               Param  : constant String := ICS.Value (Value);
               Column : constant Natural :=
                          Ada.Strings.Fixed.Index
                            (Param, ":", Ada.Strings.Backward);

            begin
               --  Param should be of the form target:protocol

               if Column = 0 then
                  raise Invalid_Switch;
               end if;

               Free (Target);
               Free (Protocol);
               Target   :=
                 new String '(Param (Param'First .. Column - 1));
               Protocol :=
                 new String '(Param (Column + 1 .. Param'Last));
            end;

         elsif Switch = "--traceon" then
            GNATCOLL.Traces.Set_Active (Create (ICS.Value (Value)), True);

         elsif Switch = "--traceoff" then
            GNATCOLL.Traces.Set_Active (Create (ICS.Value (Value)), True);

         elsif Switch = "--tracefile" then
            GNATCOLL.Traces.Parse_Config_File
              (Filename => Create_From_Base (+ICS.Value (Value)));

         elsif Switch = "--tracelist" then
            GNATCOLL.Traces.Show_Configuration
              (Ada.Text_IO.Put_Line'Access);

            Do_Exit := True;
         end if;

         return 1;
      end On_Switch;

      -------------
      -- On_File --
      -------------

      function On_File
        (Option_Name : ICS.chars_ptr;
         Value       : ICS.chars_ptr;
         Data        : System.Address;
         Error       : access Glib.Error.GError) return Glib.Gboolean
      is
         pragma Unreferenced (Option_Name, Data, Error);
         FName : constant String := ICS.Value (Value);
         Item  : File_To_Open;

      begin
         if FName (FName'First) = '-' then
            --  Ignore switches
            return 0;

         elsif FName (FName'First) = '=' then
            --  =<basename> means open from project
            Item.File :=
              To_Unbounded_String (FName (FName'First + 1 .. FName'Last));
            Item.Line := Line;
            Line := 1;
            Item.From_Project := True;
            Files_To_Open.Append (Item);

         elsif FName (FName'First) = '+' then
            --  +<line number> means open next file on command line at a
            --  specific line number
            Line := Positive'Value (FName (FName'First + 1 .. FName'Last));

         else
            Item.File := To_Unbounded_String (FName);
            Item.Line := Line;
            Line := 1;
            Files_To_Open.Append (Item);
         end if;

         return 1;
      end On_File;

      --------------
      -- To_Gchar --
      --------------

      function To_Gchar (C : Character) return Glib.Gchar is
      begin
         return Glib.Gchar (Interfaces.C.char'(Interfaces.C.To_C (C)));
      end To_Gchar;

      Opt_Project  : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("project"),
                        Short_Name      => To_Gchar ('P'),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Load project file project or project.gpr"),
                        Arg_Description => ICS.New_String ("project"));
      Opt_Help     : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("help"),
                        Short_Name      => To_Gchar ('h'),
                        Flags           => G_Option_Flag_No_Arg,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Show this help message and exit"),
                        Arg_Description => ICS.Null_Ptr);
      Opt_Help_All : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("help-all"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => G_Option_Flag_No_Arg +
                                         G_Option_Flag_Hidden,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Show this help message with all options"),
                        Arg_Description => ICS.Null_Ptr);
      Opt_Version  : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("version"),
                        Short_Name      => To_Gchar ('v'),
                        Flags           => G_Option_Flag_No_Arg,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Show the GPS version and exit"),
                        Arg_Description => ICS.Null_Ptr);
      Opt_Debug    : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("debug"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => G_Option_Flag_Optional_Arg +
                                         G_Option_Flag_Filename,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Start a debug session"),
                        Arg_Description => ICS.New_String ("[program]"));
      Opt_Debugger : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("debugger"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => G_Option_Flag_Filename,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Specify the debugger's command line"),
                        Arg_Description => ICS.New_String
                          ("debugger"));
      Opt_Hide     : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("hide"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => G_Option_Flag_No_Arg,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Hide GPS main window"),
                        Arg_Description => ICS.Null_Ptr);
      Opt_Host     : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("host"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Use tools_host to launch tools (e.g. gdb)"),
                        Arg_Description => ICS.New_String ("tools_host"));
      Opt_Target   : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("target"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Load program on machine TARG using " &
                           "protocol PRO"),
                        Arg_Description => ICS.New_String ("TARG:PRO"));
      Opt_Load     : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("load"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Execute an external file written in " &
                           "the language lang"),
                        Arg_Description => ICS.New_String ("lang:file"));
      Opt_Eval     : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("eval"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Execute a command written in the language " &
                           "lang. This is executed before the --load " &
                           "command"),
                        Arg_Description => ICS.New_String ("lang:cmd"));
      Opt_Readonly : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("readonly"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => G_Option_Flag_No_Arg,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Open all files in read-only mode"),
                        Arg_Description => ICS.Null_Ptr);
      Opt_Server   : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("server"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Start GPS in server mode, opening a " &
                           "socket on the given port"),
                        Arg_Description => ICS.New_String ("port"));
      Opt_Traceon  : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("traceon"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Activate traces for a specific debug stream"),
                        Arg_Description => ICS.New_String ("stream"));
      Opt_Traceoff : constant Glib.Option.GOption_Entry :=
                       (Long_Name       => ICS.New_String ("traceoff"),
                        Short_Name      => To_Gchar (ASCII.NUL),
                        Flags           => 0,
                        Arg             => G_Option_Arg_Callback,
                        Arg_Data        => On_Switch'Address,
                        Description     => ICS.New_String
                          ("Disable traces for a specific debug stream"),
                        Arg_Description => ICS.New_String ("stream"));
      Opt_Tracefile : constant Glib.Option.GOption_Entry :=
                        (Long_Name       => ICS.New_String ("tracefile"),
                         Short_Name      => To_Gchar (ASCII.NUL),
                         Flags           => G_Option_Flag_Filename,
                         Arg             => G_Option_Arg_Callback,
                         Arg_Data        => On_Switch'Address,
                         Description     => ICS.New_String
                           ("Load traces configuration from file"),
                         Arg_Description => ICS.New_String ("file"));
      Opt_Tracelist : constant Glib.Option.GOption_Entry :=
                        (Long_Name       => ICS.New_String ("tracelist"),
                         Short_Name      => To_Gchar (ASCII.NUL),
                         Flags           => G_Option_Flag_No_Arg,
                         Arg             => G_Option_Arg_Callback,
                         Arg_Data        => On_Switch'Address,
                         Description     => ICS.New_String
                           ("List all available debug streams"),
                         Arg_Description => ICS.Null_Ptr);
      --  Option for remaining arguments
      Opt_Remaining : constant Glib.Option.GOption_Entry :=
                        (Long_Name       => ICS.New_String (""),
                         Short_Name      => To_Gchar (ASCII.NUL),
                         Flags           => G_Option_Flag_Filename,
                         Arg             => G_Option_Arg_Callback,
                         Arg_Data        => On_File'Address,
                         Description     => ICS.Null_Ptr,
                         Arg_Description => ICS.Null_Ptr);
      Opt_Entries   : constant Glib.Option.GOption_Entry_Array :=
                        (Opt_Project,
                         Opt_Help,
                         Opt_Help_All,
                         Opt_Version,
                         Opt_Debug,
                         Opt_Debugger,
                         Opt_Hide,
                         Opt_Host,
                         Opt_Target,
                         Opt_Load,
                         Opt_Eval,
                         Opt_Readonly,
                         Opt_Server,
                         Opt_Traceon,
                         Opt_Traceoff,
                         Opt_Tracefile,
                         Opt_Tracelist,
                         Opt_Remaining,
                         Null_GOption_Entry);

      function Get_Gtk_Option_Group
        (Open_Default_Display : Glib.Gboolean)
            return Glib.Option.GOption_Group;
      pragma Import (C, Get_Gtk_Option_Group, "gtk_get_option_group");

   begin
      Do_Exit := False;
      Status_Code := 0;

      Opt_Context := Glib.Option.G_New
        ("[-Pproject-file] [-XScenarioVar=Value] [[+line1] source1] " &
           "[[+line2] source2] ...");

      Opt_Context.Set_Summary
        ("source1, source2, ..." &
           ASCII.LF &
           "    Name of files to load. Start with '=' to load from project" &
           ASCII.LF &
           "    and use +line to go to <line> directly, e.g. +40 source1");

      Opt_Context.Add_Group (Get_Gtk_Option_Group (1));
      Opt_Context.Add_Main_Entries (Opt_Entries, "gps");

      --  Default Help implementation immediately returns. We'd like to
      --  perform cleanup beforehand
      Opt_Context.Set_Help_Enabled (False);

      Opt_Context.Parse
        (Command_Line, On_Argument'Unrestricted_Access, Success, Err);

      if not Success then
         --  Special handling for switch -P where the argument may be
         --  glued with the project file name, as in -Pproject_file
         Put_Line
           (Standard_Error, "Error: " & Glib.Error.Get_Message (Err));
         New_Line;
         Put_Line (Opt_Context.Get_Help (True, null));

         Do_Exit := True;
         Status_Code := 1;

         return;
      end if;

      Opt_Context.Free;
   end Read_Command_Line;

   ----------------------
   -- Startup_Callback --
   ----------------------

   procedure Startup_Callback
     (Application : access Gapplication_Record'Class)
   is
      pragma Unreferenced (Application);
   begin
      Gtk.Handlers.Set_On_Exception
        (Default_Gtk_Mer'Unrestricted_Access);

      OS_Utils.Install_Ctrl_C_Handler (Callbacks.Ctrl_C_Handler'Access);
   end Startup_Callback;

   -----------------------
   -- Activate_Callback --
   -----------------------

   procedure Activate_Callback
     (Application : access Gapplication_Record'Class)
   is
      pragma Unreferenced (Application);
   begin
      --  This callback is here to make GLib happy. Nothing has really to be
      --  done on the activate signal, as GPS allows multiple instances.
      Trace (Me, "GApplication Activated");
   end Activate_Callback;

   ---------------------------
   -- Command_Line_Callback --
   ---------------------------

   function Command_Line_Callback
     (Application  : access Gapplication_Record'Class;
      Command_Line : not null access Gapplication_Command_Line_Record'Class)
      return Glib.Gint
   is
      Status_Code : Glib.Gint;
      Do_Exit     : Boolean;

   begin
      Application.Hold;

      --  Sanitize the environment variables, and perform various init from
      --  them
      Initialize_Environment_Variables (Command_Line);

      --  Now permorm the low level initializations
      Initialize_Low_Level (Status_Code);

      if Status_Code /= 0 then
         Application.Release;
         return Status_Code;
      end if;

      --  Now parse the switches from the command line
      Read_Command_Line (Command_Line, Do_Exit, Status_Code);

      if Do_Exit then
         Application.Release;
         return Status_Code;
      end if;

      --  Finally create the main window, and setup the project

      GPS.Main_Window.Gtk_New
        (GPS_Main, GPS_Home_Dir, Prefix_Dir,
         Gtkada_Application (Application));

      --  We can now release the Application, as the main window took a
      --  hold on it
      Application.Release;

      Set_Project_Name;

      About_Contents := Create_From_Dir
        (Prefix_Dir, "share/gps/about.txt").Read_File;
      if About_Contents = null then
         About_Contents := new String'("");
      end if;

      if Is_Regular_File
        (Create_From_Dir (Prefix_Dir, "share/gps/gps-pro.txt"))
      then
         GPS_Main.Public_Version := False;
      end if;

      Reset_Title (GPS_Main);

      GPS.Menu.Register_Common_Menus (GPS_Main.Kernel);

      Kernel_Callback.Connect
        (Get_MDI (GPS_Main.Kernel), Signal_Child_Selected,
         Child_Selected'Access, GPS_Main.Kernel);
      Kernel_Callback.Connect
        (Get_MDI (GPS_Main.Kernel), Signal_Child_Title_Changed,
         Title_Changed'Access, GPS_Main.Kernel);

      --  Under Windows, pressing the primary button outside of the slider
      --  should jump by a page increment.

      if Config.Host = Windows then
         Set_Property
           (Gtk.Settings.Get_Default,
            Gtk_Primary_Button_Warps_Slider_Property,
            False);
      end if;

      Display_Splash_Screen;

      if Splash = null then
         Timeout_Id := Process_Timeout.Timeout_Add
           (1, Finish_Setup'Unrestricted_Access,
            (GPS_Main.Kernel, null, null, null, null, null, False));
      else
         Timeout_Id := Process_Timeout.Timeout_Add
           (Splash_Timeout, Finish_Setup'Unrestricted_Access,
            (GPS_Main.Kernel, null, null, null, null, null, False));
      end if;

      return 0;
   end Command_Line_Callback;

   ------------------------
   -- File_Open_Callback --
   ------------------------

   procedure File_Open_Callback
     (Application : Gtkada.Application.Gtkada_Application;
      Files       : Gtkada.Application.GFile_Array)
   is
      pragma Unreferenced (Application);

   begin
      if Started then
         Deiconify (GPS_Main);
      end if;

      for File of Files loop
         declare
            Path : constant Glib.UTF8_String :=
                     Gtkada.Application.Get_Path (File);
            File : constant GNATCOLL.VFS.Virtual_File :=
                     GNATCOLL.VFS.Create
                       (GNATCOLL.VFS_Utils.Normalize_Pathname
                          (+Path,
                           Resolve_Links =>
                              not Preferences.Trusted_Mode.Get_Pref));
         begin
            if File_Extension (File) = Project_File_Extension then
               Trace
                 (Me, "... opening project " &
                    Display_Full_Name (File));

               if not Started then
                  Project_Name := File;
               else
                  Load_Project (GPS_Main.Kernel, File);
               end if;

            else
               Trace
                 (Me, "... opening file " &
                    Display_Full_Name (File));

               --  Else, this is handled at the command line level
               if not Started then
                  Files_To_Open.Append
                    ((File         => To_Unbounded_String (+File.Full_Name),
                      Line         => 1,
                      From_Project => False));
               else
                  Open_File_Editor (GPS_Main.Kernel, File, New_File => False);
               end if;
            end if;
         end;
      end loop;

   exception
      when E : others =>
         Trace (Me, E);
   end File_Open_Callback;

   -----------------------
   -- Shutdown_Callback --
   -----------------------

   procedure Shutdown_Callback
     (Application : access Gapplication_Record'Class)
   is
      pragma Unreferenced (Application);
      Kernel   : Kernel_Handle;
      Log_File : Virtual_File;
      Pid_File : Virtual_File;
      Project  : Project_Type;
      Success  : Boolean;

   begin
      if not Cleanup_Needed then
         return;
      end if;

      Kernel   := GPS_Main.Kernel;
      Log_File := Create_From_Dir (Get_Home_Dir (Kernel), +"log");
      Pid_File := Create_From_Dir
        (Get_Home_Dir (Kernel), +("log." & Pid_Image));
      Project  := Get_Project (Kernel);

      Set_Destruction_Flag (Kernel, True);

      Cleanup_Needed := False;
      Exiting := True;

      --  We want to close the debuggers first, to avoid saving debugger
      --  consoles in the desktop.

      GVD_Module.Debug_Terminate (Kernel);

      if Started and then Save_Desktop_On_Exit.Get_Pref then
         Save_Desktop (Kernel);
      end if;

      if Started then
         Get_Messages_Container (Kernel).Save;
         Get_Messages_Container (Kernel).Clear;
      end if;

      if Get_Registry (Kernel).Tree.Status = Default then
         Trace (Me, "Remove default project on disk, no longer used");
         Delete (Project_Path (Project), Success);
      end if;

      --  All tasks should be interrupted before the main window is closed
      --  since they may need to access their consoles.

      Task_Manager.Interrupt_All_Tasks (Get_Task_Manager (Kernel));

      --  Destroy the GUI before the modules, otherwise if some package tries
      --  to access their local module_id, they will generate storage_error.
      --  No module should need to access its GUI anyway when it is destroyed,
      --  since the desktop has already been saved, histories and properties
      --  are handled separately,...
      --  Since the call to destroy below will free the animation at some
      --  point, we no longer want to access/update it past this point.

      Destroy (GPS_Main);

      Free_Modules (Kernel);

      Destroy (Kernel);

      GNATCOLL.Traces.Finalize;

      --  Memory used by the xref database.
      --  ??? This should be done in the ali_reader package

      ALI.ALIs.Free;
      ALI.Units.Free;
      ALI.Withs.Free;
      ALI.Args.Free;
      ALI.Linker_Options.Free;
      ALI.Sdep.Free;
      ALI.Xref.Free;

      --  In case of a normal exit, rename log.<pid> as log to avoid
      --  generating a new log file for each session; this way we still
      --  keep the log file in case of post mortem analysis.
      --  In case of unexpected exit, keep the log file under its original
      --  name, so that it does not get erased by the next session and can
      --  be reported.

      if not Unexpected_Exception
        and then Is_Regular_File (Pid_File)
      then
         Delete (Log_File, Success);
         Rename (Pid_File, Log_File, Success);
      end if;

      Free (Startup_Dir);

      declare
         Tmp : String_Access := Getenv ("GPS_MEMORY_MONITOR");
      begin
         if Tmp.all /= "" then
            GNATCOLL.Memory.Dump
              (Size   => 10,
               Report => GNATCOLL.Memory.All_Reports);
         end if;
         Free (Tmp);
      end;
   end Shutdown_Callback;

   ----------------------
   -- Set_Project_Name --
   ----------------------

   procedure Set_Project_Name is
   begin
      if Passed_Project_Name /= null then
         Project_Name :=
           Create
             (Normalize_Pathname
                  (Filesystem_String (Passed_Project_Name.all),
                   Resolve_Links =>
                   not GPS.Kernel.Preferences.Trusted_Mode.Get_Pref));

         if not Is_Regular_File (Project_Name) then
            if Is_Regular_File
              (+(Full_Name (Project_Name) & Project_File_Extension))
            then
               Project_Name := Create
                 (Normalize_Pathname
                    (Full_Name (Project_Name) & Project_File_Extension,
                     Resolve_Links =>
                     not GPS.Kernel.Preferences.Trusted_Mode.Get_Pref));
               Trace
                 (Me, "Found project: " &
                    Display_Full_Name (Project_Name));
            else
               --  Keep Project_Name even if it is invalid, we will look
               --  for it later on the project path, but the latter is
               --  not known yet at this point
               if Equal (File_Extension (Project_Name),
                         Project_File_Extension)
               then
                  Project_Name :=
                 Create_From_Base (Base_Name => +Passed_Project_Name.all);
               else
                  Project_Name :=
                    Create_From_Base
                      (Base_Name =>
                       +Passed_Project_Name.all & Project_File_Extension);
               end if;

               Trace
                 (Me, "Project not found in current dir: "
                  & Project_Name.Display_Base_Name);
            end if;
         else
            Trace (Me, "Found project: " &
                     Display_Full_Name (Project_Name));
         end if;

         Free (Passed_Project_Name);
      end if;
   end Set_Project_Name;

   ---------------------------
   -- Display_Splash_Screen --
   ---------------------------

   procedure Display_Splash_Screen is
      File   : constant Virtual_File :=
                 Create_From_Dir (Prefix_Dir, "share/gps/gps-splash.png");
      Image  : Gtk_Image;
      Pixbuf : Gdk_Pixbuf;
      Error  : GError;
      FD     : File_Descriptor;

   begin
      if not Hide_GPS
        and then Splash_Screen.Get_Pref
        and then Is_Regular_File (File)
      then
         FD := Open_Read (+File.Full_Name, Binary);

         if About_Contents.all /= "" then
            Splash_Timeout := 4000;
         end if;

         Close (FD);
         Gtk_New (Splash, Window_Toplevel);
         Splash.Set_Hexpand (False);
         Splash.Set_Vexpand (False);
         Set_Property (Splash, Decorated_Property, False);
         Set_Position (Splash, Win_Pos_Center);
         Gdk_New_From_File (Pixbuf, +File.Full_Name, Error);
         Gtk_New (Image, Pixbuf);
         Unref (Pixbuf);
         Add (Splash, Image);
         Show_All (Splash);
      end if;
   end Display_Splash_Screen;

   ------------------
   -- Finish_Setup --
   ------------------

   function Finish_Setup (Data : Process_Data) return Boolean is
      Auto_Load_Project : Boolean := True;
      File_Opened       : Boolean := False;
      Idle_Id           : Glib.Main.G_Source_Id;
      Project           : Project_Type;
      Screen            : Welcome_Screen;
      Icon              : Gdk_Pixbuf;
      pragma Unreferenced (Data, Idle_Id);

      procedure Setup_Debug;
      --  Load appropriate debugger project and set up debugger-related
      --  properties.

      function Setup_Project return Boolean;
      --  When no project has been specified explicitely by the user,
      --  look for a project on the current directory, or use the welcome
      --  dialog
      --  Return False if set up was aborted and GPS should exit.

      procedure Load_Sources;
      --  Load all the source files given on the command line

      -----------------
      -- Setup_Debug --
      -----------------

      procedure Setup_Debug is
      begin
         File_Opened := True;
         Auto_Load_Project := False;

         if Project_Name /= No_File then
            --  Do not clear to keep the welcome message on kernel's console
            Load_Project (GPS_Main.Kernel, Project_Name, Clear => False);
            Project := Get_Project (GPS_Main.Kernel);
         else
            Load_Empty_Project (GPS_Main.Kernel);
            Project := Get_Project (GPS_Main.Kernel);
            Get_Registry (GPS_Main.Kernel).Tree.Set_Status (From_Executable);
         end if;

         --  Project will be overriden when the executable is loaded
         Load_Sources;

         if Debugger_Name /= null then
            Project.Set_Attribute
              (Scenario  => All_Scenarios,
               Attribute => Debugger_Command_Attribute,
               Value     => Debugger_Name.all);
         end if;

         --  ??? re-enable this...
--           if Tools_Host /= null then
--              Project.Set_Attribute
--                (Scenario  => All_Scenarios,
--                 Attribute => Remote_Host_Attribute,
--                 Value     => Tools_Host.all);
--           end if;

         if Target /= null then
            Project.Set_Attribute
              (Scenario  => All_Scenarios,
               Attribute => Program_Host_Attribute,
               Value     => Target.all);
         end if;

         if Protocol /= null then
            Project.Set_Attribute
              (Scenario  => All_Scenarios,
               Attribute => Protocol_Attribute,
               Value     => Protocol.all);
         end if;

         Project.Set_Attribute
           (Scenario  => All_Scenarios,
            Attribute => Languages_Attribute,
            Values    =>
              (new String'("ada"), new String'("c"), new String'("c++")));

         Project.Set_Modified (False);

         Recompute_View (GPS_Main.Kernel);
      end Setup_Debug;

      -------------------
      -- Setup_Project --
      -------------------

      function Setup_Project return Boolean is
         Current : constant Virtual_File := Get_Current_Dir;
         Files   : File_Array_Access;
      begin
         Auto_Load_Project := False;
         Files := Read_Dir (Current, Files_Only);

         for J in Files'Range loop
            if Equal (File_Extension (Files (J)), Project_File_Extension) then
               if Project_Name = No_File then
                  Auto_Load_Project := True;
                  Project_Name := Files (J);
               else
                  Auto_Load_Project := False;
                  exit;
               end if;
            end if;
         end loop;

         Unchecked_Free (Files);

         --  If only one project file was found in the current directory, do
         --  not open the welcome dialog. Likewise if we are loading a script,
         --  or if source files have been specified on the command line.

         if Auto_Load_Project then
            return True;
         end if;

         Load_Sources;

         if File_Opened then
            return True;
         end if;

         if Batch_File /= null then
            Load_Default_Project
              (GPS_Main.Kernel, Get_Current_Dir,
               Load_Default_Desktop => True,
               Clear                => False);
            return True;
         end if;

         --  Load the project selected by the user

         Gtk_New (Screen, GPS_Main.Kernel, Project_Name);

         --  Remove the splash screen, since it conflicts with the
         --  welcome dialog.

         if Splash /= null then
            Destroy (Splash);
            Splash := null;
         end if;

         --  If the user wants to quit immediately, so be it

         case Run_Welcome (Screen) is
            when Quit_GPS =>
               Destroy (Screen);
               GPS_Main.Application.Quit;

               return False;

            when Project_Loaded =>
               --  Desktop was already loaded when the project itself
               --  was loaded.
               null;
         end case;

         Destroy (Screen);

         return True;
      exception
         when E : others =>
            Unexpected_Exception := True;
            Trace (Me, E);
            if not Hide_GPS then
               Error_Message
                 ("Unexpected fatal error during project load.");
            end if;

            GPS_Main.Application.Quit;

            return False;
      end Setup_Project;

      ------------------
      -- Load_Sources --
      ------------------

      procedure Load_Sources is
      begin
         --  Temporarily restore start-up dir, so that relative paths are
         --  properly computed

         for File_Item of Files_To_Open loop
            --  If no project has been loaded yet, load a default project
            --  and desktop before opening source editors.

            if not Auto_Load_Project and then not File_Opened then
               Load_Default_Project
                 (GPS_Main.Kernel, Get_Current_Dir,
                  Load_Default_Desktop => True,
                  Clear                => False);
            end if;

            Open_File_Editor
              (GPS_Main.Kernel,
               Create
                 (Normalize_To_OS_Case (+To_String (File_Item.File)),
                  GPS_Main.Kernel,
                  Use_Source_Path => File_Item.From_Project,
                  Use_Object_Path => False),
               File_Item.Line);
            File_Opened := True;
         end loop;

         if not Auto_Load_Project and then not File_Opened then
            Load_Default_Project
              (GPS_Main.Kernel, Get_Current_Dir,
               Load_Default_Desktop => True,
               Clear                => False);
         end if;

         --  Load a dummy project, in case the wizard needs to be launched

         if not Auto_Load_Project and then not File_Opened then
            Load_Empty_Project (GPS_Main.Kernel);
         end if;
      end Load_Sources;

   begin
      Cleanup_Needed := True;

      --  Register the default filters, so that other modules can create
      --  contextual menus

      GPS.Kernel.Contexts.Register_Default_Filters (GPS_Main.Kernel);

      --  Register this module first, in case someone needs to print a message
      --  in the console right away

      GPS.Kernel.Console.Register_Module (GPS_Main.Kernel);

      GPS.Kernel.MDI.Register_Module (GPS_Main.Kernel);

      --  Register the locations view before all the modules that register a
      --  highlighting category. Otherwise, when loading the desktop, the
      --  locations view might create highligthting with categories that don't
      --  exist.

      GPS.Location_View.Register_Module (GPS_Main.Kernel);

      --  Register all modules (scripting languages must be registered first)

      Shell_Script.Register_Module (GPS_Main.Kernel);

      if Active (Python_Trace) then
         Python_Module.Register_Module (GPS_Main.Kernel);
      end if;

      Register_Default_Script_Commands (GPS_Main.Kernel);
      GPS.Kernel.Messages.Shell.Register_Commands (GPS_Main.Kernel);
      GPS.Kernel.Styles.Shell.Register_Commands (GPS_Main.Kernel);

      --  Register this very early so that other modules can access remote
      --  files. Note that we need the scripting capabilities to be initialized
      --  before the remote mode.

      Remote_Module.Register_Module (GPS_Main.Kernel);
      GPS.Kernel.Remote.Register_Module (GPS_Main.Kernel);
      Remote.Rsync.Register_Module (GPS_Main.Kernel);

      GPS.Location_View.Register_Commands (GPS_Main.Kernel);
      GPS.Kernel.Clipboard.Register_Commands (GPS_Main.Kernel);

      --  We then must register the keymanager, so that other modules can
      --  register their keys

      KeyManager_Module.Register_Module (GPS_Main.Kernel);
      KeyManager_Module.Macros.Register_Module (GPS_Main.Kernel);
      Command_Window.Register_Module (GPS_Main.Kernel);
      Register_Keys (GPS_Main);

      --  Register the standard hooks. Other modules were able to connect to
      --  these earlier anyway, but these add shell commands, and therefore
      --  must be loaded after the script modules

      Register_Action_Hooks (GPS_Main.Kernel);
      Register_Standard_Hooks (GPS_Main.Kernel);

      --  Load the theme manager module immediately, so that any customization
      --  file or module can provide its own themes.

      Theme_Manager_Module.Register_Module (GPS_Main.Kernel);

      Vsearch.Register_Module (GPS_Main.Kernel);

      if Active (Help_Trace) then
         Help_Module.Register_Module (GPS_Main.Kernel);
      end if;

      --  Initialize the aliases module before the src_editor, since the
      --  latter registers special expansion functions

      if Active (Aliases_Trace) then
         Aliases_Module.Register_Module (GPS_Main.Kernel);
      end if;

      --  Initialize Src_Editor_Module early, since many modules depend
      --  on the editor API, and also during finalization, modules may need
      --  to access marks that are handled by this module.

      Src_Editor_Module.Register_Module (GPS_Main.Kernel);

      --  Initialize the ada semantic tree module

      Ada_Semantic_Tree_Module.Register_Module
        (GPS_Main.Kernel,
         Create_From_Dir (Prefix_Dir, "share/gps/predefined_ada.xml"));

      if Active (Call_Graph_Trace) then
         Browsers.Call_Graph.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Call_Graph_View_Trace) then
         Call_Graph_Views.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Clipboard_View_Trace) then
         Clipboard_Views.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Dependency_Trace) then
         Browsers.Dependency_Items.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Files_Explorer_Trace) then
         Project_Explorers_Files.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Browser_Trace) then
         Browsers.Projects.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Entities_Browser_Trace) then
         Browsers.Entities.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Elaboration_Browser_Trace) then
         Browsers.Elaborations.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Revision_Views_Trace) then
         Revision_Views.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Viewer_Trace) then
         Project_Viewers.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Outline_View_Trace) then
         Outline_View.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Explorer_Trace) then
         Project_Explorers.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Properties_Trace) then
         Project_Properties.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (GNATTest_Trace) then
         GNATTest_Module.Register_Module (GPS_Main.Kernel);
      end if;

      KeyManager_Module.Register_Key_Menu (GPS_Main.Kernel);

      if Active (External_Editor_Trace) then
         External_Editor_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Builder_Trace) then
         Builder_Facility_Module.Register_Module (GPS_Main.Kernel);
         Builder_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Toolchains_Trace) then
         Toolchains_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Toolchains_Editor_Trace) then
         Toolchains_Editor.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (GVD_Trace) then
         GVD_Module.Register_Module (GPS_Main.Kernel);
      end if;

      Vdiff2_Module.Register_Module (GPS_Main.Kernel);

      if Active (Scenario_View_Trace) then
         Scenario_Views.Register_Module (GPS_Main.Kernel);
      end if;

      GPS.Search.GUI.Register_Module (GPS_Main.Kernel);
      Task_Manager.GUI.Register_Module (GPS_Main.Kernel);
      GPS.Kernel.Task_Manager.Register_Module (GPS_Main.Kernel);

      if Active (VCS_Trace) then
         VCS_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (VFS_Trace) then
         VFS_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Codefix_Trace) then
         Codefix_Module.Register_Module (GPS_Main.Kernel);
      end if;

      GPS.Kernel.Preferences.Register_Module (GPS_Main.Kernel);

      if Active (Custom_Trace) then
         Custom_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Project_Templates_Trace) then
         Project_Templates.GPS.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Refactor_Trace) then
         Refactoring_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Docgen2_Trace) then
         Docgen2_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (Code_Analysis_Trace) then
         Code_Analysis_Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (CodePeer_Trace) then
         CodePeer.Module.Register_Module (GPS_Main.Kernel);
      end if;

      if Active (GNATStack_Trace) then
         GNATStack.Module.Register_Module (GPS_Main.Kernel);
      end if;

      --  Register the supported languages and their associated LI handlers

      Ada_Module.Register_Module (GPS_Main.Kernel);

      if Active (CPP_Trace) then
         Cpp_Module.Register_Module (GPS_Main.Kernel);
      end if;

      Casing_Exceptions.Register_Module (GPS_Main.Kernel);

      Switches_Chooser.Scripts.Register_Module (GPS_Main.Kernel);

      --  Load these last, since this requires the collaboration of other
      --  modules

      Bookmark_Views.Register_Module (GPS_Main.Kernel);

      Buffer_Views.Register_Module (GPS_Main.Kernel);

      if Active (Startup_Trace) then
         Startup_Module.Register_Module (GPS_Main.Kernel);
      end if;

      GPS.Kernel.Custom.Parse_Startup_Scripts_List (GPS_Main.Kernel);

      --  Load system files.
      --  This must be done before loading the Navigation module, since that
      --  module relies on icons defined in custom files.

      if Active (Custom_Trace) then
         Load_System_Custom_Files (GPS_Main.Kernel);
      end if;

      --  Create a hook for when GPS is started

      Register_Hook_No_Args (GPS_Main.Kernel, GPS_Started_Hook);

      --  Load the customization files before loading the actual projects,
      --  so that the usual hooks are taken into account right from the
      --  beginning

      if Active (Python_Trace) then
         Python_Module.Load_System_Python_Startup_Files (GPS_Main.Kernel);
      end if;

      --  The system wide custom files have been loaded, load the user's ones

      if Active (Custom_Trace) then
         Load_User_Custom_Files (GPS_Main.Kernel);
      end if;

      if Active (Python_Trace) then
         Python_Module.Load_User_Python_Startup_Files (GPS_Main.Kernel);
      end if;

      Navigation_Module.Register_Module (GPS_Main.Kernel);

      if Server_Mode then
         Socket_Module.Register_Module (GPS_Main.Kernel, Port_Number);
      end if;

      --  Load preferences, but only after loading custom files, to make sure
      --  the themes loaded at startup are still overriden by the user's
      --  local choices. Note that the preferences have already been loaded
      --  once before, to take into account the splash screen pref for instance

      Load_Preferences (GPS_Main.Kernel);

      --  Load the custom keys last, so that they override everything else set
      --  so far.
      KeyManager_Module.Load_Custom_Keys (GPS_Main.Kernel);

      --  Set default icon for dialogs and windows
      --  ??? as soon as gdk_pixbuf is modified to derive from Glib.GObject
      --   construct an icon list from gps-icon-16, gps-icon-32 and gps-icon-48
      --   and call Set_Default_Icon_List

      Icon := Render_Icon_Pixbuf (GPS_Main, "gps-icon-32", Icon_Size_Dialog);

      if Icon /= null then
         Set_Default_Icon (Icon);
      end if;

      --  Print a welcome message in the console, but before parsing the error
      --  messages, so that these are visible

      GPS_Main.Kernel.Insert
        (-"Welcome to GPS " & Config.Version &
         " (" & Config.Source_Date &
         (-") hosted on ") & Config.Target & ASCII.LF &
         (-"the GNAT Programming Studio") & ASCII.LF & About_Contents.all &
         "(c) 2001-2013 AdaCore" & ASCII.LF);
      Free (About_Contents);

      --  Apply the preferences to the MDI. In particular, we want to set the
      --  default position for notebook tabs, since they can be overriden by
      --  the desktop (and changing that default later on would switch all
      --  notebooks)

      Configure_MDI (GPS_Main.Kernel);

      --  We now make sure we have a project loaded, so that opening editors
      --  will work correctly.

      --  If no project has been specified on the command line, try to open
      --  the first one in the current directory (if any).

      if Program_Args /= null then
         --  --debug has been specified
         --  Load project, and set debugger-related project properties

         Setup_Debug;

      else
         if Project_Name /= No_File
           and then not Is_Regular_File (Project_Name)
         then
            --  We can finally search on ADA_PROJECT_PATH, which is now known

            declare
               P : constant Virtual_File := Locate_Regular_File
                 (Base_Name (Project_Name),
                  Get_Registry (GPS_Main.Kernel)
                  .Environment.Predefined_Project_Path);
            begin
               if P /= No_File then
                  Project_Name := P;
               else
                  --  Keep the user project, which will display an error in
                  --  GPS.
                  null;
               end if;
            end;
         end if;

         if Project_Name = No_File then
            if Server_Mode then
               Auto_Load_Project := True;
               Load_Empty_Project (GPS_Main.Kernel);
               Load_Sources;

            else
               if not Setup_Project then
                  return False;
               end if;
            end if;
         end if;
      end if;

      if Auto_Load_Project and then Project_Name /= No_File then
         --  Do not clear to keep the welcome message on kernel's console
         Load_Project (GPS_Main.Kernel, Project_Name, Clear => False);
         Load_Sources;
      end if;

      if not File_Opened
        and then not Has_User_Desktop (GPS_Main.Kernel)
      then
         Display_Welcome_Page (GPS_Main.Kernel);
      end if;

      if Splash /= null then
         Destroy (Splash);
      end if;

      --  After loading the project, force remote host assignment if
      --  Tools_Host is not null

      if Tools_Host /= null then
         for S in Distant_Server_Type'Range loop
            GPS.Kernel.Remote.Assign
              (GPS_Main.Kernel, S, Tools_Host.all, Reload_Prj => True);
         end loop;
      end if;

      --  Disable tip of the day pop up window is --hide is
      --  specified.

      if Hide_GPS then
         Set_Pref (Tip_Of_The_Day, GPS_Main.Kernel, False);
      end if;

      --  Load the preferences set when creating the kernel
      --  This needs to be done after all the graphical eleents have been
      --  created, to be sure they are realized and will take the preferences
      --  into account.

      declare
         D : aliased Preference_Hooks_Args :=
           (Hooks_Data with Pref => null);
      begin
         Run_Hook (GPS_Main.Kernel, Preference_Changed_Hook, D'Access);
      end;

      if not Hide_GPS then
         GPS_Main.Present;
      end if;

      if Program_Args /= null then
         --  Initialize the debugger after having executed scripts if any,
         --  so that it is possible to set up the environment before starting
         --  a debug session.
         --  Needs to be done after the call to Show, so that the GPS window
         --  already has a proper size, otherwise we might end up with windows
         --  with height=0 or width=0
         GVD_Module.Initialize_Debugger (GPS_Main.Kernel, Program_Args.all);
      end if;

      --  Execute the startup scripts now, even though it is recommended that
      --  they connect to the GPS_Started_Hook if they have graphical actions
      --  to do
      --  This has to be launched after the call to Show, otherwise, the
      --  mini-loop launched in the trace function of the python module
      --  displatchs FOCUS_CHANGE, even if keyboard never been ungrab. This
      --  causes the editor to be uneditable on some cases on windows.

      if Batch_Script /= null then
         Execute_Batch (Batch_Script.all, As_File => False);
      end if;

      if Batch_File /= null then
         Execute_Batch (Batch_File.all, As_File => True);
         Free (Batch_File);
      end if;

      Started := True;

      --  Set the title of the GPS window
      Set_Main_Title
        (GPS_Main.Kernel, Get_Focus_Child (Get_MDI (GPS_Main.Kernel)));

      Idle_Id := Glib.Main.Idle_Add (On_GPS_Started'Access);

      return False;
   end Finish_Setup;

   -------------------
   -- Execute_Batch --
   -------------------

   procedure Execute_Batch (Batch : String; As_File : Boolean) is
      Executed : Boolean := False;
      Script   : Scripting_Language;
      Errors   : Boolean;
   begin
      Trace (Me, "Execute_Batch: " & Batch);
      for J in Batch'Range loop
         if Batch (J) = ':' then
            Script := Lookup_Scripting_Language
            (Get_Scripts (GPS_Main.Kernel), Batch (Batch'First .. J - 1));

            if Script = null then
               exit;
            end if;

            if As_File then
               Execute_File
                 (Script   => Script,
                  Filename => Normalize_Pathname
                     (Batch (J + 1 .. Batch'Last), Startup_Dir.all),
                  Show_Command => False,
                  Errors   => Errors);
            else
               GNATCOLL.Scripts.Execute_Command
                 (Script   => Script,
                  CL       => Parse_String
                    (Batch (J + 1 .. Batch'Last),
                     Command_Line_Treatment (Script)),
                  Errors   => Errors);
            end if;

            Executed := True;
            exit;
         end if;
      end loop;

      if not Executed then
         if As_File then
            Insert
              (GPS_Main.Kernel,
               -"Language unknown for --load command line switch",
               Mode => Error);
         else
            Insert
              (GPS_Main.Kernel,
               -"Language unknown for --script command line switch",
               Mode => Error);
         end if;
      end if;

   exception
      when E : others =>
         if As_File then
            Insert (GPS_Main.Kernel,
                    -"Error when executing the script for -batch switch",
                    Mode => Error);
         else
            Insert (GPS_Main.Kernel,
                    -"Error when executing the script for --script switch",
                    Mode => Error);
         end if;
         Trace (Me, E);
   end Execute_Batch;

   -----------------------------------
   -- Default_Gtk_Mer --
   -----------------------------------

   procedure Default_Gtk_Mer
     (Occurrence : Ada.Exceptions.Exception_Occurrence)
   is
   begin
      Trace (Gtk_Errors, Occurrence);
   end Default_Gtk_Mer;

   -------------------
   -- Error_Message --
   -------------------

   procedure Error_Message (Message : String) is
      Log_File : constant Virtual_File :=
                   Create_From_Dir
                     (Get_Home_Dir (GPS_Main.Kernel),
                      "log");
      Pid_File : constant Virtual_File :=
                   Create_From_Dir
                     (Get_Home_Dir (GPS_Main.Kernel),
                      +("log." & Pid_Image));
      Str      : Virtual_File;

   begin
      if Is_Regular_File (Pid_File) then
         Str := Pid_File;
      else
         Str := Log_File;
      end if;

      if Active (Testsuite_Handle) then
         Put_Line ("Error message generated: " & Message);
      else
         Button := Message_Dialog
           (Message
            & ASCII.LF
            & "Please report with contents of " & Str.Display_Full_Name,
            Error, Button_OK,
            Title         => -"Fatal Error",
            Justification => Justify_Left);
      end if;
   end Error_Message;

   Darwin_Host : Boolean := False;
   Dead        : Boolean;
   Status      : Glib.Gint;
   pragma Unreferenced (Dead);

begin
   --  Create and setup a Gtk Applciation

   Application := Gtk_Application_New
     ("com.adacore.GPS",
      Glib.Application.G_Application_Handles_Open +
        Glib.Application.G_Application_Handles_Command_Line +
          Glib.Application.G_Application_Send_Environment +
            Glib.Application.G_Application_Non_Unique);
   Application.Set_Default;

   Darwin_Host :=
     Ada.Strings.Fixed.Index (Config.Target, "darwin") > 0;

   if Config.Host = Config.Unix and then not Darwin_Host then
      --  On systems with DBus and an existing DBus configuration
      --  for the system's gtk, we don't want to open a session as
      --  we're using a different gtk library, that may have
      --  incompatibilities or missing modules.
      Glib.Properties.Set_Property
        (Application, Register_Session_Property, False);
   else
      Glib.Properties.Set_Property
        (Application, Register_Session_Property, True);
   end if;

   Application.On_Startup (Startup_Callback'Unrestricted_Access);
   Application.On_Activate (Activate_Callback'Unrestricted_Access);
   Application.On_Command_Line (Command_Line_Callback'Unrestricted_Access);
   Application.On_Open (File_Open_Callback'Unrestricted_Access);
   Application.On_Shutdown (Shutdown_Callback'Unrestricted_Access);

   Status := Application.Run;

   if Status /= 0 then
      Ada.Text_IO.Put_Line ("Exiting with status " & Status'Img);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Status));
   else
      Ada.Text_IO.Put_Line ("Exiting normally");
   end if;

   Trace (Me, "Done");

exception
   when E : others =>
      Unexpected_Exception := True;
      Trace (Me, E);
      Error_Message
        ("Unexpected fatal error, GPS is in an inconsistent state"
         & ASCII.LF
         & "You will be asked to save modified files before GPS exits");
      Dead := Save_MDI_Children (GPS_Main.Kernel, Force => False);
end GPS.Main;
