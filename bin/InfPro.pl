#! /usr/bin/perl -w

sub inicio{
	mostrarAyuda();
	my $opcion = menuPrincipal();
	my @rutas;
	crearHashes();
	#for $family ( keys %hash_cod_norma ) {
	#	 #chomp($family);
   	#	 print "$family: @{ $hash_cod_norma{$family} }";
	#}	
	procesarConsulta($opcion);
}

sub menuPrincipal{
	separador();
	print "\nIngrese una opción: ";
	$entrada = <STDIN>;
	chomp($entrada);	
	print "\n"; 
	
	#Loop infinito hasta que se ingrese opcion valida
	while( !($entrada =~ m/[a c cg i ig e eg]/i) || (length($entrada) > 3) ){
		print "Opcion incorrecta. Intente nuevamente: ";
		$entrada = <STDIN>;
		chomp($entrada);
	}
	return $entrada;
}

sub procesarConsulta{
	my $entrada = $_[0];
	my ($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor); 	

	#Parmaetros: a c cg e eg 
	if ($entrada eq "a"){
		mostrarAyuda();
	}
	if ($entrada eq "c"){
		my @rutas_cod_norma;
		my @rutas_anios;

		$palabra_clave = ingresarPalabraClave();
		pedirFiltros($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor); 
		#print "$filtro_cod_norma\n";
		#print "$filtro_anios\n";
		@rutas_cod_norma = candidatosPorCodigoNorma($filtro_cod_norma);
		@rutas_anios = candidatosPorAnios($filtro_anios);
		
		
		print "Rutas de los codigos de norma: \n";
		foreach $ruta (@rutas_cod_norma){
			print "$ruta";
		}
		print "Rutas de los anios: \n";
		foreach $ruta (@rutas_anios){
			print "$ruta";
		}
	}
}


sub candidatosPorAnios{
	my $filtro_anios = $_[0];
	my $ruta;
	my $rutas_anios;
	my @rutas_aux_anios;

	if ($filtro_anios ne ""){
		($anio_inicial, $anio_final) = split(' ', $filtro_anios);	
		chomp($anio_inicial);
		chomp($anio_final);

		$anio = $anio_inicial;
		while ($anio <= $anio_final){
			if ( exists($hash_anio{$anio}) ){
   				for $ruta ( @{ $hash_anio{$anio} }){
					push(@rutas_anios, $ruta);
				}
				
			}
			$anio++;
		}
	}
	else{	print "tengo de tomar todos los años\n";
		for $rutas_aux_anios ( keys %hash_anio ) {	
   			for $ruta ( @{ $hash_anio{$rutas_aux_anios} }){
				push(@rutas_anios, $ruta);
			}
		}
	}
	#foreach $ruta (@rutas_anios){
	#	print "$ruta";
	#}
	return @rutas_anios;
}

sub candidatosPorCodigoNorma{
	my $filtro_cod_norma = $_[0];
	my $ruta;
	my @rutas_cod_norma;
	my @rutas_aux_cod_norma;

	if ($filtro_cod_norma ne ""){
		if ( exists($hash_cod_norma{$filtro_cod_norma}) ){
			@rutas_cod_norma = @{$hash_cod_norma{$filtro_cod_norma}};
		}
		else{
			@rutas_cod_norma = ();
		}
	} 
	else{
		for $rutas_aux_cod_norma ( keys %hash_cod_norma ) {
   			 for $ruta ( @{ $hash_cod_norma{$rutas_aux_cod_norma} }){
				push(@rutas_cod_norma, $ruta);
			}
		}
	}
	return @rutas_cod_norma;
}

sub pedirFiltros{
	my ($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor) = @_;	
	$filtro_cod_norma = ingresarFiltroPorCodNorma();
	$filtro_anios = ingresarFiltroPorAnio(); 	     
	$filtro_nro_norma = ingresarFiltroPorNroNorma();
	$filtro_cod_gestion = ingresarFiltroPorCodGestion();
	$filtro_cod_emisor = ingresarFiltroPorCodEmisor();


	if ( ($filtro_cod_norma eq "") && ($filtro_anios eq "") && ($filtro_nro_norma eq "") 
	             && ($filtrocod_gestion eq "") && ($filtro_cod_emisor eq "") ){
		print "Debe ingresar al menos un filtro !!!\n";
		pedirFiltros($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor);
	}
	$_[0] = $filtro_cod_norma;
	$_[1] = $filtro_anios;
	$_[2] = $filtro_nro_norma;
	$_[3] = $filtro_cod_gestion;
	$_[4] = $filtro_cod_emisor;
}

sub ingresarPalabraClave{
	print "Ingrese palabra clave (mandato): ";
	$palabra_clave = <STDIN>;
	return $palabra_clave;
}
sub ingresarFiltroPorCodNorma{
	print "Ingrese filtro por codigo de norma (CON): ";
	$cod_norma = <STDIN>;
	chomp($cod_norma);
	$cod_norma_aux = $cod_norma;
	$cod_norma_aux =~ s/\s//g;	
	$esValido = 0;
	
	# Validaciones
	while ( $esValido == 0 ){	
		if( ( length($cod_norma) == 3 ) && ( $cod_norma !~ /\d+/ ) && ( $cod_norma eq $cod_norma_aux ) ){
			$esValido = 1;
			return $cod_norma;
		}
		elsif ($cod_norma eq ""){
			return $cod_norma;
		}
		else{
			print "Codigo de norma invalido. Ingrese nuevamente: ";
			$cod_norma = <STDIN>;
			chomp($cod_norma);
			$cod_norma_aux = $cod_norma;
			$cod_norma_aux =~ s/\s//g;
		}
			
	}				 	
}

sub ingresarFiltroPorAnio{

	print "Ingrese un rango de anios (1974-1989): ";
	$rango_anios = <STDIN>;
	chomp($rango_anios);
	
	$rango_anios = validarRango($rango_anios);		

	return $rango_anios;				
}

sub validarRango{
	$rango_anios = $_[0];
	$esValido = 0;
	
	while ( $esValido == 0 ){
		if( ( ( length($rango_anios) == 9 ) && ( $rango_anios =~ /[0-9]{4}.[0-9]{4}/ ) ) || ( length($rango_anios) == 0 )){
			return $rango_anios;
		}
		else{
			print "Rango invalido. Ingrese nuevamente: ";
			$rango_anios = <STDIN>;
			chomp($rango_anios);
		}
	}
}

sub ingresarFiltroPorNroNorma{
	
	print "Ingrese un rango Numero de Norma (52): ";
	$rango_nro_norma = <STDIN>;
	chomp($rango_nro_norma);
	$esValido = 0;

	while ( $esValido == 0 ){

		if ( ($rango_nro_norma !~ /\D+/) || (length($rango_nro_norma) == 0) ){		
			return $rango_nro_norma;		
		}
		else{
			print "Rango invalido. Ingrese nuevamente: ";
			$rango_nro_norma = <STDIN>;
			chomp($rango_nro_norma);
		}
	}		
}

sub ingresarFiltroPorCodGestion{
	print "Ingrese un Codigo de Gestion (Illia): ";
	my $cod_gestion = <STDIN>;
	chomp($cod_gestion);
	my $esValido = 0;

	while ( $esValido == 0 ){
		if (($cod_gestion =~ /[0-9]$/ ) && ($cod_gestion =~ /^[^0-9]*.$/ )){
			return $cod_gestion;
		}
		elsif (($cod_gestion =~ /[A-Za-z]+/) && ( $cod_gestion =~ /^[^0-9]*.$/ )){
			return $cod_gestion;
		}
		elsif ($cod_gestion eq ""){
			return $cod_gestion;
		}
		else {
			print "Codigo de Gestion invalido. Ingrese nuevamente: ";
			$cod_gestion = <STDIN>;
			chomp($cod_gestion);
		}
	}
}

sub ingresarFiltroPorCodEmisor{
	print "Ingrese un Codigo de Emisor (4444): ";
	$cod_emisor = <STDIN>;
	chomp($cod_emisor);
	
	$cod_emisor_aux = $cod_emisor;
	$cod_emisor_aux =~ s/\s//g;	
	$esValido = 0;
	
	# Validaciones
	while ( $esValido == 0 ){	
		if( ( ( $cod_emisor !~ /\D+/ ) && ( $cod_emisor eq $cod_emisor_aux ) ) || (length($cod_emisor) == 0) ){
			print "$cod_emisor\n";
			return $cod_emisor;
		}
		else{
			print "Codigo de emisor invalido. Ingrese nuevamente: ";
			$cod_emisor = <STDIN>;
			chomp($cod_emisor);
			$cod_emisor_aux = $cod_emisor;
			$cod_emisor_aux =~ s/\s//g;
		}
	}		
}

sub crearHashes{
	#my $dir = "/home/hernan/PROCDIR";
	my $dir = "../PROCDIR";
	find(\&tomarArchivos, $dir);
	$separador = ';';
	my @regs;

	foreach my $ruta (@rutas){
		crearHashCodNorma($ruta);
		crearHashAnio($ruta);

		open (FILE, "$ruta") or die "Falla al abrir ";
		$reg = <FILE>;
		while($reg ne ""){ 
			@regs = split($separador, $reg);		
			$i = 1;
			foreach $campo (@regs){	
				if ( $i == 3){		
					crearHashNroNorma($campo);	
				}
				if ( $i == 14){
					crearHashCodEmisor($campo);	
				}
				$i++;
			}	
			$reg = <FILE>;
		}
	}	
}

sub crearHashNroNorma{
	my $nro_norma = $_[0];
	my $ruta = $_[1];
	if (exists($hash_nro_norma{$nro_norma})){
		push($hash_nro_norma{$nro_norma}, $ruta);
	}
	else{
		$hash_nro_norma{$nro_norma}[0] = $ruta;
	}
}

sub crearHashCodEmisor{
	my $cod_emisor = $_[0];
	my $ruta = $_[1];
	if (exists($hash_cod_emisor{$cod_emisor})){
		push($hash_cod_emisor{$cod_emisor}, $ruta);
	}
	else{
		$hash_cod_emisor{$cod_emisor}[0] = $ruta;
	}
}
sub crearHashCodNorma{
	my $ruta = $_[0];
	$tamanio = length($ruta);
	$cod_norma_aux = substr($ruta, $tamanio-4);
	chomp($cod_norma_aux);
	if (exists($hash_cod_norma{$cod_norma_aux})){
		push($hash_cod_norma{$cod_norma_aux}, $ruta);
	}
	else{
		$hash_cod_norma{$cod_norma_aux}[0] = $ruta;
	}
}

sub crearHashAnio{
	my $ruta = $_[0];
	$tamanio = length($ruta);
	$anio_aux = substr($ruta, $tamanio-9,4);
	chomp($anio_aux);
	if (exists($hash_anio{$anio_aux})){
		push($hash_anio{$anio_aux}, $ruta);
	}
	else{
		$hash_anio{$anio_aux}[0] = $ruta;
	}
}


sub tomarArchivos{
	my $elem = $_;
	if (-f $elem){
		push (@rutas, "$File::Find::name\n");	
	}
	
}
sub separador{
	for (my $i = 0; $i < (split(/ /,`/bin/stty size`))[1]/4; $i+=1){ print "----"; };
	for (my $i = 0; $i < (split(/ /,`/bin/stty size`))[1]%4; $i+=1){ print "-"; };
	print "\n";
}

sub mostrarAyuda{
	separador();
	print "InfPro: El propósito de este comando es resolver consultas sobre los documentos protocolizados y emitir informes y estadisticas sobre ellos.\n";
	print "Opciones:\n";
	print "\ta:\t\tMostar ayuda.\n";
	print "\tg:\t\tGrabar.\n";
	print "\tc:\t\tConsultar.\n";
	print "\ti:\t\tInforme.\n";
	print "\te:\t\tEstadisticas.\n";
	print "\ts:\t\tSalir.\n";
	separador();
	#exit 0;
}

sub guardarPID{
	if (-e 'PidFile') {	
		open(FILE,'>>'.'PidFile') or die "Falla al abrir PidFile";
		print FILE $$."\n";		
		close(FILE);
	}else{
		print "Archivo de PID inexistente";
	}
}

sub recuperarPID{
	if (!-e 'PidFile') {	
		open(FILE,'>'.'PidFile') or die "Falla al crear PidFile";
		close(FILE);
		return 0;
	}
	if(-z 'PidFile'){
		return 0;
	}	
	if (-e 'PidFile') {
		open(FILE,'PidFile') or die "Falla al abrir PidFile";
		my @lines = <FILE>;
		close(FILE);
		@lines = reverse(@lines);
		return $lines[0];
	}
}

sub estaCorriendo{
	$pid = recuperarPID();
	if($pid){
		$exists = kill 0, $pid;
		if($exists){
			return 1;
		}else{
			return 0;
		}
	}else{
		return 0;
	}
}


use Data::Dumper;
use Getopt::Std;
use strict;
use File::Find;
#$clear_string = `clear`;

#VERIFICAR SI EL PROCESO DE INFPRO ESTA CORRIENDO
if(estaCorriendo()){
	#SI TIENE EL MISMO PID ENTONCES CIERRO EL PROCESO
	print "InfPro.pl ya esta corriendo.\n";	
	exit;
}else{
	guardarPID();
}

my %hash_cod_norma;
my %hash_anio;
my %hash_nro_norma;
my %hash_cod_emisor;

inicio();
