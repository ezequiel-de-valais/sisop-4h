#! /usr/bin/perl -w 

sub inicio{

	mostrarAyuda();

	my $opcion = menuPrincipal();
	#%hash_gestiones;
	#%hash_emisores;
	my @rutas;
	#my @resultados_elegidos;
	## Levanto a memoria los archivos de gestiones y emisores
	%hash_gestiones = &cargarHashGestiones();
	%hash_emisores = &cargarHashEmisores();
	## Se carga una sola vez los hashes para las consultas
	while ($opcion ne "s"){	
		if ($opcion eq "a"){
			mostrarAyuda();
		}	 
		if (($opcion eq "c") || ($opcion eq "cg") || ($opcion eq "e") || ($opcion eq "eg")){	
			cargarHashesParaConsulta();
			procesarConsulta($opcion);
			procesarEstadisticas($opcion);
		}
		if (($opcion eq "i") || ($opcion eq "ig")){
			my @resultados_elegidos = pedirResultados();
			cargarHashesParaInforme(@resultados_elegidos);
			procesarInforme($opcion);
			
		}	
		$opcion = menuPrincipal();
	}
	#for $family ( keys %hash_cod_norma ) {
       	#	 print "$family: @{ $hash_cod_norma{$family}}\n";
	#}
}

sub pedirResultados{
	
	separador();
	print("INFORMES\n");	
	separador();
	print"\n";
	my @resultados = obtenerArchivosResultado();
	my $opcion_elegida;
	my @opciones_elegidas;
	my $correcto = 0;	
	while (!$correcto){
		my $indice = 1;
		print "Si lo desea elija la o las opciones deseadas para realizar el informe:\n";
		print "Ingrese el o los numeros de las opciones separadas por un espacio\n\n";
		foreach my $resultado (@resultados){
			print ("$indice- $resultado");
			$indice++;
		}
		$opcion_elegida = <STDIN>;
		chomp($opcion_elegida);
		@opciones_elegidas = split(' ',$opcion_elegida);		

		my $cant_opciones = scalar @opciones_elegidas;
		my $cant_resultados = scalar @resultados;
		
		if($cant_resultados >= $cant_opciones){
			my $es_numero = 1;
			my $existe_opcion = 1;
			my $iter = 0;		
			while( ($es_numero) && ($iter < $cant_opciones) && ($existe_opcion)){
				# si es una letra 
				if ($opciones_elegidas[$iter] =~ /\D+/){	
					$es_numero = 0;
				}
				# si no existe opcion
				if ( ( 1 > $opciones_elegidas[$iter] ) || ( $opciones_elegidas[$iter] > $cant_resultados ) ){
					$existe_opcion = 0;
				}
				$iter++;
			}
			if (!$es_numero){
				print("\nDebe ingresar solo numeros. Ingrese nuevamente.\n\n");				
			}
			if (!$existe_opcion){
				print("\nAlguna de las opciones ingresadas fue incorrecta. Ingrese nuevamente\n\n");
			}
			if ($es_numero && $existe_opcion){	
				$correcto = 1;
			}
		}
	}
	## Cargo en @resultados_elegidos los archivos que elijio
	my @resultados_elegidos;
	foreach my $opcion_elegida (@opciones_elegidas){
		push(@resultados_elegidos, $resultados[$opcion_elegida-1]);
	}
	return @resultados_elegidos;
}

sub obtenerArchivosResultado{

	my @resultadoss;	

	my $dir = $GRUPO.$INFODIR;	
	my @rutas = cargarArchivos($dir);

	foreach my $ruta (@rutas){
		$nombre_archivo = substr($ruta, length($ruta) - 15, 10);
		if ($nombre_archivo eq "resultados"){	
			push(@resultadoss,$ruta);
		}
	}
	@resultadoss = sort @resultadoss;
	return @resultadoss;
}

sub procesarEstadisticas{

	$opcion = $_[0];
#	my @anios_ordenados;
	%hash_anio_cronologico = ();
	#@salida_estadisticas;
	if ( ($opcion eq "e")|| ($entrada eq "eg") ){
		separador();
		print("ESTADISTICAS\n");	
		separador();
		print"\n";
		cargarSalidaEstadistica();
		if ($entrada eq "e"){	mostrarEstadistica();}
		else{			grabarEstadistica();}  							
	}
}

sub cargarSalidaEstadistica{
	my @codigos_emisores;		
	my @rutas_anios = ();
	my @rutas_cod_gestion = ();	
	my $filtro_anios = ingresarFiltroPorAnio(); 	     
	my $filtro_cod_gestion = ingresarFiltroPorCodGestion();
	my @interseccion_rutas = ();

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
	foreach my $ruta (@interseccion_rutas){
		$anio = substr($ruta,length($ruta)-9,4);
		if (exists($hash_anio_cronologico{$anio})){
			push ($hash_anio_cronologico{$anio}, $ruta);
		}
		else{
			$hash_anio_cronologico{$anio}[0] = $ruta;
		}
	}
	## Inicializo los arrays para la siguiente estadistica
	@interseccion_rutas = ();
	##
	my $descripcion;
	my $anio;
	my $cod_gestion;
	my $nombres_emisores;
	my $cantidad_registros;
	my $cant_resoluciones;
	my $cant_disposiciones;
	my $cant_convenios;
	my $salida_string;

	my @anios_ordenados = sort (keys %hash_anio_cronologico);
	my @rutas_del_anio_ordenado;
	my $tam = scalar @anios_ordenados;
	my $i = 0;
	
	## Recorro los Años ordenados y proceso
	while ( $i < $tam ){
		$cant_resoluciones = 0;
		$cant_disposiciones = 0;
		$cant_convenios = 0;
		$anio = $anios_ordenados[$i];

		## Ordeno las rutas == Ordeno por Codigo de Gestion
		@rutas_del_anio_ordenado = sort (@{$hash_anio_cronologico{$anio}});
		
		my $primera_vez = 1;

		# Se tiene todas las rutas para ese Año
		my $i_2 = 0;
		my $tam_2 = scalar @rutas_del_anio_ordenado;
		
		# Leo la primera ruta para empezar las comparaciones
		$ruta = $rutas_del_anio_ordenado[$i_2];
		open(FILE, $ruta) || die "Error al abrir el archivo";
		$reg = <FILE>;
		@regs = split (';', $reg);		
		$cod_gestion_anterior = $regs[11];
		#$cod_gestion_actual;
		close (FILE);

		## Recorro todas las rutas de ese año, puede pasar que para ese año haya gestiones distintas
		while ( $i_2 < $tam_2){

			$ruta = $rutas_del_anio_ordenado[$i_2];
			open(FILE, $ruta) || die "Error al abrir el archivo";
			$reg = <FILE>;
			@regs = split (';', $reg);

			$cod_gestion_actual = $regs[11];

			## Si el codigo de gestion coincide con el anterior voy acumulando en las variables 	
			if($cod_gestion_actual eq $cod_gestion_anterior){
				
				if ($primera_vez){
					$cod_gestion = $regs[11];
					$descripcion = $hash_gestiones{$cod_gestion};
					$primera_vez = 0;

				}
			
				my $cod_norma = $regs[12];
				chomp($cod_norma);	
				$cantidad_registros = 0;	
				while($reg = <FILE>){
					@regs = split (';', $reg);	
					$cantidad_registros = $cantidad_registros + 1;
					my $cod_emisor = $regs[13];
					chomp($cod_emisor);
					if( !grep( $_ eq $cod_emisor, @codigos_emisores ) ){
						push(@codigos_emisores, $cod_emisor);
					}
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
			## Agrego en la lista de salidas para despues mostrar
			else{
				$salida_string = $descripcion.";".$anio.";".$nombres_emisores.";".$cant_resoluciones.";".$cant_disposiciones.";".$cant_convenios;

				push(@salida_estadisticas, $salida_string);

				$cant_resoluciones = 0;
				$cant_disposiciones = 0;
				$cant_convenios = 0;
				$nombres_emisores = "";
				@codigos_emisores = ();	
				$primera_vez = 1;			
				$cod_gestion_anterior = $cod_gestion_actual;
			}								
			close(FILE);	
		}
		$salida_string = $descripcion.";".$anio.";".$nombres_emisores.";".$cant_resoluciones.";".$cant_disposiciones.";".$cant_convenios;
		push(@salida_estadisticas, $salida_string);				
		$cant_resoluciones = 0;
		$cant_disposiciones = 0;
		$cant_convenios = 0;
		$nombres_emisores = "";
		@codigos_emisores = ();	
		$primera_vez = 1;
		$i++;
	}
}
sub grabarEstadistica{
	@rutas = ();
	my $dir = $GRUPO.$INFODIR;
	my @rutas = cargarArchivos($dir);

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
	$ruta_siguiente = $dir."/estadistica_".$result;
	
	#Grabo la consulta
	my $i=0;
	my $tam = scalar @salida_estadisticas;
	#$primero = 1;

	if ($tam > 0){	

		open(FILE, "> $ruta_siguiente") || die "Error al abrir el archivo";
		while ($i< $tam){
			my $salida_string = $salida_estadisticas[$i];
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
		print("\nSu busqueda se ha almacenado en la siguiente ruta:\n");
		print("$ruta_siguiente\n\n");
		close(FILE);
	}
	else{
			print "\nNo se encontro ningun coincidencia \n\n";
	}
	@salida_estadisticas = ();
}
sub mostrarEstadistica{
	my $i=0;
	my $tam = scalar @salida_estadisticas;
	if ($tam > 0){
		print "\nLista de estadisticas: \n\n";
		while ($i< $tam){
			my $salida_string = $salida_estadisticas[$i];
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
	@salida_estadisticas = ();
}
sub cargarHashGestiones{
	my %hash_gestiones;
	$direccion_gestiones = $GRUPO.$MAEDIR."/"."gestiones.mae";
	open (FILE, $direccion_gestiones) || die "Error al abrir archivo de gestiones.mae";
	while(my $reg = <FILE>){
		my @regs = split(";", $reg);
		my $cod_gestion = $regs[0];
		my $descripcion = $regs[3];
		$hash_gestiones{$cod_gestion} = $descripcion;
	}
	close(FILE);
	return (%hash_gestiones);
}

sub cargarHashEmisores{
	my %hash_emisores;
	$direccion_emisores = $GRUPO.$MAEDIR."/"."emisores.mae";
	open(FILE, $direccion_emisores) || die "Error al abrir archivo de emisores.mae";
	while(my $reg = <FILE>){
		my @regs = split(";", $reg);
		my $cod_emisor = $regs[0];
		my $nombre_emisor = $regs[1];
		$hash_emisores{$cod_emisor} = $nombre_emisor;
	}
	close(FILE);
	return (%hash_emisores);
}

sub menuPrincipal{
	separador();
	print "\nIngrese una opción: ";
	$entrada = <STDIN>;
	chomp($entrada);	
	print "\n"; 
	#Loop infinito hasta que se ingrese opcion valida

	while( ($entrada !~ /^(a|c|i|e|s)$/) && ($entrada !~ /^(c|i|e)(g)$/) ){
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
	%hash_puntajes = ();
}

sub grabarInforme{
	@rutas = ();
	my $dir = $GRUPO.$INFODIR;
	my @rutas = cargarArchivos($dir);

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
	$ruta_siguiente = $dir."/informe_".$result;
	
	#Grabo la consulta
	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	
	if ((scalar @puntajes_ordenados) > 0){
		
		open(FILE, "> $ruta_siguiente") || die "Error al abrir el archivo";
		for $puntaje( @puntajes_ordenados ) {
			if ($puntaje>0){
				for $reg (@{ $hash_puntajes{$puntaje}}){
					@campos = split (';', $reg);
					print FILE "$campos[0];$campos[1];$campos[2];$campos[3];$campos[4];$campos[5];$campos[6];$campos[7];$campos[8];$campos[9]\n";
				}
			}
			else{
				### ARMO HASH_CRONOLOGICO: CLAVE: añomesdia, VALOR: lista de registros
				my %hash_cronologico;
				my $fecha;
				my $aaaammdd;
				my @campos;	
				for $reg (@{ $hash_puntajes{$puntaje}}){		
					@campos = split (';', $reg);
					$fecha = $campos[6];
					$aaaammdd = substr($fecha,6).substr($fecha,3,2). substr($fecha,0,2);	
					
					if (exists($hash_cronologico{$aaaammdd}))   {push ($hash_cronologico{$aaaammdd}, $reg); }
					else					{$hash_cronologico{$aaaammdd}[0] = $reg;	 }	
				}
				@fechas = keys %hash_cronologico;
				@cronologico = reverse sort{$a <=> $b} @fechas;
				for $fecha ( @cronologico ) {
					for $reg (@{ $hash_cronologico{$fecha}}){
						@campos = split (';', $reg);
						print FILE "$campos[0];$campos[1];$campos[2];$campos[3];$campos[4];$campos[5];$campos[6];$campos[7];$campos[8];$campos[9]\n";
					}
				}
			}	
		}
		close(FILE);			
		print("\nSu informe se ha almacenado en la siguiente ruta:\n");
		print("$ENV{PWD}.$ruta_siguiente\n\n"); ##CORREGIR RUTA!!!!!! IDEM PARA OtrAS GRABACIONES
	}
	else{
		print("\nNo se encontro ninguna coincidencia\n");
	}
}

sub procesarConsulta{


	$entrada = $_[0];
	my ($filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor); 	
	$separador = ';';

	#Faltaria ordenar los resultados por orden cronologico si no agrega palabra clave
	if ( ($entrada eq "c")  || ($entrada eq "cg") ){
		separador();
		print("CONSULTAS\n");	
		separador();
		print"\n";
		cargarHashPuntajes($entrada);
		if ($entrada eq "c"){
			mostrarConsulta();
		}
		else{
			grabarConsulta();
		}
	}
	%hash_puntajes = ();
}

sub cargarHashPuntajes{
		my $opcion = $_[0];
		my @rutas_cod_norma = 0;
		my @rutas_anios = 0;
		my @rutas_nro_norma = 0;
		my @rutas_cod_gestion = 0;
		my @rutas_cod_emisor = 0;
		my @interseccion_rutas = 0;

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
	
	#Grabo la consulta
	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	if ((scalar @puntajes_ordenados) > 0){
		my $dir = $GRUPO.$INFODIR;
		my @rutas = cargarArchivos($dir);

		@rutas = reverse sort(@rutas);
		if ((scalar @rutas) > 0){
			$ruta_mayor = $rutas[0];
			$numero_mayor = substr($ruta_mayor, length($ruta_mayor)-4);
		}else{
			$numero_mayor = 0;
		}
		$numero_siguiente = $numero_mayor + 1;
		$result = sprintf('%03d',$numero_siguiente);
		$ruta_siguiente = $dir."/resultados_".$result;
			
		open(FILE, "> $ruta_siguiente") || die "Error al abrir el archivo";


		for $puntaje( @puntajes_ordenados ) {
			if ($puntaje>0){
				for $reg (@{ $hash_puntajes{$puntaje}}){
					@campos = split (';', $reg);
					$nombre_emisor = $hash_emisores{$campos[13]};
					print FILE "$campos[12];$nombre_emisor;$campos[13];$campos[2];$campos[3];$campos[11];$campos[1];$campos[4];$campos[5];$campos[10]\n";
				}
			}
			else{
				### ARMO HASH_CRONOLOGICO: CLAVE: añomesdia, VALOR: lista de registros
				my %hash_cronologico;
				my $fecha;
				my $aaaammdd;
				my @campos;	
				for $reg (@{ $hash_puntajes{$puntaje}}){		
					@campos = split (';', $reg);
					$fecha = $campos[1];
					$aaaammdd = substr($fecha,6).substr($fecha,3,2). substr($fecha,0,2);	
					
					if (exists($hash_cronologico{$aaaammdd}))   {push ($hash_cronologico{$aaaammdd}, $reg); }
					else					{$hash_cronologico{$aaaammdd}[0] = $reg;	 }	
				}
				@fechas = keys %hash_cronologico;
				@cronologico = reverse sort{$a <=> $b} @fechas;
				for $fecha ( @cronologico ) {
					for $reg (@{ $hash_cronologico{$fecha}}){
						@campos = split (';', $reg);
						$nombre_emisor = $hash_emisores{$campos[13]};
						print FILE "$campos[12];$nombre_emisor;$campos[13];$campos[2];$campos[3];$campos[11];$campos[1];$campos[4];$campos[5];$campos[10]\n";
					}
				}
			}	
		}	
		print("\nSu busqueda se ha almacenado en la siguiente ruta:\n");
		print("$ruta_siguiente\n\n");
		close(FILE);
	}
	else{
			print "\nNo se encontro ningun coincidencia \n\n";
	}
}

sub mostrarInforme{
	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	#Muestro el resultado de la consulta
	if ((scalar @puntajes_ordenados) > 0){
		print "\nLista de archivos ordenados por peso: \n\n";
		for $puntaje( @puntajes_ordenados ) {
			if ($puntaje>0){
				for $reg (@{ $hash_puntajes{$puntaje}}){
					&mostrarInformePorSalidaSTD($reg);
				}	
			}
			else{
				### ARMO HASH_CRONOLOGICO: CLAVE: añomesdia, VALOR: lista de registros
				my %hash_cronologico;
				my $fecha;
				my $aaaammdd;
				my @campos;	
				for $reg (@{ $hash_puntajes{$puntaje}}){		
					@campos = split (';', $reg);
					$fecha = $campos[6];
					$aaaammdd = substr($fecha,6).substr($fecha,3,2). substr($fecha,0,2);	
					
					if (exists($hash_cronologico{$aaaammdd}))   {push ($hash_cronologico{$aaaammdd}, $reg); }
					else					{$hash_cronologico{$aaaammdd}[0] = $reg;	 }	
				}
				@fechas = keys %hash_cronologico;
				@cronologico = reverse sort{$a <=> $b} @fechas;
				for $fecha ( @cronologico ) {
					for $reg (@{ $hash_cronologico{$fecha}}){
						&mostrarInformePorSalidaSTD($reg);
					}
				}
			}
		}
	}
	else{
		print "\nNo se encontro ningun coincidencia\n";
	}

}

sub mostrarInformePorSalidaSTD(){
	my $reg=$_[0];
	my @campos = split (';', $reg);
	print "$campos[0] $campos[1]($campos[2]) $campos[3]/$campos[4] $campos[5] $campos[6] Peso=<$puntaje>\n";
	print "$campos[7]\n";
	print "$campos[8]\n\n";
}		
sub mostrarConsulta(){

	@puntajes = keys %hash_puntajes;	
	@puntajes_ordenados = reverse sort{$a <=> $b} @puntajes; 
	#Muestro el resultado de la consulta
	if ((scalar @puntajes_ordenados) > 0){
		print "\nLista de archivos ordenados por peso: \n\n";
		for $puntaje( @puntajes_ordenados ) {
			if ($puntaje > 0 ){
				for $reg (@{ $hash_puntajes{$puntaje}}){
					&mostrarConsultaPorSalidaSTD($reg);
				}
			}
			else{
				### ARMO HASH_CRONOLOGICO: CLAVE: añomesdia, VALOR: lista de registros
				my %hash_cronologico;
				my $fecha;
				my $aaaammdd;
				my @campos;	
				for $reg (@{ $hash_puntajes{$puntaje}}){		
					@campos = split (';', $reg);
					$fecha = $campos[1];
					$aaaammdd = substr($fecha,6).substr($fecha,3,2). substr($fecha,0,2);	
					
					if (exists($hash_cronologico{$aaaammdd}))   {push ($hash_cronologico{$aaaammdd}, $reg); }
					else					{$hash_cronologico{$aaaammdd}[0] = $reg;	 }	
				}
				@fechas = keys %hash_cronologico;
				@cronologico = reverse sort{$a <=> $b} @fechas;
				for $fecha ( @cronologico ) {
					for $reg (@{ $hash_cronologico{$fecha}}){
						&mostrarConsultaPorSalidaSTD($reg);
					}
				}
			}	
		}
	}
	else{
		print "\nNo se encontro ningun coincidencia\n";
	}
}

sub mostrarConsultaPorSalidaSTD(){
	my $reg=$_[0];
	my @campos = split (';', $reg);
	$nombre_emisor = $hash_emisores{$campos[13]};
	print "$campos[12] $nombre_emisor($campos[13]) $campos[2]/$campos[3] $campos[11] $campos[1] Peso=<$puntaje>\n";
	print "$campos[4]\n";
	print "$campos[5]\n\n";
}
## VOLVER A FILTRAR
sub calcularPesos{
	$opcion = $_[0];
	($opcion, $palabra_clave, $filtro_cod_norma, $filtro_anios, $filtro_nro_norma, $filtro_cod_gestion, $filtro_cod_emisor, @interseccion_rutas, %hash_puntajes) = @_;

	chomp($palabra_clave); 
	#$nro_norma; 
	#$cod_emisor;
	#$cod_norma;
	#$cod_gestion;
	#$causante;	
	#$extracto;
	
	if ($palabra_clave eq ""){
		$puntaje_min=0;
	}
	else {  $puntaje_min=1;   }

	for $ruta (@interseccion_rutas){
		chomp($ruta);
		open(FILE, $ruta) || die "No se pudo abrir el archivo";

		while ($reg = <FILE>){
			$puntaje = 0; 
			chomp($reg);
			@campos = split (';', $reg);
			## CHEQUEAR QUE LOS REGISTROS COINCIDEN CON LOS FILTROS	

			if ( ($opcion eq "i") || ($opcion eq "ig") ){
			 	$cod_emisor = $campos[2];
				$nro_norma = $campos[3];
				$cod_norma = $campos[0];
				$cod_gestion = $campos[5];
				$causante = $campos[7];	
				$extracto = $campos[8];
			}
			# opcion es "c" 0 "cg"
			else {
				$cod_emisor = $campos[13];
				$nro_norma = $campos[2];	
				$cod_norma = $campos[12];
				$cod_gestion = $campos[11];
				$causante = $campos[4];	
				$extracto = $campos[5];
			}

			if ($filtro_nro_norma ne ""){
				($nro_norma_inicial, $nro_norma_final) = split(/[ -]/, $filtro_nro_norma);
				chomp($nro_norma_inicial);
				chomp($nro_norma_final);
				$nro_norma_inicial =~ s/^0+//g;
				$nro_norma_final =~ s/^0+//g;
				if (($nro_norma_inicial > $nro_norma) || ($nro_norma > $nro_norma_final)){
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
			if ($puntaje >= $puntaje_min){
				if ( exists($hash_puntajes{$puntaje}) ){
					push ($hash_puntajes{$puntaje}, $reg);
				}
				else{
					$hash_puntajes{$puntaje}[0] = $reg;
				}
			}
		}
	}
	## Inicializo el array interseccion para la siguiente consulta
	@interseccion_rutas = ();
}

sub cantidadDeOcurrencias{
	my $text = $_[0];
	my $palabra_clave = $_[1];
	#my @strings = split (' ', $text);
	#my $count = 0; 	
	if ( $palabra_clave ne "" ){
		$count= () = $text =~ /$palabra_clave/g;
		return $count;
	}
	# La comparacion no es case sensitive
	#foreach my $str (@strings) {
		
#		if (lc($str) eq lc($palabra_clave)){	
#			$count++;
#		}
#	}
	return 0;
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
	my @rutas_aux_cod_gestion = ();
	@rutas_cod_gestion = ();

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

sub cargarHashesParaInforme{

	my @resultados_elegidos = @_;
	my $tam_resultados_elegidos = scalar @resultados_elegidos;

	my $dir = $GRUPO.$INFODIR;

	my @rutas_infodir = cargarArchivos($dir);
	my $tam_rutas_infodir = scalar @rutas_infodir;
	
	if ($tam_resultados_elegidos > 0){
		armarHashesParaInforme(@resultados_elegidos);
	}
	else{
		armarHashesParaInforme(@rutas_infodir);
	}

}

sub armarHashesParaInforme{
	my @rutas = @_;
	my $separador = ';';
	my @regs;
	%hash_cod_norma = ();
	%hash_anio = ();
	%hash_nro_norma = ();
	%hash_cod_emisor = ();
	%hash_cod_gestion = ();	

	foreach my $ruta (@rutas){
		$nombre_archivo = substr($ruta, length($ruta) - 15, 10);
		if ($nombre_archivo eq "resultados"){	
			open (FILE, "$ruta") or die "Falla al abrir ";

			while($reg = <FILE>){ 
				@regs = split($separador, $reg);		
				$i = 1;
				foreach $campo (@regs){	
					if ( $i == 1){
						crearHashCodNorma($campo, $ruta);
					}			
					if ( $i == 4){	
						crearHashNroNorma($campo, $ruta);	
					}
					if ( $i == 3){
						crearHashCodEmisor($campo, $ruta);	
					}
					if ( $i == 5){
						crearHashAnio($campo, $ruta);	
					}
					if ( $i == 6){
						crearHashCodGestion($campo, $ruta);	
					}
					$i++;
				}
			}
			close(FILE);
		}	

	}
}

sub cargarHashesParaConsulta{
	my $dir = $GRUPO.$PROCDIR;

	my @rutas = cargarArchivosDirDires($dir);
	$separador = ';';
	my @regs;
	my $esPrimero;
	#$cod_gestion_aux;
	%hash_cod_norma = ();
	%hash_anio = ();
	%hash_nro_norma = ();
	%hash_cod_emisor = ();
	%hash_cod_gestion = ();

	foreach my $ruta (@rutas){
		$tamanio = length($ruta);
		$cod_norma = substr($ruta, $tamanio-4);
		chomp($cod_norma);
		$anio = substr($ruta, $tamanio-9,4);
		chomp($anio);
		crearHashCodNorma($cod_norma, $ruta);
		crearHashAnio($anio, $ruta);

		open (FILE, "$ruta") or die "Falla al abrir ";
		
		$esPrimero = 0;

		while($reg = <FILE>){ 
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
				$cod_gestion_aux = $regs[11];	
				$esPrimero = 1;
			}

			#$reg = <FILE>;
		}
		
		crearHashCodGestion($cod_gestion_aux, $ruta);
		chomp($anio);
		close(FILE);
	}
}

sub cargarArchivosDirDires{
	$directorio_padre = $_[0];
	my @rutas;
	opendir(DP, $directorio_padre) || die "No puede abrirse el directorio $directorio_padre\n";

	while (my $nombre_directorio_hijo = readdir(DP)) {
		if ( ($nombre_directorio_hijo ne ".") && ($nombre_directorio_hijo ne "..")  && ($nombre_directorio_hijo ne "proc") ){
			$nombre_directorio_hijo = $directorio_padre."/".$nombre_directorio_hijo."/";
			if(-e $nombre_directorio_hijo){    
				opendir(DH, $nombre_directorio_hijo) || die "No puede abrirse el directorio $nombre_directorio_hijo";
				while (my $archivo = readdir(DH)) {
					if ( ($archivo ne ".") && ($archivo ne "..") ){
						$archivo = $nombre_directorio_hijo.$archivo."\n";
						push(@rutas,$archivo);
					}
				}
				close(DH);
			}
		}
	}
	closedir(DP);
	@rutas;
}

sub cargarArchivos{
	$directorio = $_[0];
	my @rutas;
	opendir(D, $directorio) || die "No puede abrirse el directorio $directorio\n";
	
	while (my $archivo = readdir(D)) {
		if ( ($archivo ne ".") && ($archivo ne "..") ){
			$archivo = $directorio."/".$archivo."\n";
			push(@rutas,$archivo);
		}
	}
	close(D);
	@rutas
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
	print "\tc:\t\tConsultar.\n";
	print "\tcg:\t\tConsultar y grabar.\n";
	print "\ti:\t\tInforme.\n";
	print "\tig:\t\tInforme y grabar.\n";
	print "\te:\t\tEstadisticas.\n";
	print "\teg:\t\tEstadisticas y grabar.\n";
	print "\ts:\t\tSalir.\n";
	separador();
	#exit 0;
}

# Valida que el ambiente se haya inicializado con el IniPro.sh

sub esAmbienteValido{

   if ( ! defined $GRUPO || $GRUPO eq "" || ! defined $PROCDIR || $PROCDIR eq "" || ! defined $MAEDIR || $MAEDIR eq "" || ! defined $INFODIR || $INFODIR eq "" || ! defined $INICIALIZADO || $INICIALIZADO ne "true")
   {
      print "Ambiente no inicializado. Ejecute el comando . IniPro.sh\n";
      return 0;
   }
   return 1;

}

# Valida que no esté corriendo alguna instancia de InfPro

sub estaInfProCorriendo{

   my $InfProPIDCant=`ps ax | grep -v "grep" | grep -v "gedit" | grep -o "InfPro.pl" | sed 's-\(^ *\)\([0-9]*\)\(.*\$\)-\2-g' | wc -l`;
   if ($InfProPIDCant > 1)
   {
      print "Ya se está ejecutando el programa InfPro. Por favor, espere a que el mismo termine.\n";
      return 0;
   }
   return 1;

}

######################
#                    #
# PROGRAMA PRINCIPAL #
#                    #
######################

#use Data::Dumper;
#use Getopt::Std;
#use strict;


#CONSTANTES

$PROCDIR = $ENV{'PROCDIR'};
$MAEDIR = $ENV{'MAEDIR'};
$INFODIR = $ENV{'INFODIR'};
$GRUPO = $ENV{'GRUPO'};
$INICIALIZADO = $ENV{'INICIALIZADO'};

# NO DEBE EJECUTARSE SI LA INICIALIZACION DE AMBIENTE NO FUE INICIALIZADA
if ( &esAmbienteValido() ){
	#VERIFICAR SI EL PROCESO DE INFPRO ESTA CORRIENDO
	if( ! &estaInfProCorriendo() ){
		#SI TIENE EL MISMO PID ENTONCES CIERRO EL PROCESO
		exit;
	}

	my %hash_cod_norma;
	my %hash_anio;
	my %hash_nro_norma;
	my %hash_cod_emisor;
	my %hash_cod_gestion;
	my %hash_puntajes;

	&inicio();
}
