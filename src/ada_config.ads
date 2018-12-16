with GNAT.Strings; use GNAT.Strings;
with Ada.Strings;

with Ada.Containers.Doubly_Linked_Lists;

with Ada.Text_IO;

package Ada_Config is

   type Config_Key (<>) is limited private;

   function Create (Name, Val, Typ : String) return Config_Key;

   procedure Print
     (Key  : Config_Key;
      File : Ada.Text_IO.File_Type := Ada.Text_IO.Standard_Output);

private

   type Config_Type_Kind is (Real, Int, Enum, Str, Bool);

   package String_List_Pck is new Ada.Containers.Doubly_Linked_Lists (String_Access);

   type Config_Type (Kind : Config_Type_Kind) is record
      case Kind is
         when Real | Int =>
            First, Last : String_Access := null;
         when Enum =>
            Values : String_List_Pck.List;
         when Str | Bool =>
            null;
      end case;
   end record;

   type Config_Key (Kind : Config_Type_Kind)is limited record
      Name : String_Access;
      Typ : Config_Type (Kind);
      Val : String_Access;
   end record;

end Ada_Config;
