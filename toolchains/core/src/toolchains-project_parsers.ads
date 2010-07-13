-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                    Copyright (C) 2010, AdaCore                    --
--                                                                   --
-- GPS is free  software;  you can redistribute it and/or modify  it --
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

--  This package provides a way to analyze & modify the toolchain definition
--  decribed in a GNAT project file.
--
--  Supported patterns are:
--
--  package IDE is
--    for GNAT use "name";
--    for GNATlist use "name";
--    for Compiler_Command ("c") use "name";
--    for Compiler_Command ("ada") use "name";
--  end IDE;
--
--  type Target_Type is ("cross-triplet", ...)
--  Target : Target_Type := external ("TARGET", "native")
--  package IDE is
--    for GNAT use Target & "-gnat";
--    for GNATlist use Target & "-gnatls";
--    for Compiler_Command ("c") use Target & "-gnat";
--    for Compiler_Command ("ada") use Target & "-gcc";
--  end IDE;
--
--  type Target_Type is (<native | aamp | custom>, "cross-triplet", ...)
--  Target : Target_Type := external ("TARGET", "native")
--  package IDE is
--    case Target is
--       when <native | aamp | custom> =>
--          for GNAT use "name";
--          for GNATlist use "name";
--          for Compiler_Command ("c") use "name";
--          for Compiler_Command ("ada") use "name";
--       when others =>
--          for GNAT use Target & "-gnat";
--          for GNATlist use Target & "-gnatls";
--          for Compiler_Command ("c") use Target & "-gnat";
--          for Compiler_Command ("ada") use Target & "-gcc";
--    end case;
--  end IDE;
--
--  These patterns can be read and analyzed by the parser, and are generated
--  depending on the selected toolchains.
--
--  The parser is able to detect that it can't handle the toolchain description
--  and will provide a way to get a message in such case.
--
--  The parser is able to follow package renaming, and will offer update
--  capabilities on the renamed package.

with Prj;      use Prj;
with Prj.Tree; use Prj.Tree;
private with Ada.Containers.Indefinite_Ordered_Maps;
private with Ada.Containers.Ordered_Maps;
private with Toolchains.Parsers;

package Toolchains.Project_Parsers is

   type Project_Parser_Record is private;
   type Project_Parser is access all Project_Parser_Record;
   --  This type provides edition / modifications capabilities for the
   --  toolchains.

   procedure Parse
     (This         : Project_Parser;
      Manager      : Toolchain_Manager;
      Path         : Virtual_File;
      Project_Path : String);
   --  Parse a project according to its location (path) and the project path
   --  (GNAT_Project_Path).

   function Get_Manager
     (This : access Project_Parser_Record) return Toolchain_Manager;

   function Is_Valid (This : access Project_Parser_Record) return Boolean;
   --  Return true if the parser could correctly parse the project, false
   --  otherwise. And invalid project may be semantically correct, but doesn't
   --  fall into the standard supported toolchain description.

   type Parsed_Project_Record is private;
   type Parsed_Project is access all Parsed_Project_Record;

   function Get_Root_Project
     (This : access Project_Parser_Record) return Parsed_Project;

   function Get_Parsed_Project
     (This : access Project_Parser_Record;
      Node : Project_Node_Id) return Parsed_Project;

   function Get_Variable
     (This : access Parsed_Project_Record;
      Name : String) return Project_Node_Id;
   --  Return the project node id corresponding to the name given in parameter,
   --  Empty_Node if none.

   function Get_Project_Node
     (This : access Parsed_Project_Record) return Project_Node_Id;
   --  Return the project node associated to this project

private
   use Toolchains.Parsers;

   package Parsed_Projects_Maps is new Ada.Containers.Ordered_Maps
     (Project_Node_Id, Parsed_Project);

   type Project_Parser_Record is record
      Manager                : Toolchain_Manager;

      Tree_Data              : Project_Tree_Ref;
      Node_Data              : Project_Node_Tree_Ref;
      Enclosing_Project_Node : Project_Node_Id;
      Root_Project_Node      : Project_Node_Id;
      Is_Valid               : Boolean := False;

      Toolchain_Found        : Toolchain_Parser;
      Root_Project           : Parsed_Project;
      Parsed_Projects        : Parsed_Projects_Maps.Map;
   end record;

   package Tree_Node_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (String, Project_Node_Id);

   type Parsed_Project_Record is record
      Project_Node : Project_Node_Id;
      Node_Data    : Project_Node_Tree_Ref;
      Variables    : Tree_Node_Maps.Map;
      Path         : Virtual_File;
      Is_Root      : Boolean;
   end record;

   procedure Initialize
     (This         : Parsed_Project;
      Parser       : Project_Parser;
      Node_Data    : Project_Node_Tree_Ref;
      Project_Node : Project_Node_Id);

end Toolchains.Project_Parsers;
