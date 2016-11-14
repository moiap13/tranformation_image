with Text_IO; use Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure transformation_image is
   type T_Image is array (Integer range<>, Integer range<>) of Natural;

   type T_Texte is record
      Txt : String(1..80):= (others => Ascii.Nul);
      Longueur : Natural := 0;
   end record;

   type T_Entete is record 
      Genre : T_Texte;
      Dim_X, Dim_Y   : Natural;
      Niveau  : Natural;
   end record;

   type T_Moitier is record 
      x,y : Natural;
   end record;

   function LireEntete(Nom_Fichier : String) return T_Entete is
      Fichier  : File_Type;
      Entete   : T_Entete;
      Tmp      : String(1..80);
      Longueur : Natural;
      b : boolean;
   begin
      Open(Fichier,In_File,Nom_Fichier);
      Get_Line(Fichier,Entete.Genre.txt,Entete.Genre.Longueur);
      loop -- on saute les lignes de commentaires
         Look_Ahead(Fichier,Tmp(1),b);
         exit when Tmp(1) /= '#';
         Get_Line(Fichier,Tmp,Longueur);
      end loop;
      Get(Fichier,Entete.Dim_X);
      Get(Fichier,Entete.Dim_Y);
      Get(Fichier,Entete.Niveau);
      Close(Fichier);
      return Entete;
   end LireEntete;
   
   procedure Lire(Image : out T_Image; Nom_Fichier : in String) is
      Fichier  : File_Type;
      Tmp      : String(1..80);
      Longueur : Natural;
      b : boolean;
   begin
      Open(Fichier,In_File,Nom_Fichier);
      Get_Line(Fichier,Tmp,Longueur);
      loop
         Look_Ahead(Fichier,Tmp(1),b);
         exit when Tmp(1) /= '#';
         Get_Line(Fichier,Tmp,Longueur);
      end loop;
      Get_Line(Fichier,Tmp,longueur);
      Get_Line(Fichier,Tmp,longueur);
      for I in Image'Range(1) loop
         for J in Image'Range(2) loop
            Get(Fichier,Image(I,J));
         end loop;
      end loop;
      Close (Fichier);
   end Lire;

   procedure Ecrire (Entete: in T_Entete; Image : in T_Image; Nom_Fichier : String) is
      Fichier   : File_Type;
   begin
      Create (Fichier,Out_File,Nom_Fichier);
      Put(Fichier,Entete.Genre.txt(1..Entete.Genre.Longueur));
      New_Line(Fichier);
      Put(Fichier,Entete.Dim_X,4);
      Put(Fichier,Entete.Dim_Y,4);
      New_Line(Fichier);
      Put(Fichier,Entete.Niveau,4);
      New_Line(Fichier);
      for I in Image'Range(1) loop
         for J in Image'Range(2) loop
            Put(Fichier, Image (I,J),4);
            if ((I-1)*Image'length(2)+J-1) mod 20 = 0 then
                New_Line(Fichier);
            end if;
         end loop;
      end loop;
      Close (Fichier);
   end Ecrire;

   function negatif(img : T_Image) return T_Image is
      img_2 : T_Image(img'range(1),img'range(2)) := (others=>(others => 0));
   begin
      for I in img'Range(1) loop
         for J in img'Range(2) loop
            img_2(I,J) := 255 - img (I,J);
         end loop;
      end loop;

      return img_2;
   end;

   function symetrie(img : T_Image; sense : Integer := 0) return T_Image is
      img_2 : T_Image(img'range(1),img'range(2)) := img;
   begin
      if sense = 0 then
         for I in img'first .. img'last/2 loop
            for J in img'Range(2) loop
               img_2(img_2'last(1)-I, J) :=  img(I,J);
            end loop;
         end loop;
      else
         for I in img'first(2) .. img'last(2)/2 loop
            for J in img'Range(1) loop
               img_2(J, img_2'last(2)-I) :=  img(J,I);
            end loop;
         end loop;
      end if;
      return img_2;
   end;

   function photomaton(img : T_Image; moitier : T_Moitier) return T_Image is
      img_2, img_tmp : T_Image(img'range(1),img'range(2)) := img;
   begin
      for k in 0 .. 14 loop
         img_tmp := img_2;
         for i  in img'range(1) loop
            for j in img'range(2) loop
               if(j > img_2'first) and (j < img_2'last(2)) then
                  if(j rem 2 = 0) then
                     img_2(i,j) := img_tmp(i,j/2);
                  else
                     img_2(i,j) := img_tmp(i,j/2+moitier.x);
                  end if;
               end if;
            end loop;
         end loop;
      end loop;

      for k in 0 .. 14 loop
         img_tmp := img_2;
          for i  in img'range(2) loop
               for j in img'range(1) loop
                  if(j > img_2'first) and (j < img_2'last(1)) then
                     if(j rem 2 = 0) then
                        img_2(j,i) := img_tmp(j/2,i);
                     else
                        img_2(j,i) := img_tmp(j/2+moitier.x,i);
                     end if;
                  end if;
               end loop;
            end loop;  
      end loop; 

      return img_2;
   end;

   monEntete: T_Entete := LireEntete("lena.pgm");
   monImage, img_negatif, img_symetrie_h, img_symetrie_v, img_photomaton : T_Image(1..monEntete.Dim_X,1..monEntete.Dim_Y);
   moitier : T_Moitier;
   
begin
   lire(monImage,"lena.pgm");

   moitier.x := monEntete.Dim_X / 2;
   moitier.y := monEntete.Dim_y / 2;

   img_negatif := negatif(monImage);
   ecrire(monEntete,img_negatif,"negatif.pgm");

   img_symetrie_h := symetrie(monImage);
   ecrire(monEntete,img_symetrie_h,"symetrie_h.pgm");

   img_symetrie_v := symetrie(monImage,1);
   ecrire(monEntete,img_symetrie_v,"symetrie_v.pgm");

   img_photomaton := photomaton(monImage, moitier);
   ecrire(monEntete, img_photomaton, "photomaton.pgm");

end transformation_image;