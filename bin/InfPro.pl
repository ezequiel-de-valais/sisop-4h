#! /usr/bin/perl -w

sub inicio{
	mostrarAyuda();
	my $opcion = menuPrincipal();
	my %hash_gestiones;
	my %hash_emisores;
	my @rutas;
	cargarHashes($opcion);
	#for $family ( keys %hash_cod_norma ) {
       	#	 print "$family: @{ $hash_cod_norma{$family}}\n";
	#}
	procesarConsulta($opcion);
	procesarEstadisticas($opcion);
	procesarInforme($opcion);
}

sub procesarEstadisticas{
	$opcion = $_[0];
	my %hash_anio_cronologico;
	my @anios_ordenados;
	@salida_estadisticas;
	
	cargarHashGestiones(%hash_gestiones);
	cargarHashEmisores(%hash_emisores);

	if ( ($opcion eq "e")|| ($entrada eq "eg") ){

		my @codigos_emisores;		
		
		$filtro_anios = ingresarFiltroPorAnio(); 	     
		$filtro_cod_gestion = ingresarFiltroPorCodGestion();
		
		@rutas_anios = candidatosPorAnios($filtro_anios);
		@rutas_cod_gestion = candidatosPorCodigoGestion($filtro_cod_gestion);

		#Busco interseccion entre los arrays de rutas
		@interseccion_rutas = do {
		    my %seen;
		    for my $x (\@rutas_anios, \@rutas_cod_gestion) {
			for my $y (@$x) {
			    $seen{$y}{$x} = undef;
			}
		    }
		    grep {2 == keys %{$seen{$_}}} keys %seen;
		};

		
		#Armo hash de anio/ruta
		foreach my $ruta (@interseccion_rutas){
			$anio = substr($ruta,length($ruta)-9,4);
			if (exists($hash_anio_cronologico{$anio})){
				push ($hash_anio_cronologico{$anio}, $ruta);
			}
			else{
				$hash_anio_cronologico{$anio}[0] = $ruta;
			}
		}
		
		@anios_ordenados = sort (keys %hash_anio_cronologico);
		my $descripcion;
		my $anio;
		my $cod_gestion;
		my $nombres_emisores;
		my $cantidad_registros;
		my $cant_resoluciones;
		my $cant_disposiciones;
		my $cant_convenios;
		my $salida_string;
		#my @rutas_del_anio_ordenado;

		my $i = 0;
		my $tam = scalar @anios_ordenados;
		
	
		while ( $i < $tam ){
			$cant_resoluciones = 0;
			$cant_disposiciones = 0;
			$cant_convenios = 0;
			$anio = @anios_ordenados[$i];
			my @rutas_del_anio_ordenado = sort (@{$hash_anio_cronologico{$anio}});
			
			my $primera_vez = 1;

			# Se tiene todas las rutas para ese anio
			my $i_2 = 0;
			my $tam_2 = scalar @rutas_del_anio_ordenado;
			
			#Leo la primera ruta para empezar las comparaciones
			$ruta = @rutas_del_anio_ordenado[$i_2];
			open(FILE, $ruta) || die "Error al abrir el archivo";
			my $reg = <FILE>;
			my @regs = split (';', $reg);		
			$cod_gestion_anterior = $regs[11];
			close (FILE);
			
			while ( $i_2 < $tam_2){
	
				$ruta = @rutas_del_anio_ordenado[$i_2];
				open(FILE, $ruta) || die "Error al abrir el archivo";
				my $reg = <FILE>;
				my @regs = split (';', $reg);

				my $cod_gestion_actual = $regs[11];

				if($cod_gestion_actual eq $cod_gestion_anterior){
					
					if ($primera_vez){
						$cod_gestion = $regs[11];
						$anio = $regs[3];
						$descripcion = $hash_gestiones{$cod_gestion};
						$primera_vez = 0;

					}
				
					my $cod_norma = $regs[12];
					chomp($cod_norma);	
					$cantidad_registros = 0;	
					while($reg ne ""){
						$cantidad_registros = $cantidad_registros + 1;
						my $cod_emisor = $regs[13];
						chomp($cod_emisor);
						if( !grep( $_ eq $cod_emisor, @codigos_emisores ) ){
							push(@codigos_emisores, $cod_emisor);
						}
						$reg = <FILE>;
						@regs = split (';', $reg);	
					}
					close(FILE);
					$nombres_emisores = "";
					foreach my $cod_emisor (@codigos_emisores){
						my $nombre_emisor = $hash_emisores{$cod_emisor};
						if ($nombre_emisor ne ""){
							if ($nombres_emisores ne ""){
								$nombres_emisores = $nombres_emisores.",".$nombre_emisor;
							}
							else{
								$nombres_emisores = $nombre_emisor;
							}
						}		
					}
					if ($cod_norma eq "RES"){$cant_resoluciones = $cantidad_registros;}
					if ($cod_norma eq "DIS"){$cant_disposiciones = $cantidad_registros;}
					if ($cod_norma eq "CON"){$cant_convenios = $cantidad_registros;}
					$i_2++;
					
				}
				else{
					$salida_string= $descripcion.";".$anio.";".$nombres_emisores.";".$cant_resoluciones.";".$cant_disposiciones.";".$cant_convenios;

					push(@salida_estadisticas, $salida_string);
	
					$cant_resoluciones = 0;
					$cant_disposiciones = 0;
					$cant_convenios = 0;
					$nombres_emisores = "";
					@codigos_emisores = ();	
					$primera_vez = 1;			
					$cod_gestion_anterior = $cod_gestion_actual;
				    }	
							
			}
			$salida_string= $descripcion.";".$anio.";".$nombres_emisores.";".$cant_resoluciones.";".$cant_disposiciones.";".$cant_convenios;
			push(@salida_estadisticas, $salida_string);				
			$cant_resoluciones = 0;
			$cant_disposiciones = 0;
			$cant_convenios = 0;
			$nombres_emisores = "";
			@codigos_emisores = ();	
			$primera_vez = 1;
			$i++;
		}
		if ($entrada eq "e"){	mostrarEstadistica();}
		else{			grabarEstadistica();}  							
	}	
}


sub grabarEstadistica{
	@rutas = ();
	my $dir = "/home/hernan/INFODIR";
	#my $dir = "/home/ezequiel/SisOpTp/INFODIR";
	#my $dir = "../INFODIR";
	find(\&tomarArchivos, $dir);

	@rutas = reverse sort(@rutas);
		
	$i = 0;
	$tam =scalar @rutas; 	
	
	$encontrado = 0;
	while ($i < $tam){
		$ruta = $rutas[$i];
		$nombre_archivo = substr($ruta, length($ruta) - 15, 10);

		if ( ($nombre_archivo eq "stadistica") && !($encontrado) ){
			$ruta_mayor = $ruta;
			$numero_mayor = substr($ruta_mayor, length($ruta_mayor)-4);
			$encontrado = 1;
		}
		$i++;
	}	
		
	$numero_siguiente = $numero_mayor + 1;
	$result = sprintf('%03d',$numero_siguiente);
	$ruta_siguiente = $dir."/"."estadistica_".$result;
	
	open(FILE, "> $ruta_siguiente") || die "Error al abrir el archivo";
	
	#Grabo la consulta
	my $i=0;
	my $tam = scalar @salida_estadisticas;
	while ($i< $tam){
		my $salida_string = @salida_estadisticas[$i];
		my ($descripcion, $anio, $nombres_emisores, $cant_resoluciones, $cant_disposiciones, $cant_convenios) = split (';', $salida_string);
		print	FILE"Gestion: $descripcion ";
		print	FILE"Anio: $anio ";
		print	FILE"Emisores: $nombres_emisores\n";
		print	FILE"Cantidad de resoluciones:  $cant_resoluciones\n";	
		print	FILE"Cantidad de disposiciones:  $cant_disposiciones\n";
		print	FILE"Cantidad de convenios:  $cant_convenios\n";
		$i++;
	}
	close(FILE);
	
	print("\nSu estadistica se ha almacenado en la siguiente ruta:\n");
	print("$ruta_siguiente\n\n");


}
sub mostrarEstadistica{
	my $i=0;
	my $tam = scalar @salida_estadisticas;
	if ($tam > 0){
		print "\nLista de estadisticas: \n\n";
		while ($i< $tam){
			my $salida_string = @salida_estadisticas[$i];
			my ($descripcion, $anio, $nombres_emisores, $cant_resoluciones, $cant_disposiciones, $cant_convenios) = split (';', $salida_string);
			print("Gestion: $descripcion ");
			print("Anio: $anio ");
			print("Emisores: $nombres_emisores\n");
			print("Cantidad de resoluciones:  $cant_resoluciones\n");	
			print("Cantidad de disposiciones:  $cant_disposiciones\n");
			print("Cantidad de convenios:  $cant_convenios\n");
			$i++;
		}
	}
	else{	print "\nNo se han encontrado nada \n\n";	}
}
sub cargarHashGestiones{
	%hash_gestiones = $_[0];

	#open(FILE, "..MAEDIR/gestiones.mae") || die "Error al abrir archivo de gestiones.mae";
	open(FILE, "/home/hernan/MAEDIR/gestiones.mae") || die "Error al abrir archivo de gestiones.mae";
	#open(FILE, "/home/ezequiel/SisOpTp/MAEDIR/gestiones.mae") || die "Error al abrir archivo de gestiones.mae";
	while(my $reg = <FILE>){
		my @regs = split(";", $reg);
		my $cod_gestion = $regs[0];
		my $descripcion = $regs[3];
		$hash_gestiones{$cod_gestion} = $descripcion;
	}
	close(FILE);
}

sub cargarHashEmisores{
	%hash_emisores = $_[0];

	#open(FILE, "..MAEDIR/emisores.mae") || die "Error al abrir archivo de emisores.mae";
	#open(FILE, "/home/ezequiel/SisOpTp/MAEDIR/emisores.mae") || die "Error al abrir archivo de gestiones.mae";
	open(FILE, "/home/hernan/MAEDIR/emisores.mae") || die "Error al abrir archivo de emisores.mae";
	while(my $reg = <FILE>){
		my @regs = split(";", $reg);
		my $cod_emisor = $regs[0];
		my $nombre_emisor = $regs[1];
		$hash_emisores{$cod_emisor} = $nombre_emisor;
	}
	close(FILE);
}

sub menuPrincipal{
	separador();
	print "\nIngrese una opción: ";
	$entrada = <STDIN>;
	chomp($entrada);	
	print "\n"; 
	
	#Loop infinito hasta que se ingrese opcion valida
	while( ($entrada !~ /[a c cg i ig e eg]/) || (length($entrada) > 3) ){
		print "Opcion incorrecta. Intente nuevamente: ";
		$entrada = <STDIN>;
		chomp($entrada);
	}
	return $entrada;
}

sub procesarInforme{
	my $opcion = "i";
	my ($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor); 	
	$separador = ';';
	#Faltaria ordenar los resultados por orden cronologico si no agrega palabra clave

	if ( ($entrada eq "i")  || ($entrada eq "ig") ){
		cargarHashPuntajes($opcion);
		if ($entrada eq "i"){
			mostrarInforme();
		}
		else{
			grabarInforme();
		}
	}
}

sub grabarInforme{
	@rutas = ();
	#my $dir = "/home/ezequiel/SisOpTp/INFODIR";
	
	my $dir = "/home/hernan/INFODIR";
	#my $dir = "../INFODIR";
	find(\&tomarArchivos, $dir);

	@rutas = reverse sort(@rutas);
	
	$i = 0;
	$tam =scalar @rutas; 	
	$encontrado = 0;

	while ($i < $tam){
		$ruta = $rutas[$i];
		$nombre_archivo = substr($ruta, length($ruta) - 12, 7);
		if ( ($nombre_archivo eq "informe") && !($encontrado) ){
			$ruta_mayor = $ruta;
			$numero_mayor = substr($ruta_mayor, length($ruta_mayor)-4);
			$encontrado = 1;
		}
		$i++;
	}	
	
	$numero_siguiente = $numero_mayor + 1;
	$result = sprintf('%03d',$numero_siguiente);
	$ruta_siguiente = $dir."/"."informe_".$result;
	
	#Grabo la consulta
	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	
	if ((scalar @puntajes_ordenados) > 0){
		
		open(FILE, "> $ruta_siguiente") || die "Error al abrir el archivo";
		for $puntaje( @puntajes_ordenados ) {
			for $reg (@{ $hash_puntajes{$puntaje}}){
				@campos = split (';', $reg);
				#Entrar a la tabla con codigo emisor y extraer el Emisor
				print FILE "$campos[0];$campos[1];$campos[2];$campos[3];$campos[4];$campos[5];$campos[6];$campos[7];$campos[8]\n";
			}	
		}
		close(FILE);			
		print("\nSu informe se ha almacenado en la siguiente ruta:\n");
		print("$ruta_siguiente\n\n");
	}
}

sub procesarConsulta{
	my $opcion = "c";
	my ($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor); 	
	$separador = ';';
	#Faltaria ordenar los resultados por orden cronologico si no agrega palabra clave

	if ( ($entrada eq "c")  || ($entrada eq "cg") ){
		cargarHashPuntajes($opcion);
		if ($entrada eq "c"){
			mostrarConsulta();
		}
		else{
			grabarConsulta();
		}
	}
}

sub cargarHashPuntajes{
		my $opcion = $_[0];
		my @rutas_cod_norma;
		my @rutas_anios;
		my @rutas_nro_norma;
		my @rutas_cod_gestion;
		my @rutas_cod_emisor;
		my @interseccion_rutas;

		$palabra_clave = ingresarPalabraClave();
		pedirFiltros($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor); 

		@rutas_cod_norma = candidatosPorCodigoNorma($filtro_cod_norma);
		@rutas_anios = candidatosPorAnios($filtro_anios);
		@rutas_nro_norma = candidatosPorNumeroNorma($filtro_nro_norma);
		@rutas_cod_gestion = candidatosPorCodigoGestion($filtro_cod_gestion);
		@rutas_cod_emisor = candidatosPorCodigoEmisor($filtro_cod_emisor);

		@interseccion_rutas = do {
		    my %seen;
		    for my $x (\@rutas_cod_norma, \@rutas_anios, \@rutas_nro_norma, \@rutas_cod_gestion, \@rutas_cod_emisor) {
			for my $y (@$x) {
			    $seen{$y}{$x} = undef;
			}
		    }
		    grep {5 == keys %{$seen{$_}}} keys %seen;
		};
		# Calculo de los pesos de las rutas
		calcularPesos($opcion, $palabra_clave, $filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor, @interseccion_rutas, %hash_puntajes);
}
sub grabarConsulta(){
	
	@rutas = ();
	#my $dir = "/home/ezequiel/SisOpTp/INFODIR";
	my $dir = "/home/hernan/INFODIR";
	#my $dir = "../INFORDIR";
	find(\&tomarArchivos, $dir);

	@rutas = reverse sort(@rutas);

	$ruta_mayor = $rutas[0];

	$numero_mayor = substr($ruta_mayor, length($ruta_mayor)-4);	
	
	$numero_siguiente = $numero_mayor + 1;

	$result = sprintf('%03d',$numero_siguiente);
	
	$ruta_siguiente = $dir."/"."resultados_".$result;
	
	open(FILE, "> $ruta_siguiente") || die "Error al abrir el archivo";
	
	#Grabo la consulta
	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	
	if ((scalar @puntajes_ordenados) > 0){
		for $puntaje( @puntajes_ordenados ) {
			for $reg (@{ $hash_puntajes{$puntaje}}){
				@campos = split (';', $reg);
				#Entrar a la tabla con codigo emisor y extraer el Emisor
				print FILE "$campos[12];$campos[13];$campos[2];$campos[3];$campos[11];$campos[1];$campos[4];$campos[5];$campos[10]\n";
			}	
		}
	}
	close(FILE);
	
	print("\nSu busqueda se ha almacenado en la siguiente ruta:\n");
	print("$ruta_siguiente\n\n");
}

sub mostrarInforme{
	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	
	#Muestro el resultado de la consulta
	if ((scalar @puntajes_ordenados) > 0){
		print "\nLista de archivos ordenados por peso: \n\n";
		for $puntaje( @puntajes_ordenados ) {
			for $reg (@{ $hash_puntajes{$puntaje}}){
				@campos = split (';', $reg);
				print "$campos[0] $campos[1] $campos[2]/$campos[3] $campos[4] $campos[5] $puntaje\n";
				print "$campos[6]\n";
				print "$campos[7]\n\n";
			}	
		}
	}
	else{
		print "\nNo se encontro ningun archivo\n";
	}

}	
sub mostrarConsulta(){

	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	
	#Muestro el resultado de la consulta
	if ((scalar @puntajes_ordenados) > 0){
		print "\nLista de archivos ordenados por peso: \n\n";
		for $puntaje( @puntajes_ordenados ) {
			for $reg (@{ $hash_puntajes{$puntaje}}){
				@campos = split (';', $reg);
				print "$campos[12] $campos[13] $campos[2]/$campos[3] $campos[11] $campos[1] $puntaje\n";
				print "$campos[4]\n";
				print "$campos[5]\n\n";
			}	
		}
	}
	else{
		print "\nNo se encontro ningun archivo\n";
	}

}

## VOLVER A FILTRAR
sub calcularPesos{
	($opcion, $palabra_clave, $filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor, @interseccion_rutas, %hash_puntajes) = @_;

	chomp($palabra_clave);  
	$cod_emisor;
	$cod_norma;
	$cod_gestion;
	$causante;	
	$extracto;
	
	for $ruta (@interseccion_rutas){

		chomp($ruta);
		open(FILE, $ruta) || die "No se pudo abrir el archivo";

		while ($reg = <FILE>){
			$puntaje = 0; 
			chomp($reg);
			@campos = split (';', $reg);
			## CHEQUEAR QUE LOS REGISTROS COINCIDEN CON LOS FILTROS	

			if ($opcion eq "i"){
			 	$cod_emisor = @campos[1];
				$cod_norma = @campos[0];
				$cod_gestion = @campos[4];
				$causante = $campos[6];	
				$extracto = $campos[7];
			}
			else {
				$cod_emisor = @campos[13];	
				$cod_norma = @campos[12];
				$cod_gestion = @campos[11];
				$causante = $campos[4];	
				$extracto = $campos[5];
			}

			if ($filtro_nro_norma ne ""){
				($nro_norma_inicial, $nro_norma_final) = split(/[ -]/, $filtro_nro_norma);
				chomp($nro_norma_inicial);
				chomp($nro_norma_final);
				$nro_norma_inicial =~ s/^0+//g;
				$nro_norma_final =~ s/^0+//g;
				if (($nro_norma_inicial > $campos[2]) || ($campos[2] > $nro_norma_final)){
					next;
				} 
			}
			if (($filtro_cod_emisor ne "")) {
				if ($filtro_cod_emisor != $cod_emisor){
					next;
				}
			}
			if (($filtro_cod_norma ne "")) {
				if ($filtro_cod_norma ne $cod_norma){
					next;
				}
			}
			if (($filtro_cod_gestion ne "")) {
				if ($filtro_cod_gestion ne $cod_gestion){
					next;
				}
			}

			chomp($causante);
			chomp($extracto);

			$puntaje += cantidadDeOcurrencias($causante, $palabra_clave)*10;
			$puntaje += cantidadDeOcurrencias($extracto, $palabra_clave)*1;

			if ( exists($hash_puntajes{$puntaje}) ){
				push ($hash_puntajes{$puntaje}, $reg);
			}
			else{
				$hash_puntajes{$puntaje}[0] = $reg;
			}
		}
	}
}

sub cantidadDeOcurrencias{
	my $text = $_[0];
	my $palabra_clave = $_[1];

	my @strings = split / /, $text;
	my $count = 0; 	

	foreach my $str (@strings) {
		if ($str eq $palabra_clave){	
			$count++;
		}
	}

	return $count;
}

sub candidatosPorCodigoEmisor(){
	my $filtro_cod_emisor = $_[0];
	my $ruta;
	my $rutas_cod_emisor;
	my @rutas_aux_cod_emisor;

	if ($filtro_cod_emisor ne ""){
		
		if ( exists($hash_cod_emisor{$filtro_cod_emisor}) ){
			for $ruta ( @{ $hash_cod_emisor{$filtro_cod_emisor} }){
				push(@rutas_cod_emisor, $ruta);
			}
		}
	}
	else{
		for $rutas_aux_cod_emisor ( keys %hash_cod_emisor ) {	
   			for $ruta ( @{ $hash_cod_emisor{$rutas_aux_cod_emisor} }){
				push(@rutas_cod_emisor, $ruta);
			}
		}
	}
	return @rutas_cod_emisor;
}

sub candidatosPorCodigoGestion{
	my $filtro_cod_gestion = $_[0];
	my $ruta;
	my $rutas_cod_gestion;
	my @rutas_aux_cod_gestion;

	if ($filtro_cod_gestion ne ""){
		
		if ( exists($hash_cod_gestion{$filtro_cod_gestion}) ){
			for $ruta ( @{ $hash_cod_gestion{$filtro_cod_gestion} }){
				push(@rutas_cod_gestion, $ruta);
			}
		}
	}
	else{
		for $rutas_aux_cod_gestion ( keys %hash_cod_gestion ) {	
   			for $ruta ( @{ $hash_cod_gestion{$rutas_aux_cod_gestion} }){
				push(@rutas_cod_gestion, $ruta);
			}
		}
	}
	return @rutas_cod_gestion;
}

sub tomarArchivosCodGestion{
	my $elem = $_;	
	if (-f $elem){
		push (@rutas_cod_gestion, "$File::Find::name\n");	
	}
}

sub candidatosPorNumeroNorma{
	my $filtro_nro_norma = $_[0];
	my $ruta;
	my $rutas_nro_norma;
	my @rutas_aux_nro_norma;

	if ($filtro_nro_norma ne ""){
		($nro_norma_inicial, $nro_norma_final) = split(/[ -]/, $filtro_nro_norma);
		chomp($nro_norma_inicial);
		chomp($nro_norma_final);
		$nro_norma_inicial =~ s/^0+//g;
		$nro_norma_final =~ s/^0+//g;

		$nro_norma = $nro_norma_inicial;
		while ($nro_norma <= $nro_norma_final){
			if ( exists($hash_nro_norma{$nro_norma}) ){
   				for $ruta ( @{ $hash_nro_norma{$nro_norma} }){
					push(@rutas_nro_norma, $ruta);
				}
			}
		$nro_norma++;
		}
	}
	else{
		for $rutas_aux_nro_norma ( keys %hash_nro_norma ) {	
   			for $ruta ( @{ $hash_nro_norma{$rutas_aux_nro_norma} }){
				push(@rutas_nro_norma, $ruta);
			}
		}
	}
	return @rutas_nro_norma;
}


sub candidatosPorAnios{
	my $filtro_anios = $_[0];
	my $ruta;
	my @rutas_anios;
	my @rutas_aux_anios;

	if ($filtro_anios ne ""){
		($anio_inicial, $anio_final) = split(/[ -]/, $filtro_anios);	
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
	else{
		for $rutas_aux_anios ( keys %hash_anio ) {	
   			for $ruta ( @{ $hash_anio{$rutas_aux_anios} }){
				push(@rutas_anios, $ruta);
			}
		}
	}

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
	             && ($filtro_cod_gestion eq "") && ($filtro_cod_emisor eq "") ){
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
	
	$rango_anios = validarRangoAnios($rango_anios);		

	return $rango_anios;				
}

sub validarRangoAnios{
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
	
	print "Ingrese un rango Numero de Norma (0001-7345): ";
	$rango_nro_norma = <STDIN>;
	chomp($rango_nro_norma);
	$esValido = 0;

	while ( $esValido == 0 ){
		if ( ( ($rango_nro_norma =~ /[0-9]{4}.[0-9]{4}/) && ( length($rango_nro_norma) == 9 ) ) || (length($rango_nro_norma) == 0) ){				
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

sub cargarHashes{
	my $opcion = $_[0];

	if (($opcion eq "c") || ($opcion eq "cg") || ($opcion eq "e") || ($opcion eq "eg")){	
		cargarHashesParaConsulta();
	}
	if (($opcion eq "i") || ($opcion eq "ig")){
		cargarHashesParaInforme();
	}	
}

sub cargarHashesParaInforme{
	#my $dir = "/home/ezequiel/SisOpTp/INFODIR";
	#my $dir = "../PROCDIR";
	my $dir = "/home/hernan/INFODIR";
	find(\&tomarArchivos, $dir);
	$separador = ';';
	my @regs;
	
	
	foreach my $ruta (@rutas){

		print "$ruta\n";
		$nombre_archivo = substr($ruta, length($ruta) - 15, 10);
		if ($nombre_archivo eq "resultados"){
			print "entro\n";	
			open (FILE, "$ruta") or die "Falla al abrir ";
			$reg = <FILE>;
			while($reg ne ""){ 
				@regs = split($separador, $reg);		
				$i = 1;
				foreach $campo (@regs){	
					if ( $i == 1){
						crearHashCodNorma($campo, $ruta);
					}	
					# Cuando se agrege el campo emisor ($i==4)			
					if ( $i == 3){	
						crearHashNroNorma($campo, $ruta);	
					}
					if ( $i == 2){
						crearHashCodEmisor($campo, $ruta);	
					}
					if ( $i == 4){
						crearHashAnio($campo, $ruta);	
					}
					if ( $i == 5){
						crearHashCodGestion($campo, $ruta);	
					}
					$i++;
				}	
				$reg = <FILE>;
			}
			close(FILE);
		}	

	}
}

sub cargarHashesParaConsulta{
	#my $dir = "/home/ezequiel/SisOpTp/PROCDIR";
	#my $dir = "../PROCDIR";
	my $dir = "/home/hernan/PROCDIR";
	find(\&tomarArchivos, $dir);
	$separador = ';';
	my @regs;
	my $esPrimero;
	$cod_gestion_aux;

	foreach my $ruta (@rutas){
		$tamanio = length($ruta);
		$cod_norma = substr($ruta, $tamanio-4);
		chomp($cod_norma);
		$anio = substr($ruta, $tamanio-9,4);
		chomp($anio);
		crearHashCodNorma($cod_norma, $ruta);
		crearHashAnio($anio, $ruta);

		open (FILE, "$ruta") or die "Falla al abrir ";
		$reg = <FILE>;
		$esPrimero = 0;

		while($reg ne ""){ 
			@regs = split($separador, $reg);		
			$i = 1;
			foreach $campo (@regs){	
				if ( $i == 3){	
					crearHashNroNorma($campo, $ruta);	
				}
				if ( $i == 14){
					crearHashCodEmisor($campo, $ruta);	
				}
				$i++;
			}
			if (!$esPrimero){	
				$cod_gestion_aux = @regs[11];	
				$esPrimero = 1;
			}

			$reg = <FILE>;
		}
		
		crearHashCodGestion($cod_gestion_aux, $ruta);
		chomp($anio);
		close(FILE);
	}
}

sub crearHashCodGestion{
	my $cod_gestion = $_[0];
	my $ruta = $_[1];	
	if (exists($hash_cod_gestion{$cod_gestion})){
		push($hash_cod_gestion{$cod_gestion}, $ruta);
	}
	else{
		$hash_cod_gestion{$cod_gestion}[0] = $ruta;
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
	chomp($cod_emisor);	

	if (exists($hash_cod_emisor{$cod_emisor})){
		push($hash_cod_emisor{$cod_emisor}, $ruta);
	}
	else{
		$hash_cod_emisor{$cod_emisor}[0] = $ruta;
	}
}
sub crearHashCodNorma{
	my $cod_norma_aux = $_[0];
	my $ruta = $_[1];
	if (exists($hash_cod_norma{$cod_norma_aux})){
		push($hash_cod_norma{$cod_norma_aux}, $ruta);
	}
	else{
		$hash_cod_norma{$cod_norma_aux}[0] = $ruta;
	}
}

sub crearHashAnio{
	my $anio_aux = $_[0];	
	my $ruta = $_[1];
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
my %hash_cod_gestion;
my %hash_puntajes;

inicio();
