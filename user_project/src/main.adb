with Ada.Text_IO; use Ada.Text_IO;

with My_Config;

procedure Main is
begin

   Put_Line ("Address: " & My_Config.address);

   Put_Line ("Brightness:" & My_Config.brightness'Img);

   Put_Line ("Buffer_Size:" & My_Config.buffer_size'Img);

   Put_Line ("Verbose: " & My_Config.verbose'Img);

   Put_Line ("Mode: " & My_Config.mode'Img);

end Main;
