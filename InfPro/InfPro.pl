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
	}
	 
}

#Para ordenar los archivos primero debo pasar el hash a una lista
sub devolverArchivosOrdenados{
	my %archivosResultantes = (
	   nombre1 => 89,
	   nombre2 => 20,
	   nombre3 => 182,
	);

	foreach my $name (keys %archivosResultantes) {
	    printf "%-8s %s\n", $name, $archivosResultantes{$name};
	}
}

sub leerTodosArchivos{
	my $palabraClave = "Romina";
	my $ruta = $ENV{"NOVEDIR"};
	opendir (DIR, $ruta) or die $!;
	my %hashResultados;
	while (my $file = readdir(DIR)) {
		my $filename = $ruta.'/'.$file;
		open(my $fh, '<:encoding(UTF-8)', $filename)
		 or die "Could not open file '$filename' $!";
		 
		while (my $row = <$fh>) {
			chomp $row;
			my $causal = "";
			my $extracto = "";		
			my @data = split(";",$row);
			$causal = $data[2];
			$extracto = $data[3];
			#leerArchivo($file);
			if (defined $causal and index($causal, $palabraClave) != -1) {
			    #Agrego al hash el puntaje del archivo - pasar a metodo
				if( !exists($hashResultados{$file} ) ){
					$hashResultados{$file} = 10;
				}
				else{
					$hashResultados{$file} += 10;
				}	
			}

			if (defined $extracto and index($extracto, $palabraClave) != -1) {
			    #Agrego al hash el puntaje del archivo - pasar a metodo
				if( !exists($hashResultados{$file} ) ){
					$hashResultados{$file} = 1;
				}
				else{
					$hashResultados{$file} += 1;
				}		
			}
	
		}
   	 }

    	closedir(DIR);
	foreach my $name (keys %hashResultados) {
	    	printf "%-8s %s\n", $name, $hashResultados{$name};
	}
	
}


sub informar{
	print "Se eligió -i\n";
}

sub estadisticas{
	print "Se eligió -e\n"; 
}
