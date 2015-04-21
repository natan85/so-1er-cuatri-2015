#!/usr/bin/perl -w
use strict;
use warnings;
use Fcntl qw(:flock);
use feature qw/switch/; 


###### Se valida que el comando no este en ejecución#####
open(my $script_fh, '<', $0)
   or die("No se pudo abrir el archivo: $!\n");

unless (flock($script_fh, LOCK_EX|LOCK_NB)) {
    print "$0 ya se encuentra en ejecución.\n";
    exit(1);
}

###### Se valida ejecucion de IniPro######
# Si no existen las variables de ambiente sabemos que IniPro no se ejecuto
if (!exists($ENV{"MAEDIR"}) && !exists($ENV{"PROCDIR"}) && !exists($ENV{"INFODIR"}) ) 
{
	 print "Previamente debe ejecutar el comando IniPro\n";
     exit(1);	  
} 

###### MENU ##############################
###### Si no ingresa ningún parametro se mostrará la ayuda
my $num_parametros = $#ARGV + 1;

if ($num_parametros < 1) {
    print "Debe ingresar una opción.\n";
    mostrarAyuda();
    exit;
}else{
	my $primero=$ARGV[0];

	if($primero eq "-a") { mostrarAyuda(); }
	elsif($primero eq "-c") { consultar();}
	elsif($primero eq "-g") { grabar();}
	elsif($primero eq "-i") { informar(); }
	elsif($primero eq "-e") { estadisticas();}
	else { 
			print "Opción incorrecta.\n";
    		mostrarAyuda();
    		exit;
    	}
}

####### Declaración de funciones ###### 
 
sub mostrarAyuda {
	print "Ayuda: InfPro [opción] [argumentos] 
		  -a                  Muestra esta ayuda
		  -g                  Grabar
		  -c[palabra clave]   Consulta por palabra clave
		  -i                  Información
		  -e                  Estadísticas\n";
}

sub grabar{
	print "Se eligió -g\n"; 
	my $ruta = $ENV{"INFODIR"};
	my $epoc = time();
	my $str = "Dato de prueba.";
	my $nombreArchivo = $ruta."/resultado_".$epoc;
	open FILE, ">".$nombreArchivo or die $!; 
	print FILE $str; 
	close FILE;
}

sub consultar{
	my $num_par = $#ARGV + 1;
	if($num_parametros == 1){
		print "Debe ingresar al menos una palabra clave\n";
	}else{
		print "Se eligió -c\n";
		leerTodosArchivos();	
		#leerarchivos();
	}
	 
}

sub leerTodosArchivos{
	my $ruta = $ENV{"NOVEDIR"};
	opendir (DIR, $ruta) or die $!;

	while (my $file = readdir(DIR)) {
		my $filename = $ruta.'/'.$file;
		open(my $fh, '<:encoding(UTF-8)', $filename)
		 or die "Could not open file '$filename' $!";
		 
		while (my $row = <$fh>) {
		  chomp $row;
		  print "$row\n";
		#leerArchivo($file);
		}
   	 }
    	closedir(DIR);	
}

#TODO: Llamar a esta funcion 
sub leerArchivo{
	my $ruta = $ENV{"NOVEDIR"};
	#my $file = _@;
	my $filename = $ruta.'/';#.$file;
	open(my $fh, '<:encoding(UTF-8)', $filename)
	  or die "Could not open file '$filename' $!";
	 
	while (my $row = <$fh>) {
	  chomp $row;
	  print "$row\n";
	}

}

sub informar{
	print "Se eligió -i\n";
}

sub estadisticas{
	print "Se eligió -e\n"; 
}
