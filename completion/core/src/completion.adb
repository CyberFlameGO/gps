------------------------------------------------------------------------------
--                               GNAT Studio                                --
--                                                                          --
--                     Copyright (C) 2006-2021, AdaCore                     --
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

with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Unchecked_Deallocation;

with Glib.Unicode; use Glib.Unicode;

package body Completion is

   use Completion_List_Pckg;

   ----------
   -- Free --
   ----------

   procedure Free (List : in out Completion_List) is
   begin
      Free (List.List);
      Free (List.Searched_Identifier);
   end Free;

   --------------------------
   -- Get_Completed_String --
   --------------------------

   function Get_Completed_String (This : Completion_List) return String
   is
     (if This.Searched_Identifier = null then
         ""
      else
         This.Searched_Identifier.all);

   ----------
   -- Free --
   ----------

   procedure Free (Context : in out Completion_Context_Record) is
      pragma Unreferenced (Context);
   begin
      null;
   end Free;

   ----------
   -- Free --
   ----------

   procedure Free (Context : in out Completion_Context) is
      procedure Internal is new Ada.Unchecked_Deallocation
        (Completion_Context_Record'Class, Completion_Context);
   begin
      Internal (Context);
   end Free;

   ----------------
   -- Get_Buffer --
   ----------------

   function Get_Buffer
     (Context : Completion_Context) return String_Access is
   begin
      return Context.Buffer;
   end Get_Buffer;

   ---------------------------------
   -- Get_Completion_Start_Offset --
   ---------------------------------

   function Get_Completion_Start_Offset
     (Context : Completion_Context) return String_Index_Type is
   begin
      return Context.Start_Offset;
   end Get_Completion_Start_Offset;

   -------------------------------
   -- Get_Completion_End_Offset --
   -------------------------------

   function Get_Completion_End_Offset
     (Context : Completion_Context) return String_Index_Type is
   begin
      return Context.End_Offset;
   end Get_Completion_End_Offset;

   --------------
   -- Get_File --
   --------------

   function Get_File (Context : Completion_Context) return Virtual_File is
   begin
      return Context.File;
   end Get_File;

   ---------------
   -- Deep_Copy --
   ---------------

   function Deep_Copy
     (Context : Completion_Context) return Completion_Context is
   begin
      return new Completion_Context_Record'
        (Buffer       => Context.Buffer,
         Start_Offset => Context.Start_Offset,
         End_Offset   => Context.End_Offset,
         Lang         => Context.Lang,
         File         => Context.File);
   end Deep_Copy;

   ---------
   -- "<" --
   ---------

   function "<" (Left, Right : Completion_Id) return Boolean is
   begin
      return Left.Id_Length < Right.Id_Length
        or else
          (Left.Id_Length = Right.Id_Length
           and then
             (Left.Line < Right.Line
              or else
               (Left.Line = Right.Line
                and then
                  (Left.Column < Right.Column
                   or else
                     (Left.Column = Right.Column
                      and then
                      (Left.Id < Right.Id
                       or else
                         (Left.Id = Right.Id
                          and then
                            (Left.File < Right.File
                             or else
                             (Left.File = Right.File
                              and then
                              Left.Resolver_Id < Right.Resolver_Id)))))))));
   end "<";

   ---------
   -- "=" --
   ---------

   overriding function "=" (Left, Right : Completion_Id) return Boolean is
   begin
      return Left.Resolver_Id = Right.Resolver_Id
        and then Left.Id = Right.Id
        and then Left.File = Right.File
        and then Left.Line = Right.Line
        and then Left.Column = Right.Column;
   end "=";

   ----------
   -- Next --
   ----------

   function Next
     (Resolver : access Completion_Resolver'Class)
      return Completion_Resolver_Access
   is
      It : Completion_Resolver_Map_Pckg.Cursor := First
        (Resolver.Manager.Resolvers);
   begin
      while It /= Completion_Resolver_Map_Pckg.No_Element loop
         if Element (It) = Completion_Resolver_Access (Resolver) then
            if Next (It) /= Completion_Resolver_Map_Pckg.No_Element then
               return Element (Next (It));
            else
               return null;
            end if;
         end if;

         It := Next (It);
      end loop;

      return null;
   end Next;

   ----------
   -- Free --
   ----------

   procedure Free (This : in out Completion_Manager_Access) is
      procedure Internal_Free is new
        Ada.Unchecked_Deallocation
          (Completion_Manager'Class, Completion_Manager_Access);
   begin
      This.Contexts.Clear;
      Internal_Free (This);
   end Free;

   -----------------------
   -- Register_Resolver --
   -----------------------

   procedure Register_Resolver
     (Manager  : access Completion_Manager;
      Resolver : access Completion_Resolver'Class) is
   begin
      Insert
        (Manager.Resolvers,
         Get_Id (Resolver.all),
         Completion_Resolver_Access (Resolver));
      Append
        (Manager.Ordered_Resolvers,
         Completion_Resolver_Access (Resolver));
      Resolver.Manager := Completion_Manager_Access (Manager);
   end Register_Resolver;

   --------------------
   -- Create_Context --
   --------------------

   function Create_Context
     (Manager      : access Completion_Manager;
      File         : GNATCOLL.VFS.Virtual_File;
      Buffer       : String_Access;
      Lang         : Language_Access;
      Start_Offset : String_Index_Type;
      End_Offset   : String_Index_Type) return Completion_Context
   is
      New_Context : constant Completion_Context :=
        new Completion_Context_Record;
   begin
      New_Context.Buffer := Buffer;
      New_Context.Start_Offset := Start_Offset;
      New_Context.End_Offset := End_Offset;
      New_Context.File := File;
      New_Context.Lang := Lang;

      Append (Manager.Contexts, New_Context);

      return New_Context;
   end Create_Context;

   ------------------
   -- Get_Resolver --
   ------------------

   function Get_Resolver
     (Manager : access Completion_Manager;
      Name    : String) return Completion_Resolver_Access
   is
   begin
      return Element (Manager.Resolvers, Name);
   end Get_Resolver;

   -------------------
   -- Get_Resolvers --
   -------------------

   function Get_Resolvers
     (Manager : access Completion_Manager)
      return Completion_Resolver_Lists.List is
   begin
      return Manager.Ordered_Resolvers;
   end Get_Resolvers;

   ----------
   -- Free --
   ----------

   procedure Free (Resolver : in out Completion_Resolver_Access) is
      procedure Internal_Free is new
        Ada.Unchecked_Deallocation
          (Completion_Resolver'Class, Completion_Resolver_Access);
   begin
      Free (Resolver.all);
      Internal_Free (Resolver);
   end Free;

   ----------
   -- Free --
   ----------

   procedure Free (This : in out Completion_Proposal_Access) is
      procedure Internal is new Ada.Unchecked_Deallocation
        (Completion_Proposal'Class, Completion_Proposal_Access);
   begin
      Free (This.all);
      Internal (This);
   end Free;

   -------------------
   -- Free_Proposal --
   -------------------

   procedure Free_Proposal (Proposal : in out Completion_Proposal'Class) is
      pragma Unreferenced (Proposal);
   begin
      null;
   end Free_Proposal;

   ---------------
   -- Get_Label --
   ---------------

   function Get_Label
     (Proposal : Completion_Proposal;
      Db : access Xref.General_Xref_Database_Record'Class)
      return UTF8_String is
   begin
      return Get_Completion (Completion_Proposal'Class (Proposal), Db);
   end Get_Label;

   -------------------
   -- Get_Sort_Text --
   -------------------

   function Get_Sort_Text
     (Proposal : Completion_Proposal;
      Db       : access Xref.General_Xref_Database_Record'Class)
      return UTF8_String is
   begin
      return "";
   end Get_Sort_Text;

   ---------------------
   -- Get_Filter_Text --
   ---------------------

   function Get_Filter_Text
     (Proposal : Completion_Proposal;
      Db       : access Xref.General_Xref_Database_Record'Class)
      return UTF8_String
   is
     (Get_Label (Completion_Proposal'Class (Proposal), Db));

   ------------
   -- Get_Id --
   ------------

   function Get_Id
     (Proposal : Completion_Proposal;
      Db : access Xref.General_Xref_Database_Record'Class)
      return UTF8_String is
   begin
      return Get_Completion (Completion_Proposal'Class (Proposal), Db);
   end Get_Id;

   ----------------------
   -- Get_Caret_Offset --
   ----------------------

   function Get_Caret_Offset
     (Proposal : Completion_Proposal;
      Db       : access Xref.General_Xref_Database_Record'Class)
      return Basic_Types.Character_Offset_Type is
   begin
      return
        Basic_Types.Character_Offset_Type
          (UTF8_Strlen
               (Get_Completion (Completion_Proposal'Class (Proposal), Db)));
   end Get_Caret_Offset;

   ------------------
   -- Get_Location --
   ------------------

   function Get_Location
     (Proposal : Completion_Proposal;
      Db : access Xref.General_Xref_Database_Record'Class) return File_Location
   is
      pragma Unreferenced (Db, Proposal);
   begin
      return Null_File_Location;
   end Get_Location;

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (Proposal : Completion_Proposal) return Boolean is
      pragma Unreferenced (Proposal);
   begin
      return True;
   end Is_Valid;

   ------------------
   -- Get_Resolver --
   ------------------

   function Get_Resolver (Proposal : Completion_Proposal)
     return Completion_Resolver_Access is
   begin
      return Completion_Resolver_Access (Proposal.Resolver);
   end Get_Resolver;

   -----------
   -- First --
   -----------

   function First
     (This : Completion_List)
      return Completion_Iterator
   is
      It : Completion_Iterator := (It => First (This.List), others => <>);

      Next_Done : Boolean := False;
   begin
      while not Is_Valid (It) loop
         Next (It);

         Next_Done := True;
      end loop;

      if not Next_Done and then not At_End (It) then
         Completion_Id_Set.Insert
           (It.Already_Extracted, To_Completion_Id (Get_Proposal (It)));
      end if;

      return It;
   end First;

   ----------
   -- Next --
   ----------

   procedure Next
     (This : in out Completion_Iterator) is
   begin
      loop
         Next (This.It);

         exit when At_End (This);

         if Is_Valid (This) then
            declare
               Id : constant Completion_Id :=
                 To_Completion_Id (Get_Proposal (This));
            begin
               if Completion_Id_Set.Find
               (This.Already_Extracted, Id) = Completion_Id_Set.No_Element
               then
                  Completion_Id_Set.Insert (This.Already_Extracted, Id);

                  exit;
               end if;
            end;
         end if;
      end loop;
   end Next;

   --------------
   -- Is_Valid --
   --------------

   function Is_Valid (It : Completion_Iterator) return Boolean is
   begin
      return At_End (It) or else Is_Valid (Get_Proposal (It));
   end Is_Valid;

   ------------------
   -- Get_Proposal --
   ------------------

   function Get_Proposal
     (This : Completion_Iterator) return Completion_Proposal'Class is
   begin
      return Get (This.It);
   end Get_Proposal;

   --------------------
   -- Get_Completion --
   --------------------

   overriding function Get_Completion
     (Proposal : Simple_Completion_Proposal;
      Db : access Xref.General_Xref_Database_Record'Class)
      return UTF8_String
   is
      pragma Unreferenced (Db);
   begin
      return Proposal.Name.all;
   end Get_Completion;

   ------------------
   -- Get_Category --
   ------------------

   overriding function Get_Category
     (Proposal : Simple_Completion_Proposal) return Language_Category is
   begin
      return Proposal.Category;
   end Get_Category;

   --------------------
   -- Get_Visibility --
   --------------------

   overriding function Get_Visibility
     (Proposal : Simple_Completion_Proposal) return Construct_Visibility
   is
      pragma Unreferenced (Proposal);
   begin
      return Visibility_Public;
   end Get_Visibility;

   -----------
   -- Match --
   -----------

   overriding function Match
     (Proposal : Simple_Completion_Proposal;
      Context  : Completion_Context;
      Offset   : String_Index_Type) return Boolean
   is
      pragma Unreferenced (Proposal, Context, Offset);
   begin
      --  ??? Implement correcly this function
      return True;
   end Match;

   ----------
   -- Free --
   ----------

   overriding procedure Free (Proposal : in out Simple_Completion_Proposal) is
   begin
      Free (Proposal.Name);
   end Free;

   ---------------
   -- Deep_Copy --
   ---------------

   overriding function Deep_Copy
     (Proposal : Simple_Completion_Proposal)
      return Completion_Proposal'Class is
   begin
      return Simple_Completion_Proposal'
        (Resolver => Proposal.Resolver,
         Name     => new String'(Proposal.Name.all),
         Category => Proposal.Category);
   end Deep_Copy;

   -----------
   -- Match --
   -----------

   function Match
     (Seeked_Name, Tested_Name : String; Is_Partial : Boolean) return Boolean
   is
   begin
      if (not Is_Partial and then Seeked_Name'Length /= Tested_Name'Length)
        or else Seeked_Name'Length > Tested_Name'Length
      then
         return False;
      end if;

      for J in 1 .. Seeked_Name'Length loop
         if To_Lower (Tested_Name (J + Tested_Name'First - 1)) /=
           To_Lower (Seeked_Name (J + Seeked_Name'First - 1))
         then
            return False;
         end if;
      end loop;

      return True;
   end Match;

   ----------------------
   -- To_Completion_Id --
   ----------------------

   overriding function To_Completion_Id
     (Proposal : Simple_Completion_Proposal)
      return Completion_Id is
   begin
      return (Proposal.Name'Length,
              "SIMPLE  ",
              Proposal.Name.all,
              GNATCOLL.VFS.No_File, 0, 0);
   end To_Completion_Id;

   ----------
   -- Free --
   ----------

   procedure Free (This : in out Completion_Iterator) is
   begin
      Free (This.It);
   end Free;

   ------------
   -- At_End --
   ------------

   function At_End (This : Completion_Iterator) return Boolean is
   begin
      return At_End (This.It);
   end At_End;

   ------------
   -- Append --
   ------------

   procedure Append
     (This      : in out Completion_List;
      Component : Completion_List_Pckg.Virtual_List_Component'Class) is
   begin
      Completion_List_Pckg.Append (This.List, Component);
   end Append;

end Completion;
