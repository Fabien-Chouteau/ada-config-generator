with GNAT.Command_Line;
with GNAT.Strings;

with GNAT.Strings; use GNAT.Strings;

with Ada.Text_IO; use Ada.Text_IO;

with GNATCOLL.Projects; use GNATCOLL.Projects;
with GNATCOLL.VFS;      use GNATCOLL.VFS;
with Ada.Containers.Indefinite_Ordered_Maps;

with GNATCOLL.Traces;
with Ada_Config;

package body Config_Generator is

   Project_Package      : aliased String := "configuration";
   Project_Package_List : aliased String_List :=
     (1 => Project_Package'Access);

   type Attribute is (Config_Type, Config_Value, Package_Name);

   subtype Non_Indexed_Attribute is Attribute range Package_Name .. Package_Name;
   subtype Indexed_Attribute is Attribute range Config_Type .. Config_Value;

   function "+" (A : Attribute) return Attribute_Pkg_String;

   package Scv_Maps is
     new Ada.Containers.Indefinite_Ordered_Maps
       (Key_Type     => String,
        Element_Type => String);
   Scv_Map : Scv_Maps.Map;
   --  All defined scenario variables

   Env      : Project_Environment_Access;
   Prj_Tree : Project_Tree_Access;

   procedure Initialize;
   --  Initialize project environment. Target is the target prefix, or NULL
   --  for the native case.

   ---------
   -- "+" --
   ---------

   function "+" (A : Attribute) return Attribute_Pkg_String is
   begin
      return Build (Project_Package, A'Img);
   end "+";

   ----------------------
   -- Add_Scenario_Var --
   ----------------------

   procedure Add_Scenario_Var (Key, Value : String) is
   begin
      Scv_Map.Include (Key, Value);
   end Add_Scenario_Var;

   --------------------------
   -- Compute_Project_View --
   --------------------------

   procedure Compute_Project_View is
   begin
      if Prj_Tree /= null then
         Prj_Tree.Recompute_View;
      end if;
   end Compute_Project_View;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use Scv_Maps;
   begin
      Initialize (Env);

      --  Register attributes of package Coverage

      for A in Attribute'Range loop
         declare
            Err : constant String :=
                    Register_New_Attribute
                      (Name    => A'Img,
                       Pkg     => Project_Package,
                       Is_List => False,
                       Indexed => A in Indexed_Attribute);
         begin
            if Err /= "" then
               Put_Line (Err);
            end if;
         end;
      end loop;

      --  Set scenario variables

      for Scv_C in Scv_Map.Iterate loop
         Change_Environment (Env.all, Key (Scv_C), Element (Scv_C));
      end loop;
   end Initialize;

   -----------------
   -- Print_Error --
   -----------------

   procedure Print_Error (Str : String) is
   begin
      Put_Line (Str);
   end Print_Error;

   -----------------------
   -- Load_Root_Project --
   -----------------------

   procedure Load_Root_Project (Prj_Name : String) is
   begin
      if Prj_Tree /= null then
         raise Program_Error with "only one root project can be specified";
      end if;

      --  Allow activation of GNATcoll debug traces via configuration file,
      --  prior to initializing the project subsystem.

      GNATCOLL.Traces.Parse_Config_File (Filename => No_File);

      pragma Assert (Env = null);
      Initialize;
      pragma Assert (Env /= null);

      Prj_Tree := new Project_Tree;
      Prj_Tree.Load
        (Root_Project_Path => Create (+Prj_Name),
         Env               => Env,
         Packages_To_Check => Project_Package_List'Access,
         Recompute_View    => False,
         Errors            => Print_Error'Access);

   end Load_Root_Project;

   -----------
   -- Print --
   -----------

   procedure Print (File : Ada.Text_IO.File_Type := Ada.Text_IO.Standard_Output) is

      Pck_Name_Attr : constant String :=
        Prj_Tree.Root_Project.Attribute_Value (+Package_Name);

      Pck_Name : constant String :=
        (if Pck_Name_Attr /= "" then Pck_Name_Attr else "Configuration");

   begin
      Put_Line (File, "package " & Pck_Name & " is");

      for Key_Name of Attribute_Indexes (Prj_Tree.Root_Project, +Config_Value)
      loop
         declare

            Key_Type : constant String :=
              Prj_Tree.Root_Project.Attribute_Value
                (+Config_Type, Key_Name.all);

            Key_Value : constant String :=
              Prj_Tree.Root_Project.Attribute_Value
                (+Config_Value, Key_Name.all);

            Key : constant Ada_Config.Config_Key :=
              Ada_Config.Create (Key_Name.all, Key_Value, Key_Type);

         begin
            Ada_Config.Print (Key, File);
         end;
      end loop;

      New_Line (File);
      Put_Line (File, "end " & Pck_Name & ";");
   end Print;

end Config_Generator;
