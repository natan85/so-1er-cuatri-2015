#!/usr/bin/perl -w
use strict;
use warnings;
use Fcntl qw(:flock);
use feature qw/switch/; 
our %filtros = ('-ft' => " ", '-fa' => " ", '-fn' => " ", '-fg' => " ", '-fe' => " ");
#our @a_resultados;
our %contenido_resultados_consola;
our %contenido_resultados_archivo;
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


sub consultar{
	my $num_parametros = $#ARGV + 1;
	
	if($num_parametros < 4 ){
		print "Debe utilizar al menos un filtro\n";	
	}else{
		print "Se eligió -c\n";
		leerTodosArchivos();
	}
}

sub leerTodosArchivos{
	#my $palabraClave = shift;
	my $pidioGuardar = 0;
	my $palabraClave = $ARGV[1];
	my $ruta = $ENV{"PROCDIR"};
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
			my $cumplioFiltroTipoNorma = 0;
			my $cumplioFiltroAnio = 0;
			my $cumplioFiltroNumeroNorma = 0;
			my $cumplioFiltroGestion = 0;
			my $cumplioFiltroEmisor = 0;

			#Busco los valores de causal y extracto		
			my @data = split(";",$row);
			my $causal = $data[4];
			my $extracto = $data[5];
			#leerArchivo($file);
			if (defined $causal and index($causal, $palabraClave) != -1) {
			   $cumplioCausal = 1; 
			}
			if(defined $extracto and index($extracto, $palabraClave) != -1){
			   $cumplioExtracto = 1;	
			}
			#Busco por filtro Tipo Norma
			my $tipoNorma = $data[12];
			my $normaIngresada = $filtros{'-ft'};
			
			if ($normaIngresada eq " "){
			   $cumplioFiltroTipoNorma = 1;	
			}
			if (defined $tipoNorma and ($normaIngresada ne " ") and index($tipoNorma, $normaIngresada) != -1) {
			   $cumplioFiltroTipoNorma = 1; 
			}

			#Busco por filtro Año
			my $anio = $data[3];
			my $anioIngresado = $filtros{'-fa'};
			
			if ($anioIngresado eq " "){
			   $cumplioFiltroAnio = 1;	
			}
			if (defined $anio and ($anioIngresado ne " ") and index($anio, $anioIngresado) != -1) {
			   $cumplioFiltroAnio = 1; 
			}
			#Busco por filtro numero Norma
			my $numero = $data[2];
			my $numeroIngresado = $filtros{'-fn'};
				
			if ($numeroIngresado eq " "){
			   $cumplioFiltroNumeroNorma = 1;	
			}
			if (defined $numero and ($numeroIngresado ne " ") and index($numero, $numeroIngresado) != -1) {
			   $cumplioFiltroNumeroNorma = 1; 
			}
			#Busco por filtro Gestion
			my $gestion = $data[11];
			my $gestionIngresada = $filtros{'-fg'};
			
			if ($gestionIngresada eq " "){
			   $cumplioFiltroGestion = 1;	
			}
			
			if (defined $gestion and index($gestion, $gestionIngresada) != -1) {
			   $cumplioFiltroGestion = 1; 
			}
			#Busco por filtro Emisor
			my $emisor = $data[13];
			my $emisorIngresado = $filtros{'-fe'};
			
			if ($emisorIngresado eq " "){
			   $cumplioFiltroEmisor = 1;	
			}
			
			if (defined $emisor and index($emisor, $emisorIngresado) != -1) {
			   $cumplioFiltroEmisor = 1; 
			}

			if (($cumplioCausal == 1 or $cumplioExtracto == 1) and $cumplioFiltroTipoNorma == 1 and $cumplioFiltroAnio == 1 and $cumplioFiltroNumeroNorma == 1 and $cumplioFiltroGestion == 1 and $cumplioFiltroEmisor == 1){
				#Armamos la salida por consola
				my $fechaNorma = $data[1];		
				my $peso = obtenerPeso($causal, $extracto, $palabraClave);
				my $renglon1 = $tipoNorma." ".$emisor." ".$numero."/".$anio." ".$gestion." ".$fechaNorma." ".$peso."\n";
				my $renglon2 = $extracto."\n";
				my $renglon3 = $causal."\n";
				#Cargamos en la lista para luego ordenar
				my $idReg = $data[10];
				$contenido_resultados_consola{$peso."-".$file.$idReg} = $renglon1.$renglon2.$renglon3;
				my $lineaSalida = $tipoNorma." ".$emisor." ".$numero." ".$anio." ".$gestion." ".$fechaNorma." ".$causal." ".$extracto." ".$idReg."\n";
				$contenido_resultados_archivo{$peso."-".$file.$idReg} = $lineaSalida;
				
			}
	
		}#Del while lineas
   	 }#Del while archivos
	
	imprimirYGrabarResultadosOrdenados($pidioGuardar);

    	closedir(DIR);
}

sub imprimirYGrabarResultadosOrdenados(){
	my $pidioGuardar = $_[0];
	my $resultadoArchivo;		    
	foreach my $keyHash (sort{$b <=> $a} keys %contenido_resultados_consola) {
		my $resultado = $contenido_resultados_consola{$keyHash};
	    	print "$resultado\n";
		if ($pidioGuardar == 1){
			$resultadoArchivo .= $contenido_resultados_archivo{$keyHash};	
		}
	    }
	grabar($resultadoArchivo);	
}


sub grabar{
	my $resultado = $_[0];
	my $ruta = $ENV{"INFODIR"};
	my $epoc = time();
	my $nombreArchivo = $ruta."/resultado_".$epoc;
	open FILE, ">".$nombreArchivo or die $!; 
	print FILE $resultado; 
	close FILE;
	print "Se generó el archivo $nombreArchivo\n";
}


sub obtenerPeso(){
	my $causal = $_[0];
	my $extracto = $_[1];
	my $palabraClave = $_[2];
	my $contadorCausal = () = $causal =~ /$palabraClave/g;
	my $contadorExtracto = () = $extracto =~ /$palabraClave/g;
	my $peso = $contadorCausal*10+$contadorExtracto;
	return $peso;
}

sub informar{
	print "Se eligió -i\n";
}

sub estadisticas{
	print "Se eligió -e\n"; 
}
