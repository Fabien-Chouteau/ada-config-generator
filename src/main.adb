with Config_Generator;

procedure Main is

begin
   Config_Generator.Load_Root_Project ("user_project/user_project.gpr");
   Config_Generator.Print;
end Main;
