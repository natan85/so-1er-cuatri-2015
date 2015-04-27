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
if (!exists($ENV{"MAEDIR"}) && !exists($ENV{"PROCDIR"}) && !exists($ENV{"INFODIR"}) && !exists($ENV{"NOVEDIR"}))
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
	my $num_parametros = $#ARGV + 1;
	if($num_parametros == 1){
		print "Debe ingresar al menos una palabra clave\n";
	}else{
		if($num_parametros < 4 ){
			print "Debe utilizar al menos un filtro\n";	
		}else{
			print "Se eligió -c\n";
			leerTodosArchivos();
		}
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
	#my $palabraClave = shift;
	my %filtros = ('-ft' => " ", '-fa' => " ", '-fn' => " ", '-fg' => " ", '-fe' => " ");
	my $pidioGuardar = 0;
	my $palabraClave = $ARGV[1];	
	my $ruta = $ENV{"NOVEDIR"};
	opendir (DIR, $ruta) or die $!;
	my %hashResultados;
	#Cargamos los filtros
	my $i = 2;
	while($i < $#ARGV){
		my $parametro = $ARGV[$i]; 
		if(!exists($filtros{$parametro} ) ){
			$i += 1;					
		}else{
			my $valorFiltro = $ARGV[$i+1]; 					
			$filtros{$parametro} = $valorFiltro;
			$i += 2;
		}	
	}
	foreach my $name (keys %filtros) {
	    	printf "%-8s %s\n", $name, $filtros{$name};
	}
	#Validamos si se ingreso guardar
	if($i <= $#ARGV){
		my $ultimaEntrada = $ARGV[$#ARGV];
		if(defined $ultimaEntrada and $ultimaEntrada eq "-g"){
			$pidioGuardar = 1;	
			print "se pidio Guardar\n";
		}
	}
	#Leo cada archivo
	while (my $file = readdir(DIR)) {
		my $filename = $ruta.'/'.$file;
		open(my $fh, '<:encoding(UTF-8)', $filename)
		 or die "Could not open file '$filename' $!";

		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			#Inicializo variables de filtrado
			my $cumplioCausal = 0;
			my $cumplioExtracto = 0;
			my $cumplioFiltroTipoNorma = 1;
			my $cumplioFiltroAnio = 1;
			my $cumplioFiltroNumeroNorma = 1;
			my $cumplioFiltroGestion = 1;
			my $cumplioFiltroEmisor = 1;

			#Busco los valores de causal y extracto		
			my @data = split(";",$row);
			my $causal = $data[2];
			my $extracto = $data[3];
			#leerArchivo($file);
			if (defined $causal and index($causal, $palabraClave) != -1) {
			   $cumplioCausal = 1; 
			}
			if(defined $extracto and index($extracto, $palabraClave) != -1){
			   $cumplioExtracto = 1;	
			}
			
			if (($cumplioCausal == 1 or $cumplioExtracto == 1) and $cumplioFiltroTipoNorma == 1 and $cumplioFiltroAnio == 1 and $cumplioFiltroNumeroNorma == 1 and $cumplioFiltroGestion == 1 and $cumplioFiltroEmisor == 1){
				#Agrego al hash el puntaje del archivo - pasar a metodo
				if($cumplioCausal == 1){
					if(!exists($hashResultados{$file} ) ){
						$hashResultados{$file} = 10;					
					}else{
						$hashResultados{$file} += 10;
					}
				}
				if ($cumplioExtracto == 1) {
				    	#Agrego al hash el puntaje del archivo - pasar a metodo
					if( !exists($hashResultados{$file} ) ){
						$hashResultados{$file} = 1;
					}
					else{
						$hashResultados{$file} += 1;
					}		
				}	
			}
	
		}#Del while lineas
   	 }#Del while archivos

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
