% ==============================================================================
% Archivo: Logic.pl
% Módulo: Motor de Inferencia (Sistema Experto)
% Descripción: Recibe las intenciones (si/no) y los atributos extraídos por 
% el analizador sintáctico y los evalúa contra la base de datos (hechos) 
% para encontrar la profesión más adecuada mediante backtracking.
% ==============================================================================
:- encoding(utf8).
:- set_prolog_flag(encoding, utf8).
:- prolog_load_context(directory, FileDir),
   directory_file_path(FileDir, 'BD.pl', BDPath),
   directory_file_path(FileDir, 'BNF.pl', BNFPath),
   ensure_loaded([BDPath, BNFPath]).

% ------------------------------------------------------------------------------
% UTILIDADES DE MANEJO DE LISTAS
% ------------------------------------------------------------------------------

% Verifica si al menos un elemento de la primera lista existe en la segunda.
interseccion_lista([H|_], Lista2) :- member(H, Lista2), !.
interseccion_lista([_|T], Lista2) :- interseccion_lista(T, Lista2).

% Cuenta cuántos elementos en común tienen dos listas (para calificar el match).
contar_coincidencias([], _, 0).
contar_coincidencias([H|T], Lista2, N) :-
    member(H, Lista2), !,
    contar_coincidencias(T, Lista2, N1),
    N is N1 + 1.
contar_coincidencias([_|T], Lista2, N) :-
    contar_coincidencias(T, Lista2, N).

% ------------------------------------------------------------------------------
% EVALUACIÓN DEL PERFIL DEL USUARIO
% Acumula los gustos (intención: si) y rechazos (intención: no) detectados.
% ------------------------------------------------------------------------------

% Predicado para procesar la entrada y actualizar el perfil temporal
% evalua_perfil(+Intencion, +Atributos, +GustosActuales, +RechazosActuales, -NuevosGustos, -NuevosRechazos)
evalua_perfil(si, Atributos, GustosIn, RechazosIn, GustosOut, RechazosIn) :-
    append(GustosIn, Atributos, GustosOut).

evalua_perfil(no, Atributos, GustosIn, RechazosIn, GustosIn, RechazosOut) :-
    append(RechazosIn, Atributos, RechazosOut).

% ------------------------------------------------------------------------------
% REGLA PRINCIPAL DEL SISTEMA EXPERTO
% recomendar_carrera(+GustosUsuario, +RechazosUsuario, -CarreraRecomendada)
% Ejecuta el motor lógico cruzando restricciones con la Base de Datos.
% ------------------------------------------------------------------------------
recomendar_carrera(GustosUsuario, RechazosUsuario, CarreraRecomendada) :-
    % 1. findall recopila TODAS las carreras que cumplen las condiciones
    % y las guarda en el formato Coincidencias-NombreCarrera
    findall(Coincidencias-Carrera,
            (
                profesion(Carrera, Afinidades, Fortalezas, AntagoniasCarrera),
                
                % RESTRICCIÓN LÓGICA 1: El usuario NO debe detestar lo que la carrera exige
                \+ interseccion_lista(RechazosUsuario, Afinidades),
                \+ interseccion_lista(RechazosUsuario, Fortalezas),
                
                % RESTRICCIÓN LÓGICA 2: El usuario NO debe gustarle lo que la carrera rechaza
                \+ interseccion_lista(GustosUsuario, AntagoniasCarrera),
                
                % CONDICIÓN DE ÉXITO: Debe haber afinidad comprobada
                append(Afinidades, Fortalezas, PerfilCarrera),
                contar_coincidencias(GustosUsuario, PerfilCarrera, Coincidencias),
                Coincidencias > 0
            ), 
            ListaResultados),
    
    % 2. Verifica que al menos haya encontrado una carrera
    ListaResultados \= [],
    
    % 3. keysort ordena la lista de menor a mayor cantidad de coincidencias
    keysort(ListaResultados, ResultadosOrdenados),
    
    % 4. reverse le da la vuelta para extraer la de mayor coincidencia
    reverse(ResultadosOrdenados, [_MaxCoincidencias-CarreraRecomendada | _]).

% ------------------------------------------------------------------------------
% INTERFAZ CONVERSACIONAL
% Inicia una sesión interactiva en lenguaje natural con el usuario.
% ------------------------------------------------------------------------------
iniciar :-
    writeln('Hola, sé que la tarea de buscar una carrera es difícil. ¡Estamos aquí para ayudarte!'),
    writeln('Puedes escribir "salir" en cualquier momento para terminar.'),
    catch(conversacion([], []), salir, writeln('Hasta pronto, gracias por usar OrientadorCE.')).

conversacion(Gustos, Rechazos) :-
    preguntas_secuencia(Preguntas),
    procesar_preguntas(Preguntas, Gustos, Rechazos, GustosFinal, RechazosFinal),
    recomendar_y_mostrar(GustosFinal, RechazosFinal).

preguntas_secuencia([
    pregunta('Dime qué te gusta.', []),
    pregunta('¿Te gusta la tecnología y los computadores?', [tecnologia, compu, maquinas]),
    pregunta('¿Te interesan la investigación y la ciencia?', [investigacion, ciencia]),
    pregunta('¿Te gusta resolver problemas con números?', [problemas, calculo, matematicas]),
    pregunta('¿Te interesa diseñar, dibujar o crear arte?', [diseno, dibujo, creatividad, arte]),
    pregunta('¿Te atrae la naturaleza, las plantas o los animales?', [naturaleza, plantas, animales, exteriores]),
    pregunta('¿Te gusta trabajar con personas y comunicarte?', [personas, gente, humanos, hablar, escuchar]),
    pregunta('¿Te gusta escribir para el público o contar historias?', [escribir, publico]),
    pregunta('¿Te gustaría trabajar en una oficina?', [oficina]),    pregunta('¿Te gusta trabajar bajo presión o en situaciones de estrés?', [trabajar_bajo_presion]),    pregunta('¿Te interesa enseñar y tener paciencia?', [ensenar, paciencia]),
    pregunta('¿Te molesta la rutina?', [rutina])
]).

procesar_preguntas([], Gustos, Rechazos, Gustos, Rechazos).
procesar_preguntas([pregunta(Texto, Targets)|Resto], Gustos, Rechazos, GustosFinal, RechazosFinal) :-
    preguntar_y_actualizar(Texto, Targets, Gustos, Rechazos, Gustos2, Rechazos2),
    procesar_preguntas(Resto, Gustos2, Rechazos2, GustosFinal, RechazosFinal).

preguntar_y_actualizar(Texto, Targets, Gustos, Rechazos, GustosOut, RechazosOut) :-
    writeln(Texto),
    leer_respuesta(Respuesta),
    ( es_respuesta_directa_si_no(Respuesta) ->
        writeln('No respondas solo "si" o "no". Escribe una frase más completa.'),
        preguntar_y_actualizar(Texto, Targets, Gustos, Rechazos, GustosOut, RechazosOut)
    ; ( procesar_respuesta(Respuesta, Targets, Gustos, Rechazos, GustosOut, RechazosOut)
      -> true
      ; writeln('No entendí tu respuesta. Intenta expresarlo de otra forma.'),
        preguntar_y_actualizar(Texto, Targets, Gustos, Rechazos, GustosOut, RechazosOut)
      )
    ).

es_respuesta_directa_si_no(Respuesta) :-
    split_string(Respuesta, " ,.?!;:\t", " ,.?!;:\t", Tokens),
    Tokens = [Unico],
    ( Unico = "si"
    ; Unico = "sí"
    ; Unico = "no"
    ).

leer_respuesta(Respuesta) :-
    read_line_to_string(user_input, Raw),
    string_lower(Raw, Lower),
    normalize_space(string(Trim), Lower),
    ( Trim = "salir" -> throw(salir) ; Respuesta = Trim ).

procesar_respuesta(Respuesta, Targets, Gustos, Rechazos, GustosOut, RechazosOut) :-
    ( procesar_oracion(Respuesta, Intencion, Atributos)
    ; fallback_respuesta(Respuesta, Targets, Intencion, Atributos)
    ),
    interpretar_respuesta(Intencion, Respuesta, Targets, Atributos, AtributosFinal, IntencionFinal),
    evalua_perfil(IntencionFinal, AtributosFinal, Gustos, Rechazos, GustosOut, RechazosOut),
    respuesta_de_confirmacion(IntencionFinal, AtributosFinal).

fallback_respuesta(Respuesta, _, Intencion, AtributosFinal) :-
    string_lower(Respuesta, Lower),
    split_string(Lower, " ,.?!", " ,.?!", Tokens),
    maplist(atom_string, AtomTokens, Tokens),
    ( member(no, AtomTokens), \+ member(si, AtomTokens) -> Intencion = no
    ; member(si, AtomTokens), \+ member(no, AtomTokens) -> Intencion = si
    ),
    findall(A, (member(A, AtomTokens), es_atributo(A)), AtributosExtract),
    AtributosExtract \=[],
    AtributosFinal = AtributosExtract.

interpretar_respuesta(desconocido, _, _, _, _, _) :-
    !, fail.
interpretar_respuesta(rechazo_directo, Respuesta, Targets, Atributos, AtributosFinal, IntencionFinal) :-
    !,
    mapear_intencion_directa(Respuesta, IntencionFinal),
    ( Atributos ==[] -> AtributosFinal = Targets ; AtributosFinal = Atributos ),
    AtributosFinal \=[].
interpretar_respuesta(Intencion, _, Targets, Atributos, AtributosFinal, Intencion) :-
    % FIX: Evaluamos Atributos directamente para asignar a AtributosFinal una sola vez.
    ( Atributos ==[] -> AtributosFinal = Targets ; AtributosFinal = Atributos ),
    AtributosFinal \=[].

mapear_intencion_directa(Respuesta, no) :- sub_atom(Respuesta, _, _, _, 'no'), !.
mapear_intencion_directa(Respuesta, si) :- sub_atom(Respuesta, _, _, _, 'si'), !.
mapear_intencion_directa(_, desconocido).

respuesta_de_confirmacion(si, _) :-
    format('Perfecto, lo tengo.~n', []),
    !.
respuesta_de_confirmacion(no, _) :-
    format('Gracias por tu sinceridad.~n', []),
    !.
respuesta_de_confirmacion(_, _) :-
    true.

recomendar_y_mostrar(Gustos, Rechazos) :-
    ( recomendar_carrera(Gustos, Rechazos, Carrera) ->
        nombre_carrera(Carrera, Nombre),
        format('Dadas tus preferencias te recomendaría estudiar ~w.~n', [Nombre])
    ; writeln('No pude encontrar una carrera que cuadre con tus respuestas. Intenta describir mejor tus gustos.')
    ).

nombre_carrera(ingenieria_computadores, 'Ingeniería en Computadores').
nombre_carrera(psicologia, 'Psicología').
nombre_carrera(medicina, 'Medicina').
nombre_carrera(arquitectura, 'Arquitectura').
nombre_carrera(derecho, 'Derecho').
nombre_carrera(administracion, 'Administración de Empresas').
nombre_carrera(diseno_grafico, 'Diseño Gráfico').
nombre_carrera(biologia, 'Biología').
nombre_carrera(periodismo, 'Periodismo').
nombre_carrera(educacion, 'Educación').