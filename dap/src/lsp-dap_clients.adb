------------------------------------------------------------------------------
--                               GNAT Studio                                --
--                                                                          --
--                        Copyright (C) 2021, AdaCore                       --
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

with Ada.Strings.Wide_Unbounded; use Ada.Strings.Wide_Unbounded;
with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Wide_Text_IO;

with VSS.JSON.Streams.Readers.Simple;
with VSS.Stream_Element_Vectors.Conversions;
with VSS.Strings.Conversions;
with VSS.Text_Streams.Memory_UTF8_Input;
with LSP.JSON_Streams;
with DAP.Tools;            use DAP.Tools;
with GPS.Kernel;           use GPS.Kernel;
with GVD;
with GVD.Breakpoints_List; use GVD.Breakpoints_List;

package body LSP.DAP_Clients is

   procedure Initialize
     (Self   : in out Client;
      Kernel :        access GPS.Kernel.Kernel_Handle_Record'Class)
   is
   begin
      Self.Kernel := Kernel;
   end Initialize;

   function Get_Request_ID (Self : in out Client) return LSP.Types.LSP_Number
   is
      ID : constant LSP.Types.LSP_Number := Self.Request_Id;
   begin
      Self.Request_Id := Self.Request_Id + 1;
      return ID;
   end Get_Request_ID;

   overriding procedure On_Raw_Message
     (Self    : in out Client; Data : Ada.Strings.Unbounded.Unbounded_String;
      Success : in out Boolean)
   is
      procedure Look_Ahead
        (Id     : out LSP.Types.LSP_Number_Or_String;
         A_Type : out LSP.Types.LSP_String;
         Method : out LSP.Types.Optional_String; Is_Error : in out Boolean);

      Memory : aliased VSS.Text_Streams.Memory_UTF8_Input
        .Memory_UTF8_Input_Stream;

      procedure Look_Ahead
        (Id     : out LSP.Types.LSP_Number_Or_String;
         A_Type : out LSP.Types.LSP_String;
         Method : out LSP.Types.Optional_String; Is_Error : in out Boolean)
      is
         use all type VSS.JSON.Streams.Readers.JSON_Event_Kind;

         R  : aliased VSS.JSON.Streams.Readers.Simple.JSON_Simple_Reader;
         JS : aliased LSP.JSON_Streams.JSON_Stream (False, R'Access);

      begin
         R.Set_Stream (Memory'Unchecked_Access);
         R.Read_Next;
         pragma Assert (R.Is_Start_Document);
         R.Read_Next;
         pragma Assert (R.Is_Start_Object);
         R.Read_Next;
         while not R.Is_End_Object loop
            pragma Assert (R.Is_Key_Name);
            declare
               Key : constant String :=
                 VSS.Strings.Conversions.To_UTF_8_String (R.Key_Name);
            begin
               R.Read_Next;

               if Key = "seq" then
                  case R.Event_Kind is
                     when String_Value =>
                        Id := (Is_Number => False, String => R.String_Value);
                     when Number_Value =>
                        Id :=
                          (Is_Number => True,
                           Number    =>
                             LSP.Types.LSP_Number
                               (R.Number_Value.Integer_Value));
                     when others =>
                        raise Constraint_Error;
                  end case;
                  R.Read_Next;
               elsif Key = "type" then
                  pragma Assert (R.Is_String_Value);
                  A_Type := LSP.Types.To_LSP_String (R.String_Value);
                  R.Read_Next;
               elsif Key = "command" then
                  pragma Assert (R.Is_String_Value);
                  Method :=
                    (Is_Set => True,
                     Value  => LSP.Types.To_LSP_String (R.String_Value));
                  R.Read_Next;
               elsif Key = "success" then
                  Is_Error := not R.Boolean_Value;
                  JS.Skip_Value;
               else
                  JS.Skip_Value;
               end if;
            end;
         end loop;

         Memory.Rewind;
      end Look_Ahead;

      Reader : aliased VSS.JSON.Streams.Readers.Simple.JSON_Simple_Reader;
      Stream : aliased LSP.JSON_Streams.JSON_Stream
        (Is_Server_Side => False, R => Reader'Unchecked_Access);
      Id      : LSP.Types.LSP_Number_Or_String;
      Command : LSP.Types.Optional_String;
      A_Type  : LSP.Types.LSP_String;

      Is_Error : Boolean := False;

   begin
      Success := False;
      Self.Error_Message.Clear;
      --  First, cleanup error message from previous value.

      Memory.Set_Data
        (VSS.Stream_Element_Vectors.Conversions.Unchecked_From_Unbounded_String
           (Data));

      Look_Ahead (Id, A_Type, Command, Is_Error);
      Reader.Set_Stream (Memory'Unchecked_Access);
      Stream.R.Read_Next;
      pragma Assert (Stream.R.Is_Start_Document);
      Stream.R.Read_Next;
      pragma Assert (Stream.R.Is_Start_Object);
      Success := True;

      if A_Type = "event" then
         --  there are 16 events to parse te be able to fully react to
         --  all the events the DA sends us.
         Put_Line ("=====");
         Put_Line (Ada.Strings.Unbounded.To_String (Data));
         Put_Line ("=====");
      elsif A_Type = "response" then
         Put_Line ("=====");
         Put_Line (Ada.Strings.Unbounded.To_String (Data));
         Put_Line ("=====");

         if Command.Is_Set then
            if Command.Value = "initialize" then
               declare
                  init_rp : aliased InitializeResponse;
               begin
                  Read_InitializeResponse
                    (S => Stream'Access, V => init_rp'Unchecked_Access);
                  Insert
                    (Self.Kernel,
                     "Init: '" &
                     VSS.Strings.Conversions.To_UTF_8_String
                       (init_rp.message) &
                     "'" & " Success: " & init_rp.success'Image);
               end;
               Put_Line
                 ("Here for example I can handle the initialize response");
            elsif Command.Value = "disconnect" then
               Put_Line ("Here we disconnect the debug adapter and kill it");
               Self.Stop;
            elsif Command.Value = "launch" then
               Put_Line ("Here we handle the launch response");
            elsif Command.Value = "setBreakpoints" then
               Put_Line ("Here we handle the setBreakpoints response");
            elsif Command.Value = "configurationDone" then
               Put_Line ("Here we handle the configurationDone response");
            elsif Command.Value = "threads" then
               Put_Line ("Here we handle the threads response");
            elsif Command.Value = "stackTrace" then
               Put_Line ("Here we handle the stackTrace response");
            elsif Command.Value = "scopes" then
               Put_Line ("Here we handle the scopes response");
            elsif Command.Value = "variables" then
               Put_Line ("Here we handle the variables response");
            elsif Command.Value = "continue" then
               Put_Line ("Here we handle the continue response");
            else
               Put_Line ("Unkwown command: ");
               Ada.Wide_Text_IO.Put_Line
                 (To_Wide_String (Unbounded_Wide_String (Command.Value)));
            end if;
         end if;
         Put_Line ("=====");
      end if;

   end On_Raw_Message;

   overriding function Error_Message
     (Self : Client) return VSS.Strings.Virtual_String
   is
   begin
      return VSS.Strings.Empty_Virtual_String;
   end Error_Message;

end LSP.DAP_Clients;
