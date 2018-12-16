with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Maps;
with Ada.Strings.Fixed;

package body Ada_Config is

   -----------------
   -- Starts_With --
   -----------------

   function Starts_With (Str, Pattern : String) return Boolean
   is (Str'Length >= Pattern'Length
       and then
       Str (Str'First .. Str'First + Pattern'Length - 1) = Pattern);

   ---------
   -- Img --
   ---------

   function Img (Typ : Config_Type) return String
   is (case Typ.Kind is
          when Str => "String",
          when Bool => "Boolean",
          when Enum => "Enum", --  FIXME: List of enum values
          when Real => "Real range " & Typ.First.all & " .. " & Typ.Last.all,
          when Int => "Integer range " & Typ.First.all & " .. " & Typ.Last.all
      );

   -----------
   -- Split --
   -----------

   procedure Split (Str : String; List : in out String_List_Pck.List) is
      Set : constant Ada.Strings.Maps.Character_Set :=
        Ada.Strings.Maps.To_Set (',');
      From : Positive := Str'First;
      First : Positive;
      Last  : Natural;
   begin
      loop
         Ada.Strings.Fixed.Find_Token (Source => Str,
                                       Set    => Set,
                                       From   => From,
                                       Test   => Ada.Strings.Inside,
                                       First  => First,
                                       Last   => Last);
         if Last >= First then
            declare
               Val    : constant String := Str (From .. Last - 1);
               Trimed : constant String :=
                 Ada.Strings.Fixed.Trim (Val, Ada.Strings.Both);
            begin
               List.Append (new String'(Trimed));
               From := Last + 1;
            end;
         else
            return;
         end if;
      end loop;
   end Split;

   -----------------
   -- Parse_Range --
   -----------------

   procedure Parse_Range (Str : String; First, Last : out String_Access) is
      Trimed : String := Ada.Strings.Fixed.Trim (Str, Ada.Strings.Both);
      X : Natural;
   begin
      if Trimed'Length = 0 then
         First := null;
         Last := null;
         return;
      elsif Starts_With (Trimed, "range") then
         X := Ada.Strings.Fixed.Index
           (Source  => Trimed (Trimed'First + 5 .. Trimed'Last),
            Pattern => "..");

         if X not in Trimed'First + 5 .. Trimed'Last then
            raise Program_Error with "invalid range definition";
         end if;

         declare
            F : constant String := Ada.Strings.Fixed.Trim
              (Trimed (Trimed'First + 5 .. X - 1), Ada.Strings.Both);
            L : constant String := Ada.Strings.Fixed.Trim
              (Trimed (X + 2.. Trimed'Last), Ada.Strings.Both);
         begin
            First := new String'(F);
            Last := new String'(L);
         end;
      else
         raise Program_Error with "range expected";
      end if;
   end Parse_Range;

   ----------------
   -- Parse_Type --
   ----------------

   function Parse_Type (Typ : String) return Config_Type is
      Trimed : constant String :=
        Ada.Strings.Fixed.Trim (Typ, Ada.Strings.Both);
   begin
      if Trimed'Length = 0 then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,
                               "No type defined, using default: String");
         return (Kind => Str);
      elsif Starts_With (Typ, "String") then
         return (Kind => Str);
      elsif Starts_With (Typ, "Boolean") then
         return (Kind => Bool);
      elsif Starts_With (Typ, "Real") then
         return Result : Config_Type (Real) do
            Parse_Range (Typ (Typ'First + 4 .. Typ'Last), Result.First, Result.Last);
         end return;
      elsif Starts_With (Typ, "Integer") then
         return Result : Config_Type (Int) do
            Parse_Range (Typ (Typ'First + 7 .. Typ'Last), Result.First, Result.Last);
         end return;
      elsif Starts_With (Typ, "Enum") then
         return Result : Config_Type (Enum) do
            Result.Values.Append (new String'("Test"));
            Split (Typ (Typ'First + 4 .. Typ'Last), Result.Values);
         end return;
      end if;
      raise Program_Error with "Invalid type declaration: '" & Typ & "'";
   end Parse_Type;

   -----------
   -- Valid --
   -----------

   function Valid (Typ : Config_Type; Val : String) return Boolean is
   begin
      case Typ.Kind is
         when Str =>
            return True;
         when Bool =>
            return Val = "True" or else Val = "False";
         when Enum =>
            return (for some V of Typ.Values => V.all = Val);

         when Real =>
            --  Should be infinite precision here

            if Typ.First /= null
              and then
                Float'Value (Val) < Float'Value (Typ.First.all)
            then
               return False;
            end if;

            if Typ.Last /= null
              and then
                Float'Value (Val) > Float'Value (Typ.Last.all)
            then
               return False;
            end if;

            return True;
         when Int =>
            --  Should be infinite precision here
            if Typ.First /= null
              and then
                Integer'Value (Val) < Integer'Value (Typ.First.all)
            then
               return False;
            end if;

            if Typ.Last /= null
              and then
                Integer'Value (Val) > Integer'Value (Typ.Last.all)
            then
               return False;
            end if;

            return True;
      end case;
   exception
      when others =>
         return False;
   end Valid;

   ------------
   -- Create --
   ------------

   function Create (Name, Val, Typ : String) return Config_Key is
      Ctype : Config_Type := Parse_Type (Typ);
   begin
      if not Valid (Ctype, Val) then
         raise Program_Error with "Invalid value '" & Val & "' for type " & Img (Ctype);
      end if;
      return Config_Key'(Kind => Ctype.Kind,
                         Name => new String'(Name),
                         Val  => new String'(Val),
                         Typ  => Ctype);
   end Create;

   -----------
   -- Print --
   -----------

   procedure Print
     (Key  : Config_Key;
      File : Ada.Text_IO.File_Type := Ada.Text_IO.Standard_Output)
   is
      First : Boolean := True;
   begin
      New_Line (File);
      Put_Line (File, "   -- " & Key.Name.all & " --");
      case Key.Kind is
         when Str =>
            Put_Line (File,
                      "   " & Key.Name.all & " : constant String := """ &
                        Key.Val.all & """;");
         when Bool =>
            Put_Line (File,
                      "   " & Key.Name.all & " : constant Boolean := " &
                        Key.Val.all & ";");
         when Enum =>
            Put (File, "   type " & Key.Name.all & "_Kind is (");
            for Val of Key.Typ.Values loop
               if not First then
                  Put (", ");
               else
                  First := False;
               end if;
               Put (Val.all);
            end loop;
            Put_Line (File, ");");
            Put_Line (File,
                      "   " & Key.Name.all & " : constant " &
                        Key.Name.all & "_Kind := " &
                        Key.Val.all & ";");
         when Real | Int =>
            if Key.Typ.First /= null then
               Put_Line (File,
                         "   " & Key.Name.all & "_First : constant := " &
                           Key.Typ.First.all & ";");
            end if;
            if Key.Typ.First /= null then
               Put_Line (File,
                         "   " & Key.Name.all & "_Last : constant := " &
                           Key.Typ.Last.all & ";");
            end if;
            Put_Line (File,
                      "   " & Key.Name.all & " : constant := " & Key.Val.all & ";");
      end case;
   end Print;

end Ada_Config;
