with Ada.Text_IO;

package Config_Generator is

   procedure Load_Root_Project (Prj_Name : String);

   procedure Print (File : Ada.Text_IO.File_Type := Ada.Text_IO.Standard_Output);

end Config_Generator;
