package My_Config is

   -- verbose --
   verbose : constant Boolean := True;

   -- brightness --
   brightness_First : constant := 0.0;
   brightness_Last : constant := 1.0;
   brightness : constant := 0.6;

   -- buffer_size --
   buffer_size_First : constant := 1;
   buffer_size_Last : constant := 4096;
   buffer_size : constant := 256;

   -- mode --
   type mode_Kind is (Test, Mode1, Mode2);
   mode : constant mode_Kind := Mode1;

   -- address --
   address : constant String := "example.com";

end My_Config;
