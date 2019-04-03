------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2018-2019, AdaCore                     --
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

with Ada.Strings.UTF_Encoding;
with GNAT.OS_Lib;

with GNATCOLL.JSON;
with GNATCOLL.Traces;    use GNATCOLL.Traces;

with GPS.Editors;
with GPS.Kernel.Project;
with GPS.LSP_Client.Utilities;
with Language;

package body GPS.LSP_Clients is

   Me : constant Trace_Handle := Create ("GPS.LSP_CLIENT");

   function "+" (Text : Ada.Strings.UTF_Encoding.UTF_8_String)
     return LSP.Types.LSP_String renames
       LSP.Types.To_LSP_String;

   procedure Process_Command_Queue (Self : in out LSP_Client'Class);

   -------------
   -- Enqueue --
   -------------

   procedure Enqueue
     (Self : in out LSP_Client'Class;
      Item : Command) is
   begin
      if Self.Is_Ready and then Self.Commands.Is_Empty then
         Self.Process_Command (Item);
      else
         Self.Commands.Append (Item);
      end if;
   end Enqueue;

   -------------------------
   -- Initialize_Response --
   -------------------------

   overriding procedure Initialize_Response
     (Self     : not null access Response_Handler;
      Request  : LSP.Types.LSP_Number;
      Response : LSP.Messages.Initialize_Response)
   is
      pragma Unreferenced (Request);
   begin
      Self.Client.Server_Capabilities := Response.result.capabilities;

      if Response.result.capabilities.textDocumentSync.Is_Set then
         if Response.result.capabilities.textDocumentSync.Is_Number then
            case Response.result.capabilities.textDocumentSync.Value is
            when LSP.Messages.None =>
               Self.Client.Text_Document_Synchronization :=
                 GPS.LSP_Client.Text_Documents.Full;

            when LSP.Messages.Full =>
               Self.Client.Text_Document_Synchronization :=
                 GPS.LSP_Client.Text_Documents.Full;

            when LSP.Messages.Incremental =>
               Self.Client.Text_Document_Synchronization :=
                 GPS.LSP_Client.Text_Documents.Incremental;
            end case;

         else
            Self.Client.Text_Document_Synchronization :=
              GPS.LSP_Client.Text_Documents.Full;
         end if;

      else
         Self.Client.Text_Document_Synchronization :=
           GPS.LSP_Client.Text_Documents.Full;
      end if;

      Self.Client.Is_Ready := True;
      Self.Client.Initialized;

      Self.Client.Listener.Server_Started;

      Process_Command_Queue (Self.Client.all);
   end Initialize_Response;

   --------------
   -- Is_Ready --
   --------------

   function Is_Ready (Self : LSP_Client'Class) return Boolean is
   begin
      return Self.Is_Ready;
   end Is_Ready;

   --------------
   -- On_Error --
   --------------

   overriding procedure On_Error
     (Self  : in out LSP_Client;
      Error : String) is
   begin
      Me.Trace ("On_Error:" & Error);
      Self.Is_Ready := False;
   end On_Error;

   ----------------
   -- On_Started --
   ----------------

   overriding procedure On_Started (Self : in out LSP_Client) is
      Root    : constant GNATCOLL.VFS.Virtual_File :=
                  GPS.Kernel.Project.Get_Project
                    (Self.Kernel).Project_Path.Dir;
      --  ??? Root directory of the project is directoy where
      --  project file is stored.
      --  ??? Must be synchronized with ada.projectFile passed in
      --  WorkspaceDidChangeConfiguration notification.
      Id      : LSP.Types.LSP_Number;
      My_PID  : constant Integer :=
                  GNAT.OS_Lib.Pid_To_Integer (GNAT.OS_Lib.Current_Process_Id);
      Request : constant LSP.Messages.InitializeParams :=
                  (processId    => (True, My_PID),
                   rootPath     => +Root.Display_Full_Name,
                   rootUri      =>
                     GPS.LSP_Client.Utilities.To_URI (Root),
                   capabilities =>
                     (workspace => (applyEdit => LSP.Types.False,
                                       others    => <>),
                      textDocument => <>),
                   trace        => LSP.Types.Unspecified);

   begin
      Self.Initialize_Request (Id, Request);
   end On_Started;

   ---------------------
   -- Process_Command --
   ---------------------

   procedure Process_Command
     (Self : in out LSP_Client'Class;
      Item : Command)
   is
      procedure Process_Open_File;
      procedure Process_Changed_File;
      procedure Process_Close_File;

      --------------------------
      -- Process_Changed_File --
      --------------------------

      procedure Process_Changed_File is
      begin
         Self.Text_Document_Did_Change
           (Item.Handler.Get_Did_Change_Message
              (Self.Text_Document_Synchronization));
      end Process_Changed_File;

      ------------------------
      -- Process_Close_File --
      ------------------------

      procedure Process_Close_File is
         Value : constant LSP.Messages.DidCloseTextDocumentParams :=
                   (textDocument =>
                      (uri        =>
                         GPS.LSP_Client.Utilities.To_URI (Item.File)));

      begin
         Self.Text_Document_Did_Close (Value);
      end Process_Close_File;

      -----------------------
      -- Process_Open_File --
      -----------------------

      procedure Process_Open_File is
         Factory : constant GPS.Editors.Editor_Buffer_Factory_Access :=
                     Self.Kernel.Get_Buffer_Factory;
         Buffer  : constant GPS.Editors.Editor_Buffer'Class := Factory.Get
           (File        => Item.Handler.File,
            Open_Buffer => True,
            Open_View   => False);
         Lang    : constant not null Language.Language_Access :=
                     Buffer.Get_Language;
         Value   : constant LSP.Messages.DidOpenTextDocumentParams :=
                     (textDocument =>
                        (uri        =>
                           GPS.LSP_Client.Utilities.To_URI
                             (Item.Handler.File),
                         languageId => +Lang.Get_Name,
                         version    => 0,
                         text       => +Buffer.Get_Chars));

      begin
         Self.Text_Document_Did_Open (Value);
      end Process_Open_File;

   begin
      case Item.Kind is
         when Open_File =>
            Process_Open_File;

         when Changed_File =>
            Process_Changed_File;

         when Close_File =>
            Process_Close_File;
      end case;
   end Process_Command;

   ---------------------------
   -- Process_Command_Queue --
   ---------------------------

   procedure Process_Command_Queue (Self : in out LSP_Client'Class) is
   begin
      --  ??? Must be rewritten for asynchronous execution.

      while not Self.Commands.Is_Empty loop
         Self.Process_Command (Self.Commands.First_Element);
         Self.Commands.Delete_First;
      end loop;
   end Process_Command_Queue;

   -----------------------------------
   -- Send_Text_Document_Did_Change --
   -----------------------------------

   overriding procedure Send_Text_Document_Did_Change
     (Self     : in out LSP_Client;
      Document : not null
        GPS.LSP_Client.Text_Documents.Text_Document_Handler_Access)
   is
      use type GPS.LSP_Client.Text_Documents.Text_Document_Handler_Access;

   begin
      for Command of Self.Commands loop
         if Command.Kind = Changed_File
           and then Command.Handler = Document
         then
            --  Nothing to do, DidChangeTextDocument notification has been
            --  requested.

            return;
         end if;
      end loop;

      Self.Enqueue ((Changed_File, Document));
   end Send_Text_Document_Did_Change;

   ----------------------------------
   -- Send_Text_Document_Did_Close --
   ----------------------------------

   overriding procedure Send_Text_Document_Did_Close
     (Self     : in out LSP_Client;
      Document : not null
        GPS.LSP_Client.Text_Documents.Text_Document_Handler_Access) is
   begin
      --  ??? Should check for incomplete Change_File command in queue and
      --  modify it properly.

      Self.Enqueue ((Close_File, Document.File));
   end Send_Text_Document_Did_Close;

   ---------------------------------
   -- Send_Text_Document_Did_Open --
   ---------------------------------

   overriding procedure Send_Text_Document_Did_Open
     (Self     : in out LSP_Client;
      Document : not null
        GPS.LSP_Client.Text_Documents.Text_Document_Handler_Access) is
   begin
      Self.Enqueue ((Open_File, Document));
   end Send_Text_Document_Did_Open;

   -----------
   -- Start --
   -----------

   procedure Start
     (Self       : aliased in out LSP_Client;
      Executable : String;
      Arguments  : Spawn.String_Vectors.UTF_8_String_Vector) is
   begin
      Self.Set_Response_Handler (Self.Response_Handler'Unchecked_Access);

      Self.Set_Program (Executable);
      Self.Set_Arguments (Arguments);
      --  TODO: Self.Set_Environment
      --  TODO: Self.Set_Working_Directory
      Me.Trace ("Starting '" & Executable & ''');
      Self.Start;
   end Start;

end GPS.LSP_Clients;
