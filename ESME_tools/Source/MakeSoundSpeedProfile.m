%MakeSoundSpeedProfile
%
%Builds specified theoretical sound speed profile

DfltPath = 'C:\';

State = 'StartMenu';
Done = 0;

while ~Done
   switch State
   case 'StartMenu',
      switch menu('Choose profile to build', ...
            'Munk', ...
            'N2_Linear', ...
            'Exit');
      case 1,
         State = 'MakeMunk';
      case 2,
         State = 'MakeN2_Linear';
      case 3,
         State = 'Exit';
      end
      
   case 'Exit'
      Done = 1;
      
   case 'MainMenu',
      switch menu('Main menu', ...
            'Build new profile', ...
            'Plot profile', ...
            'Save profile', ...
         'Exit');
      case 1,
         State = 'StartMenu';
      case 2,
         State = 'PlotProfile';
      case 3,
         State = 'SaveProfile';
      case 4,
         State = 'Exit';
      end
      
   case 'MakeMunk',
		%Builds a sound speed file giving the Munk profile
      %(see Jensen et al p 276)
      %

      Z = 0:100:5000;

      Epsilon = 0.00737;

      Zs = 2*(Z - 1300)/1300;

      C = 1500*(1 + Epsilon * (Zs - 1 + exp(-Zs)));
      State = 'MainMenu';
      
   case 'MakeN2_Linear',
      %Builds N^2-linear profile as per Jensen p 154    
      Z = 0:50:5000;
      C0 = 1550;
      
      C = C0 ./ sqrt(1+2.4*Z/C0);
      State = 'MainMenu';
      
   case 'SaveProfile',
      OutDat = [Z.' C.'];
      Here = pwd;
      cd(DfltPath);
      [FName, Path] = uiputfile('*.txt');
      cd(Here);
      if FName ~= 0
         DfltPath = Path;
         save([Path, FName], 'OutDat', '-ascii');
      end
      State = 'MainMenu';
      
   case 'PlotProfile',
      Ans = inputdlg({'Figure number'}, '', 1, {'1'});
      if ~isempty(Ans)
         figure(str2num(Ans{1}));
         plot(C, Z);
         view(0, -90);
         xlabel('Sound speed (m/s)');
         ylabel('Depth (m)');
      end
      State = 'MainMenu';
   end
end
